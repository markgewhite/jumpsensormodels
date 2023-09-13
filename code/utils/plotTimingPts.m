function plotTimingPts( ax, y, idxOld, idxNew )
    % Plot the timing points on the jump acceleration curve
    arguments
        ax          
        y           double {mustBeVector}
        idxOld      double {mustBeVector}
        idxNew      double {mustBeVector}
    end

    % trim to timing points
    idxFirst = max( min( [idxOld, idxNew] ) - 100, 1 );
    idxLast = min( max( [idxOld, idxNew] ) + 100, length(y) );

    % plot the curve
    plot( ax, idxFirst:idxLast, y(idxFirst:idxLast) );

    % plot the timing points
    hold( ax, 'on' );
    plot( ax, idxOld, y( idxOld ), 'kx', LineWidth=2 );
    plot( ax, idxNew, y( idxNew ), 'ro', LineWidth=2 );
    hold( ax, 'off' );

    drawnow;

end
