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
                            channelLabels = labels );

            self.Set = set;
            self.JumpType = args.JumpType;
            self.Sensor = args.Sensor;
            self.OutcomeVar = args.OutcomeVar;

        end

    end

    methods (Static)

        function [ XCell, Y, subjectID ] = load( type, sensor, outcome )

            path = fileparts( which('DelsysDataset.m') );
            path = [path '/../../data/'];
            
            load( fullfile( path, 'DelsysJumpData.mat' ), 'delsysJumpData' );

            % find the jumps of the specified type
            % getting the indices in a long 1D array (across and down)
            selection = find( delsysJumpData.type'==type );

            % extract the data
            Y = delsysJumpData.(outcome)( selection ); 

            switch sensor
                case 'LB'
                    acc = delsysJumpData.acc(:,:,1);
                case 'UB'
                    acc = delsysJumpData.acc(:,:,2);
            end
            XCell = acc( selection );
            subjectID = num2str( fix( selection/16 ), 'S%02u' );

       end

   end


end


