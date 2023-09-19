% test the model with a grid search

% -- data setup --
setup.data.class = @SmartphoneDataset;

% -- model setup --
setup.model.class = @JumpModel;
setup.model.args.EncodingType = 'Discrete';

% --- evaluation setup ---
setup.eval.args.CVType = 'KFold';
setup.eval.args.KFolds = 2;
setup.eval.args.KFoldRepeats = 1;
setup.eval.args.InParallel = false;

% first investigation
name = 'test';
path = fileparts( which('code/testAnalysis.m') );
path = [path '/../results/'];

parameters = [ "model.args.EncodingType", ...
               "data.args.Proportion", ...
               "data.args.Instance" ];
values = {{'Discrete', 'Continuous'}, ...
          0.2:0.2:1.0, ...
          1:20 };

myInvestigation = ParallelInvestigation( name, path, parameters, values, setup );

myInvestigation.run;

aggrTrainRMSE = mean( myInvestigation.TrainingResults.Mean.RMSE, 3 );
aggrValRMSE = mean( myInvestigation.ValidationResults.Mean.RMSE, 3 );

