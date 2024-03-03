% test the model with a grid search

clear;

path = fileparts( which('code/analyseLinearModel.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.StoreIndividualBetas = true;
setup.model.args.StoreIndividualVIFs = true;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 5;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = true;
setup.eval.RetainAllParameters = true;

parameters = [ "model.args.EncodingType", ...
               "data.class" ];
values = {{'Discrete', 'Continuous'}, ...
          {@SmartphoneDataset, @DelsysDataset}};

myInvestigation = Investigation( 'LinearModel', path, parameters, values, setup );

myInvestigation.run;

%% extract training model's statistics
metrics = ["StdRMSE", "FStat", "RSquared", "Shrinkage", "CookMeanOutlierProp", "VIFHighProp"];
results = myInvestigation.getMultiVarTable( metrics );
exportTableToLatex( results, fullfile(path, 'LinearModelStats') );

%% create box plots for the beta coefficients
vars = myInvestigation.Evaluations{1}.Models{1}.Model.CoefficientNames(2:end);
vars = strrep(vars, 'x', 'Beta');
values = myInvestigation.getResultArray( vars );

fig = figure;
fontname( fig, 'Arial' );
fig.Position(3) = 800;
fig.Position(4) = 600;
layout = tiledlayout( 2, 2, TileSpacing='loose' );
ax = gobjects( 4, 1 );
for i = 1:4

    ax(i) = nexttile(layout);

    boxplot( ax(i), squeeze(values(:,i,:)) );
    ylim( ax(i), [-1.5 1.5] );
    title( ax(i), myInvestigation.EvaluationNames(i) );

end

