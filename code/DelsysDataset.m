classdef DelsysDataset < ModelDataset
    % Subclass for loading the smartphone jump data

    properties
        Set             % training, testing or combined (no purpose here)
        JumpType        % type of jump included
        Sensor          % sensor chosen (anatomical position)
        OutcomeVar      % outcome variable chosen
    end

    methods

        function self = DelsysDataset( set, superArgs, args )
            % Load the countermovement jump GRF dataset
            arguments
                set                string ...
                    {mustBeMember( set, ...
                            {'Training', 'Testing', 'Combined'} )}
                superArgs.?ModelDataset
                args.JumpType      string ...
                    {mustBeMember( args.JumpType , ...
                            {'V', 'VA', 'H', 'HA'} )} = 'V'
                args.Sensor        string ...
                    {mustBeMember( args.Sensor, ...
                            {'LB', 'UB'} )} = 'LB'
                args.OutcomeVar    string ...
                    {mustBeMember( args.OutcomeVar, ...
                            {'jumpHeight', 'jumpHeightTOV', ...
                             'peakPower'} )} = 'peakPower'
            end

            [ XRaw, Y, SubjectID ] = DelsysDataset.load( args.JumpType, ...
                                                         args.Sensor, ...
                                                         args.OutcomeVar );

            labels = { 'AccX', 'AccY', 'AccZ' };

            % process the data and complete the initialization
            superArgsCell = namedargs2cell( superArgs );

            self = self@ModelDataset( XRaw, Y, SubjectID, ...
                                      superArgsCell{:}, ...
                                      Name = "Delsys Data", ...
                                      channelLabels = labels, ...
                                      SampleFreq = 250, ...
                                      CutoffFreq = 50);

            self.Set = set;
            self.JumpType = args.JumpType;
            self.Sensor = args.Sensor;
            self.OutcomeVar = args.OutcomeVar;

        end

    end

    methods (Static)

        function [ XCell, Y, subjectID ] = load( type, sensor, outcome )

            path = fileparts( which('DelsysDataset.m') );
            path = [path '/../data/'];
            
            load( fullfile( path, 'DelsysJumpData.mat' ), 'delsysJumpData' );

            % find the jumps of the specified type
            % first, flatten the arrays
            type1D = reshape( delsysJumpData.type, [], 1 );         
            switch sensor
                case 'LB'
                    acc1D = reshape( delsysJumpData.acc(:,:,1), [], 1 );
                case 'UB'
                    acc1D = reshape( delsysJumpData.acc(:,:,2), [], 1 );
            end
            outcome1D = reshape( delsysJumpData.(outcome), [], 1 );
            
            % make the selection
            selection = find( type1D==type );

            % remove 190
            selection(190) = [];

            % extract the data
            XCell = acc1D( selection );
            Y = outcome1D( selection );

            % scale it
            XCell = cellfun( @(x) -9.80665*x, XCell, ...
                             UniformOutput=false );

            % centre it based on first half second
            XCell = cellfun( @(x) x-mean( x(1:125,:) ), XCell, ...
                             UniformOutput=false );

            % infer the subject IDs knowing that array width
            subjectID = num2str( fix( selection/size(type,2) ), 'S%02u' );

       end

   end


end


