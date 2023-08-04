classdef FPCAEncodingStrategy < EncodingStrategy
    % Class for features based on functional principal component analysis

    properties
        BasisOrder      % basis function order
        PenaltyOrder    % roughness penalty order
        Lambda          % roughness penalty
        MeanFd          % mean curve as a functional data object
        CompFd          % component curves as functional data objects
    end

    methods

        function self = FPCAEncodingStrategy( numFeatures, args )
            % Initialize the model
            arguments 
                numFeatures             double
                args.BasisOrder         double ...
                    {mustBeInteger, ...
                     mustBeGreaterThanOrEqual(args.BasisOrder, 4)} = 4
                args.PenaltyOrder       double ...
                    {mustBeInteger, ...
                     mustBeLessThanOrEqual(args.PenaltyOrder, 2)} = 2
                args.Lambda             double ...
                    {mustBePositive} = 1E-8
            end

            if args.PenaltyOrder > (args.BasisOrder-2)
                eid = 'FPCA-01';
                msg = 'Penalty order too higher for basis order.';
                throwAsCaller( MException(eid, msg) );
            end

            self = self@EncodingStrategy( numFeatures );

            self.BasisOrder = args.BasisOrder;
            self.PenaltyOrder = args.PenaltyOrder;
            self.Lambda = args.Lambda;

        end

        
        function self = fitModel( self, thisDataset )
            % Fit the model to the data
            % This requires creating a functional representation
            % which in turn requires curve alignment
            arguments
                self                FPCAEncodingStrategy
                thisDataset         ModelDataset
            end

            % align the curves
            XAligned = alignCurves( thisDataset.X, Reference = 'Random' );
            
            % create the functional representation
            XFd = funcSmoothData( XAligned );

            % perform principal components analysis (fit the model)
            pcaStruct = pca_fd( XFd, self.NumFeatures );

            % store the model
            self.MeanFd = pcaStruct.meanfd;
            self.CompFd = pcaStruct.harmfd;

        end


        function Z = extractFeatures( self, thisDataset )
            % Compute the features using the fitted model
            arguments
                self                FPCAEncodingStrategy
                thisDataset         ModelDataset
            end

            % create the functional representation
            XFd = funcSmoothData( thisDataset.X );

            % generate principal component scores
            Z = pca_fd_score( XFd, ...
                              self.MeanFd, ...
                              self.CompFd, ...
                              self.NumFeatures );

        end

    end


    methods (Access = private)

        function XFd = funcSmoothData( self, XCell )
            % Convert raw time series data to smooth functions
            arguments
                self            FPCAEncodingStrategy
                XCell           cell
            end
        
            % pad the series for smoothing
            X = padData( XCell, 0, 0, ...
                         Longest = true, ...
                         Same = true, ...
                         Location = 'Right' );
        
            % set an arbitrary time span
            tSpan = linspace( 0, 1, size(X,1) );
        
            % set the functional basis
            basisFd = create_bspline_basis( [tSpan(1) tSpan(end)], ...
                                            self.NumBasis, ...
                                            self.BasisOrder );
            
            % and the parameters
            FdParams = fdPar( basisFd, self.PenaltyOrder, self.Lambda );
        
            % create the smooth functions from the original data
            XFd = smooth_basis( tSpan, X, FdParams );
        
        end

    end

end


function [ alignedX, offsets, correlations ] = alignCurves( X, args )
    % Align X series using cross correlation with a reference signal
    arguments
        X               double
        args.Reference  string ...
                {mustBeMember( args.Reference, ...
                    {'First', 'Random'})} = 'Random'
    end

    [sigLength, numSignals, numDim] = size( X );
    
    % shift dimensions
    X = permute( X, [1 3 2] );

    % align the squared diff of the resultant
    Z = squeeze(diff( sqrt(sum(X.^2, 2)) ).^2);

    % select the reference signal
    switch args.Reference
        case 'First'
            refIdx = 1;
            refZ = Z( :, refIdx );
        case 'Random'
            refIdx = randi(numSignals);
            refZ = Z( :, refIdx );
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