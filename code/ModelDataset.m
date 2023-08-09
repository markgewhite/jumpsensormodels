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

            % store series lengths
            self.XLen = cellfun( @length, XRaw );

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


        function thisSubset = partition( self, idx )
            % Create the subset of this ModelDataset
            % using the indices specified
            arguments
                self        ModelDataset
                idx         logical 
            end
        
            thisSubset = self;
        
            thisSubset.X = self.X( idx );
            thisSubset.XLen = self.XLen( idx );
            thisSubset.Y = self.Y( idx );
            thisSubset.SubjectID = self.SubjectID( idx );
    
        end


        function selection = getCVPartition( self, args )
            % Generate a CV partition for the dataset
            arguments
                self                ModelDataset
                args.Holdout        double ...
                    {mustBeInRange(args.Holdout, 0, 1)}
                args.KFolds         double ...
                    {mustBeInteger, mustBePositive}
                args.Repeats        double ...
                    {mustBeInteger, mustBePositive} = 1
                args.Identical      logical = false
            end
        
            if ~isfield( args, 'Holdout' ) && ~isfield( args, 'KFolds' )
                eid = 'ModelDataset:PartitioningNotSpecified';
                msg = 'Partitioning scheme not specified.';
                throwAsCaller( MException(eid,msg) );
            end
        
            if isfield( args, 'Holdout' ) && isfield( args, 'KFolds' )
                eid = 'ModelDataset:PartitioningOverSpecified';
                msg = 'Two partitioning schemes specified, not one.';
                throwAsCaller( MException(eid,msg) );
            end
        
            unit = self.S;
            uniqueUnit = unique( unit );
        
            if isfield( args, 'Holdout' )
        
                if args.Holdout > 0
                    % holdout partitioning
                    cvpart = cvpartition( length( uniqueUnit ), ...
                                              Holdout = args.Holdout );
                    selection = ismember( unit, uniqueUnit( training(cvpart) ));
                else
                    % no partitioning - select all
                    selection = true( self.NumObs, 1 );
                end
              
            else
                % K-fold partitioning
                if args.KFolds > 1
        
                    selection = false( self.NumObs, args.KFolds, args.Repeats );
                    for r = 1:args.Repeats
        
                        if r==1 || ~args.Identical
                            cvpart = cvpartition( length( uniqueUnit ), ...
                                                  KFold = args.KFolds );
                        end
                        
                        if length( uniqueUnit ) <= length( unit )
                            % partitioning unit is a grouping variable
                            for k = 1:args.KFolds
                                if args.Identical
                                    % special case - make all partitions the same
                                    f = 1;
                                else
                                    f = k;
                                end
                                selection( :, k, r ) = ismember( unit, ...
                                                uniqueUnit( training(cvpart,f) ));
                            end
                        else
                            selection( :, :, r ) = training( cvpart );
                        end
        
                    end
                    selection = reshape( selection, [], args.KFolds*args.Repeats );
                    
                else
                    % no partitioning - select all
                    selection = true( self.NumObs, 1 );
        
                end
        
            end

        end

    end

end


function X = applyFilter( XCell )
    % Smooth the raw data using a low-pass filter
    arguments
        XCell       cell
    end

    % placeholder for now
    X = XCell;

end