classdef ModelDataset < handle
    % Class defining a dataset

    properties
        X               % time series as a cell array
        Y               % outcome array
        SubjectID       % subjects array
        XLen            % lengths of each series
        NumChannels     % number of X channels
        Name            % name of the dataset
        ChannelLabels   % names for each of the channels
    end

    properties (Dependent = true)
        NumObs          % number of observations
    end


    methods

        function self = ModelDataset( XRaw, Y, SubjectID, args )
            % Create and preprocess the data.
            % The calling function will be a data loader or
            % a function partitioning the data.
            arguments
                XRaw                    cell
                Y                       double
                SubjectID               string
                args.Name               string
                args.ChannelLabels      string
            end

            % set properties
            self.Y = Y;
            self.SubjectID = SubjectID;
            self.Name = args.Name;
            self.ChannelLabels = args.ChannelLabels;
            self.NumChannels = size( XRaw{1}, 2 );

            % create smooth functions for the data
            self.X = applyFilter( XRaw );

        end


        function NumObs = get.NumObs( self )
            % Get the number of classes
            arguments
                self            ModelDataset            
            end
               
            NumObs = length( self.Y );

        end
        
        
        % class methods
        selection = getCVPartition( self, args )

        thisSubset = partition( self, idx )

        fig = plot( self, args )

    end

    %methods (Abstract)

     %   truncate

    %end

end