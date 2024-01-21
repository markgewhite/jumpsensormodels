classdef FPCAEncodingStrategy < EncodingStrategy
    % Class for features based on functional principal component analysis

    properties
        NumComponents       % number of principal components
        Length              % fixed length for encoding
        BasisOrder          % basis function order
        PenaltyOrder        % roughness penalty order
        Lambda              % roughness penalty
        MeanFd              % mean curve as a functional data object
        CompFd              % component curves as functional data objects
        AlignmentMethod     % method for aligning signals prior to PCA
        AlignmentSignal     % reference signal for alignment
        AlignmentTolerance  % alignment variance tolerance
        ShowConvergence     % show plots and variance of alignement convergence
        Fitted              % flag whether the model has been fit
        FittedAlignmentIdx  % fitted alignment indices for training data
        RefAlignmentIdx     % ground truth alignment indices for reference
    end

    methods

        function self = FPCAEncodingStrategy( samplingFreq, args )
            % Initialize the model
            arguments
                samplingFreq            double
                args.NumComponents      double ...
                    {mustBeInteger, mustBePositive} = 3
                args.BasisOrder         double ...
                    {mustBeInteger, ...
                     mustBeGreaterThanOrEqual(args.BasisOrder, 4)} = 4
                args.PenaltyOrder       double ...
                    {mustBeInteger, ...
                     mustBeLessThanOrEqual(args.PenaltyOrder, 2)} = 2
                args.Lambda             double ...
                    {mustBePositive} = 1E-8
                args.AlignmentMethod    char ...
                    {mustBeMember( args.AlignmentMethod, ...
                        {'XCRandom', 'XCMeanConv', ...
                         'LMTakeoff', 'LMLanding', ...
                         'LMTakeoffDiscrete', ...
                         'LMTakeoffActual' })} = 'XCRandom'
                args.AlignmentTolerance double ...
                    {mustBePositive} = 5E-2
                args.ShowConvergence    logical = false
            end

            if args.PenaltyOrder > (args.BasisOrder-2)
                eid = 'FPCA-01';
                msg = 'Penalty order too higher for basis order.';
                throwAsCaller( MException(eid, msg) );
            end

            self = self@EncodingStrategy( samplingFreq );

            self.NumComponents = args.NumComponents;
            self.BasisOrder = args.BasisOrder;
            self.PenaltyOrder = args.PenaltyOrder;
            self.Lambda = args.Lambda;

            self.AlignmentMethod = args.AlignmentMethod;
            self.AlignmentTolerance = args.AlignmentTolerance;
            self.ShowConvergence = args.ShowConvergence;
            self.Fitted = false;

        end


        function self = fit( self, thisDataset )
            % Fit the model to the data
            % This requires creating a functional representation
            % which in turn requires curve alignment
            arguments
                self                FPCAEncodingStrategy
                thisDataset         ModelDataset
            end

            % align the curves, setting alignment
            XAligned = self.setCurveAlignment( thisDataset );

            if isempty( XAligned )
                error('No alignment data.');
            end

            % create the functional representation
            XFd = self.funcSmoothData( XAligned );

            % perform principal components analysis (fit the model)
            pcaStruct = pca_fd( XFd, self.NumComponents );

            % store the model
            self.MeanFd = pcaStruct.meanfd;
            self.CompFd = pcaStruct.harmfd;

            self.Fitted = true;

        end


        function [ Z, offsets ] = extractFeatures( self, thisDataset )
            % Compute the features using the fitted model
            arguments
                self                FPCAEncodingStrategy
                thisDataset         ModelDataset
            end

            if ~self.Fitted
                Z = [];
                return
            end

            % align the curves
            [ XAligned, offsets ] = self.alignCurves( thisDataset );

            % create the functional representation
            XFd = self.funcSmoothData( XAligned );

            % generate principal component scores
            Z = pca_fd_score( XFd, ...
                              self.MeanFd, ...
                              self.CompFd, ...
                              self.NumComponents );

            % flatten
            Z = reshape( Z, size(Z,1), [] );

        end

    end


    methods (Access = private)


        function XAligned = setCurveAlignment( self, thisDataset )
            % Set curve alignment when fitting
            arguments
                self            FPCAEncodingStrategy
                thisDataset     ModelDataset
            end

            % convert to padded array
            X = padData( thisDataset.Acc, ...
                         Longest = true, ...
                         Same = true, ...
                         Location = 'Right' );
            self.Length = size( X, 1 );

            % align arrays
            switch self.AlignmentMethod

                case 'XCRandom'
                    [XAligned, self.AlignmentSignal, self.FittedAlignmentIdx] = ...
                                xcorrAlignment( X, Reference = 'Random' );

                case 'XCMeanConv'
                    [XAligned, self.AlignmentSignal, self.FittedAlignmentIdx ] = ...
                                iteratedAlignment( X, ...
                                                   self.AlignmentTolerance, ...
                                                   self.ShowConvergence );

                case {'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual'}
                    [XAligned, self.FittedAlignmentIdx] = ...
                                self.landmarkAlignment( X, ...
                                                        thisDataset.ReferenceIdx );

            end

            % store reference values
            self.RefAlignmentIdx = thisDataset.ReferenceIdx;

        end


        function [ XAligned, offsets ] = alignCurves( self, thisDataset )
            % Align the curves by chosen method
            arguments
                self            FPCAEncodingStrategy
                thisDataset     ModelDataset
            end

            % convert to padded array
            X = padData( thisDataset.Acc, ...
                         PadLen = self.Length, ...
                         Same = true, ...
                         Location = 'Right' );

            % perform alignment using fitted reference
            switch self.AlignmentMethod

                case {'XCRandom', 'XCMeanConv'}
                    [ XAligned, ~, offsets ] = xcorrAlignment( X, ...
                                               Reference = 'Specified', ...
                                               RefSignal = self.AlignmentSignal );

                case {'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual'}
                    [ XAligned, offsets ] = self.landmarkAlignment( X, ...
                                               thisDataset.ReferenceIdx );

            end

        end


        function XFd = funcSmoothData( self, X )
            % Convert raw time series data to smooth functions
            arguments
                self            FPCAEncodingStrategy
                X               double
            end
        
            % set an arbitrary time span
            numPts = size(X,1);
            tSpan = linspace( 0, 1, numPts );
        
            % set the functional basis
            numBasis = fix( numPts/10 );
            basisFd = create_bspline_basis( [tSpan(1) tSpan(end)], ...
                                            numBasis, ...
                                            self.BasisOrder );
            
            % and the parameters
            FdParams = fdPar( basisFd, self.PenaltyOrder, self.Lambda );
        
            % create the smooth functions from the original data
            XFd = smooth_basis( tSpan, X, FdParams );
        
        end


        function [ alignedX, offsets, lmIdx ] = landmarkAlignment( self, X, refIdx )
            % Align X series using a given landmark
            arguments
                self                FPCAEncodingStrategy
                X                   double
                refIdx              double
            end
        
            [sigLength, numSignals, numDim] = size( X );
            
            % shift dimensions
            X = permute( X, [1 3 2] );

            % initialization
            alignedX = zeros( sigLength, numDim, numSignals );
            offsets = zeros( numSignals, 1 );
            lmIdx = zeros( numSignals, 1 );
            halfWidthIdx = fix( size(X,1)/2 );
            if isempty( refIdx )
                refIdx = lmIdx;
            end
        
            for i = 1:numSignals
            
                lmIdx(i) = self.findLandmark( squeeze(X(:,:,i)), refIdx(i) );
        
                if lmIdx(i) > 0
                    % Adjust the signal based on the offset. This is a simple shift.
                    offsets(i) = halfWidthIdx - lmIdx(i);
                    if offsets(i) > 0
                        alignedX(:,:,i) = [X(1,:,i).*ones(offsets(i), numDim); 
                                           X(1:end-offsets(i),:,i)];
                    elseif offsets(i) < 0
                        alignedX(:,:,i) = [X(-offsets(i):end, :, i); 
                                           X(end,:,i).*ones(-offsets(i)-1, numDim)];
                    else
                        alignedX(:,:,i) = X(:,:,i);
                    end
                else
                    alignedX(:,:,i) = X(:,:,i);
                end
        
            end
        
            % shift back
            alignedX = permute( alignedX, [1 3 2] );
        
        end


        function offset = findLandmark( self, X, refIdx )
            % Find the specified landmark in the time series
            arguments
                self                FPCAEncodingStrategy
                X                   double
                refIdx              double
            end
        
            switch self.AlignmentMethod
                case {'LMTakeoff', 'LMLanding'}
                    offset = findLandmarkStandard( X, ...
                                                   self.AlignmentMethod, ...
                                                   self.SamplingFreq );
                case 'LMTakeoffDiscrete'
                    offset = findLandmarkDiscreteMethod( X, ...
                                                         self.SamplingFreq );

                case 'LMTakeoffActual'
                    offset = refIdx;

                otherwise
                    offset = 0;
            end

            if isempty( offset )
                offset = 0;
            end
        
        end

    end

