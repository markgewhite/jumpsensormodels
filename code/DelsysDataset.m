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
        
        
        function accCell = getAcceleration( self )
            % Extract the preferred acceleration component
            % Dimension 1 (approx vertical)
            arguments
                self            ModelDataset            
            end
               
            accCell = cellfun( @(x) x(:,1), self.X, ...
                               UniformOutput = false );

        end

    end
    

    methods (Static)

        function [ XCell, Y, S ] = load( type, sensor, outcome )

            path = fileparts( which('DelsysDataset.m') );
            path = [path '/../data/'];
            
            load( fullfile( path, 'DelsysJumpData.mat' ), 'delsysJumpData' );

            % find the jumps of the specified type
            % first, flatten the arrays
            jumpType = reshape( delsysJumpData.type', [], 1 );     
            switch sensor
                case 'LB'
                    acc = reshape( delsysJumpData.acc(:,:,1)', [], 1 );
                case 'UB'
                    acc = reshape( delsysJumpData.acc(:,:,2)', [], 1 );
            end
            outcome = reshape( delsysJumpData.(outcome)', [], 1 );
            %q = cellfun( @(x) sum(x,'all'), delsysJumpData.acc(:,:,1) );
            %outcome = reshape( q', [], 1 );

            % setup the subject identities as numeric for now
            [numSubjects, numTrials] = size( delsysJumpData.type );        
            subjectIDs = repmat( 1:numSubjects, [numTrials 1] );
            subjectIDs = reshape( subjectIDs, [], 1 );
            
            % make the selection
            selection = find( jumpType==type );

            % remove rows where there is no acc recorded
            isMissing = cellfun( @isempty, acc );
            selection( isMissing(selection) ) = [];

            % extract the data
            XCell = acc( selection );
            Y = outcome( selection );
            S = string(num2str( subjectIDs( selection ), 'S%02u' ));

            % convert to the resultant
            XCell = cellfun( @(x) sqrt(sum(x.^2, 2)), XCell, ...
                             UniformOutput=false );

            % scale it
            XCell = cellfun( @(x) 9.812*x, XCell, ...
                             UniformOutput=false );

       end

   end


end


