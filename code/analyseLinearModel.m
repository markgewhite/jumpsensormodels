% test the model with a grid search

clear;

path = fileparts( which('code/testAnalysis.m') );
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

parameters = [ "data.class", ...
               "model.args.EncodingType" ];
values = {{@SmartphoneDataset, @DelsysDataset}, ...
          {'Discrete', 'Continuous'}};

myInvestigation = ParallelInvestigation( 'LinearModel', path, parameters, values, setup );

myInvestigation.run;