end


function [XAligned, alignmentSignal, alignmentIdx ] = iteratedAlignment( X, tol, verbose )
    % Iterate curve alignment using the mean curve
    arguments
        X           double
        tol         double
        verbose     logical
    end

    if verbose
        figure(1);
        hold off;
    end

    prevXMeanVar = mean(var(permute(X, [1 3 2]), [], 3), 'all');
    converged = false;
    i = 0;
    XAligned = X;

    while ~converged && i<10
        [XAligned, alignmentSignal, alignmentIdx] = ...
                            xcorrAlignment( XAligned, Reference = 'Mean' );

        XVar = var(permute(XAligned, [1 3 2]), [], 3);
        XMeanVar = mean( XVar, 'all' );
        converged = abs(prevXMeanVar - XMeanVar) < tol;
        prevXMeanVar = XMeanVar;
        i = i+1;

        if verbose
            plot( XVar );
            hold on;
            disp(['XAligned Var = ' num2str( XMeanVar, '%10.8f' )]);
        end

    end

    if verbose
        hold off;
    end

end


function [ alignedX, refZ, offsets, correlations ] = xcorrAlignment( X, args )
    % Align X series using cross correlation with a reference signal
    arguments
        X               double
        args.Reference  string ...
                {mustBeMember( args.Reference, ...
                    {'Random', 'Mean', 'Specified'})} = 'Random'
        args.RefSignal  double
    end

    [sigLength, numSignals, numDim] = size( X );
    
    % shift dimensions
    X = permute( X, [1 3 2] );

    % align the squared diff of the resultant
    Z = squeeze(diff( sqrt(sum(X.^2, 2)) ).^2);

    % select the reference signal
    switch args.Reference
        case 'Random'
            refIdx = randi(numSignals);
            refZ = Z( :, refIdx );
        case 'Mean'
            refIdx = 0;
            refZ = mean( Z, 2 );
        case 'Specified'
            refIdx = 0;
            refZ = args.RefSignal;
   end

    % initialize
    alignedX = zeros( sigLength, numDim, numSignals );
    offsets = zeros( numSignals, 1 );
    correlations = zeros( numSignals, 1 );

    for i = 1:numSignals

        if i==refIdx
            % no need to align the reference signal
            alignedX( :, :, refIdx ) = X( :, :, refIdx );
            continue
        end
    
        [offsets(i), correlations(i)] = computeOffset( refZ, Z(:,i) );

        % Adjust the signal based on the offset. This is a simple shift.
        % For more complex adjustments, you may need to interpolate.
        if offsets(i) > 0
            alignedX(:,:,i) = [X(1,:,i).*ones(offsets(i), numDim); 
                               X(1:end-offsets(i),:,i)];
        elseif offsets(i) < 0
            alignedX(:,:,i) = [X(-offsets(i):end, :, i); 
                               X(end,:,i).*ones(-offsets(i)-1, numDim)];
        else
            alignedX(:,:,i) = X(:,:,i);
        end

    end

    % shift back
    alignedX = permute( alignedX, [1 3 2] );

