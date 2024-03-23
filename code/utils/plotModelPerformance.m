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
        args.XLogScale      logical = false
        args.YLogScale      logical = false
        args.Percentiles    logical = false
        args.FitType        char ...
            {mustBeMember(args.FitType, ...
                {'none', 'poly1', 'poly2', 'power1', 'exp1'})} = 'none'
    end

    % extract the grid search values
    numEncodings = thisInvestigation.SearchDims(1);
    numPredictors = thisInvestigation.SearchDims(2);
    numDatasets = thisInvestigation.SearchDims(3);
    numModelTypes = thisInvestigation.SearchDims(4);

    % create the figure and layout
    fig = figure;
    fontname( fig, 'Arial' );
    fig.Position(3) = 350*numEncodings + 100;
    fig.Position(4) = 250*numDatasets + 100;
    layout = tiledlayout( numDatasets, numEncodings, TileSpacing='compact' );
    colours = lines(numModelTypes);
    
    x0 = thisInvestigation.GridSearch{2};

    % use percentiles or average
    if args.Percentiles
        y = thisInvestigation.([args.Set 'Results']).Median.(metric);
        err{1} = y - thisInvestigation.([args.Set 'Results']).Prctile25.(metric);
        err{2} = thisInvestigation.([args.Set 'Results']).Prctile75.(metric) - y;
    else
        y = thisInvestigation.([args.Set 'Results']).Mean.(metric);
        err{1} = repmat( thisInvestigation.([args.Set 'Results']).SD.(metric), 2 , 1);
        err{2} = err{1};
    end

    % extract the names for labels
    encodingNames = thisInvestigation.GridSearch{1};
    datasetNames = string(cellfun(@func2str, thisInvestigation.GridSearch{3}, 'UniformOutput', false));
    modelTypeNames = thisInvestigation.GridSearch{4};
    
    jitter = 0.005*(max(x0)-min(x0));
    for i = 1:numDatasets
        for j = 1:numEncodings

            ax = nexttile(layout);
            hold( ax, 'on' );

            lineObj = gobjects( numModelTypes, 1 );
            for k = 1:numModelTypes

                % introduce jitter to the x points so they don't overlap
                x = x0+randn(1,numPredictors)*jitter;

                % plot the actual points
                lineObj(k) = plot( ax, x, y(j, :, i, k), ...
                                  Marker = 'o', MarkerSize = 5, ...
                                  MarkerFaceColor = colours(k,:), ...
                                  Color = colours(k,:), ...
                                  LineStyle = 'none');
                
                % with error bars 
                errorbar(ax, x, y(j, :, i, k), ...
                    err{1}(j, :, i, k), err{2}(j, :, i, k), ...
                    LineStyle = 'none', ...
                    Color = colours(k,:), LineWidth = 1, ...
                    CapSize = 5, ...
                    HandleVisibility = 'off');

                % include a best fit line of chosen type
                if ~strcmp(args.FitType, 'none')

                    % include only valid points
                    idx = ~isnan(y(j, :, i, k));
                    xValid = x(idx);
                    yValid = y(j, idx, i, k);

                    % create the fitting object
                    [curveFit, ~] = fit(xValid', yValid', ...
                                        fittype(args.FitType));
                    
                    % create a more granular scale
                    xFit = linspace(min(x), max(x), 50);

                    % evaluate the fitted curve
                    [yFitCI, yFit] = predint(curveFit, xFit, 0.95, 'functional');

                    % fill in a shared region showing uncertainty
                    fill([xFit, fliplr(xFit)], [yFitCI(:,1); flipud(yFitCI(:,2))], ...
                         colours(k,:), ...
                         FaceAlpha=0.2, EdgeColor='none');

                    % plot the best fit line
                    plot(ax, xFit, yFit, '--', ...
                         Color = colours(k,:), LineWidth = 2);

                end

            end

            % set the desired scales
            if args.XLogScale
                ax.XAxis.Scale = 'log';
            else
                xlim( ax, [0 max(x0)] );
            end

            if args.YLogScale
                ax.YAxis.Scale = 'log';
            elseif isfield(args, 'YLimits')
                ylim(ax, args.YLimits);
                if isfield(args, 'YTickInterval')
                    yTicks = args.YLimits(1):args.YTickInterval:args.YLimits(2);
                    yTickLabels = arrayfun(@(x) num2str(x, '%.2f'), yTicks, 'UniformOutput', false);
                    ax.YTick = yTicks;
                    ax.YTickLabel = yTickLabels;
                end
            end

            % finalise the plot
            xlabel( ax, varName );
            ylabel( ax, metricName );
            heading = strcat( datasetNames(i), " - ", encodingNames(j) );
            title( ax, heading );

            if i==1 && j==1
                legend( ax, lineObj, modelTypeNames, Location = 'best' );
            end

        end
    end

end