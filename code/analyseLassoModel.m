% test the model with a grid search

clear;

path = fileparts( which('code/analyseLassoModel.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'LassoSelect';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = 20;

setup.model.args.StoreIndividualBetas = true;
setup.model.args.StoreIndividualVIFs = true;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 1;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = true;
setup.eval.RetainAllParameters = true;

parameters = [ "model.args.EncodingType", ...
               "model.args.NumPredictors", ...
               "data.class" ];
values = {{'Discrete', 'Continuous'}, ...
          1:15, ...
          {@SmartphoneDataset, @DelsysDataset}};

myInvestigation = Investigation( 'LassoModel', path, parameters, values, setup );

myInvestigation.run;
