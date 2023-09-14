classdef DiscreteEncodingStrategy < EncodingStrategy
    % Class for features based on discrete features

    properties
        SampleFreq      % sampling frequency of the data
        VMD             % VMD parameters structure
                        %    Alpha           balancing parameter for data fidelity
                        %    NoiseTolerance  time-step of dual ascent
                        %    NumModes        number of modes, K
                        %    UseDCMode       whether VMD uses DC mode
                        %    OmegaInit       initialisation mode for omega
                        %           0 = all omegas start at 0
                        %           1 = all omegas start uniformly distributed
                        %           2 = all omegas initialized randomly
                        %    Tolerance       tolerance for convergence
        Onset           % jump onset detection parameters structure
                        %    Filtering              if signal filtering first
                        %    DetectionMethod        how to detect movement
                        %    WindowMethod           where to locate window
                        %    SDDetectionThreshold   SD multiple factor
                        %    AccDetectionThreshold  absolute value
                        %    DetectionAdjustment    backwards from detection point
                        %    WindowAdjustment       backwards from detection
        PlotTimePts     % flag whether to plot timing points when generating features
        LegacyCode      % flag whether to run legacy code
    end


    methods

        function self = DiscreteEncodingStrategy( sampleFreq, args )
            % Initialize the model
            arguments
                sampleFreq              double ...
                    {mustBePositive}
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
                % Onset parameters
                args.Filtering          logical = true
                args.DetectionMethod        char ...
                    {mustBeMember( args.DetectionMethod, ...
                        {'SDMultiple', 'Absolute'})} = 'SDMultiple'
                args.WindowMethod        char ...
                    {mustBeMember( args.WindowMethod, ...
                        {'Fixed', 'Dynamic'})} = 'Fixed'
                args.SDDetectionThreshold double = 8
                args.AccDetectionThreshold double = 1.0
                args.DetectionAdjustment double = 0.03
                args.WindowAdjustment    double = 1.00
                args.PlotTimePts         logical = false
                args.LegacyCode          logical = false
            end

            self = self@EncodingStrategy( 26 );

            self.SampleFreq = sampleFreq;

            % set the VMD parameters
            self.VMD.Alpha = args.Alpha;
            self.VMD.NoiseTolerance = args.NoiseTolerance;
            self.VMD.NumModes = args.VMDModes;
            self.VMD.UseDCMode = args.UseDCMode;
            self.VMD.OmegaInit = args.OmegaInit;
            self.VMD.Tolerance= args.Tolerance;

            % set the jump onset parameters
            self.Onset.Filtering = args.Filtering;
            self.Onset.DetectionMethod = args.DetectionMethod;
            self.Onset.WindowMethod = args.WindowMethod;
            self.Onset.SDDetectionThreshold = args.SDDetectionThreshold;
            self.Onset.AccDetectionThreshold = args.AccDetectionThreshold;
            self.Onset.DetectionAdjustment = args.DetectionAdjustment;
            self.Onset.WindowAdjustment = args.WindowAdjustment;

            % operation
            self.PlotTimePts = args.PlotTimePts;
            self.LegacyCode = args.LegacyCode;

        end


        function Z = extractFeatures( self, thisDataset )
            % Compute the features 
            arguments
                self                DiscreteEncodingStrategy
                thisDataset         ModelDataset
            end

            numObs = thisDataset.NumObs;
            fs = thisDataset.SampleFreq;
            acc = thisDataset.Acc;
            g = 9.80665;

            % compute features for one observations at a time
            Z = zeros( numObs, 26 );
            for i = 1:numObs
                
                % setup plot, if required
                if self.PlotTimePts
                    if mod(i-1, 30)==0
                        fig = figure;
                        tiling = tiledlayout( fig, 5, 6, ...
                                              TileSpacing='compact' );
                    end
                    ax = nexttile( tiling );
                end

                if self.LegacyCode
                    try
                        % check with original code
                        [stack, data, times] = get_features_GPL_CMJ(acc{i}, fs, 0);
                    catch
                        disp(['Legacy code error: row = ' num2str(i)]);
                    end
                else
                    times = NaN;
                end

                % find the jump start
                t0 = findStartTime( acc{i}, fs, self.Onset );

                % compute the velocity time series
                vel = calcVelCurve( t0, acc{i}, fs );

                % find time UB
                [tUB, tBP, tTO] = findOtherTimes( acc{i}, vel, fs, g );

                % compute the power time series
                pwr  = calcPwrCurve( tTO, acc{i}, vel, g );

                % calculate the jump height
                h = calcJumpHeight( tTO, vel, g );

                % calculate jump features
                featuresJump = calcJumpFeatures( t0, tUB, tBP, tTO, ...
                                                 acc{i}, vel, pwr, fs );

                % perform VMD
                featuresVMD = calcVMDFeatures( acc{i}, fs, self.VMD );

                % assemble features vector
                Z( i, : ) = [round(100*h) featuresJump featuresVMD];

                % plot the timing points, if required
                if self.PlotTimePts
                    plotTimingPts( ax, acc{i}, [t0, tUB, tBP, tTO], times );
                    text( ax, 0.1, 0.8, num2str(i), units = 'normalized' );
                end

            end

            % convert into a table
            varNames = {'h', 'A', 'b', 'C', 'D', 'e', 'F', 'G', 'H', 'i', 'J', 'k', 'l', 'M',...
                        'n', 'O', 'p', 'q', 'r', 's', 'u', 'W', 'z', 'f3', 'f2', 'f1'};
            Z = array2table( Z, 'VariableNames', varNames);

        end

    end

