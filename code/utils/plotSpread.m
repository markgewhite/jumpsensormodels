function plotSpread( ax, X, t, c )
    % Plot the variation of waveforms
    arguments
        ax          
        X           double
        t           double = []
        c           {mustBeA(c, {'char', 'double'})} = lines(1)
    end

    if isempty(t)
        t = 0:size(X, 1)-1;
    end

    stdX = std( X, [], 2);
    meanX = mean( X, 2);

    % draw the shading spread of +/- SD
    xSpread = [ t flip(t) ];
    ySpread = [ meanX+stdX; flip(meanX-stdX) ];

    fill( ax, xSpread, ySpread, c, FaceAlpha = 0.5, EdgeColor = 'none' );
    hold( ax, 'on' );
    plot( ax, t, meanX, LineWidth=2.5, Color=c );

end