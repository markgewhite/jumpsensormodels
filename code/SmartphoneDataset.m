classdef SmartphoneDataset < ModelDataset
    % Subclass for loading the smartphone jump data

    properties
        Set             % training, testing or combined (no purpose here)
        JumpType        % whether 'CMJ' or 'SJ'
        SignalAligned   % whether the signal has been aligned vertically
    end

    methods

        function self = SmartphoneDataset( set, superArgs, args )
            % Load the countermovement jump GRF dataset
            arguments
                set                 string ...
                    {mustBeMember( set, ...
                            {'Training', 'Testing', 'Combined'} )}
                superArgs.?ModelDataset
                args.JumpType       string ...
                    {mustBeMember( args.JumpType , ...
                            {'CMJ', 'SJ'} )} = 'CMJ'
                args.SignalAligned  logical = true
            end

            [ XRaw, Y, SubjectID ] = SmartphoneDataset.load( args.JumpType );

            labels = { 'AccX', 'AccY', 'AccZ', 'GyrX', 'GyrY', 'GyrZ' };

            % process the data and complete the initialization
            superArgsCell = namedargs2cell( superArgs );

            self = self@ModelDataset( XRaw, Y, SubjectID, [], ...
                            superArgsCell{:}, ...
                            Name = "Smartphone Data", ...
                            channelLabels = labels, ...
                            SampleFreq = 128, ...
                            CutoffFreq = 50 );

            self.Set = set;
            self.JumpType = args.JumpType;
            self.SignalAligned = args.SignalAligned;

            if args.SignalAligned
                % align the signal vertically
                self.align
            end
            
        end


        function accCell = getAcceleration( self )
            % Extract the preferred acceleration component
            % Dimension 2 (vertical) 
            arguments
                self            ModelDataset            
            end
               
            accCell = cellfun( @(x) x(:,2), self.X, ...
                               UniformOutput = false );

        end


        function align( self )
            % Align all the signals vertically
            arguments
                self           SmartphoneDataset
            end

            for i = 1:self.NumObs
                self.X{i}(:, 1:3) = orientate( self.X{i}, self.SampleFreq );
            end
                                              

        end
        
    end


    methods (Static)

        function [ XCell, Y, subjectID ] = load( type )

            path = fileparts( which('SmartphoneDataset.m') );
            path = [path '/../data/'];
            
            load( fullfile( path, 'SmartphoneData.mat' ), ...
                            'sensorData', 'forceData' );

            uniqueID = fieldnames( sensorData );

            % pre-allocate arrays by estimating the number of jumps
            estNumJumps = 3*length(uniqueID);
            subjectID = strings( estNumJumps, 1 );
            XCell = cell( estNumJumps, 1 );
            Y = zeros( estNumJumps, 1 );
            
            k = 0;
            % iterate through the unique subject IDs
            for s = 1:length(uniqueID)
                % extract the subject's data
                subjectData = sensorData.(uniqueID{s});
                perfData = forceData( strcmp(forceData.SBJ, uniqueID{s}), :);

                % get all the jump IDs
                jumpID = sort(fieldnames( subjectData ));
                for j = 1:length(jumpID)
                    if contains( jumpID{j}, type )

                        % find the corresponding performance data
                        peakPower = perfData.n( strcmp(perfData.JUMP, jumpID{j}) );
                        if isempty( peakPower )
                            % no performance recorded
                            continue
                        end

                        % add a jump if it has right type
                        k = k+1;
                        acc = subjectData.(jumpID{j}).acc;
                        gyr = subjectData.(jumpID{j}).gyr;
                        % pad gyro to the same length
                        padding = length(acc) - length(gyr);
                        gyr = [zeros(padding,3); gyr];
                        XCell{k} = [acc gyr];
                        subjectID(k) = uniqueID{s};
                        Y(k) = peakPower;

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


function acc_glob = orientate(X, fs)
    % Align signal vertically
    arguments
        X                   double {mustBeFloat}
        fs                  double {mustBePositive}
    end

    acc = X(:, 1:3);
    gyr = X(:, 4:6);

    % create the orientation object
    AHRS = MadgwickAHRS(SamplePeriod = 1/fs, ...
                        Beta = 0.001);
    
    % correct for WRF alignemnt 
    time = linspace(0, length(acc) / fs, length(acc));
    quaternion = zeros(length(time), 4);
    
    for t = 1 : length(time)
        AHRS.UpdateIMU(gyr(t,:), acc(t,:));
        quaternion(t, :) = AHRS.Quaternion;
    end
    
    quaternion_star = quaternConj(quaternion);
    acc_q = [zeros(length(acc),1), acc];
    acc_temp = quaternProd(quaternion, acc_q);
    acc_glob = quaternProd(acc_temp, quaternion_star);

    offset = mean(acc_glob( 1:fs, 2:end ));
    acc_glob = acc_glob( :, 2:end ) - offset;

end



