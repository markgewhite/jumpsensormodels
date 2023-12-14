classdef JumpModel < handle
    % Class of jump models

    properties
        ModelName           % name of the model
        DatasetName         % name of the dataset
        NumObs              % number of observations
        NumChannels         % number of data channels
        Path                % file path for storing outputs
        EncodingStrategy    % encoding strategy
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
                            {'Linear', 'Linear2', 'SVM', 'XGBoost'})} = 'Linear'
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

            % select the model
            switch self.ModelType
                case 'Linear'
                    modelFcn = @fitrlinear;
                case 'Linear2'
                    modelFcn = @(z, y) fitlm( z, y, 'linear' );
                case 'SVM'
                    modelFcn = @fitrsvm;
                case 'XGBoost'
                    modelFcn = @fitrensemble;
            end

            % fit the model with optional additional arguments
            if isempty(self.ModelArgs)
                self.Model = modelFcn( Z, thisDataset.Y );
            else
                modelArgCell = namedargs2cell( self.ModelArgs );
                self.Model = modelFcn( Z, thisDataset.Y, modelArgCell{:} );
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

        function [eval, Y, YHat] = evaluateSet( self, thisDataset )
            % Evaluate the model with a specified dataset
            arguments
                self            JumpModel
                thisDataset     ModelDataset
            end
        
            % generate the encoding
            Z = self.EncodingStrategy.extractFeatures( thisDataset );

            % get the ground truth
            Y = thisDataset.Y;

            % generate the predictions
            YHat = predict( self.Model, Z );
        
            % compute loss
            eval.RMSE = sqrt(mean((YHat - Y).^2));

        end

    end

end