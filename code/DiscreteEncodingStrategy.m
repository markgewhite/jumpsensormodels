classdef DiscreteEncodingStrategy < EncodingStrategy
    % Class for features based on discrete features

    properties
        AccG            % acceleration due to gravity
        Filtering       % whether acceleration has been low-pass filtered
        FilterCutoff    % low-pass filter cutoff frequency
        FilterOrder     % order 
        IncludeHeight   % whether estimated jump height should be included
        Onset           % jump onset detection parameters structure
                        %    Filter                 if signal filtering first
                        %    DetectionMethod        how to detect movement
                        %    WindowMethod           where to locate window
                        %    SDDetectionThreshold   SD multiple factor
                        %    AccDetectionThreshold  absolute value
                        %    DetectionAdjustment    backwards from detection point
                        %    WindowAdjustment       backwards from detection
        PlotTimePts     % flag whether to plot timing points when generating features
        LegacyCode      % flag whether to run legacy code
        ReturnVar       % name of variable to be returned as index for evaluations
    end


    methods

        function self = DiscreteEncodingStrategy( samplingFreq, args )
            % Initialize the model
            arguments
                samplingFreq            double
                args.Filtering          logical = true
                args.FilterForStart     logical = true
                args.FilterCutoff       double {mustBePositive} = 50 % Hz
                args.FilterOrder        double {mustBeInteger, ...
                    mustBeGreaterThan(args.FilterOrder, 3)} = 6
                args.IncludeHeight      logical = true
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
                args.ReturnVar           string ...
                    {mustBeMember( args.ReturnVar, ...
                        {'t0', 'tUB', 'tBP', 'tTO'})} = 'tTO'
            end

            self = self@EncodingStrategy( samplingFreq );

            % set acceleration due to gravity and sampling
            self.AccG = 9.80665;

            % set other parameters
            self.Filtering = args.Filtering;
            self.FilterCutoff = args.FilterCutoff;
            self.FilterOrder = args.FilterOrder;
            self.IncludeHeight = args.IncludeHeight;

            % set the jump onset parameters
            self.Onset.Filter = args.FilterForStart;
            self.Onset.DetectionMethod = args.DetectionMethod;
            self.Onset.WindowMethod = args.WindowMethod;
            self.Onset.SDDetectionThreshold = args.SDDetectionThreshold;
            self.Onset.AccDetectionThreshold = args.AccDetectionThreshold;
            self.Onset.DetectionAdjustment = args.DetectionAdjustment;
            self.Onset.WindowAdjustment = args.WindowAdjustment;

            % operation
            self.PlotTimePts = args.PlotTimePts;
            self.LegacyCode = args.LegacyCode;
            self.ReturnVar = args.ReturnVar;

        end


        function self = fit( self, thisDataset )
            % This method is required by the superclass 
            % but it is redundant here
            arguments
                self                DiscreteEncodingStrategy
                thisDataset         ModelDataset %#ok<INUSA>
            end

        end


        function [ Z, offsetIdx ] = extractFeatures( self, thisDataset )
            % Compute the features 
            arguments
                self                DiscreteEncodingStrategy
                thisDataset         ModelDataset
            end

            numObs = thisDataset.NumObs;
            self.SamplingFreq = thisDataset.SampleFreq;
            vmd = thisDataset.VMD;
            numNodes = thisDataset.VMDParams.NumModes;

            % compute features for one observations at a time
            Z = zeros( numObs, 22 + numNodes + self.IncludeHeight );
            offsetIdx = zeros( numObs, 1 );
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
                        [stack, data, times] = ...
                            get_features_GPL_CMJ(thisDataset.Acc{i}, self.SamplingFreq, 0);
                    catch
                        disp(['Legacy code error: row = ' num2str(i)]);
                        times = NaN;
                    end
                else
                    times = NaN;
                end

                if self.Filtering
                    acc = bwfilt(thisDataset.Acc{i}, self.FilterOrder, ...
                                 self.SamplingFreq, self.FilterCutoff, 'low');
                else
                    acc = thisDataset.Acc{i};
                end

                % find the jump start
                if self.Onset.Filter
                    t0 = self.findStartTime( acc );
                else
                    t0 = self.findStartTime( thisDataset.Acc{i} );
                end

                % compute the velocity time series
                vel = self.calcVelCurve( t0, acc );

                % find time UB
                [tUB, tBP, tTO] = self.findOtherTimes( acc, vel );

                % compute the power time series
                pwr  = self.calcPwrCurve( t0, tTO, acc, vel );

                % calculate jump features
                featuresJump = self.calcJumpFeatures( t0, tUB, tBP, tTO, ...
                                                      acc, vel, pwr );
                % perform VMD
                featuresVMD = vmd( i, : );

                % assemble features vector
                if self.IncludeHeight
                    % calculate the jump height
                    h = self.calcJumpHeight( tTO, vel );
                    Z( i, : ) = [featuresJump featuresVMD round(100*h)];
                else
                    Z( i, : ) = [featuresJump featuresVMD];
                end

                %disp(['i = ' num2str(i) '; ' num2str(featuresJump)]);

                % plot the timing points, if required
                if self.PlotTimePts
                    plotTimingPts( ax, acc{i}, [t0, tUB, tBP, tTO], times );
                    text( ax, 0.1, 0.8, num2str(i), units = 'normalized' );
                    isInSeq = all( diff( [t0, tUB, tBP, tTO] )>0 );
                    if ~isInSeq
                        msg = 'OUT OF ORDER';
                    else
                        msg = '';
                    end
                    disp([num2str(i) ': t0 = ' num2str(t0)  ...
                          '; tUB = ' num2str(tUB) ...
                          '; tBP = ' num2str(tBP) ...
                          '; tTO = ' num2str(tTO) ...
                          '; ' msg] );
                end

                % store for reference
                offsetIdx(i) = eval( self.ReturnVar );

            end

        end


        function t0 = findStartTime( self, acc )
            % Find the start of the jump from the acceleration 
            % Code adapted from Beatrice de Lazzari
            arguments
                self            DiscreteEncodingStrategy
                acc             double {mustBeVector}
            end
        
            % determine the acceleration threshold for detecting the jump
            switch self.Onset.DetectionMethod
        
                case 'Absolute'
                    % use the absolute deviation 
                    threshold = self.Onset.AccDetectionThreshold;
        
                case 'SDMultiple'
                    % use a multiple of the SD within a window
                    windowWidth = fix( self.SamplingFreq/2 );
                    switch self.Onset.WindowMethod
        
                        case 'Fixed'
                            % set the window at the start
                            window = 1:windowWidth;
        
                        case 'Dynamic'
                            % locate the window close to the jump
                            % use a coarse detection threshold
                            detectIdx = find( abs(acc)>self.Onset.AccDetectionThreshold, 1 );
                            if isempty( detectIdx )
                                eid = 'Dynamic:NotDetected';
                                msg = ['Jump not detected with AccDetectionThreshold = ' ...
                                        num2str(self.Onset.AccDetectionThreshold)];
                                throwAsCaller( MException(eid, msg) );
                            end
                            % locate the window back from the detection point
                            windowStartIdx = max( detectIdx - fix(self.Onset.WindowAdjustment*self.SamplingFreq), 1 );
                            % define the window from that point
                            window = windowStartIdx:(windowStartIdx+windowWidth);
        
                    end
                    % now calculate the threshold using the defined window
                    threshold = self.Onset.SDDetectionThreshold*std( acc(window) );
        
            end

            % now make the final detection using threshold
            detectIdx = find( abs(acc)>threshold, 1 );
            if isempty( detectIdx )
                eid = 'Final:NotDetected';
                msg = ['Jump not detected with threshold = ' num2str(threshold)];
                throwAsCaller( MException(eid, msg) );
            end
        
            % make the backwards adjustment
            t0 = max( detectIdx - round(self.Onset.DetectionAdjustment*self.SamplingFreq), 1 );
        
        end


        function [tUB, tBP, tTO] = findOtherTimes( self, acc, vel )
            % Find the remaining time indices
            % Code adapted from Beatrice de Lazzari
            arguments
                self          DiscreteEncodingStrategy
                acc           double {mustBeVector}
                vel           double {mustBeVector}
            end
        
            % find the first minimum in velocity (peak in negative vel)
            [~, tUB] = findpeaks( -vel, NPeaks = 1, ...
                                        MinPeakProminence=0.2);
        
            % find the next maximum in velocity after the minimum
            [~, velMaxIdx] = findpeaks( vel(tUB:end), NPeaks = 1, ...
                                              MinPeakProminence=0.2);
            if isempty( velMaxIdx )
                % try again without limits
                [~, velMaxIdx] = findpeaks( vel(tUB:end), NPeaks = 1 );
                if isempty( velMaxIdx )
                    % use the max peak
                    [~, velMaxIdx] = max( vel(tUB:end) );
                end
            end
            velMaxIdx = velMaxIdx + tUB - 1;
        
            % find the last prominent acceleration peak before the vel peak
            [~, accMaxIdx] = findpeaks( acc(1:velMaxIdx), ...
                                        MinPeakHeight=1, MinPeakProminence=0.2 );
            if isempty( accMaxIdx )
                % try again without limits
                [~, accMaxIdx] = findpeaks( acc(1:velMaxIdx) );
                if isempty( accMaxIdx )
                    % use the max peak
                    [~, accMaxIdx] = max( acc(1:velMaxIdx) );
                end
            end
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
            takeoffIdx = find( acc(tBP:end)<-self.AccG, 1 );
            if isempty( takeoffIdx )
                % use an alternative method
                [~, startIdx] = findpeaks( vel(tBP:end), NPeaks=1 );
                startIdx = startIdx + tBP - 1;
                endIdx = startIdx + fix(0.0235*self.SamplingFreq);
                [~, accMinIdxTO] = min( acc(startIdx:endIdx) );
                tTO = startIdx + accMinIdxTO - 1;
            else
                tTO = takeoffIdx + tBP - 1;
            end
        
        end
        
        
        function v = calcVelCurve( self, t0, acc )
            % Compute Velocity from "onset"
            % Code adapted from Beatrice de Lazzari
            arguments
                self            DiscreteEncodingStrategy
                t0              double {mustBeInteger, mustBePositive}
                acc             double {mustBeVector}
            end
        
            n = length(acc);
            t = linspace( 0, (n - t0)/self.SamplingFreq, n - t0 );
            vt = cumtrapz(t, acc( t0:end-1 ));
        
            % fill v with zeros to match a shape
            v = [ zeros(t0,1); vt ];
        
        end
        
        
        function P = calcPwrCurve( self, t0, tTO, acc, vel )
            % Compute the power time series
            % Code adapted from Beatrice de Lazzari
            arguments
                self          DiscreteEncodingStrategy
                t0            double {mustBeInteger, mustBePositive}
                tTO           double {mustBeInteger, mustBePositive}
                acc           double {mustBeVector}
                vel           double {mustBeVector}
            end
        
            P = [ zeros(t0, 1); (acc(t0:tTO)+self.AccG).*vel(t0:tTO) ];
        
        end
        
        
        function h = calcJumpHeight( self, tTO, vel )
            % Calculate jump height
            arguments
                self          DiscreteEncodingStrategy
                tTO           double {mustBeInteger, mustBePositive}
                vel           double {mustBeVector}
            end
        
            h = 0.5*vel(tTO)^2/self.AccG;
        
        end


        function features = calcJumpFeatures( self, t0, tUB, tBP, tTO, acc, vel, pwr )
            % Calculate (almost) all jump features
            % Code adapted from Beatrice de Lazzari
            arguments
                self          DiscreteEncodingStrategy
                t0            double {mustBeInteger, mustBePositive}
                tUB           double {mustBeInteger, mustBePositive}
                tBP           double {mustBeInteger, mustBePositive}
                tTO           double {mustBeInteger, mustBePositive}
                acc           double {mustBeVector}
                vel           double {mustBeVector}
                pwr           double {mustBeVector}
            end
        
            % -- A -- %
            A = (tUB - t0)/self.SamplingFreq;
            
            % -- b -- %
            b = min(acc( t0:tBP ));
            
            % -- C -- %
            [~, a_min] = min(acc(t0 : tBP));
            [~, a_max] = max(acc(t0 : tTO));
            C = (a_max - a_min)/self.SamplingFreq;
            
            % -- D -- %
            F0 = find( acc(tUB:tTO)>=0, 1, 'last' ) + tUB;
            D = (F0 - tUB)/self.SamplingFreq;
            
            % -- e -- %
            e = max(acc( t0:tTO ));
            
            % -- F -- %
            F = (tTO - a_max)/self.SamplingFreq;
            
            % -- G -- %
            G = (tTO - t0)/self.SamplingFreq;
            
            % -- H -- %
            H = (tBP - a_min)/self.SamplingFreq; 
            
            % -- i -- %
            tilt = diff(acc( a_min:a_max + 1));
            [~, tilt_max] = max( tilt );
            if isempty(tilt_max)
                tilt_max = 0;
            end
            i = acc(t0 + a_min + tilt_max);
            
            % -- J -- %
            [~, v_min] = min( vel(1:tBP) );
            J = (tBP - v_min)/self.SamplingFreq;
            
            % -- k -- %
            k1 = acc( tBP );
            
            % -- l -- %
            l = min(pwr( tUB:tBP ));
            
            % -- M -- %
            pwrIdx = find( pwr(tBP+3:end)<0, 1 );
            if isempty( pwrIdx )
                P0 = length(pwr);
            else
                P0 = pwrIdx + tBP + 1;
            end
            M = (P0 - tBP)/self.SamplingFreq;
            
            % -- n -- %
            n = max(pwr);
            
            % -- O -- %
            [~, P_max] = max(pwr);
            O = (tTO - P_max)/self.SamplingFreq;
            
            % -- p -- %
            p = (e - b) / C;
            
            % -- q -- %
            time = linspace(0, (F0 - tUB)/self.SamplingFreq, (F0 - tUB));
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
            W = (P_max - P_min)/self.SamplingFreq;
            
            % assemble features array 
            features = [A, b, C, D, e, F, G, H, i, J, k1, l, M, n, O, p, q, r, s, u, W, z];
        
        end


    end


end

