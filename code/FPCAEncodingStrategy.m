classdef FPCAEncodingStrategy < EncodingStrategy
    % Class for features based on functional principal component analysis

    properties
        NumComponents       % number of principal components
        Length              % fixed length for encoding
        BasisOrder          % basis function order
        PenaltyOrder        % roughness penalty order
        Lambda              % roughness penalty
        TSpan               % common timespan for FDA
        MeanFd              % mean curve as a functional data object
        CompFd              % component curves as functional data objects
        VarProp             % proportion of variance explained
        AlignmentMethod     % method for aligning signals prior to PCA
        AlignmentSignal     % reference signal for alignment
        AlignmentTolerance  % alignment variance tolerance
        AlignSquareDiff     % align using the square diff instead of unchanged signal
        ShowConvergence     % show plots and variance of alignment convergence
        Fitted              % flag whether the model has been fit
        FittedAlignmentIdx  % fitted alignment indices for training data
        RefAlignmentIdx     % ground truth alignment indices for reference
        LMAlignmentIdx      % landmark alignment index
        StoreXAligned       % whether the store the aligned signals
        XAlignedPts         % (optional) aligned signals in an array
    end

    methods

        function self = FPCAEncodingStrategy( args )
            % Initialize the model
            arguments
                args.NumComponents      double ...
                    {mustBeInteger, mustBePositive} = 16
                args.BasisOrder         double ...
                    {mustBeInteger, mustBePositive} = 4
                args.PenaltyOrder       double ...
                    {mustBeInteger, mustBePositive} = 1
                args.Lambda             double ...
                    {mustBePositive} = 1E-8
                args.AlignmentMethod    char ...
                    {mustBeMember( args.AlignmentMethod, ...
                        {'XCRandom', 'XCMeanConv', ...
                         'LMTakeoff', 'LMLanding', ...
                         'LMTakeoffDiscrete', ...
                         'LMTakeoffActual', ...
                         'LMTakeoffCorrection' })} = 'LMTakeoff'
                args.AlignSquareDiff    logical = false
                args.AlignmentTolerance double ...
                    {mustBePositive} = 1E-4
                args.ShowConvergence    logical = false
                args.StoreXAligned      logical = false
            end

            if args.PenaltyOrder > (args.BasisOrder-2)
                eid = 'FPCA-01';
                msg = 'Penalty order too higher for basis order.';
                throwAsCaller( MException(eid, msg) );
            end

            names = string(arrayfun(@(x) sprintf('FPC%d', x), ...
                                    1:args.NumComponents, ...
                                    UniformOutput = false));
            self = self@EncodingStrategy( names );

            self.NumComponents = args.NumComponents;
            self.BasisOrder = args.BasisOrder;
            self.PenaltyOrder = args.PenaltyOrder;
            self.Lambda = args.Lambda;

            self.AlignmentMethod = args.AlignmentMethod;
            self.AlignmentTolerance = args.AlignmentTolerance;
            self.AlignSquareDiff = args.AlignSquareDiff;
            self.ShowConvergence = args.ShowConvergence;
            self.Fitted = false;
            self.StoreXAligned = args.StoreXAligned;

        end


        function self = fit( self, thisDataset )
            % Fit the model to the data
            % This requires creating a functional representation
            % which in turn requires curve alignment
            arguments
                self                FPCAEncodingStrategy
                thisDataset         ModelDataset
            end

            self.SamplingFreq = thisDataset.SampleFreq;

            % align the curves, setting alignment
            XAligned = self.setCurveAlignment( thisDataset );

            if isempty( XAligned )
                error('No alignment data.');
            end

            if self.StoreXAligned
                self.XAlignedPts = XAligned;
            end

            % create the functional representation
            XFd = self.funcSmoothData( XAligned );

            % perform principal components analysis (fit the model)
            pcaStruct = pca_fd( XFd, self.NumComponents );

            % store the model
            self.MeanFd = pcaStruct.meanfd;
            self.CompFd = pcaStruct.harmfd;
            self.VarProp = pcaStruct.varprop;

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


        function [rmse, pcc, ncc, tde, mi] = calcMetrics( self, thisDataset )
            % Calculate the number of signals and signal length
            arguments
                self                FPCAEncodingStrategy
                thisDataset         ModelDataset
            end

            % align the curves
            X = self.alignCurves( thisDataset );

            numObs = size(X, 2);
            
            % Initialize variables to store the metrics
            rmse = 0;
            pcc = 0;
            ncc = 0;
            tde = 0;
            mi = 0;

            % Iterate over all pairs of signals
            for i = 1:numObs-1
                for j = i+1:numObs

                    % Calculate RMSE
                    rmse = rmse + sqrt(mean((X(:,i) - X(:,j)).^2));
                    
                    % Calculate PCC
                    pcc = pcc + corr(X(:,i), X(:,j));
                    
                    % Calculate cross-correlation
                    [cc, lags] = xcorr(X(:,i), X(:,j));
                    
                    % Calculate NCC
                    ncc = ncc + max(cc) / sqrt(sum(X(:,i).^2) * sum(X(:,j).^2));
                    
                    % Calculate TDE
                    [~, maxIndex] = max(cc);
                    tde = tde + lags(maxIndex);
                    
                    % Calculate MI
                    mi = mi + calculateMI(X(:,i), X(:,j));

                end
            end
            
            % Normalize the metrics by the number of signal pairs
            numPairs = (numObs * (numObs - 1)) / 2;
            rmse = rmse / numPairs;
            pcc = pcc / numPairs;
            ncc = ncc / numPairs;
            tde = tde / numPairs;
            mi = mi / numPairs;

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

            % set an arbitrary time span
            self.TSpan = linspace( 0, 1, self.Length );

            % align arrays
            switch self.AlignmentMethod

                case 'XCRandom'
                    [XAligned, self.AlignmentSignal, self.FittedAlignmentIdx] = ...
                                xcorrAlignment( X, ...
                                                Reference = 'Random', ...
                                                UseSqDiff = self.AlignSquareDiff );

                case 'XCMeanConv'
                    [XAligned, self.AlignmentSignal, self.FittedAlignmentIdx ] = ...
                                iteratedAlignment( X, ...
                                                   self.AlignmentTolerance, ...
                                                   self.ShowConvergence, ...
                                                   self.AlignSquareDiff );

                case {'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual', 'LMTakeoffCorrection'}
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
                                               RefSignal = self.AlignmentSignal, ...
                                               UseSqDiff = self.AlignSquareDiff );

                case {'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual', 'LMTakeoffCorrection'}
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
               
            % set the functional basis
            numBasis = fix( self.Length/10 );
            basisFd = create_bspline_basis( [self.TSpan(1) self.TSpan(end)], ...
                                            numBasis, ...
                                            self.BasisOrder );
            
            % set the roughness penality
            self.Lambda = self.findLambda( X, basisFd );

            % and the parameters
            FdParams = fdPar( basisFd, self.PenaltyOrder, self.Lambda );
        
            % create the smooth functions from the original data
            XFd = smooth_basis( self.TSpan, X, FdParams );
        
        end

        
        function lambda = findLambda( self, X, basisFd )
            % Determine the roughness penalty with automated 
            % general cross validation
            arguments
                self            FPCAEncodingStrategy
                X               double
                basisFd
            end

            % define Generalised Cross-Validation function
            gcvFcn = @(L) gcv( L, X, self.TSpan, basisFd, self.PenaltyOrder );
        
            % find the loglambda where GCV is minimized
            warning( 'off', 'Wid2:reduce' );
        
            % find L that minimizws gcvFcn to a precision of 0.1
            opt = optimset( 'TolX', 1, ...
                            'MaxIter', 9, 'Display', 'off' );
            logLambda = fminbnd( gcvFcn, -10, 0, opt );
        
            warning( 'on', 'Wid2:reduce' );
            lambda = 10^round( logLambda, 1 );

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
            if isempty( refIdx )
                refIdx = lmIdx;
            end
        
            % find all the landmarks
            for i = 1:numSignals
                lmIdx(i) = self.findLandmark( squeeze(X(:,:,i)), refIdx(i) );
            end
            
            % set the landmark alignment index to the mean (if not set)
            if isempty( self.LMAlignmentIdx )
                self.LMAlignmentIdx = round(mean(lmIdx), 0);
            end

            % shift the signals to align with the mean position
            for i = 1:numSignals

                if lmIdx(i) > 0
                    % Adjust the signal based on the offset. This is a simple shift.
                    offsets(i) = self.LMAlignmentIdx - lmIdx(i);
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
                case {'LMTakeoff', 'LMLanding', 'LMTakeoffCorrection'}
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


