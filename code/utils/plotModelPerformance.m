function fig = plotModelPerformance( thisInvestigation, ...
                                     varName, metric, metricName, ...
                                     set, yLimits, yTickIncrement )
    % Produce a figure of model performance from results
    arguments
        thisInvestigation   Investigation
        varName             string
        metric              string
        metricName          string
        set                 char {mustBeMember(set, {'Training', 'Validation'})}
        yLimits             double = []
        yTickIncrement      double = 0.25
    end

    numEncodings = thisInvestigation.SearchDims(1);
    numPredictors = thisInvestigation.SearchDims(2);
    numDatasets = thisInvestigation.SearchDims(3);
    numModelTypes = thisInvestigation.SearchDims(4);

    fig = figure;
    fontname( fig, 'Arial' );
    fig.Position(3) = 350*numEncodings + 100;
    fig.Position(4) = 250*numDatasets + 100;
    layout = tiledlayout( numDatasets, numEncodings, TileSpacing='compact' );
    colours = lines(numModelTypes);
    
    x0 = thisInvestigation.GridSearch{2};
    y = thisInvestigation.([set 'Results']).Mean.(metric);
    err = thisInvestigation.([set 'Results']).SD.(metric);
    
    encodingNames = thisInvestigation.GridSearch{1};
    datasetNames = string(cellfun(@func2str, thisInvestigation.GridSearch{3}, 'UniformOutput', false));
    modelTypeNames = thisInvestigation.GridSearch{4};
    
    for i = 1:numDatasets
        for j = 1:numEncodings

            ax = nexttile(layout);
            hold( ax, 'on' );

            for k = 1:numModelTypes
                x = x0+rand(1,numPredictors)*0.2;
                plot( ax, x, y(j, :, i, k), ...
                    Marker = 'o', MarkerSize = 5, ...
                    MarkerFaceColor = colours(k,:), ...
                    Color = colours(k,:), LineWidth = 2);
                
                errorbar(ax, x, y(j, :, i, k), err(j, :, i, k), ...
                    LineStyle = 'none', ...
                    Color = colours(k,:), LineWidth = 1, ...
                    CapSize = 5, ...
                    HandleVisibility = 'off');
            end

            xlim( ax, [0 max(x0)] );
            if ~isempty(yLimits)
                ylim(ax, yLimits);
                if ~isempty(yTickIncrement)
                    yTicks = yLimits(1):yTickIncrement:yLimits(2);
                    yTickLabels = arrayfun(@(x) num2str(x, '%.2f'), yTicks, 'UniformOutput', false);
                    ax.YTick = yTicks;
                    ax.YTickLabel = yTickLabels;
                end
            end
            xlabel( ax, varName );
            ylabel( ax, metricName );
            heading = strcat( datasetNames(i), " - ", encodingNames(j) );
            title( ax, heading );

            if i==1 && j==1
                legend( ax, modelTypeNames, Location = 'best' );
            end

        end
    end

end