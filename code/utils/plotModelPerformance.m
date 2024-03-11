function fig = plotModelPerformance( thisInvestigation, ...
                                     varName, metric, metricName, args )
    % Produce a figure of model performance from results
    arguments
        thisInvestigation   Investigation
        varName             string
        metric              string
        metricName          string
        args.Set            char {mustBeMember(args.Set, {'Training', 'Validation'})}
        args.YLimits        double
        args.YTickInterval  double
        args.LogScale       logical = false
        args.Percentiles    logical = false
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

    if args.Percentiles
        y = thisInvestigation.([args.Set 'Results']).Median.(metric);
        err{1} = y - thisInvestigation.([args.Set 'Results']).Prctile25.(metric);
        err{2} = thisInvestigation.([args.Set 'Results']).Prctile75.(metric) - y;
    else
        y = thisInvestigation.([args.Set 'Results']).Mean.(metric);
        err{1} = repmat( thisInvestigation.([args.Set 'Results']).SD.(metric), 2 , 1);
        err{2} = err{1};
    end

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
                
                errorbar(ax, x, y(j, :, i, k), ...
                    err{1}(j, :, i, k), err{2}(j, :, i, k), ...
                    LineStyle = 'none', ...
                    Color = colours(k,:), LineWidth = 1, ...
                    CapSize = 5, ...
                    HandleVisibility = 'off');
            end

            xlim( ax, [0 max(x0)] );
            if isfield(args, 'YLimits')
                ylim(ax, args.YLimits);
                if isfield(args, 'YTickIncrement')
                    yTicks = args.YLimits(1):args.YTickInterval:args.YLimits(2);
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