% Compute alignment spreads of the methods available for FPCA
clear

path = fileparts( which('code/showAlignmentQuality.m') );
path = [path '/../results/'];

datasets = { @SmartphoneDataset, @DelsysDataset };
methods = {'XCMeanConv', 'XCRandom', 'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual'};
numMethods = length(methods);
metrics = {'AlignmentRMSE', 'AlignmentPCC', 'AlignmentTDE'};
metricNames = {'Alignment RMSE (ms)', 'Pearson Correlation', 'Time Delay Estimate (ms)'};
numMetrics = length(metrics);

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.StoreXAligned = true;
setup.model.args.StoreAlignmentMetrics = true;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 25;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = true;

parameters = [ "data.class", ...
               "model.args.ContinuousEncodingArgs.AlignmentMethod" ];
values = { datasets, methods };

thisInvestigation = Investigation( 'AlignmentQuality', path, ...
                                    parameters, values, setup, true );
thisInvestigation.run;


%% Plot alignment quality
fig = figure;
fontname( fig, 'Arial' );
fig.Position(3) = 800;
fig.Position(4) = 350;
layout = tiledlayout( 2, 3, TileSpacing='loose' );
for i = 1:2
    for j = 1:numMetrics
        ax = nexttile( layout );

        y = [thisInvestigation.TrainingResults.Mean.(metrics{j})(i,:);
             thisInvestigation.ValidationResults.Mean.(metrics{j})(i,:)]';

        bar( ax, methods, y );

        title( ax, metricNames{i} );
        xlabel( ax, 'Alignment Methods');
        ylabel( ax, metricNames{i} );

    end
end


%saveGraphicsObject( fig, path, 'OffsetSpread' );
