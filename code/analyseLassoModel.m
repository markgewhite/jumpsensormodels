% test the model with a grid search

clear;

path = fileparts( which('code/analyseLassoModel.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = 26;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 50;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = false;

parameters = [ "model.args.EncodingType", ...
               "model.args.NumPredictors", ...
               "data.class", ...
               "model.args.ModelType" ];
values = {{'Discrete', 'Continuous'}, ...
          2:2:26, ...
          {@SmartphoneDataset, @DelsysDataset}, ....
          {'Linear', 'Lasso', 'SVM', 'XGBoost'}};

myInvestigation = ParallelInvestigation( 'Predictors', path, parameters, values, setup );

myInvestigation.run;

%% plot RMSE as a function of the number of predictors

figTrn = plotModelPerformance( myInvestigation, ...
                              'Number of Features', ...
                              'StdRMSE', 'Standardised RMSE', ...
                              'Training', [0 1.25], 0.25 );
leftSuperTitle( figTrn, 'Training Set', 'a');

figVal = plotModelPerformance( myInvestigation, ...
                              'Number of Features', ...
                              'StdRMSE', 'Standardised RMSE', ...
                              'Validation', [0.25 1.5], 0.25 );
leftSuperTitle( figVal, 'Validation Set', 'b');


saveGraphicsObject( figTrn, path, 'ModelTypeTraining' );
saveGraphicsObject( figVal, path, 'ModelTypeValidation' );