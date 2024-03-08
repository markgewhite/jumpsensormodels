% test the model with a grid search

clear;

path = fileparts( which('code/analyseLassoModel.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = 26;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 50;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = false;

parameters = [ "model.args.EncodingType", ...
               "model.args.NumPredictors", ...
               "data.class", ...
               "model.args.ModelType" ];
values = {{'Discrete', 'Continuous'}, ...
          2:2:26, ...
          {@SmartphoneDataset, @DelsysDataset}, ....
          {'Linear', 'Lasso', 'SVM', 'XGBoost'}};

myInvestigation = ParallelInvestigation( 'Predictors', path, parameters, values, setup );

myInvestigation.run;

%% plot RMSE as a function of the number of predictors
numEncodings = myInvestigation.SearchDims(1);
numPredictors = myInvestigation.SearchDims(2);
numDatasets = myInvestigation.SearchDims(3);
numModelTypes = myInvestigation.SearchDims(4);

fig = figure;
fontname( fig, 'Arial' );
fig.Position(3) = 800;
fig.Position(4) = 600;
layout = tiledlayout( numDatasets, numEncodings, TileSpacing='loose' );
colours = lines(numModelTypes);

x0 = myInvestigation.GridSearch{2};
y = myInvestigation.ValidationResults.Mean.StdRMSE;
err = myInvestigation.ValidationResults.SD.StdRMSE;

encodingNames = myInvestigation.GridSearch{1};
modelTypeNames = myInvestigation.GridSearch{4};
datasetNames = ["Smartphone", "Delsys"];

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
            
            errorbar(ax, x, y(j, :, i, k), err(j, :, i, k), ...
                LineStyle = 'none', ...
                Color = colours(k,:), LineWidth = 1, ...
                CapSize = 5, ...
                HandleVisibility = 'off');
        end
        xlabel( ax, 'Number of Features' );
        ylabel( ax, 'Standardised RMSE' );
        legend( ax, modelTypeNames );
        heading = strcat( datasetNames(i), " - ", encodingNames(j) );
        title( ax, heading );
    end
end

saveGraphicsObject( fig, path, 'ModelType' );