function plotSpread( ax, X, t, c, lb, ub )
    % Plot the variation of waveforms
    arguments
        ax          
        X           double
        t           double = []
        c           {mustBeA(c, {'char', 'double'})} = lines(1)
        lb          double = []
        ub          double = []
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

    if ~isempty(lb) || ~isempty(ub)
        if ~isempty(lb)
            ySpread = [ meanX-stdX; flip(lb) ];
        else
            ySpread = [ ub; flip(meanX+stdX) ];
        end
        fill( ax, xSpread, ySpread, c, FaceAlpha = 0.25, EdgeColor = 'none' );
    end

    plot( ax, t, meanX, LineWidth=2.5, Color=c );

end