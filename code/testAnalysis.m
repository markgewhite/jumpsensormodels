% test the model with a grid search

testID = 2;

% -- data setup --
setup.data.class = @DelsysDataset;

% -- model setup --
setup.model.class = @JumpModel;
setup.model.args.EncodingType = 'Continuous';
setup.model.args.ContinuousEncodingArgs.ShowConvergence = true;

% --- evaluation setup ---
setup.eval.args.CVType = 'KFold';
setup.eval.args.KFolds = 2;
setup.eval.args.KFoldRepeats = 5;
setup.eval.args.InParallel = false;

% first investigation
name = 'test2';
path = fileparts( which('code/testAnalysis.m') );
path = [path '/../results/'];

switch testID

    case 1
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

    case 2
        parameters = [ "model.args.ContinuousEncodingArgs.NumComponents", ...
                       "data.args.Instance" ];
        values = { 1:15, 1:20 };
        
        myInvestigation = Investigation( name, path, parameters, values, setup );
        
        myInvestigation.run;
        
        aggrTrainRMSE = mean( myInvestigation.TrainingResults.Mean.RMSE, 2 );
        aggrValRMSE = mean( myInvestigation.ValidationResults.Mean.RMSE, 2 );

end