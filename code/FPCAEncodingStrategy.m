classdef FPCAEncodingStrategy < EncodingStrategy
    % Class for features based on functional principal component analysis

    properties
        BasisOrder      % basis function order
        PenaltyOrder    % roughness penalty order
        Lambda          % roughness penalty
        MeanFd          % mean curve as a functional data object
        CompFd          % component curves as functional data objects
        Fitted          % flag whether the model has been fit
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
            self.Fitted = false;

        end

        
        function self = fitModel( self, thisDataset )
            % Fit the model to the data
            % This requires creating a functional representation
            % which in turn requires curve alignment
            arguments
                self                FPCAEncodingStrategy
                thisDataset         ModelDataset
            end

            % convert to padded array
            X = padCellToArray( thisDataset.X );

            % align the curves
            XAligned = alignCurves( X, Reference = 'Random' );
            
            % create the functional representation
            XFd = self.funcSmoothData( XAligned );

            % perform principal components analysis (fit the model)
            pcaStruct = pca_fd( XFd, self.NumFeatures );

            % store the model
            self.MeanFd = pcaStruct.meanfd;
            self.CompFd = pcaStruct.harmfd;

            self.Fitted = true;

        end


        function Z = extractFeatures( self, thisDataset )
            % Compute the features using the fitted model
            arguments
                self                FPCAEncodingStrategy
                thisDataset         ModelDataset
            end

            if ~self.Fitted
                eid = 'FPCA-02';
                msg = 'Model not fitted yet.';
                throwAsCaller( MException(eid, msg) );
            end

            % convert to padded array
            X = padCellToArray( thisDataset.X );

            % align the curves
            XAligned = alignCurves( X, Reference = 'Random' );

            % create the functional representation
            XFd = self.funcSmoothData( XAligned );

            % generate principal component scores
            Z = pca_fd_score( XFd, ...
                              self.MeanFd, ...
                              self.CompFd, ...
                              self.NumFeatures );

            % flatten
            Z = reshape( Z, size(Z,1), [] );

        end

    end


    methods (Access = private)

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

    end

end