function [XFd, XSmth] = funcSmoothData( XCell )
    % Convert raw time series data to smooth functions
    arguments
        XCell       cell
    end

    % pad the series for smoothing
    X = padData( XCell, 0, 0, ...
                 Longest = true, ...
                 Same = true, ...
                 Location = 'Right' );

    % set an arbitrary time span
    tSpan = linspace( 0, 1, size(X,1) );

    % set the functional data analysis options
    numBasis = fix( length(tSpan)/10 );
    basisOrder = 4;
    penaltyOrder = 2;
    % in future, assume filtering has done the smoothing already
    lambda = 1E-8; 

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