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
    end

    methods

        function self = JumpModel( thisDataset, args )
            % Initialize the model
            arguments
                thisDataset             ModelDataset
                args.Name               string = "[ModelName]"
                args.Path               string = ""
                args.EncodingType       string ...
                    {mustBeMember( args.EncodingType, ...
                            {'Discrete', 'Continuous'})} = 'Continuous'
                args.DiscreteEncodingArgs   struct
                args.ContinuousEncodingArgs struct
                args.ModelType          string ...
                    {mustBeMember( args.ModelType, ...
                            {'Linear', 'LinearReg', 'LinearOpt', 'SVM', 'XGBoost'})} = 'Linear'
                args.ModelArgs          struct
            end

            % set properties based on inputs
            self.ModelName = args.Name;
            self.DatasetName = thisDataset.Name;
            self.NumObs = thisDataset.NumObs;
            self.NumChannels = thisDataset.NumChannels;
            self.Path = args.Path;
            self.ModelType = args.ModelType;

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
            stdZ = (Z-self.ZMean)./self.ZStd;
            
            % standardize the outcome
            self.YMean = mean( thisDataset.Y );
            self.YStd = std( thisDataset.Y );
            stdY = (thisDataset.Y - self.YMean)/self.YStd;

            % select the model
            switch self.ModelType
                case 'Linear'
                    modelFcn = @(z, y) fitlm( z, y, 'linear' );
                case 'LinearReg'
                    modelFcn = @fitrlinear;
                case 'LinearOpt'
                    modelFcn = @(z, y) fitrlinear( z, y, OptimizeHyperparameters='auto' );
                case 'SVM'
                    modelFcn = @fitrsvm;
                case 'XGBoost'
                    modelFcn = @fitrensemble;
            end

            % fit the model with optional additional arguments
            if isempty(self.ModelArgs)
                self.Model = modelFcn( stdZ, stdY );
            else
                modelArgCell = namedargs2cell( self.ModelArgs );
                self.Model = modelFcn( stdZ, stdY, modelArgCell{:} );
            end

        end


        function self = evaluate( self, thisTrnSet, thisValSet )
            % Evaluate the model with a specified dataset
            arguments
                self            JumpModel
                thisTrnSet      ModelDataset
                thisValSet      ModelDataset
            end
        
            [self.Loss.Training, self.Y.Training, self.YHat.Training] = ...
                self.evaluateSet( self, thisTrnSet );
        
            if thisValSet.NumObs > 0
                [self.Loss.Validation, self.Y.Validation, self.YHat.Validation] = ...
                    self.evaluateSet( self, thisValSet );   
            end
    
        end

    end

    
    methods (Static)

        function [eval, stdY, stdYHat] = evaluateSet( self, thisDataset )
            % Evaluate the model with a specified dataset
            arguments
                self            JumpModel
                thisDataset     ModelDataset
            end
        
            % generate the encoding
            Z = self.EncodingStrategy.extractFeatures( thisDataset );
            stdZ = (Z - self.ZMean)./self.ZStd;

            % get the ground truth
            stdY = (thisDataset.Y - self.YMean)./self.YStd;

            % generate the predictions
            stdYHat = predict( self.Model, stdZ );
        
            % compute standardized loss
            eval.StdRMSE = sqrt(mean((stdYHat - stdY).^2));

            % re-scaled loss
            eval.RMSE = eval.StdRMSE*self.YStd;

            % F-statistic (if linear)
            if ismember( self.ModelType, {'Linear', 'LinearReg'} )
                eval.FStat = self.Model.ModelFitVsNullModel.Fstat;
                eval.FStatPValue = self.Model.ModelFitVsNullModel.Pvalue;
                eval.RSquared = self.Model.Rsquared.Ordinary;
                eval.Shrinkage = self.Model.Rsquared.Ordinary - ...
                                    self.Model.Rsquared.Adjusted;
                eval.OutlierProp = sum(abs(self.Model.Residuals.Studentized)>2)/self.NumObs;
            end
            
        end

    end

end