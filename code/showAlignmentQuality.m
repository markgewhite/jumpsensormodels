% Compute alignment spreads of the methods available for FPCA
clear

path = fileparts( which('code/showAlignmentQuality.m') );
path = [path '/../results/'];

datasets = { @SmartphoneDataset, @AccelerometerDataset };
methods = {'XCMeanConv', 'XCRandom', 'LMTakeoffPeak', 'LMLandingPeak', ...
                        'LMTakeoffBiomechanical', 'LMTakeoffActual'};
modelTypes = {'Linear', 'Lasso', 'SVM', 'XGBoost'};

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.StoreXAligned = true;
setup.model.args.StoreAlignmentMetrics = true;
setup.model.args.Optimize = true;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 25;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = true;

parameters = [ "data.class", ...
               "model.args.ContinuousEncodingArgs.AlignmentMethod", ...
               "model.args.ModelType" ];
values = { datasets, methods, modelTypes };

thisInvestigation = Investigation( 'AlignmentQuality2', path, ...
                                    parameters, values, setup, true );
thisInvestigation.run;
report = thisInvestigation.saveReport;


%% Plot alignment quality
methodsShort = methods;
methodsShort{end} = '';
metrics = {'AlignmentRMSE', 'AlignmentPCC', 'AlignmentSNR'};
titles = {'Alignment RMSE', 'Pearson Correlation', 'Signal-to-Noise Ratio'};
yLabels = {'RMSE (m/s^2)', 'Correlation', 'SNR (dB)'};

yLimits = {[0.6 1.2], [0.2 0.8], [-1 3]};

figS1 = createBarCharts( report, methodsShort, metrics, yLabels, yLimits, titles, 1, false );
leftSuperTitle( figS1, 'Smartphone Dataset', 'a' );
saveGraphicsObject( figS1, path, 'AlignmentQualitySmart' );

figS2 = createBarCharts( report, methods, metrics, yLabels, yLimits, titles, 2, false );
leftSuperTitle( figS2, 'Accelerometer Dataset', 'b' );
saveGraphicsObject( figS2, path, 'AlignmentQualityAccel' );


%% Plot model performance as a consequence
numMethods = length(methods);
metrics = {'StdRMSE', 'StdRMSE', 'StdRMSE', 'StdRMSE'};
titles = {'Linear', 'Lasso', 'SVM', 'XGBoost'};

yLabels = {'Standardised RMSE', 'Standardised RMSE', 'Standardised RMSE', 'Standardised RMSE'};
numMetrics = length(metrics);

yLimits = {[0 1.3], [0 1.3], [0 1.3], [0 1.3]};

figA1 = createBarCharts( report, methodsShort, metrics, yLabels, yLimits, titles, 1, true );
leftSuperTitle( figA1, 'Smartphone Dataset', 'a' );
saveGraphicsObject( figA1, path, 'AlignmentPerfSmart' );

figA2 = createBarCharts( report, methods, metrics, yLabels, yLimits, titles, 2, true );
leftSuperTitle( figA2, 'Accelerometer Dataset', 'b' );
saveGraphicsObject( figA2, path, 'AlignmentPerfAccel' );


%% Generate figure
function fig = createBarCharts( report, methods, metrics, metricNames, yLimits, titles, d, multiModel )
    % Generate the standard bar chart
    
    numMethods = length(methods);
    numMetrics = length(metrics);

    fig = figure;
    fontname( fig, 'Arial' );
    fig.Position(3) = numMetrics*300+100;
    fig.Position(4) = 350;
    layout = tiledlayout( 1, numMetrics, TileSpacing='compact' );

    for i = 1:numMetrics
        ax = nexttile( layout );

        if multiModel
            k = i;
        else
            k = 1;
        end

        y = squeeze(report.TrainingResults.Mean.(metrics{i})(d,:,k))';
        err = squeeze(report.TrainingResults.SD.(metrics{i})(d,:,k))';

        if isfield(report.ValidationResults.Mean, metrics{i})
            y = [y squeeze(report.ValidationResults.Mean.(metrics{i})(d,:,k))']; %#ok<*AGROW>
            err = [err squeeze(report.ValidationResults.SD.(metrics{i})(d,:,k))'];
        end

        if d==1
            % no LMTakeoffActual for Smartphone
            y(numMethods,:) = NaN;
            err(numMethods,:) = NaN;
        end

        obj = bar( ax, methods, y );
        hold( ax, 'on' );

        % locate the x coordinates of the bar end points
        xErr = arrayfun( @(obj) obj.XEndPoints, obj, UniformOutput=false );
        xErrorBars = cat(1,xErr{:})';

        % Plot the error bars
        errorbar( ax, xErrorBars, y, err, '.', 'Color', 'black', 'LineWidth', 1);

        % Annotate validation values
        if isfield(report.ValidationResults.Mean, metrics{i}) && multiModel
            xVal = xErrorBars(:,2);
            yVal = y(:,2);
            for j = 1:numMethods
                text(ax, xVal(j)-0.1, yVal(j), sprintf('%.3f', yVal(j)), ...
                     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
            end
        end

        ylabel( ax, metricNames{i} );
        ylim( ax, yLimits{i} );
        title( ax, titles{i} );

        if i==1
            legend( ax, {'Training', 'Validation'}, Location='northwest' );
        end

    end

end
