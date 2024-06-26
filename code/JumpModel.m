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
        Optimize            % whether to automatically optimize hyperparameters
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
        StoreAlignmentMetrics % store measures of signal alignment
        CompressModel       % whether to compress the models
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
                            {'Discrete', 'Continuous', 'Combined'})} = 'Continuous'
                args.Standardize            logical = true
                args.DiscreteEncodingArgs   structT
                args.ContinuousEncodingArgs struct
                args.ModelType              string ...
                    {mustBeMember( args.ModelType, ...
                            {'Linear', 'Ridge', 'Lasso', 'ElasticNet', 'LassoSelect', ...
                             'LinearOpt', 'SVM', 'XGBoost'})} = 'Linear'
                args.ModelArgs              struct
                args.Optimize               logical = true
                args.NumPredictors          double ...
                    {mustBeInteger, mustBePositive} = []
                args.EvaluateOffsets        logical = false
                args.StoreIndividualOffsets logical = false
                args.StoreIndividualBetas   logical = false
                args.StoreIndividualVIFs    logical = false
                args.StoreIndividualKSs     logical = false
                args.StoreAlignmentMetrics  logical = false
                args.CompressModel          logical = false
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
            self.Optimize = args.Optimize;
            self.EvaluateOffsets = args.EvaluateOffsets;
            self.StoreIndividualOffsets = args.StoreIndividualOffsets;            
            self.StoreIndividualBetas = args.StoreIndividualBetas;
            self.StoreIndividualVIFs = args.StoreIndividualVIFs;
            self.StoreIndividualKSs = args.StoreIndividualKSs;
            self.StoreAlignmentMetrics = args.StoreAlignmentMetrics;
            self.CompressModel = args.CompressModel;

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

                case 'Combined'

                    if isfield( args, 'DiscreteEncodingArgs' )
                        encodingArgs.DiscreteEncodingArgs = args.DiscreteEncodingArgs;
                    end
                    if isfield( args, 'ContinuousEncodingArgs' )
                        encodingArgs.ContinuousEncodingArgs = args.ContinuousEncodingArgs;
                    end
                    if exist('encodingArgs', 'var')
                        encodingArgsCell = namedargs2cell( encodingArgs );
                        self.EncodingStrategy = CombinedEncodingStrategy( encodingArgsCell{:} );
                    else
                        self.EncodingStrategy = CombinedEncodingStrategy;
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
                    modelFcn = @(data, args) fitlm( data, 'linear', args{:} );
                    self.ModelArgs.Intercept = true; % default anyway but need to set at least one argument

                case 'Ridge'
                    modelFcn = @(data, args) fitrlinear( data(:,1:end-1), data(:,end), args{:} );
                    self.ModelArgs.Regularization = 'ridge';

                case 'Lasso'
                    modelFcn = @(data, args) fitrlinear( data(:,1:end-1), data(:,end), args{:} );
                    self.ModelArgs.Regularization = 'lasso';

                case 'ElasticNet'
                    modelFcn = @(data, args) LassoModel( data(:,1:end-1), data(:,end), args{:} );
                    if ~isfield(self.ModelArgs, 'Alpha')
                        self.ModelArgs.Alpha = 0.5; % Set the default alpha value (0.5 for equal Lasso and Ridge)
                    end

                case 'LassoSelect'
                    modelFcn = @(data, args) fitrlinear( data(:,1:end-1), data(:,end), args{:} );
                    self.ModelArgs.Regularization = 'lasso';
                    self.ModelArgs.Learner = 'leastsquares';
                    self.ModelArgs.Lambda = getLassoLambda(normZ, normY, self.NumPredictors);

                case 'SVM'
                    modelFcn = @(data, args) fitrsvm( data(:,1:end-1), data(:,end), args{:} );
                    self.ModelArgs.KernelScale = 1; % default anyway but need to set at least one argument
                    if self.CompressModel
                        % do not save training data
                        self.ModelArgs.SaveSupportVectors = 'off';
                    end

                case 'XGBoost'
                    modelFcn = @(data, args) fitrensemble( data(:,1:end-1), data(:,end), args{:} );
                    self.ModelArgs.Method = 'LSBoost';
                    self.ModelArgs.NumLearningCycles = 200;
                    self.ModelArgs.LearnRate = 0.1;

            end

            if self.Optimize && self.ModelType~="Linear" && self.ModelType~="ElasticNet"
                self.ModelArgs.OptimizeHyperparameters = 'auto';
                self.ModelArgs.HyperparameterOptimizationOptions.Kfold = 2;
                self.ModelArgs.HyperparameterOptimizationOptions.Repartition = true;
                self.ModelArgs.HyperparameterOptimizationOptions.Verbose = 0;
                self.ModelArgs.HyperparameterOptimizationOptions.ShowPlots = false;
                self.ModelArgs.HyperparameterOptimizationOptions.MaxObjectiveEvaluations = 20;
            end

            warning('off', 'all');
            
            % fit the model with optional additional arguments
            modelArgCell = namedargs2cell( self.ModelArgs );
            self.Model = modelFcn( data, modelArgCell );

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

            if self.CompressModel
                % clear memory
                self.Y = [];
                self.YHat = [];
                if ~strcmp(self.ModelType, 'SVM')
                    self.Model = compact( self.Model );
                end
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

            if isa(self.EncodingStrategy, 'FPCAEncodingStrategy')

                eval.RoughnessPenaltyLog10 = log10(self.EncodingStrategy.Lambda);
                if self.StoreAlignmentMetrics
                    % record alignment metrics
                    alignmentMetrics = self.EncodingStrategy.calcMetrics( thisDataset );

                    eval.AlignmentRMSE = alignmentMetrics.rmse;
                    eval.AlignmentPCC = alignmentMetrics.pcc;
                    eval.AlignmentNCC = alignmentMetrics.ncc;
                    eval.AlignmentTDE = alignmentMetrics.tde;
                    eval.AlignmentMI = alignmentMetrics.mi;
                    eval.AlignmentSNR = alignmentMetrics.snr;

                    eval.AlignmentOffsetRMSE = 1000*sqrt(mean(self.EncodingStrategy.FittedAlignmentIdx.^2)) ...
                                                /self.EncodingStrategy.SamplingFreq;
                end
                 
            end

            if extras 
                % calculate extra metrics, first from the model fit

                switch self.ModelType
                    
                    case 'Linear'

                        eval.RankDeficient = self.IsRankDeficient;
                        eval.RSquared = self.Model.Rsquared.Ordinary;
                        eval.Shrinkage = self.Model.Rsquared.Ordinary - ...
                                            self.Model.Rsquared.Adjusted;

                        if self.StoreIndividualBetas
                            % record the standardized beta coefficients
                            names = self.Model.CoefficientNames;
                            names{1} = "Intercept";
                            for i = 1:self.Model.NumCoefficients
                                eval.(['Beta' char(names{i})]) = self.Model.Coefficients.Estimate(i);
                            end
                        end

                        if ~self.CompressModel
                            eval.FStat = self.Model.ModelFitVsNullModel.Fstat;
                            eval.FStatPValue = self.Model.ModelFitVsNullModel.Pvalue;
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

                            [skew, kurt] = skewKurt( self.Model );
                            eval.SkewnessMean = mean(skew);
                            eval.KurtosisMean = mean(kurt);

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
                        end


                    case {'Ridge', 'Lasso'}

                        % record the hyperparameters
                        eval.LRLambdaLog10 = log10(self.Model.Lambda);
                        eval.LRLearner = strcmp(self.Model.Learner, 'leastsquares');

                        % record the shrunk beta coefficients
                        for i = 1:length(self.Model.Beta)
                            eval.(['Beta' num2str(i)]) = self.Model.Beta(i);
                        end

                    case 'ElasticNet'
                        % record the hyperparameters
                        eval.ElasticNetAlpha = self.ModelArgs.Alpha;
                        eval.ElasticNetLambda = self.Model.Lambda;
                    
                        % record the shrunk beta coefficients
                        for i = 1:length(self.Model.Beta)
                            eval.(['Beta' num2str(i)]) = self.Model.Beta(i);
                        end
                
                    case 'SVM'

                        % record the hyperparameters
                        eval.SVMBoxConstraintLog10 = mean(log10(self.Model.BoxConstraints));
                        eval.SVMKernelScaleLog10 = log10(self.Model.KernelParameters.Scale);
                        eval.SVMEpsilonLog10 = log10(self.Model.Epsilon);

                    case 'XGBoost'

                        % record the hyperparameters
                        eval.XGBMethod = strcmp(self.Model.Method, 'Bag');
                        eval.XGBNumLearningCycles = self.Model.ModelParameters.NLearn;
                        eval.XGBLearnRate = self.Model.ModelParameters.LearnRate;

                end

            end
            
        end

    end

end


function [lambda, selection] = getLassoLambda( X, y, p, alpha )
    % Determine lambda required to obtain specified number of predictors
    arguments
        X           double
        y           double
        p           double {mustBeInteger, mustBePositive}
        alpha       double {mustBeInRange(alpha, 0, 1)} = 1 % Default to Lasso
    end

    % Fit lasso model with a wide range of lambda values
    [B, fitInfo] = lasso(X, y, Alpha=alpha, NumLambda=100);

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
