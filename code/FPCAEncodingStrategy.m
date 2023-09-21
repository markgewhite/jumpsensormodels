classdef FPCAEncodingStrategy < EncodingStrategy
    % Class for features based on functional principal component analysis

    properties
        NumComponents   % number of principal components
        BasisOrder      % basis function order
        PenaltyOrder    % roughness penalty order
        Lambda          % roughness penalty
        MeanFd          % mean curve as a functional data object
        CompFd          % component curves as functional data objects
        AlignmentSignal % reference signal for alignment
        AlignmentTolerance % alignment variance tolerance
        ShowConvergence % show plots and variance of alignement convergence
        Fitted          % flag whether the model has been fit
    end

    methods

        function self = FPCAEncodingStrategy( args )
            % Initialize the model
            arguments 
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
                args.AlignmentTolerance double ...
                    {mustBePositive} = 5E-2
                args.ShowConvergence    logical = false
            end

            if args.PenaltyOrder > (args.BasisOrder-2)
                eid = 'FPCA-01';
                msg = 'Penalty order too higher for basis order.';
                throwAsCaller( MException(eid, msg) );
            end

            self = self@EncodingStrategy;

            self.NumComponents = args.NumComponents;
            self.BasisOrder = args.BasisOrder;
            self.PenaltyOrder = args.PenaltyOrder;
            self.Lambda = args.Lambda;
            self.AlignmentTolerance = args.AlignmentTolerance;
            self.ShowConvergence = args.ShowConvergence;
            self.Fitted = false;

        end


        function Z = extractFeatures( self, thisDataset )
            % Compute the features using the fitted model
            arguments
                self                FPCAEncodingStrategy
                thisDataset         ModelDataset
            end

            % fit the principal components
            self.fit( thisDataset );

            % convert to padded array
            X = padCellToArray( thisDataset.X );

            % align the curves
            XAligned = alignCurves( X, ...
                                    Reference = 'Specified', ...
                                    RefSignal = self.AlignmentSignal );

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

        
        function self = fit( self, thisDataset )
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
            if self.ShowConvergence
                figure(1);
                hold off;
            end

            prevXMeanVar = mean(var(X, [], 2));
            converged = false;
            i = 0;
            XAligned = X;
            while ~converged && i<10
                [XAligned, self.AlignmentSignal] = alignCurves( XAligned, Reference = 'Mean' );
                XVar = var(XAligned, [], 2);
                XMeanVar = mean( XVar );
                converged = abs(prevXMeanVar - XMeanVar) < self.AlignmentTolerance;
                prevXMeanVar = XMeanVar;
                i = i+1;
                if self.ShowConvergence
                    plot( XVar );
                    hold on;
                    disp(['XAligned Var = ' num2str( XMeanVar, '%10.8f' )]);
                end
            end
            if self.ShowConvergence
                hold off;
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

    end

end
