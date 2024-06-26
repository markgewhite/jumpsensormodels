function fig = plotModelPerformance( report, ...
                                     varName, metric, metricName, args )
    % Produce a figure of model performance from results
    arguments
        report              {mustBeA(report, {'Investigation', 'struct'})}
        varName             string
        metric              string
        metricName          string
        args.Set            char {mustBeMember(args.Set, {'Training', 'Validation'})}
        args.XLimits        double
        args.YLimits        double
        args.YTickInterval  double
        args.XTickInterval  double
        args.XLogScale      logical = false
        args.YLogScale      logical = false
        args.Percentiles    logical = false
        args.FitType        char ...
            {mustBeMember(args.FitType, ...
                {'none', 'poly1', 'poly2', 'poly3', 'poly4', ...
                 'power1', 'power2', 'exp1', ...
                 'smoothingspline', 'lowess', 'loess', 'gpr'})} = 'none'
        args.SplineParameter double = 0.05
        args.GPBasisFunction char ...
            {mustBeMember(args.GPBasisFunction, ...
                {'none', 'constant', 'linear', 'pureQuadratic'})} = 'none'
        args.GPKernelFunction char ...
            {mustBeMember(args.GPKernelFunction, ...
                {'exponential', 'squaredexponential', 'matern32', 'matern52'})} = 'squaredexponential'        
        args.FitCoefBounds  double
        args.ShowFitCI      logical = false
        args.FitLogLog      logical = false
    end

    % extract the grid search values
    numEncodings = report.SearchDims(1);
    numPredictors = report.SearchDims(2);
    numDatasets = report.SearchDims(3);
    numModelTypes = report.SearchDims(4);

    % define the parametric and non-parametric fit types
    parametricFitTypes = {'poly1', 'poly2', 'poly3', 'poly4', 'power1', 'power2', 'exp1'};
    nonparametricFitTypes = {'smoothingspline', 'lowess', 'loess', 'gpr'};

    % create the figure and layout
    fig = figure;
    fontname( fig, 'Arial' );
    fig.Position(3) = 350*numEncodings + 100;
    fig.Position(4) = 250*numDatasets + 100;
    layout = tiledlayout( numDatasets, numEncodings, TileSpacing='compact' );
    colours = lines(numModelTypes);
    
    x0 = report.GridSearch{2};

    % use percentiles or average
    if args.Percentiles
        y = report.([args.Set 'Results']).Median.(metric);
        err{1} = y - report.([args.Set 'Results']).Prctile25.(metric);
        err{2} = report.([args.Set 'Results']).Prctile75.(metric) - y;
    else
        y = report.([args.Set 'Results']).Mean.(metric);
        err{1} = repmat( report.([args.Set 'Results']).SD.(metric), 2 , 1);
        err{2} = -err{1};
    end

    % also gather every single result
    yAll = cellfun( @(mdl) mdl.(metric), ...
                    report.([args.Set 'Results']).Models, ...
                    UniformOutput = false );
    xAll = repelem( x0, numel(yAll), 1 )';
    yAll = cat( 5, yAll{:} );

    % define extreme points
    extreme = @(z) (abs(z)>1E3) | (abs(z-median(y, 'all', 'omitnan'))>5*iqr(y, 'all'));

    % extract the names for labels
    encodingNames = report.GridSearch{1};
    datasetNames = string(cellfun(@func2str, report.GridSearch{3}, 'UniformOutput', false));
    modelTypeNames = report.GridSearch{4};
    
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
                    Color = colours(k,:), LineWidth = 0.75, ...
                    CapSize = 4, ...
                    HandleVisibility = 'off');

                % include a best fit line of chosen type
                if ~strcmp(args.FitType, 'none')

                    % include only valid points
                    ySubset = squeeze(yAll(j, :, i, k, :));
                    isValid = ~isnan(ySubset);
                    xValid = xAll(isValid);
                    yValid = ySubset(isValid);

                    % exclude any extreme values
                    isExtreme = extreme(yValid);
                    xValid = xValid(~isExtreme);
                    yValid = yValid(~isExtreme);

                    if args.FitLogLog
                        xValid = log10(xValid);
                        yValid = log10(yValid);
                    end

                    if ismember(args.FitType, parametricFitTypes)
                        % parametric curve fitting
                        [curveFit, xFit, yFit, yFitCI] = fitParametricCurve(xValid, yValid, args);
                    elseif ismember(args.FitType, nonparametricFitTypes)
                        % non-parametric curve fitting
                        [xFit, yFit, yFitCI] = fitNonparametricCurve(xValid, yValid, args);
                    end

                    if args.FitLogLog
                        xFit = 10.^xFit;
                        yFitCI = 10.^yFitCI;
                        yFit = 10.^yFit;
                    end

                    if args.ShowFitCI
                        % fill in a shared region showing uncertainty
                        fill([xFit, fliplr(xFit)], [yFitCI(:,1); flipud(yFitCI(:,2))], ...
                             colours(k,:), ...
                             FaceAlpha=0.2, EdgeColor='none');
                    end

                    % plot the best fit line
                    isExtrap = xFit>(1.1*max(xValid));
                    plot(ax, xFit(~isExtrap), yFit(~isExtrap), ...
                         Color = colours(k,:), LineWidth = 2.5);
                    plot(ax, xFit(isExtrap), yFit(isExtrap), '.', ...
                         Color = colours(k,:), LineWidth = 1);

                end

            end

            % set the desired scales
            if isfield( args, 'XLimits' )
                xlim( ax, args.XLimits );
                if isfield(args, 'XTickInterval')
                    numTicks = ceil(args.XLimits(2)/args.XTickInterval);
                    xTicks = args.XTickInterval:args.XTickInterval:numTicks*args.XTickInterval;
                    xTickLabels = arrayfun(@(x) num2str(x, '%.0f'), xTicks, 'UniformOutput', false);
                    ax.XTick = xTicks;
                    ax.XTickLabel = xTickLabels;
                end
            end
            
            if args.XLogScale
                ax.XAxis.Scale = 'log';
            end

            if isfield(args, 'YLimits')
                ylim(ax, args.YLimits);
                if isfield(args, 'YTickInterval')
                    numTicks = ceil(args.YLimits(2)/args.YTickInterval);
                    yTicks = args.YTickInterval:args.YTickInterval:numTicks*args.YTickInterval;
                    yTickLabels = arrayfun(@(x) num2str(x, '%.1f'), yTicks, 'UniformOutput', false);
                    ax.YTick = yTicks;
                    ax.YTickLabel = yTickLabels;
                end
            end

            if args.YLogScale
                ax.YAxis.Scale = 'log';
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


