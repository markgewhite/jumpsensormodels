function XSmth = funcSmoothData( XCell, XLen )
    % Convert raw time series data to smooth functions
    arguments
        XCell       cell
        XLen        double
    end

    % pad the series for smoothing
    X = padData( XCell, max(XLen), 0, ...
                 Same = true, ...
                 Location = 'Right' );

    % set an arbitrary time span
    tSpan = linspace( 0, max(XLen)-1 );

    % set the functional data analysis options
    numBasis = fix( length(tSpan)/10 );
    basisOrder = 2;
    penaltyOrder = 4;
    lambda = 1E-10; % assume filtering has done the smoothing already

    % set the functional basis
    basisFd = create_bspline_basis( [tSpan(1) tSpan(end)], ...
                                    numBasis, ...
                                    basisOrder );
    
    % and the parameters
    FdParams = fdPar( basisFd, penaltyOrder, lambda );

    % create the smooth functions from the original data
    XFd = smooth_basis( tSpan, X, FdParams );

    % re-sample for the input
    XSmth = eval_fd( tSpan, XFd );

end