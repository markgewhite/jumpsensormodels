% test the model with a grid search

clear;

path = fileparts( which('code/analyseFeatureSelection.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear'; % doesn't matter which
setup.model.args.EncodingType = 'Combined';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'XCMeanConv';

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 50;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = true;
setup.eval.RetainAllParameters = true;

predictorCount = 5:5:20;

parameters = [ "data.class", ...
               "model.args.NumPredictors" ];
values = {{@SmartphoneDataset, @AccelerometerDataset}, ...
          predictorCount};

myInvestigation = Investigation( 'FeatureSelection', path, parameters, values, setup );

myInvestigation.run;

%% create histograms of predictor selection frequency

titles = {'Smartphone', 'Accelerometer'};
selectedPredictorsCounts = [1 2 3];
numHistograms = length(selectedPredictorsCounts);

fig1 = figure;
fontname( fig1, 'Arial' );
fig1.Position(3) = 1400;
fig1.Position(4) = 600;
layout = tiledlayout(fig1, 2, numHistograms, TileSpacing='compact' );
colours = lines(2);

predictorNames = myInvestigation.Evaluations{1}.Models{1}.EncodingStrategy.Names;
numPredictors = length(predictorNames);
isContinuous = contains( predictorNames, ["VMD", "FPC"] );
numContinuous = sum(isContinuous);

for i = 1:2 % dataset
    for j = selectedPredictorsCounts

        thisEvaluation = myInvestigation.Evaluations{i,j};
    
        % count the number of times each predictor has been included
        selections = cellfun( @(mdl) mdl.PredictorSelection, thisEvaluation.Models, ...
                              UniformOutput=false);
        selections = cat(2, selections{:});
        counts = sum(selections, 2);
        prob = counts/thisEvaluation.NumModels;
      
        % create the bar chart
        ax = nexttile(layout);
    
        discreteData = prob;
        discreteData(isContinuous) = 0;
        continuousData = prob;
        continuousData(~isContinuous) = 0;

        chart1 = bar(ax, predictorNames, discreteData, FaceColor='flat');
        hold(ax, 'on');
        chart2 = bar(ax, predictorNames, continuousData, FaceColor='flat');
        hold(ax, 'off');

        chart1.CData(:, :) = repmat(colours(1,:), numPredictors, 1);
        chart2.CData(:, :) = repmat(colours(2,:), numPredictors, 1);

        ylim(ax, [0, 1]);
        if i==2
            xlabel(ax, 'Available Features');
        end
        if j==selectedPredictorsCounts(1)
            ylabel(ax, 'Selection Probability');
        end

        title(ax, [titles{i} ' - ' ...
                   num2str(predictorCount(j)) ...
                   ' Features Chosen']);

        if i==1 && j==selectedPredictorsCounts(1)
            legend([chart1(1), chart2(1)], {'Discrete', 'Continuous'}, Location='northeast');
        end
    
    end
end

saveGraphicsObject( fig1, path, 'SelectionHistograms' );


%% create plots of mean absolute beta coefficients

fig2 = figure;
fontname( fig2, 'Arial' );
fig2.Position(3) = 1400;
fig2.Position(4) = 600;
layout = tiledlayout(fig2, 2, numHistograms, TileSpacing='loose' );

for i = 1:2 % dataset
    for j = selectedPredictorsCounts

        thisEvaluation = myInvestigation.Evaluations{i,j};
    
        % initialize an array to store the mean absolute beta coefficients
        meanAbsBeta = zeros(numPredictors, 1);

        for k = 1:thisEvaluation.NumModels
            % get the model's variable names and coefficients
            modelVarNames = thisEvaluation.Models{k}.Model.VariableNames;
            modelCoefficients = thisEvaluation.Models{k}.Model.Coefficients;

            % extract the absolute beta coefficients
            absBeta = abs(modelCoefficients.Estimate);

            % map the coefficients to the full predictor list
            [~, ia, ib] = intersect(predictorNames, modelVarNames);
            fullBeta = zeros(numPredictors, 1);
            fullBeta(ia) = absBeta(ib);

            % accumulate the absolute beta coefficients
            meanAbsBeta = meanAbsBeta + fullBeta;
        end

        % calculate the mean absolute beta coefficients
        meanAbsBeta = meanAbsBeta / thisEvaluation.NumModels;
      
        % create the bar chart
        ax = nexttile(layout);
    
        discreteData = meanAbsBeta;
        discreteData(isContinuous) = 0;
        continuousData = meanAbsBeta;
        continuousData(~isContinuous) = 0;

        chart1 = bar(ax, predictorNames, discreteData, FaceColor='flat');
        hold(ax, 'on');
        chart2 = bar(ax, predictorNames, continuousData, FaceColor='flat');
        hold(ax, 'off');

        chart1.CData(:, :) = repmat(colours(1,:), numPredictors, 1);
        chart2.CData(:, :) = repmat(colours(2,:), numPredictors, 1);

        ylim(ax, [0, 0.75]);
        if i==2
            xlabel(ax, 'Available Features');
        end
        if j==selectedPredictorsCounts(1)
            ylabel(ax, 'Mean Absolute Beta Coefficient');
        end

        title(ax, [titles{i} ' - ' ...
                   num2str(predictorCount(j)) ...
                   ' Features Chosen']);

        if i==1 && j==selectedPredictorsCounts(1)
            legend([chart1(1), chart2(1)], {'Discrete', 'Continuous'}, Location='northeast');
        end
    
    end
end