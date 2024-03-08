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
setup.eval.KFoldRepeats = 100;
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
titles = ["Smartphone (Discrete)", "Smartphone (Continuous)", ...
          "Delsys (Discrete)", "Delsys (Continuous)"];

fig1 = figure;
fontname( fig1, 'Arial' );
fig1.Position(3) = 1200;
fig1.Position(4) = 550;
layout = tiledlayout( 2, 3, TileSpacing='loose' );
colours = lines(2);
for i = 1:4

    thisEvaluation = myInvestigation.Evaluations{i};

    % compile the list of predictors (field names have beta prefix)
    varNames = ["Intercept", thisEvaluation.Models{1}.PredictorNames];
    fldNames = arrayfun( @(name) strcat("Beta", name), varNames );

    values = thisEvaluation.getResultArray(fldNames);
    varNames(1) = "Int.";

    % create the box plot
    ax = nexttile(layout);

    if mod(i,2)==0
        % continuous plot - short scale
        makeBoxPlot( ax, values, varNames, colours(2,:), titles(i) );
        ylim( ax, [-0.75 0.75] );

    else
        % discrete - one plot with wide scale, one with short scale
        makeBoxPlot( ax, values, varNames, colours(1,:), ...
                     strcat( titles(i), " - Widescale") );
        ylim( ax, [-15 15] );

        % generate another
        ax = nexttile(layout);
        makeBoxPlot( ax, values, varNames, colours(1,:), ...
                     strcat( titles(i), " - Narrow scale") );
        ylim( ax, [-0.75 0.75] );

    end

end

saveGraphicsObject( fig1, path, 'LinearBetaSpread' );

%% generate an average correlation matrix combined discrete and continuous
titles = ["Smartphone", "Delsys"];

fig2 = figure;
fontname(fig2, 'Arial');
fig2.Position(3) = 1200;
fig2.Position(4) = 550;
layout = tiledlayout(1, 2, 'TileSpacing', 'loose');

for i = 1:2

    % extract all the encoded features for discrete and continuous
    discreteModels = myInvestigation.Evaluations{(i-1)*2+1}.Models;
    ZDiscreteAll = cellfun(@(mdl) table2array(mdl.Model.Variables(:,1:end-1)), ...
        discreteModels, UniformOutput = false);

    continuousModels = myInvestigation.Evaluations{i*2}.Models;
    ZContinuousAll = cellfun(@(mdl) table2array(mdl.Model.Variables(:,1:end-1)), ...
        continuousModels, UniformOutput = false);
    
    % calculate the correlation matrix for each fold
    corrMatrices = arrayfun(@(j) corr([ZDiscreteAll{j} ZContinuousAll{j}]), ...
        1:numel(ZDiscreteAll), 'UniformOutput', false);
    
    % convert the cell array of correlation matrices to a 3D array
    corrMatrices = cat(3, corrMatrices{:});
    
    % calculate the mean correlation matrix across all folds
    meanCorrMatrix = mean(corrMatrices, 3);
    
    % blank the top right triangle and the diagonal
    numFeatures = size(meanCorrMatrix, 1);
    mask = triu(true(numFeatures), 0);
    meanCorrMatrix(mask) = NaN;
    
    % plot the heat map of the mean correlation matrix
    ax = nexttile(layout);
    imagesc(ax, meanCorrMatrix, ...
            AlphaData = ~isnan(meanCorrMatrix));
    colormap(ax, rdbuColorMap); 
    colorbar(ax);   
    clim(ax, [-1, 1]);
    ax.PlotBoxAspectRatio = [1, 1, 1];
    
    % set labels
    combinedLabels = [discreteModels{1}.PredictorNames continuousModels{1}.PredictorNames];
    xticks(ax, 1:numFeatures);
    xticklabels(ax, combinedLabels);
    yticks(ax, 1:numFeatures);
    yticklabels(ax, combinedLabels);

    title(ax, titles(i));
end

saveGraphicsObject( fig2, path, 'FeatureCorrelations' );


function makeBoxPlot( ax, v, grps, c, heading )

    xrng = [0 length(grps)+1];
    plot( ax, xrng, [0 0], 'k-' );

    hold( ax, 'on' );

    boxplot( ax, v, ...
            PlotStyle='compact', ...
            BoxStyle='filled', ...
            Labels = grps, ...
            Colors = c );

    xlim( ax, xrng );
    ax.XAxis.TickValues = 1:xrng(2)-1;
    ylabel( ax, 'Standardised Beta' );

    title( ax, heading );

end

