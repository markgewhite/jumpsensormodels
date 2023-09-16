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
setup.eval.args.InParallel = true;

% first investigation
name = 'test';
path = fileparts( which('code/runAnalysis.m') );
path = [path '/../results/'];

parameters = [ "model.args.EncodingComponents", ...
               ];
values = {[2 3 4], ...
          };


myInvestigation = Investigation( name, path, parameters, values, setup );

myInvestigation.run;



