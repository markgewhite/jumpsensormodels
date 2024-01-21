classdef ModelDataset < handle
    % Class defining a dataset

    properties
        X               % time series as a cell array
        Y               % outcome array
        SubjectID       % subjects array
        ReferenceIdx    % takeoff index rray
        XLen            % lengths of each series
        NumChannels     % number of X channels
        Name            % name of the dataset
        Instance        % instance counter
        ChannelLabels   % names for each of the channels
        SampleFreq      % time series' sampling frequency
        CutoffFreq      % cutoff frequency for the filter
        FilterOrder     % Butterworth filter order
        FilterType      % filter type - low or high
        Proportion      % proportion of the datasets full size
        VMDParams       % VMD parameters structure
                        %    Alpha           balancing parameter for data fidelity
                        %    NoiseTolerance  time-step of dual ascent
                        %    NumModes        number of modes, K
                        %    UseDCMode       whether VMD uses DC mode
                        %    OmegaInit       initialisation mode for omega
                        %           0 = all omegas start at 0
                        %           1 = all omegas start uniformly distributed
                        %           2 = all omegas initialized randomly
                        %    Tolerance       tolerance for convergence
        VMD             % VMD features
    end

    properties (Dependent = true)
        NumObs          % number of observations
        Acc             % acceleration, selected from X dimensions
    end


    methods

        function self = ModelDataset( XRaw, Y, SubjectID, referenceIdx, args )
            % Create and preprocess the data.
            % The calling function will be a data loader or
            % a function partitioning the data.
            arguments
                XRaw                    cell
                Y                       double
                SubjectID               string
                referenceIdx            double
                args.Name               string
                args.Instance           double {mustBePositive, mustBeInteger} = 1
                args.ChannelLabels      string
                args.SampleFreq         double {mustBePositive} = 100
                args.CutoffFreq         double {mustBePositive} = 10
                args.FilterOrder        double ...
                    {mustBeInteger, ...
                     mustBeGreaterThanOrEqual(args.FilterOrder, 3)} = 6
                args.FilterType         char ...
                    {mustBeMember(args.FilterType, {'low', 'high'})} = 'low'
                args.Proportion         double ...
                    {mustBeInRange( args.Proportion, 0, 1 )} = 1.0
             % VMD parameters
                args.Alpha              double ...
                    {mustBePositive} = 100
                args.NoiseTolerance     double ...
                    {mustBeGreaterThanOrEqual(args.NoiseTolerance,0)} = 0
                args.VMDModes           double ...
                    {mustBeInteger, mustBePositive} = 3
                args.UseDCMode          logical = false
                args.OmegaInit          double ...
                    {mustBeMember(args.OmegaInit, [0 1 2])} = 0
                args.Tolerance          double ...
                    {mustBePositive, ...
                     mustBeLessThan(args.Tolerance, 1E-2)} = 1E-6
 
            end

            % set properties
            self.Y = Y;
            self.SubjectID = SubjectID;
            self.ReferenceIdx = referenceIdx;

            self.Name = args.Name;
            self.Instance = args.Instance;
            self.ChannelLabels = args.ChannelLabels;
            self.NumChannels = size( XRaw{1}, 2 );
            self.SampleFreq = args.SampleFreq;
            self.CutoffFreq = args.CutoffFreq;
            self.FilterOrder = args.FilterOrder;
            self.FilterType = args.FilterType;
            self.Proportion = args.Proportion;

            % set the VMD parameters
            self.VMDParams.Alpha = args.Alpha;
            self.VMDParams.NoiseTolerance = args.NoiseTolerance;
            self.VMDParams.NumModes = args.VMDModes;
            self.VMDParams.UseDCMode = args.UseDCMode;
            self.VMDParams.OmegaInit = args.OmegaInit;
            self.VMDParams.Tolerance= args.Tolerance;

            % store series lengths
            self.XLen = cellfun( @length, XRaw );

            % centre the signals based on first half second
            idx = fix( self.SampleFreq/2 );
            self.X = cellfun( @(x) x-mean( x(1:idx,:) ), ...
                              XRaw, ...
                              UniformOutput=false );
            

            % load VMD features 
            [vmd, vmdParams] = self.loadVMD;

            if isequal( vmdParams, self.VMDParams ) && length(vmd)==self.NumObs
                % previous run's data does match - re-use it
                self.VMD = vmd;
            else
                % previous run's data does not match - calculate VMD features
                self.VMD = self.calcVMD;
                self.saveVMD;
            end

            % truncate the data if a subsample is required
            if args.Proportion~=1
                self.truncate( args.Proportion );
            end

        end


        function NumObs = get.NumObs( self )
            % Get the number of classes
            arguments
                self            ModelDataset            
            end
               
            NumObs = length( self.Y );

        end


        function Acc = get.Acc( self )
            % Get the acceleration from X
            arguments
                self            ModelDataset            
            end
               
            Acc = self.getAcceleration;

        end

        
        function accCell = getAcceleration( self )
            % Extract the acceleration component
            arguments
                self            ModelDataset            
            end
               
            accCell = cellfun( @(x) x, self.X, ...
                               UniformOutput = false );

        end

        
        function XFilt = filterX( self )
            % Smooth the raw data using a low-pass filter
            arguments
                self       ModelDataset
            end
        
            XFilt = cell( size(self.X) );
            for i = 1:length(XFilt)
                XFilt{i} = bwfilt( self.X{i}, ...
                                   self.FilterOrder, ...
                                   self.SampleFreq, ...
                                   self.CutoffFreq, ...
                                   self.FilterType );
            end
                        
        end


        function thisSubset = partition( self, idx )
            % Create the subset of this ModelDataset
            % using the indices specified
            arguments
                self        ModelDataset
                idx         logical 
            end
        
            % create a copy of self without invoking the constructor
            byteStream = getByteStreamFromArray( self );
            thisSubset = getArrayFromByteStream( byteStream );
        
            thisSubset.X = self.X( idx );
            thisSubset.XLen = self.XLen( idx );
            thisSubset.Y = self.Y( idx );
            thisSubset.SubjectID = self.SubjectID( idx );
            if ~isempty( self.ReferenceIdx )
                thisSubset.ReferenceIdx = self.ReferenceIdx( idx );
            end
            thisSubset.VMD = self.VMD( idx, : );
    
        end


        function self = truncate( self, proportion )
            % Truncate the dataset by taking a random smaller proportion
            arguments
                self        ModelDataset
                proportion  double {mustBeInRange(proportion, 0, 1)}
            end

            unit = self.SubjectID;
            uniqueUnit = unique( unit );

            numUnits = length( uniqueUnit );
            subset = randsample( numUnits, ceil(proportion*numUnits) );
            selection = ismember( unit, uniqueUnit( subset ));

            self.X = self.X( selection );
            self.XLen = self.XLen( selection );
            self.Y = self.Y( selection );
            self.SubjectID = self.SubjectID( selection );
            self.VMD = self.VMD( selection, : );

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
        
            unit = self.SubjectID;
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



        function vmd = calcVMD( self )
            % Perform variational mode decomposition
            arguments
                self            ModelDataset                      
            end

            acc = self.Acc;
            vmd = zeros( self.NumObs, self.VMDParams.NumModes );
            for i = 1:self.NumObs
                [~, ~, omega] = vmdLegacy( acc{i}, ...
                                           self.VMDParams.Alpha, ...
                                           self.VMDParams.NoiseTolerance, ...
                                           self.VMDParams.NumModes, ...
                                           self.VMDParams.UseDCMode, ...
                                           self.VMDParams.OmegaInit, ...
                                           self.VMDParams.Tolerance );
        
                vmd(i,:) = omega(end,:) * self.SampleFreq/2;
            end
        
        end


        function [vmd, params] = loadVMD( self )
            % Load variational mode decomposition data from previous run
            arguments
                self            ModelDataset                      
            end

            path = fileparts( which('ModelDataset.m') );
            path = [path '/../data/'];

            filename = [ char(strrep(self.Name, ' ', '')) 'VMDData.mat'];
            
            try
                load( fullfile( path, filename ), 'vmd', 'params' );
            catch
                vmd = [];
                params = [];
            end

        end


        function saveVMD( self )
            % Save variational mode decomposition data
            arguments
                self            ModelDataset                      
            end

            path = fileparts( which('ModelDataset.m') );
            path = [path '/../data/'];

            filename = [ char(strrep(self.Name, ' ', '')) 'VMDData.mat'];
            vmd = self.VMD;
            params = self.VMDParams;

            save( fullfile( path, filename ), 'vmd', 'params' );

        end


    end


end


