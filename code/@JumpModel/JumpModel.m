classdef JumpModel
    % Class of jump models

    properties
        XDim            % X dimension (number of points) for input
        ZDim            % Z dimension (number of features)
        XChannels       % number of channels in X
        TSpan           % time-spans used in fitting
        Info            % information about the dataset
        Scale           % scaling factor for reconstruction loss

        Predictions     % training and validation predictions
        Loss            % training and validation losses
        Correlations    % training and validation correlations
        Timing          % training and evaluation execution times

        RandomSeed      % for reproducibility
    end

    methods

        function self = JumpModel( thisDataset, args )
            % Initialize the model
            arguments
                thisDataset             ModelDataset
                args.KFolds             double ...
                    {mustBeInteger, mustBePositive} = 5
                args.RandomSeed         double ...
                    {mustBeInteger, mustBePositive}
                args.ShowPlots          logical = true
                args.IdenticalPartitions logical = false
                args.Name               string = "[ModelName]"
                args.Path               string = ""
            end

            % set properties based on the data
            self.XDim = thisDataset.XDim;
            self.XChannels = thisDataset.XChannels;
            self.Info = thisDataset.Info;

            % initialize the time spans
            self.TSpan = thisDataset.TSpan;

            % set the scaling factor(s) based on all X
            self.Scale = scalingFactor( thisDataset.XInput );
          
            if isfield( args, 'randomSeed' )
                self.RandomSeed = args.RandomSeed;
            else
                self.RandomSeed = [];
            end

            self.Info.Name = args.Name;
            self.Info.Path = args.Path;

        end

        % class methods

    end

    
    methods (Static)

        [eval, pred, cor] = evaluateSet( thisModel, thisDataset )

    end

    
    methods (Abstract)

        % Train the model on the data provided
        self = train( self, thisDataset )

        % Encode features Z from X using the model - placeholder
        Z = encode( self, X )

    end

end