function gcv = gcv( logLambda, X, tSpan, basis, penaltyOrder  )
    % Objective function returning GCV error for given smoothing
    arguments
        logLambda       double
        X               double
        tSpan           double
        basis
        penaltyOrder    double
    end

    % set smoothing parameters
    XFdParam = fdPar( basis, penaltyOrder, 10^logLambda );
    
    % perform smoothing
    [~, ~, gcv] = smooth_basis( tSpan, X, XFdParam );

    gcv = mean(gcv, 'all');

end


function [XAligned, alignmentSignal, alignmentIdx ] = iteratedAlignment( X, tol, verbose, useSqDiff )
    % Iterate curve alignment using the mean curve
    arguments
        X           double
        tol         double
        verbose     logical
        useSqDiff   logical
    end

    prevXMeanVar = mean(var(permute(X, [1 3 2]), [], 3), 'all');
    if verbose
        disp(['X        Var = ' num2str( prevXMeanVar, '%6.4f' )]);
    end

    converged = false;
    i = 0;
    XAligned = X;
    alignmentIdx = zeros( size(X,2), 1 );

    while ~converged && i<8
        [XAligned, alignmentSignal, offset] = ...
                            xcorrAlignment( XAligned, ...
                                            Reference = 'Mean', ...
                                            UseSqDiff = useSqDiff );
        alignmentIdx = alignmentIdx + offset;

        XVar = var(permute(XAligned, [1 3 2]), [], 3);
        XMeanVar = mean( XVar, 'all' );
        converged = abs(prevXMeanVar - XMeanVar) < tol;
        prevXMeanVar = XMeanVar;
        i = i+1;

        if verbose
            disp(['XAligned Var = ' num2str( XMeanVar, '%6.4f' )]);
        end

    end

