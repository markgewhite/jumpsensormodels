% test the model with a grid search

clear;

testIndices = 2;

% -- data setup --
setup.data.class = @DelsysDataset;

% -- model setup --
setup.model.class = @JumpModel;

% --- evaluation setup ---
setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 5;
setup.eval.InParallel = false;

% results location
path = fileparts( which('code/testAnalysis.m') );
path = [path '/../results/'];

myInvestigation = cell( max(testIndices), 1 );
for i = testIndices

    % reset arguments
    if isfield( setup.model, 'args' )
        setup.model = rmfield( setup.model, 'args' );
    end
    if isfield( setup.data, 'args' )
        setup.data = rmfield( setup.data, 'args' );
    end

    switch i
    
        case 1
            name = 'SamplingTest1';
            setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
            setup.eval.KFoldRepeats = 5;

            parameters = [ "data.class", ...
                           "model.args.EncodingType", ...
                           "data.args.Instance" ];
            values = {{@SmartphoneDataset, @DelsysDataset}, ...
                      {'Continuous', 'Discrete'}, ...
                      1:5};
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;
            
            aggrTrainRMSE = mean( myInvestigation{i}.TrainingResults.Mean.RMSE, 4 );
            aggrValRMSE = mean( myInvestigation{i}.ValidationResults.Mean.RMSE, 4 );
    
        case 2
            name = 'ContAlignTest1';
            setup.model.args.EncodingType = 'Continuous';
            setup.model.args.ModelType = 'Linear2';

            setup.eval.KFoldRepeats = 20;

            parameters = [ "model.args.ContinuousEncodingArgs.NumComponents", ...
                           "data.class", ...
                           "model.args.ContinuousEncodingArgs.AlignmentMethod"];
            values = { 2:2:16, ...
                       {@SmartphoneDataset, @DelsysDataset}, ...
                       {'XCRandom', 'XCMeanConv', 'LMTakeoff', 'LMLanding' } };
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;

        case 3
            name = 'GenericTest1';
            setup.model.args.EncodingType = 'Continuous';
            setup.eval.KFoldRepeats = 50;
            setup.data.class = @TestDataset;

            parameters = "model.args.ContinuousEncodingArgs.NumComponents";
            values = {1:1:12};
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;

            aggrTrainRMSE = mean( myInvestigation{i}.TrainingResults.Mean.RMSE, 2 );
            aggrValRMSE = mean( myInvestigation{i}.ValidationResults.Mean.RMSE, 2 );

        case 4
            name = 'Synthetic1';
            zscore = 0.5;
            setup.data.class = @SyntheticDataset;
            setup.data.args.ClassSizes = [200 200];
            setup.data.args.NumTemplatePts = 17;
            setup.data.args.Scaling = [8 4 2 1];
            setup.data.args.Mu = 0.25*[4 3 2 1];
            setup.data.args.Sigma = zscore*setup.data.args.Mu;
            setup.data.args.Eta = 0.1;
            setup.data.args.Tau = 0.2;    
            setup.data.args.WarpLevel = 1;
            setup.data.args.SharedLevel = 3;
    
            setup.model.args.EncodingType = 'Continuous';
            setup.eval.KFoldRepeats = 50;

            parameters = "model.args.ContinuousEncodingArgs.NumComponents";
            values = {1:10};
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;

            aggrTrainRMSE = mean( myInvestigation{i}.TrainingResults.Mean.RMSE, 2 );
            aggrValRMSE = mean( myInvestigation{i}.ValidationResults.Mean.RMSE, 2 );

    end

end