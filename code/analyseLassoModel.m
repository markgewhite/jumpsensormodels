% test the model with a grid search

clear;

path = fileparts( which('code/analyseLassoModel.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = 20;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 2;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = false;

parameters = [ "model.args.EncodingType", ...
               "model.args.NumPredictors", ...
               "data.class", ...
               "model.args.ModelType" ];
values = {{'Discrete', 'Continuous'}, ...
          1:15, ...
          {@SmartphoneDataset, @DelsysDataset}, ....
          {'Linear', 'Lasso', 'LassoSelect', 'SVM', 'XGBoost'}};

myInvestigation = ParallelInvestigation( 'Predictors', path, parameters, values, setup );

myInvestigation.run;