end


function features = calcVMDFeatures( acc, fs, args )
    % Perform variational mode decomposition
    arguments
        acc             double {mustBeVector}
        fs              double
        args            struct            
    end

    [~, ~, omega] = vmdLegacy( acc, ...
                               args.Alpha, ...
                               args.NoiseTolerance, ...
                               args.NumModes, ...
                               args.UseDCMode, ...
                               args.OmegaInit, ...
                               args.Tolerance );

    features = omega(end,:) * fs/2;
    if isempty( features )
        features = zeros( 1, args.NumModes );
    end

end


function t0 = findStartTime( acc, fs, args )
    % Find the start of the jump from the acceleration 
    % Code adapted from Beatrice de Lazzari
    arguments
        acc             double {mustBeVector}
        fs              double
        args            struct
    end

    if args.Filtering
        accFilt = bwfilt(acc, 6, fs, 50, 'low');
    else
        accFilt = acc;
    end

    % determine the acceleration threshold for detecting the jump
    switch args.DetectionMethod

        case 'Absolute'
            % use the absolute deviation 
            threshold = args.AccDetectionThreshold;

        case 'SDMultiple'
            % use a multiple of the SD within a window
            windowWidth = fix( fs/2 );
            switch args.WindowMethod

                case 'Fixed'
                    % set the window at the start
                    window = 1:windowWidth;

                case 'Dynamic'
                    % locate the window close to the jump
                    % use a coarse detection threshold
                    detectIdx = find( abs(accFilt)>args.AccDetectionThreshold, 1 );
                    if isempty( detectIdx )
                        eid = 'DES-01';
                        msg = ['Jump not detected with AccDetectionThreshold = ' ...
                                num2str(args.AccDetectionThreshold)];
                        throwAsCaller( MException(eid, msg) );
                    end
                    % locate the window back from the detection point
                    windowStartIdx = max( detectIdx - fix(args.WindowAdjustment*fs), 1 );
                    % define the window from that point
                    window = windowStartIdx:(windowStartIdx+windowWidth);

            end
            % now calculate the threshold using the defined window
            threshold = args.SDDetectionThreshold*std( accFilt(window) );

    end

    % now make the final detection using threshold
    detectIdx = find( abs(accFilt)>threshold, 1 );
    if isempty( detectIdx )
        eid = 'DES-02';
        msg = ['Jump not detected with threshold = ' num2str(threshold)];
        throwAsCaller( MException(eid, msg) );
    end

    % make the backwards adjustment
    t0 = max( detectIdx - round(args.DetectionAdjustment*fs), 1 );

end


function v = calcVelCurve( t0, acc, fs )
    % Compute Velocity from "onset"
    % Code adapted from Beatrice de Lazzari
    arguments
        t0              double {mustBeInteger, mustBePositive}
        acc             double {mustBeVector}
        fs              double
    end

    n = length(acc);
    t = linspace( 0, (n - t0)/fs, n - t0 );
    vt = cumtrapz(t, acc( t0:end-1 ));

    % fill v with zeros to match a shape
    v = [ zeros(t0,1); vt ];

end


