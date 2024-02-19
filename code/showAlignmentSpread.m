% Compute alignment spreads of the methods available for FPCA
clear

path = fileparts( which('code/showAlignmentSpread.m') );
path = [path '/../results/'];

datasets = { @SmartphoneDataset, @DelsysDataset };
methods = {'XCRandom', 'XCMeanConv', 'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual'};

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 25;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = true;

parameters = [ "data.class", ...
               "model.args.ContinuousEncodingArgs.AlignmentMethod" ];
values = { datasets, methods };

thisInvestigation = Investigation( 'AlignmentSpread', path, ...
                                    parameters, values, setup, true );
thisInvestigation.run;


%% Compute the alignment spreads

% Initialize cell arrays to store data and groups for each dataset
numMethods = [5 6];
offsetSpreads = cell(2, 1); 
groups = cell(2, 1);
names = cell(2, 1); 

for i = 1:2
    offsetSpreads{i} = [];
    groups{i} = [];
    names{i} = thisInvestigation.Evaluations{i,1}.TrainingDataset.Name;

    for j = 1:numMethods(i)

        thisEvaluation = thisInvestigation.Evaluations{i,j};
        if isempty( thisEvaluation )
            continue
        end

        % extract the alignment shifts in terms of time indices
        offsetSDs = cellfun(@(mdl) std(mdl.EncodingStrategy.FittedAlignmentIdx), ...
                            thisEvaluation.Models);
        % convert to seconds
        offsetSDs = double(offsetSDs)/thisEvaluation.TrainingDataset.SampleFreq;

        % compile arrays for box plot
        offsetSpreads{i} = [offsetSpreads{i}; offsetSDs(:)];
        groups{i} = [groups{i}; repmat( methods(j), length(offsetSDs), 1)];

    end
end

% Plotting with refined approach
fig = figure;
fig.Position(3) = 2*300 + 50;
fig.Position(4) = 300;
layout = tiledlayout( 1, 2, TileSpacing='loose' );
ax = gobjects( 2, 1 );
for i = 1:2
    ax(i) = nexttile( layout );
    boxplot( offsetSpreads{i}, groups{i}, ...
             GroupOrder = methods(1:numMethods(i)), ...
             Notch = 'on', ...
             Symbol = 'o' );

    title( ax(i), names{i} );
    xlabel( ax(i), 'Alignment Methods');
    ylabel( ax(i), 'Offset SD Spread (s)');
end

% determine the global y-axis limits
globalYMin = min(cellfun(@(x) min(x), offsetSpreads));
globalYMax = max(cellfun(@(x) max(x), offsetSpreads));

% calculate a suitable range and tick marks for the y-axis
tickInterval = 0.2; 
yTicks = floor(globalYMin):tickInterval:ceil(globalYMax); 

% Adjust each subplot's y-axis
for i = 1:2
    ax(i).YTick = yTicks;
    ytickformat( ax(i), '%.1f' );
end
