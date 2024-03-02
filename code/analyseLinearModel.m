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
setup.eval.KFoldRepeats = 25;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = true;

parameters = [ "model.args.EncodingType", ...
               "data.class" ];
values = {{'Discrete', 'Continuous'}, ...
          {@SmartphoneDataset, @DelsysDataset}};

metrics = ["StdRMSE", "FStat", "RSquared", "Shrinkage", "CookMeanOutlierProp", "VIFHighProp"];

myInvestigation = Investigation( 'LinearModel', path, parameters, values, setup );

myInvestigation.run;

results = myInvestigation.getMultiVarTable( metrics );

exportTableToLatex( results, fullfile(path, 'LinearModelStats') );

