% test the model with a grid search

clear;

path = fileparts( which('code/analyseSensitivity.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = 18;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 10;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = false;

parameters = [ "model.args.EncodingType", ...
               "model.args.NumPredictors", ...
               "data.class" ];
values = {{'Discrete', 'Continuous'}, ...
          2:2:26, ...
          {@SmartphoneDataset, @DelsysDataset}};

myInvestigation = ParallelInvestigation( 'Sensitivity', path, parameters, values, setup );

myInvestigation.run;

%% produce scatter plots showing relationship between StdRMSE and chosen metrics
metrics = ["VIFHighProp"];

fig = figure;
fontname(fig, 'Arial');
fig.Position(3) = 800;
fig.Position(4) = 600;
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'loose');

for i = 1:4

    % extract all the encoded features for discrete and continuous
    models = myInvestigation.Evaluations{i}.Models;
    allMetrics = cellfun(@(mdl) mdl.Loss.Training.(metrics(1)), models);
    allTrnErrors = cellfun(@(mdl) mdl.Loss.Training.StdRMSE, models);
    allValErrors = cellfun(@(mdl) mdl.Loss.Validation.StdRMSE, models);
    
    ax = nexttile(layout);
    plot( ax, allMetrics, allTrnErrors, 'o' );
    hold( ax, 'on' );
    plot( ax, allMetrics, allValErrors, 'o' );

end