function plotTimingPts( ax, acc, idxNew, idxOld )
    % Plot the timing points on the jump acceleration curve
    arguments
        ax          
        acc         double {mustBeVector}
        idxNew      double {mustBeVector}
        idxOld      double
    end

    hasLegacyPts = ~isnan( idxOld );

    % trim to timing points
    if hasLegacyPts
        idxFirst = max( min( [idxOld, idxNew] ) - 100, 1 );
        idxLast = min( max( [idxOld, idxNew] ) + 100, length(acc) );
    else
        idxFirst = max( min(idxNew) - 100, 1 );
        idxLast = min( max(idxNew) + 100, length(acc) );
    end

    % divide the indices into those for acc and vel curves
    idxNewAcc = idxNew([1 4]);
    idxNewVel = idxNew([2 3]);
    if hasLegacyPts
        idxOldAcc = idxOld([1 4]);
        idxOldVel = idxOld([2 3]);
    end

    % plot the acc curve
    plot( ax, idxFirst:idxLast, acc(idxFirst:idxLast) );
    hold( ax, 'on' );

    % plot the vel curve
    vel = cumtrapz(acc)/10;
    plot( ax, idxFirst:idxLast, vel(idxFirst:idxLast) );

    % plot horizontal axis line
    plot( ax, [idxFirst idxLast], [0 0], 'k:' );

    % plot the timing points
    plot( ax, idxNewAcc, acc( idxNewAcc ), 'ro', LineWidth=2 );
    plot( ax, idxNewVel, vel( idxNewVel ), 'ro', LineWidth=2 );
    if hasLegacyPts
        plot( ax, idxOldAcc, acc( idxOldAcc ), 'kx', LineWidth=2 );
        plot( ax, idxOldVel, vel( idxOldVel ), 'kx', LineWidth=2 );
    end

    hold( ax, 'off' );

    drawnow;

end
