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
                                    parameters, values, setup );
thisInvestigation.run;


%% Compute the alignment spreads
numMethods = numel(methods);
spreadMean = zeros( 2, numMethods );
spreadSE = zeros( 2, numMethods );
spreadP05 = zeros( 2, numMethods );
spreadP95 = zeros( 2, numMethods );
alignments = cell( 2, numMethods );

for i = 1:2
    for j = 1:numMethods

        offsetSDs = cellfun( @(mdl) std(mdl.EncodingStrategy.FittedAlignmentIdx), ...
                             thisInvestigation.Evaluations{i,j}.Models );
        alignments{i,j} = double(offsetSDs)/thisInvestigation.Evaluations{i,j}.TrainingDataset.SampleFreq;

        spreadMean(i,j) = mean( offsetSDs );
        spreadSE(i,j) = std( offsetSDs );
        spreadP05(i,j) = prctile( offsetSDs, 5 );
        spreadP95(i,j) = prctile( offsetSDs, 95 );

    end
end

bar( spreadMean )
boxplot( alignments )
