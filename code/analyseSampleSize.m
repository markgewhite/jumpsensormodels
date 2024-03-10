% test the model with a grid search

clear;

path = fileparts( which('code/analyseSampleSize.m') );
path = [path '/../results/'];

setup.data = struct();

setup.model.class = @JumpModel;
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = 18;
setup.model.args.CompressModel = true;

setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 1;
setup.eval.RandomSeed = 1234;
setup.eval.InParallel = false;

parameters = [ "model.args.EncodingType", ...
               "data.args.Proportion", ...
               "data.class", ...
               "model.args.ModelType", ...
               "data.args.Instance" ];
values = {{'Discrete', 'Continuous'}, ...
          0.2:0.2:1.0, ...
          {@SmartphoneDataset, @DelsysDataset}, ....
          {'Linear', 'Lasso', 'SVM', 'XGBoost'}, ...
          1:2};

myInvestigation = ParallelInvestigation( 'SampleSize', path, parameters, values, setup );

myInvestigation.run;
myInvestigation.aggregateResults(5);

%% plot RMSE as a function of the number of predictors

figTrn = plotModelPerformance( myInvestigation, ...
                              'Sample Proportion', ...
                              'StdRMSE', 'Standardised RMSE', ...
                              'Training', [0 1], 0.25 );
leftSuperTitle( figTrn, 'Training Set', 'a');

figVal = plotModelPerformance( myInvestigation, ...
                              'Sample Proportion', ...
                              'StdRMSE', 'Standardised RMSE', ...
                              'Validation', [0 4], 0.5 );
leftSuperTitle( figVal, 'Validation Set', 'b');


saveGraphicsObject( figTrn, path, 'SampleTraining' );
saveGraphicsObject( figVal, path, 'SampleValidation' );