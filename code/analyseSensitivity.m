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
setup.eval.KFoldRepeats = 5;
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

for i = 1:numDatasets

    for j = 1:numMetrics
    
        ax = nexttile(layout);
        hold( ax, 'on' );
    
        for k = 1:numEncodings

            allMetrics = [];
            allValErrors = [];
            for p = 1:numPredictors
    
                models = myInvestigation.Evaluations{k,p,i}.Models;
                allMetrics = [allMetrics ...
                    cellfun(@(mdl) mdl.Loss.Training.(metrics(j)), models)]; %#ok<*AGROW>
                allValErrors = [allValErrors ...
                    cellfun(@(mdl) mdl.Loss.Validation.StdRMSE, models)];
        
            end

            plot( ax, allMetrics, allValErrors, 'o' );
    
        end

    end

end