% test the model with a grid search

clear;

path = fileparts( which('code/analyseSensitivity.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'XGBoost';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = 18;

setup.model.args.Optimize = true;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 1;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = false;

parameters = [ "model.args.EncodingType", ...
               "model.args.NumPredictors", ...
               "data.class" ];
values = {{'Discrete', 'Continuous'}, ...
          2:2:26, ...
          {@SmartphoneDataset, @DelsysDataset}};

myInvestigation = Investigation( 'Sensitivity', path, parameters, values, setup );

myInvestigation.run;

%% produce scatter plots showing relationship between StdRMSE and chosen metrics
setNames = ["Smartphone Dataset", "Delsys"];
metrics = ["SkewnessMean", "KurtosisMean", "VIFHighProp"];
numMetrics = length(metrics);

numEncodings = myInvestigation.SearchDims(1);
numPredictors = myInvestigation.SearchDims(2);
numDatasets = myInvestigation.SearchDims(3);

fig = figure;
fontname(fig, 'Arial');
fig.Position(3) = numMetrics*350 + 100;
fig.Position(4) = numDatasets*250 + 100;
layout = tiledlayout(fig, numDatasets, numMetrics, TileSpacing='loose');
colours = lines(numEncodings);

for i = 1:numDatasets

    for j = 1:numMetrics
    
        ax = nexttile(layout);
        hold( ax, 'on' );
    
        for k = 1:numEncodings

            xMedian = myInvestigation.TrainingResults.Median.(metrics(j));
            xPrc25 = myInvestigation.TrainingResults.Prctile25.(metrics(j));
            xPrc75 = myInvestigation.TrainingResults.Prctile75.(metrics(j));

            yMedian = myInvestigation.ValidationResults.Median.StdRMSE;
            yPrc25 = myInvestigation.ValidationResults.Prctile25.StdRMSE;
            yPrc75 = myInvestigation.ValidationResults.Prctile75.StdRMSE;

            xMedian = squeeze(xMedian(i,:,k));
            xPrc25 = squeeze(xPrc25(i,:,k));
            xPrc75 = squeeze(xPrc75(i,:,k));
            yMedian = squeeze(yMedian(i,:,k));
            yPrc25 = squeeze(yPrc25(i,:,k));
            yPrc75 = squeeze(yPrc75(i,:,k));

            errorbar( ax, xMedian, yMedian, ...
                      yMedian-yPrc25, yPrc75-yMedian, ...
                      xMedian-xPrc25, xPrc75-xMedian, ...
                      LineStyle = 'none', ...
                      Color = colours(k,:), LineWidth = 1, ...
                      CapSize = 5, ...
                      HandleVisibility = 'off');
               
        end

        legend( ax, {'Discrete', 'Continuous'} );
        xlabel( ax, metrics(j) );
        ylabel( ax, 'Standardised Validation RMSE' );
        title( ax, [char(setNames(i)) ' - ' char(metrics(j))] );

    end

end