function [tUB, tBP, tTO] = findOtherTimes( acc, vel, fs, g )
    % Find the remaining time indices
    % Code adapted from Beatrice de Lazzari
    arguments
        acc           double {mustBeVector}
        vel           double {mustBeVector}
        fs            double
        g             double
    end

    % find the first minimum in velocity (peak in negative vel)
    [~, tUB, ~, p] = findpeaks( -vel, NPeaks = 1, ...
                          MinPeakHeight=0, MinPeakProminence=0.2);

    % find the next maximum in velocity after the minimum
    [~, velMaxIdx, ~, p] = findpeaks( vel(tUB:end), NPeaks = 1, ...
                          MinPeakProminence=0.2);
    velMaxIdx = velMaxIdx + tUB - 1;

    % find the last prominent acceleration peak before the vel peak
    [~, accMaxIdx] = findpeaks( acc(1:velMaxIdx), ...
                                MinPeakHeight=2, MinPeakProminence=0.2 );
    accMaxIdx = accMaxIdx(end);

    % Find the first sample such that v > 0
    tBP = find( vel(tUB:end)>0, 1 );
    if isempty( tBP )
        % velocity never becomes positive
        % instead, use the first acceleration peak
        tBP = accMaxIdx;
    else
        tBP = tBP + tUB - 1;
    end

    % set the take-off index where acc falls below -1g
    takeoffIdx = find( acc(accMaxIdx:end)<-g, 1 );
    if isempty( takeoffIdx )
        % use an alternative method
        startIdx = findpeaks( vel, NPeaks=1 );
        endIdx = startIdx + fix(0.0235*fs);
        [~, accMinIdxTO] = min( acc(startIdx:endIdx) );
        tTO = startIdx + accMinIdxTO - 1;
    else
        tTO = takeoffIdx + accMaxIdx - 1;
    end

end


function P = calcPwrCurve( tTO, acc, vel, g )
    % Compute the power time series
    % Code adapted from Beatrice de Lazzari
    arguments
        tTO           double {mustBeInteger, mustBePositive}
        acc           double {mustBeVector}
        vel           double {mustBeVector}
        g             double
    end

    P = (acc(1:tTO)+g).*vel(1:tTO);

end


function h = calcJumpHeight( tTO, vel, g )

    h = .5 * vel(tTO)^2 / g;

end


function features = calcJumpFeatures( t0, tUB, tBP, tTO, acc, vel, pwr, fs )
    % Calculate (almost) all jump features
    % Code adapted from Beatrice de Lazzari
    arguments
        t0            double {mustBeInteger, mustBePositive}
        tUB           double {mustBeInteger, mustBePositive}
        tBP           double {mustBeInteger, mustBePositive}
        tTO           double {mustBeInteger, mustBePositive}
        acc           double {mustBeVector}
        vel           double {mustBeVector}
        pwr           double {mustBeVector}
        fs            double
    end

    % -- A -- %
    A = (tUB - t0)/fs;
    
    % -- b -- %
    b = min(acc( t0:tBP ));
    
    % -- C -- %
    [~, a_min] = min(acc( t0:tBP ));
    a_min = a_min + t0 - 1;
    [~, a_max] = max(acc( a_min:tTO ));
    a_max = a_max + a_min - 1;
    C = (a_max - a_min)/fs;
    
    % -- D -- %
    F0 = find( acc(tUB:tTO)>=0, 1, 'last' );
    D = (F0 - tUB)/fs;
    
    % -- e -- %
    e = max(acc( t0:tTO ));
    
    % -- F -- %
    F = (tTO - a_max)/fs;
    
    % -- G -- %
    G = (tTO - t0)/fs;
    
    % -- H -- %
    H = (tBP - a_min)/fs; 
    
    % -- i -- %
    tilt = diff(acc( a_min:a_max + 1));
    [~, tilt_max] = max( tilt );
    i = acc(a_min + tilt_max);
    
    % -- J -- %
    [~, v_min] = min( vel(1:tBP) );
    J = (tBP - v_min)/fs;
    
    % -- k -- %
    k1 = acc( tBP );
    
    % -- l -- %
    l = min(pwr( tUB:tBP ));
    
    % -- M -- %
    pwrIdx = find( pwr(tBP+3:end)<0, 1 );
    if isempty( pwrIdx )
        P0 = length(pwr);
    else
        P0 = pwrIdx + tBP + 2;
    end
    M = (P0 - tBP) / fs;
    
    % -- n -- %
    n = max(pwr);
    
    % -- O -- %
    [~, P_max] = max(pwr);
    O = (tTO - P_max) / fs;
    
    % -- p -- %
    p = (e - b) / C;
    
    % -- q -- %
    time = linspace(0, (F0 - tUB) / fs, (F0 - tUB));
    shape = trapz(time, acc(tUB : F0 - 1));
    q = shape / (D*e);
    
    % -- r -- %
    r = b / e; 
    
    % -- s -- %
    [~, v_max] = max(vel);
    s = min(vel( 1:v_max ));
    
    % -- z -- %
    z = mean(pwr( t0:tBP ));
    
    % -- u -- %
    u = mean(pwr( tBP:tTO ));
    
    % -- W -- %
    [~, P_min] = min(pwr( 1:P_max ));
    W = (P_max - P_min)/fs;
    
    % assemble features array 
    features = [A, b, C, D, e, F, G, H, i, J, k1, l, M, n, O, p, q, r, s, u, W, z];

end

