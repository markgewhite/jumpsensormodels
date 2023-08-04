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
                args.EncodingComponents double = 0
                args.ModelType          string ...
                    {mustBeMember( args.ModelType, ...
                            {'Linear', 'SVM', 'XGBoost'})} = 'Linear'
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
                    self.EncodingStrategy = DiscreteEncodingStrategy;
                case 'Continuous'
                    self.EncodingStrategy = FPCAEncodingStrategy( ...
                                                args.EncodingComponents );
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

    end

    
    methods (Static)

        [eval, pred, cor] = evaluateSet( thisModel, thisDataset )

    end

end