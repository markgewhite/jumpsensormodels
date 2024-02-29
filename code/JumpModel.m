classdef JumpModel < handle
    % Class of jump models

    properties
        ModelName           % name of the model
        DatasetName         % name of the dataset
        NumObs              % number of observations
        NumChannels         % number of data channels
        Path                % file path for storing outputs
        EncodingStrategy    % encoding strategy
        ZMean               % training encoding means
        ZStd                % training encoding standard deviations
        YMean               % training outcome mean
        YStd                % training outcome standard deviation        
        ModelType           % type of model
        Model               % fitted model
        ModelArgs           % specific arguments for the model
        Timing              % struct holding execution times
        Loss                % loss
        Y                   % ground truth structure Y values
        YHat                % predictions structure YHat values
        IsRankDeficient     % flag indicating rank deficiency
        EvaluateOffsets     % whether to compute stats on signal offsets
        StoreIndividualOffsets % store signal offsets
        StoreIndividualBetas% store linear models' beta coefficients
        StoreIndividualVIFs % store measures of betas' multicollinearity
        StoreIndividualKSs  % store measures of betas' normality
    end

    methods

        function self = JumpModel( thisDataset, args )
            % Initialize the model
            arguments
                thisDataset                 ModelDataset
                args.Name                   string = "[ModelName]"
                args.Path                   string = ""
                args.EncodingType           string ...
                    {mustBeMember( args.EncodingType, ...
                            {'Discrete', 'Continuous'})} = 'Continuous'
                args.DiscreteEncodingArgs   struct
                args.ContinuousEncodingArgs struct
                args.ModelType              string ...
                    {mustBeMember( args.ModelType, ...
                            {'Linear', 'Ridge', 'Lasso', ...
                             'LinearOpt', 'SVM', 'XGBoost'})} = 'Linear'
                args.ModelArgs              struct
                args.EvaluateOffsets        logical = false
                args.StoreIndividualOffsets logical = false
                args.StoreIndividualBetas   logical = false
                args.StoreIndividualVIFs    logical = false
                args.StoreIndividualKSs     logical = false
            end

            % set properties based on inputs
            self.ModelName = args.Name;
            self.DatasetName = thisDataset.Name;
            self.NumObs = thisDataset.NumObs;
            self.NumChannels = thisDataset.NumChannels;
            self.Path = args.Path;
            self.ModelType = args.ModelType;
            self.EvaluateOffsets = args.EvaluateOffsets;
            self.StoreIndividualOffsets = args.StoreIndividualOffsets;            
            self.StoreIndividualBetas = args.StoreIndividualBetas;
            self.StoreIndividualVIFs = args.StoreIndividualVIFs;
            self.StoreIndividualKSs = args.StoreIndividualKSs;

            if isfield( args, 'ModelArgs' )
                self.ModelArgs = args.ModelArgs;
            else
                self.ModelArgs = [];
            end

            % initialise
            switch args.EncodingType
                case 'Discrete'

                    if isfield( args, 'DiscreteEncodingArgs' )
                        encodingArgs = namedargs2cell( args.DiscreteEncodingArgs );
                        self.EncodingStrategy = DiscreteEncodingStrategy( encodingArgs{:} );
                    else
                        self.EncodingStrategy = DiscreteEncodingStrategy;
                    end

                case 'Continuous'

                    if isfield( args, 'ContinuousEncodingArgs' )
                        encodingArgs = namedargs2cell( args.ContinuousEncodingArgs );
                        self.EncodingStrategy = FPCAEncodingStrategy( encodingArgs{:} );
                    else
                        self.EncodingStrategy = FPCAEncodingStrategy;
                    end
                    
            end

        end


        function train( self, thisDataset )
            % Train the model
            arguments
                self            JumpModel
                thisDataset     ModelDataset
            end

            % fit the encoding model
            self.EncodingStrategy.fit( thisDataset );

            % generate the encoding
            Z = self.EncodingStrategy.extractFeatures( thisDataset );

            % standardize the encoding
            self.ZMean = mean( Z );
            self.ZStd = std( Z );
            normZ = (Z-self.ZMean)./self.ZStd;
            
            % standardize the outcome
            self.YMean = mean( thisDataset.Y );
            self.YStd = std( thisDataset.Y );
            normY = (thisDataset.Y - self.YMean)/self.YStd;

            % select the model
            switch self.ModelType
                case 'Linear'
                    modelFcn = @(z, y) fitlm( z, y, 'linear' );
                case 'Ridge'
                    modelFcn = @(z, y ) fitrlinear( z, y, Regularization = 'ridge' );
                case 'Lasso'
                    modelFcn = @(z, y ) fitrlinear( z, y, Regularization = 'lasso' );
                case 'LinearOpt'
                    modelFcn = @(z, y) fitrlinear( z, y, OptimizeHyperparameters='auto' );
                case 'SVM'
                    modelFcn = @fitrsvm;
                case 'XGBoost'
                    modelFcn = @(z, y) fitrensemble( z, y, Method = 'LSBoost', ...
                        NumLearningCycles = 200, LearnRate = 0.1);
            end

            warning('off', 'all');
            % fit the model with optional additional arguments
            if isempty(self.ModelArgs)
                self.Model = modelFcn( normZ, normY );
            else
                modelArgCell = namedargs2cell( self.ModelArgs );
                self.Model = modelFcn( normZ, normY, modelArgCell{:} );
            end
            if ~isempty(lastwarn)
                self.IsRankDeficient = strcmp( lastwarn, ...
                    'Regression design matrix is rank deficient to within machine precision.');
            end
            warning('on', 'all');

        end


        function self = evaluate( self, thisTrnSet, thisValSet )
            % Evaluate the model with a specified dataset
            arguments
                self            JumpModel
                thisTrnSet      ModelDataset
                thisValSet      ModelDataset
            end
        
            [self.Loss.Training, self.Y.Training, self.YHat.Training] = ...
                self.evaluateSet( self, thisTrnSet, true );
        
            if thisValSet.NumObs > 0
                [self.Loss.Validation, self.Y.Validation, self.YHat.Validation] = ...
                    self.evaluateSet( self, thisValSet );   
            end
    
        end

    end

    
    methods (Static)

        function [eval, stdY, stdYHat] = evaluateSet( self, thisDataset, extras )
            % Evaluate the model with a specified dataset
            arguments
                self            JumpModel
                thisDataset     ModelDataset
                extras          logical = false
            end
        
            % generate the encoding
            [ Z, offsets] = self.EncodingStrategy.extractFeatures( thisDataset );
            stdZ = (Z - self.ZMean)./self.ZStd;

            % get the ground truth
            stdY = (thisDataset.Y - self.YMean)./self.YStd;

            % generate the predictions
            stdYHat = predict( self.Model, stdZ );
        
            % compute standardized loss
            eval.StdRMSE = sqrt(mean((stdYHat - stdY).^2));

            % re-scaled loss
            eval.RMSE = eval.StdRMSE*self.YStd;

            if self.EvaluateOffsets
                % store the offsets
                eval.OffsetMean = mean( offsets );
                eval.OffsetSD = std( offsets );
                eval.OffsetSDRatio = eval.OffsetSD/std(thisDataset.ReferenceIdx);
                eval.OffsetCV = eval.OffsetSD./eval.OffsetMean;
                eval.OffsetMax = max( offsets );
                eval.OffsetMin = min( offsets );
            end

            if self.StoreIndividualOffsets
                for i = 1:length(offsets)
                    eval.(['Offsets' num2str(i)]) = offsets(i);
                end
            end

            % F-statistic (if linear)
            if extras 
                % calculate extra metrics, first from the model fit

                switch self.ModelType
                    
                    case 'Linear'

                        eval.RankDeficient = self.IsRankDeficient;

                        eval.FStat = self.Model.ModelFitVsNullModel.Fstat;
                        eval.FStatPValue = self.Model.ModelFitVsNullModel.Pvalue;
                        eval.RSquared = self.Model.Rsquared.Ordinary;
                        eval.Shrinkage = self.Model.Rsquared.Ordinary - ...
                                            self.Model.Rsquared.Adjusted;
                        eval.StudentizedOutlierProp = sum(abs(self.Model.Residuals.Studentized)>2)/self.NumObs;
                        eval.CookMeanOutlierProp = sum(self.Model.Diagnostics.CooksDistance>...
                                                    4*mean(self.Model.Diagnostics.CooksDistance))/self.NumObs;
                
                        % calculate VIF to test for multicollinearity
                        modelVIFs = vif( self.Model );
                        eval.VIFHighProp = sum( modelVIFs>10 )/(self.Model.NumCoefficients-1);
        
                        % test for normality
                        [p, KS] = kolmogorovSmirnov( self.Model );
                        eval.KSNotNormalProp = sum( p<0.05 )/(self.Model.NumCoefficients-1);
                        eval.KSMedian = median(KS);

                        if self.StoreIndividualBetas
                            % record the standardized beta coefficients
                            for i = 1:self.Model.NumCoefficients
                                eval.(['Beta' num2str(i)]) = self.Model.Coefficients.Estimate(i);
                            end
                        end

                        if self.StoreIndividualVIFs
                            % store the VIFs as well
                            for i = 1:self.Model.NumCoefficients-1
                                eval.(['VIF' num2str(i)]) = modelVIFs(i);
                            end
                        end

                        if self.StoreIndividualKSs
                            % store the KS too
                            for i = 1:self.Model.NumCoefficients-1
                                eval.(['KS' num2str(i)]) = KS(i);
                            end
                        end

                    case {'Ridge', 'Lasso'}

                        % record the hyperparameters
                        eval.Epsilon = self.Model.Epsilon;
                        eval.Lambda = self.Model.Lambda;

                        % record the shrunk beta coefficients
                        for i = 1:length(self.Model.Beta)
                            eval.(['Beta' num2str(i)]) = self.Model.Beta(i);
                        end
                
                    case 'SVM'

                        % record the hyperparameters
                        eval.Epsilon = self.Model.Epsilon;


                end

            end
            
        end

    end

end