function [curveFit, xFit, yFit, yFitCI] = fitParametricCurve(x, y, args)
    % Fit a parametric curve to the data
    if isfield(args, 'FitCoefBounds')
        [curveFit, ~] = fit(x, y, fittype(args.FitType), ...
                            'Robust', 'BiSquare', ...
                            'Lower', args.FitCoefBounds(:,1), ...
                            'Upper', args.FitCoefBounds(:,2));
    else
        [curveFit, ~] = fit(x, y, fittype(args.FitType), 'Robust', 'BiSquare');
    end

    % Create a more granular scale for the fitted curve
    if isfield(args, 'XLimits')
        if args.XLogScale
            xFit = logspace(log10(args.XLimits(1)), log10(args.XLimits(2)), 50);
        else
            xFit = linspace(args.XLimits(1), args.XLimits(2), 50);
        end
    else
        if args.XLogScale
            xFit = logspace(log10(min(x)), log10(max(x)), 50);
        else
            xFit = linspace(min(x), max(x), 50);
        end
    end

    % Evaluate the fitted curve
    [yFitCI, yFit] = predint(curveFit, xFit, 0.95, 'functional');
end


function [xFit, yFit, yFitCI] = fitNonparametricCurve(x, y, args)
    % Fit a non-parametric curve to the data
    switch args.FitType

        case 'smoothingspline'
            % Fit a spline curve to the data
            smoothingSpline = fit(x, y, 'smoothingspline', ...
                                  SmoothingParam = args.SplineParameter );
            xFit = linspace(min(x), max(x), 100);
            yFit = feval(smoothingSpline, xFit);
            if args.ShowFitCI
                % Compute pointwise confidence intervals using bootstrap
                nBoots = 500;
                yBoots = bootstrp(nBoots, @(x,y) feval(fit(x, y, 'smoothingspline', ...
                                                       SmoothingParam = args.SplineParameter), xFit), x, y);
                yFitCI = prctile(yBoots, [2.5 97.5], 2);
            else
                yFitCI = [];
            end

        case {'lowess', 'loess'}
            % Fit the smooth curve to the original data
            yFit = smooth(x, y, args.FitType);
            xFit = x;
            
            if args.ShowFitCI
                % Compute pointwise confidence intervals using bootstrap
                nBoots = 500;
                yBoots = bootstrp(nBoots, @(x,y) smooth(x, y, args.FitType), x, y);
                yFitCI = prctile(yBoots, [2.5 97.5], 2);
            else
                yFitCI = [];
            end

        case 'gpr'
            gpr = fitrgp(x, y, ...
                         BasisFunction=args.GPBasisFunction, ...
                         KernelFunction = args.GPKernelFunction, ...
                         ConstantSigma=true);
            xFit = linspace(min(x), max(x), 100)';
            [yFit, ~, yFitCI] = predict(gpr, xFit);

    end
end