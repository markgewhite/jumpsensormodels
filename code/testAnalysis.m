% test the model with a grid search

clear;

testIndices = 1;

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
            setup.model.args.ModelType = 'Linear';
            setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'XCMeanConv';

            setup.eval.KFoldRepeats = 1;

            parameters = [ "data.args.Proportion", ...
                           "data.class", ...
                           "model.args.EncodingType", ...
                           "data.args.Instance" ];
            values = {0.2:0.2:1.0, ...
                      {@SmartphoneDataset, @DelsysDataset}, ...
                      {'Continuous', 'Discrete'}, ...
                      1:3};
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;

            myInvestigation{i}.aggregateResults( 4 );
                
        case 2
            name = 'ContAlignTest1';
            setup.model.args.EncodingType = 'Continuous';
            setup.model.args.ModelType = 'Linear';

            setup.eval.KFoldRepeats = 25;

            parameters = [ "model.args.ContinuousEncodingArgs.NumComponents", ...
                           "data.class", ...
                           "model.args.ContinuousEncodingArgs.AlignmentMethod"];
            values = { 2:2:16, ...
                       {@SmartphoneDataset, @DelsysDataset}, ...
                       {'XCRandom', 'XCMeanConv', 'LMTakeoff', 'LMLanding'} };
            
            myInvestigation{i} = Investigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;

            resultsTrnMeanTbl = array2table( reshape(myInvestigation{i}.TrainingResults.Mean.RMSE, 8, []) );
            resultsTrnSDTbl = array2table( reshape(myInvestigation{i}.TrainingResults.SD.RMSE, 8, [] ));
            fullTrnTbl = tableOfStrings( resultsTrnMeanTbl, resultsTrnSDTbl, format = '%1.2f' );

            resultsValMeanTbl = array2table( reshape(myInvestigation{i}.ValidationResults.Mean.RMSE, 8, []) );
            resultsValSDTbl = array2table( reshape(myInvestigation{i}.ValidationResults.SD.RMSE, 8, [] ));
            fullValTbl = tableOfStrings( resultsValMeanTbl, resultsValSDTbl, format = '%1.2f' );

        case 3
            name = 'ModelTest1';
            setup.model.args.EncodingType = 'Continuous';
            setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'XCMeanConv';

            setup.eval.KFoldRepeats = 25;

            parameters = [ "model.args.ContinuousEncodingArgs.NumComponents", ...
                           "data.class", ...
                           "model.args.ModelType"];
            values = { 2:2:16, ...
                       {@SmartphoneDataset, @DelsysDataset}, ...
                       {'Linear', 'LinearReg', 'SVM', 'XGBoost'} };
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;

    end


end