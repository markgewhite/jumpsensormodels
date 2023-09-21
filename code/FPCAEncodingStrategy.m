classdef FPCAEncodingStrategy < EncodingStrategy
    % Class for features based on functional principal component analysis

    properties
        NumComponents   % number of principal components
        Length          % fixed length for encoding
        BasisOrder      % basis function order
        PenaltyOrder    % roughness penalty order
        Lambda          % roughness penalty
        MeanFd          % mean curve as a functional data object
        CompFd          % component curves as functional data objects
        AlignmentMethod % method for aligning signals prior to PCA
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
                args.AlignmentMethod    char ...
                    {mustBeMember( args.AlignmentMethod, ...
                        {'XCRandom', 'XCMeanConv', ...
                         'LMTakeoff', 'LMLanding' })} = 'XCRandom'
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

            % convert to padded array
            X = padData( thisDataset.X, ...
                         Longest = true, ...
                         Same = true, ...
                         Location = 'Right' );

            self.Length = size( X, 1 );

            % align the curves, setting alignment
            XAligned = self.setCurveAlignment( X );

            % create the functional representation
            XFd = self.funcSmoothData( XAligned );

            % perform principal components analysis (fit the model)
            pcaStruct = pca_fd( XFd, self.NumComponents );

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
                Z = [];
                return
            end

            % convert to padded array
            X = padData( thisDataset.X, ...
                         PadLen = self.Length, ...
                         Same = true, ...
                         Location = 'Right' );

            % align the curves
            XAligned = self.alignCurves( X );

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


        function XAligned = setCurveAlignment( self, X )
            % Set curve alignment when fitting
            arguments
                self            FPCAEncodingStrategy
                X               double
            end

            switch self.AlignmentMethod

                case 'XCRandom'
                    [XAligned, self.AlignmentSignal] = ...
                                xcorrAlignment( X, Reference = 'Random' );

                case 'XCMeanConv'
                    [XAligned, self.AlignmentSignal ] = ...
                                iteratedAlignment( X, ...
                                                   self.AlignmentTolerance, ...
                                                   self.ShowConvergence );

                case {'LMTakeoff', 'LMLanding'}
                    XAligned = landmarkAlignment( X, ...
                                        landmark = self.AlignmentMethod );


            end

        end


        function XAligned = alignCurves( self, X )
            % Align the curves by chosen method
            arguments
                self            FPCAEncodingStrategy
                X               double
            end

            switch self.AlignmentMethod

                case {'XCRandom', 'XCMeanConv'}
                    XAligned = xcorrAlignment( X, ...
                                               Reference = 'Specified', ...
                                               RefSignal = self.AlignmentSignal );

                case {'LMTakeoff', 'LMLanding'}
                    XAligned = landmarkAlignment( X, ...
                                        landmark = self.AlignmentMethod );

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

    end

end


function [XAligned, alignmentSignal ] = iteratedAlignment( X, tol, verbose )
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
        [XAligned, alignmentSignal] = xcorrAlignment( XAligned, Reference = 'Mean' );

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