end


function [lagDiff, cBest] = computeOffset( reference, target )

    [c, lags] = xcorr( reference, target ); 
    [cBest, I] = max(abs(c));
    lagDiff = lags(I);

end


function offset = findLandmarkStandard( acc, landmark, fs )
    % Find the landmarks using "standard" class methods
    arguments
        acc                 double
        landmark            string
        fs                  double
    end

    % add limited smoothing
    accSmth = squeeze(movmean( acc, fix(0.5*fs), 1 ));
    
    % find all peaks with a minimum separation
    [~, pkIdx, ~, pkProm] = findpeaks( accSmth, MinPeakDistance=25 );

    % find the two most prominent
    [~, sortIdx] = sort( -pkProm );

    switch landmark
        case 'LMTakeoff'
            offset = min( pkIdx( sortIdx(1:2) ) );
        case 'LMLanding'
            offset = max( pkIdx( sortIdx(1:2) ) );
    end

end


function tTO = findLandmarkDiscreteMethod( acc, fs )
    % Find takeoff using the discrete method
    % This code is an abbreviated version of that in
    % DiscreteEncodingStrategy
    arguments
        acc         double
        fs          double
    end

    % setup the default discrete encoding
    thisEncoding = DiscreteEncodingStrategy( fs );

    % find the onset time
    t0 = thisEncoding.findStartTime( acc );

    % compute the velocity time series
    vel = thisEncoding.calcVelCurve( t0, acc );

    % find takeoff time
    [~, ~, tTO] = thisEncoding.findOtherTimes( acc, vel );

    % remove the object from memory
    delete( thisEncoding );

end



