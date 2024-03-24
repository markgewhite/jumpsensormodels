% test the model with a grid search

clear all;

path = fileparts( which('code/analyseSampleSize.m') );
path = [path '/../results/'];

catchErrors = true;

setup.data = struct();

setup.model.class = @JumpModel;
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = 18;
setup.model.args.CompressModel = true;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 1; % 10
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = false;
setup.eval.DiscardDatasets = true;

parameters = [ "model.args.EncodingType", ...
               "data.args.CappedObs", ...
               "data.class", ...
               "model.args.ModelType", ...
               "data.args.Instance" ];
cappedObs = floor(logspace(1.4, 2.54, 10));
values = {{'Discrete', 'Continuous'}, ...
          cappedObs, ...
          {@SmartphoneDataset, @AccelerometerDataset}, ....
          {'Linear', 'Lasso', 'SVM', 'XGBoost'}, ...
          1:1}; % 1:20

myInvestigation = ParallelInvestigation( 'SampleSize', path, parameters, values, setup, catchErrors );

myInvestigation.run;
myInvestigation.aggregateResults(5);

%% plot RMSE as a function of the number of predictors

figTrn = plotModelPerformance( myInvestigation, ...
                              'Sample Size', ...
                              'StdRMSE', 'Standardised RMSE', ...
                              Set = 'Training', ...
                              Percentiles = true, ...
                              YLimits = [0 1], ...
                              YTickInterval = 0.25, ...
                              FitType = 'power1' );
leftSuperTitle( figTrn, 'Training Set', 'a');

figVal = plotModelPerformance( myInvestigation, ...
                              'Sample Size', ...
                              'StdRMSE', 'Standardised RMSE', ...
                              Set = 'Validation', ...
                              Percentiles = true, ...
                              YLimits = [0 2.5], ...
                              YTickInterval = 0.25, ...
                              FitType = 'power1' );
leftSuperTitle( figVal, 'Validation Set', 'b');


saveGraphicsObject( figTrn, path, 'SampleTraining' );
saveGraphicsObject( figVal, path, 'SampleValidation' );