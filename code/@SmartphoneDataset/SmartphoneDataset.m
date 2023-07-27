classdef SmartphoneDataset < ModelDataset
    % Subclass for loading the smartphone jump data

    properties
        Set             % training, testing or combined (no purpose here)
        JumpType        % whether 'CMJ' or 'SJ'
    end

    methods

        function self = SmartphoneDataset( set, superArgs, args )
            % Load the countermovement jump GRF dataset
            arguments
                set                string ...
                    {mustBeMember( set, ...
                            {'Training', 'Testing', 'Combined'} )}
                superArgs.?ModelDataset
                args.JumpType      string ...
                    {mustBeMember( args.JumpType , ...
                            {'CMJ', 'SJ'} )} = 'CMJ'
            end

            [ XRaw, Y, SubjectID ] = SmartphoneDataset.load( args.JumpType );

            labels = { 'AccX', 'AccY', 'AccZ', 'GyrX', 'GyrY', 'GyrZ' };

            % process the data and complete the initialization
            superArgsCell = namedargs2cell( superArgs );

            self = self@ModelDataset( XRaw, Y, SubjectID, ...
                            superArgsCell{:}, ...
                            Name = "Smartphone Data", ...
                            channelLabels = labels );

            self.Set = set;
            self.JumpType = args.JumpType;

        end

    end

    methods (Static)

        function [ XCell, Y, subjectID ] = load( type )

            path = fileparts( which('SmartphoneDataset.m') );
            path = [path '/../../data/'];
            
            load( fullfile( path, 'SmartphoneData.mat' ), 'D' );

            uniqueID = fieldnames( D );

            % pre-allocate arrays by estimating the number of jumps
            estNumJumps = 3*length(uniqueID);
            subjectID = strings( estNumJumps, 1 );
            XCell = cell( estNumJumps, 1 );
            Y = zeros( estNumJumps, 1 );
            
            k = 0;
            % iterate through the unique subject IDs
            for s = 1:length(uniqueID)
                % extract the subject's data
                subjectData = D.(uniqueID{s});
                % get all the jump IDs
                jumpID = sort(fieldnames( subjectData ));
                for j = 1:length(jumpID)
                    if contains( jumpID{j}, type )
                        % add a jump if it has right type
                        k = k+1;
                        acc = subjectData.(jumpID{j}).acc;
                        gyr = subjectData.(jumpID{j}).gyr;
                        % pad gyro to the same length
                        padding = length(acc) - length(gyr);
                        gyr = [zeros(padding,3); gyr];
                        XCell{k} = [acc gyr];
                        subjectID(k) = uniqueID{s};
                    end
                end
            end

            % trim back the arrays, if fewer jumps than expected
            subjectID = subjectID( 1:k );
            XCell = XCell( 1:k );
            Y = Y( 1:k );
            
       end

   end


end


