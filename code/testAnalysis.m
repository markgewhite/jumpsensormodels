% test the model with a grid search

clear;

testIndices = 1:2;

% -- data setup --
setup.data.class = @DelsysDataset;

% -- model setup --
setup.model.class = @JumpModel;

% --- evaluation setup ---
setup.eval.args.CVType = 'KFold';
setup.eval.args.KFolds = 2;
setup.eval.args.KFoldRepeats = 5;
setup.eval.args.InParallel = false;

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
            name = 'SamplingTest';
            setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
            setup.eval.args.KFoldRepeats = 5;

            parameters = [ "data.args.Proportion", ...
                           "data.class", ...
                           "model.args.EncodingType", ...
                           "data.args.Instance" ];
            values = {0.2:0.2:1.0, ...
                      {@SmartphoneDataset, @DelsysDataset}, ...
                      {'Continuous', 'Discrete'}, ...
                      1:20 };
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;
            
            aggrTrainRMSE = mean( myInvestigation{i}.TrainingResults.Mean.RMSE, 4 );
            aggrValRMSE = mean( myInvestigation{i}.ValidationResults.Mean.RMSE, 4 );
    
        case 2
            name = 'ContAlignTest';
            setup.model.args.EncodingType = 'Continuous';
            setup.eval.args.KFoldRepeats = 20;

            parameters = [ "model.args.ContinuousEncodingArgs.NumComponents", ...
                           "data.class", ...
                           "model.args.ContinuousEncodingArgs.AlignmentMethod"];
            values = { 1:15, ...
                       {@SmartphoneDataset, @DelsysDataset}, ...
                       {'XCRandom', 'XCMeanConv', 'LMTakeoff', 'LMLanding' } };
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;
    
    end

end