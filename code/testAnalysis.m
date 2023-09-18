% test the model with a grid search

% -- data setup --
setup.data.class = @SmartphoneDataset;

% -- model setup --
setup.model.class = @JumpModel;
setup.model.args.EncodingType = 'Discrete';

% --- evaluation setup ---
setup.eval.args.CVType = 'KFold';
setup.eval.args.KFolds = 2;
setup.eval.args.KFoldRepeats = 5;
setup.eval.args.InParallel = false;

% first investigation
name = 'test';
path = fileparts( which('code/runAnalysis.m') );
path = [path '/../results/'];

parameters = [ "model.args.EncodingType", ...
               "data.args.Proportion" ];
values = {{'Discrete', 'Continuous'}, ...
          0.1:0.1:1.0 };

myInvestigation = ParallelInvestigation( name, path, parameters, values, setup );

myInvestigation.run;



