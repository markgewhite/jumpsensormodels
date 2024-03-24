% Compute alignment spreads of the methods available for FPCA
clear

path = fileparts( which('code/showAlignmentQuality.m') );
path = [path '/../results/'];

datasets = { @SmartphoneDataset, @AccelerometerDataset };
methods = {'XCMeanConv', 'XCRandom', 'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual'};
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
thisInvestigation.save;


%% Plot alignment quality
metrics = {'AlignmentRMSE', 'AlignmentPCC', 'RSquared', 'FStat'};
titles = {'Alignment RMSE', 'Pearson Correlation', 'R Squared', 'F-Statistic'};
yLabels = {'RMSE (ms)', 'Correlation', 'R^2', 'F'};

yLimits = {[0 40], [0 0.8], [0.5 1], [0 150]};

fig1 = createBarCharts( thisInvestigation, methods, metrics, yLabels, yLimits, titles, false );
saveGraphicsObject( fig1, path, 'AlignmentQuality' );


%% Plot model performance as a consequence
numMethods = length(methods);
metrics = {'StdRMSE', 'StdRMSE', 'StdRMSE', 'StdRMSE'};
titles = {'Linear', 'Lasso', 'SVM', 'XGBoost'};

yLabels = {'RMSE (W/kg)', 'RMSE (W/kg)', 'RMSE (W/kg)', 'RMSE (W/kg)'};
numMetrics = length(metrics);

yLimits = {[0 1.6], [0 1.6], [0 1.6], [0 1.6]};

fig2 = createBarCharts( thisInvestigation, methods, metrics, yLabels, yLimits, titles, true );
saveGraphicsObject( fig2, path, 'AlignmentModelPerformance' );


%% Generate figure
function fig = createBarCharts( thisInvestigation, methods, metrics, metricNames, yLimits, titles, multiModel )
    % Generate the standard bar chart
    
    numMethods = length(methods);
    numMetrics = length(metrics);

    fig = figure;
    fontname( fig, 'Arial' );
    fig.Position(3) = numMetrics*250+100;
    fig.Position(4) = 500;
    layout = tiledlayout( 2, numMetrics, TileSpacing='compact' );
    for i = 1:2
        for j = 1:numMetrics
            ax = nexttile( layout );

            if multiModel
                k = j;
            else
                k = 1;
            end

            y = squeeze(thisInvestigation.TrainingResults.Mean.(metrics{j})(i,:,k))';
            err = squeeze(thisInvestigation.TrainingResults.SD.(metrics{j})(i,:,k))';

            if isfield(thisInvestigation.ValidationResults.Mean, metrics{j})
                y = [y squeeze(thisInvestigation.ValidationResults.Mean.(metrics{j})(i,:,k))']; %#ok<*AGROW>
                err = [err squeeze(thisInvestigation.ValidationResults.SD.(metrics{j})(i,:,k))'];
            end
    
            if i==1
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

            if i==1
                % no method labels on the top row
                ax.XTickLabel = [];
            else
                ax.XTickLabelRotation = 270;
            end

            ylabel( ax, metricNames{j} );
            ylim( ax, yLimits{j} );
            title( ax, titles{j} );
    
            if i==2 && j==1
                legend( ax, {'Training', 'Validation'}, Location='northwest' );
            end
    
        end
    end

end
