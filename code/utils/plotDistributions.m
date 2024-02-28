function [fig, ax] = plotDistributions( X, names, idx, figTitle, figID, annotations )
    % Plot distributions for specified variable indices
    arguments
        X           {mustBeA(X, {'double', 'cell'})}
        names       string
        idx         double {mustBePositive, mustBeInteger}
        figTitle    string = ""
        figID       string = ""
        annotations string = ""
    end

    numPlots = length(idx);
    if numPlots>5
        c = 5;
        r = ceil( numPlots/c );
    else
        r = 1;
        c = numPlots;
    end

    fig = figure;
    fontname( fig, 'Arial' );
    fig.Position(3) = c*200 + 100;
    fig.Position(4) = 150*r + 50;

    layout = tiledlayout( r, c, TileSpacing= 'compact' );

    ax = cell( numPlots, 1 );
    for i = 1:numPlots
        ax{i} = nexttile( layout );

        % generate probability density function
        if iscell(X)
            [pX, mu, sigma] = plotPDFSpread( ax{i}, X, idx(i) );
        else
            [pY, pX] = kde( X(:,idx(i)) );
            pY = pY./sum(pY);
            mu = mean( X(:,idx(i)) );
            sigma = std( X(:,idx(i)) );

            plot( ax{i}, pX, pY, LineWidth = 1.5 );
            hold( ax{i}, 'on' );
        end

        % generate equivalent normal distribution
        nY = (1/(sigma*sqrt(2*pi)))*exp(-.5*(((pX-mu)/sigma).^2));
        nY = nY./sum(nY);
        plot( ax{i}, pX, nY, '--', LineWidth = 1.5, color = 'k' );
        hold( ax{i}, 'off' );

        % format plot
        xlabel( ax{i}, names(idx(i)) );
        ylabel( ax{i}, 'Density' );
        ytickformat( ax{i}, '%.2f' );
        finalisePlot( ax{i} );

        if annotations~=""
            text( ax{i}, 0.9*ax{i}.XLim(2), 0.9*ax{i}.YLim(2), ...
                  annotations(i), ...
                  HorizontalAlignment = 'right', ...
                  VerticalAlignment = 'top' );
        end
    
    end

    leftSuperTitle( fig, figTitle, figID );

end


function [pNormX, mu, sigma] = plotPDFSpread( ax, X, idx )

    numFits = length(X);

    % set the bounds
    minX = min(cellfun( @(x) min(x(:,idx)), X ));
    maxX = max(cellfun( @(x) max(x(:,idx)), X ));

    % extend them
    extRngX = (maxX-minX)*0.15;

    % initialise normalised scale
    pNormX = linspace( minX-extRngX, maxX+extRngX, 100 )';
    pNormY = zeros( 100, numFits );

    % fit PDFs for each set
    for i = 1:numFits
        pY = kde( X{i}(:,idx), EvaluationPoints = pNormX );
        pNormY(:,i) = pY./sum(pY);
    end

    allX = cat(1, X{:} );
    mu = mean( allX(:,idx) );
    sigma = std( allX(:,idx) );

    prc25Y = prctile(pNormY, 25, 2);
    prc50Y = prctile(pNormY, 50, 2);
    prc75Y = prctile(pNormY, 75, 2);

    % draw the shading spread of +/- SD
    cmap = lines(1);
    xSpread = [ pNormX; flip(pNormX) ];
    ySpread = [ prc75Y; flip(prc25Y) ];
    fill( ax, xSpread, ySpread, cmap, FaceAlpha = 0.35, EdgeColor = 'none' );
    hold( ax, 'on' );

    plot( ax, pNormX, prc50Y, LineWidth=1.5, Color=cmap );


end