function fig = plotModelPerformance( thisInvestigation, varName, metric, metricName, set )
    % Produce a figure of model performance from results
    arguments
        thisInvestigation   Investigation
        varName             string
        metric              string
        metricName          string
        set                 char {mustBeMember(set, {'Training', 'Validation'})}
    end

    numEncodings = thisInvestigation.SearchDims(1);
    numPredictors = thisInvestigation.SearchDims(2);
    numDatasets = thisInvestigation.SearchDims(3);
    numModelTypes = thisInvestigation.SearchDims(4);

    fig = figure;
    fontname( fig, 'Arial' );
    fig.Position(3) = 350*numEncodings + 100;
    fig.Position(4) = 250*numDatasets + 100;
    layout = tiledlayout( numDatasets, numEncodings, TileSpacing='loose' );
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
            xlabel( ax, varName );
            ylabel( ax, metricName );
            legend( ax, modelTypeNames, Location = 'best' );
            heading = strcat( datasetNames(i), " - ", encodingNames(j) );
            title( ax, heading );
        end
    end

    sgtitle( fig, [set ' Set']);

end