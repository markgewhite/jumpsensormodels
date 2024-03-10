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