end


function [ alignedX, refZ, offsets, correlations ] = xcorrAlignment( X, args )
    % Align X series using cross correlation with a reference signal
    arguments
        X                   double
        args.Reference      string ...
                {mustBeMember( args.Reference, ...
                    {'Random', 'Mean', 'Specified'})} = 'Random'
        args.RefSignal      double
        args.UseSqDiff      logical
    end

    [sigLength, numSignals, numDim] = size( X );
    
    % shift dimensions
    X = permute( X, [1 3 2] );

    % align the squared diff of the resultant
    if args.UseSqDiff
        Z = squeeze(diff( sqrt(sum(X.^2, 2)) ).^2);
    else
        Z = squeeze(X);
    end

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
        case 'LMTakeoffCorrection'
            offset = min( pkIdx( sortIdx(1:2) ) );
            offset = offset + floor(44*fs/250);
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
    thisEncoding = DiscreteEncodingStrategy;
    thisEncoding.SamplingFreq = fs;

    % find the onset time
    t0 = thisEncoding.findStartTime( acc );

    % compute the velocity time series
    vel = thisEncoding.calcVelCurve( t0, acc );

    % find takeoff time
    [~, ~, tTO] = thisEncoding.findOtherTimes( acc, vel );

    % remove the object from memory
    delete( thisEncoding );

end


function mi = calculateMI(x1, x2)
    % Calculate mutual information between signals
    arguments
        x1          double
        x2          double
    end

    % Calculate the histograms of the signals
    edges = linspace(min(min(x1), min(x2)), max(max(x1), max(x2)), 10);
    hist1 = histcounts(x1, edges);
    hist2 = histcounts(x2, edges);
    
    % Calculate the joint histogram
    jointHist = hist3([x1 x2], {edges, edges});
    
    % Calculate the probability distributions
    p1 = hist1 / sum(hist1);
    p2 = hist2 / sum(hist2);
    pJoint = jointHist / sum(jointHist(:));
    
    % Calculate the marginal entropies
    H1 = -sum(p1 .* log2(p1 + eps));
    H2 = -sum(p2 .* log2(p2 + eps));
    
    % Calculate the joint entropy
    HJoint = -sum(pJoint(:) .* log2(pJoint(:) + eps));
    
    % Calculate the mutual information
    mi = H1 + H2 - HJoint;
end




