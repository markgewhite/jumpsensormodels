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
    
            parameters = [ "data.args.Proportion", ...
                           "model.args.EncodingType", ...
                           "data.args.Instance" ];
            values = {0.2:0.2:1.0, ...
                      {'Discrete', 'Continuous'}, ...
                      1:2 };
            
            myInvestigation{i} = Investigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;
            
            aggrTrainRMSE = mean( myInvestigation{i}.TrainingResults.Mean.RMSE, 3 );
            aggrValRMSE = mean( myInvestigation{i}.ValidationResults.Mean.RMSE, 3 );
    
        case 2
            name = 'ContAlignTest';
            setup.model.args.EncodingType = 'Continuous';
    
            parameters = [ "model.args.ContinuousEncodingArgs.NumComponents", ...
                           "model.args.ContinuousEncodingArgs.AlignmentMethod"];
            values = { 1:5, ...
                       {'XCRandom', 'XCMeanConv', 'LMTakeoff', 'LMLanding' } };
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;
    
    end

end