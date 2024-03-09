classdef JumpModel < handle
    % Class of jump models

    properties
        ModelName           % name of the model
        DatasetName         % name of the dataset
        NumObs              % number of observations
        NumChannels         % number of data channels
        NumPredictors       % number of predictors
        PredictorSelection  % logical array of selected predictors
        Path                % file path for storing outputs
        EncodingStrategy    % encoding strategy
        PredictorNames      % name of predictors used in the model
        Standardize         % whether to standardize the predictors
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
                args.Standardize            logical = true
                args.DiscreteEncodingArgs   struct
                args.ContinuousEncodingArgs struct
                args.ModelType              string ...
                    {mustBeMember( args.ModelType, ...
                            {'Linear', 'Ridge', 'Lasso', 'LassoSelect', ...
                             'LinearOpt', 'SVM', 'XGBoost'})} = 'Linear'
                args.ModelArgs              struct
                args.NumPredictors          double ...
                    {mustBeInteger, mustBePositive} = []
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
            self.Standardize = args.Standardize;
            self.NumPredictors = args.NumPredictors;
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

            if self.Standardize
                % standardize the encoding
                self.ZMean = mean( Z );
                self.ZStd = std( Z );
                normZ = (Z-self.ZMean)./self.ZStd;
            else
                normZ = Z;
            end
            
            % standardize the outcome
            self.YMean = mean( thisDataset.Y );
            self.YStd = std( thisDataset.Y );
            normY = (thisDataset.Y - self.YMean)/self.YStd;

            % select predictors (based on Lasso, if required)
            if ~isempty(self.NumPredictors) && ~strcmp(self.ModelType, 'LassoSelect')
                [~, self.PredictorSelection] = getLassoLambda(normZ, normY, self.NumPredictors);
            else
                self.PredictorSelection = true(1, length(self.EncodingStrategy.Names) );
            end
            % select those predictors
            normZ = normZ(:, self.PredictorSelection);
            self.PredictorNames = self.EncodingStrategy.Names(self.PredictorSelection);

            % create the training data table
            data = array2table( [normZ, normY], ...
                                VariableNames = [self.PredictorNames "Outcome"]);

            % select the model
            switch self.ModelType
                case 'Linear'
                    modelFcn = @(data) fitlm( data, 'linear' );
                case 'Ridge'
                    modelFcn = @(data) fitrlinear( data(:,1:end-1), data(:,end), Regularization = 'ridge' );
                case 'Lasso'
                    modelFcn = @(data) fitrlinear( data(:,1:end-1), data(:,end), Regularization = 'lasso' );
                case 'LassoSelect'
                    modelFcn = @(data) fitrlinear( data(:,1:end-1), data(:,end), ...
                                           Regularization = 'lasso', ...
                                           Learner = 'leastsquares', ...
                                           Lambda= getLassoLambda(normZ, normY, self.NumPredictors));
                case 'LinearOpt'
                    modelFcn = @(data) fitrlinear( data(:,1:end-1), data(:,end), OptimizeHyperparameters='auto' );
                case 'SVM'
                    modelFcn = @(data) fitrsvm( data(:,1:end-1), data(:,end) );
                case 'XGBoost'
                    modelFcn = @(data) fitrensemble( data(:,1:end-1), data(:,end), Method = 'LSBoost', ...
                        NumLearningCycles = 200, LearnRate = 0.1);
            end

            warning('off', 'all');
            % fit the model with optional additional arguments
            if isempty(self.ModelArgs)
                self.Model = modelFcn( data );
            else
                modelArgCell = namedargs2cell( self.ModelArgs );
                self.Model = modelFcn( data, modelArgCell{:} );
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

            % standardize if required
            if self.Standardize
                Z = (Z - self.ZMean)./self.ZStd;
            else
                Z = Z;
            end

            % select the relevant features
            Z = Z(:, self.PredictorSelection);

            % get the ground truth
            stdY = (thisDataset.Y - self.YMean)./self.YStd;

            % generate the predictions
            stdYHat = predict( self.Model, Z );
        
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
                            names = self.Model.CoefficientNames;
                            names{1} = "Intercept";
                            for i = 1:self.Model.NumCoefficients
                                eval.(['Beta' char(names{i})]) = self.Model.Coefficients.Estimate(i);
                            end
                        end

                        if self.StoreIndividualVIFs
                            % store the VIFs as well
                            for i = 1:self.Model.NumCoefficients-1
                                eval.(['VIF' char(names{i})]) = modelVIFs(i);
                            end
                        end

                        if self.StoreIndividualKSs
                            % store the KS too
                            for i = 1:self.Model.NumCoefficients-1
                                eval.(['KS' char(names{i})]) = KS(i);
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


function [lambda, selection] = getLassoLambda( X, y, p )
    % Determine lambda required to obtain specified number of predictors
    arguments
        X           double
        y           double
        p           double {mustBeInteger, mustBePositive}
    end

    % Fit lasso model with a wide range of lambda values
    [B, fitInfo] = lasso(X, y, NumLambda = 100);

    % find the index of the lambda value that gives the desired number of predictors
    lambdaIdx = find(fitInfo.DF==p, 1);
    
    if isempty(lambdaIdx)
        % find the nearest lambda value instead
        [~, nearestIndex] = min(abs(fitInfo.DF - p));
        nearestLambda = fitInfo.Lambda(nearestIndex);

        % refine the search around the nearest lambda value
        refineFactors = logspace( -0.2, 0.2, 100 );
        refinedLambdas = nearestLambda*refineFactors;
    
        % rerun lasso with the refined lambda values
        [BRefined, fitInfo] = lasso(X, y, Lambda = refinedLambdas);
        
        % Find the index of the refined lambda value that gives the desired number of predictors
        lambdaRefinedIdx = find(fitInfo.DF==p, 1);
    
        if isempty(lambdaRefinedIdx)
            lambda = nearestLambda;
            selection = (B(:, nearestIndex)~=0);
        else
            lambda = fitInfo.Lambda(lambdaRefinedIdx);
            selection = (BRefined(:, lambdaRefinedIdx)~=0);
        end

    else
        % extract the lambda found
        lambda = fitInfo.Lambda(lambdaIdx);
        selection = (B(:, lambdaIdx)~=0);

    end

end
