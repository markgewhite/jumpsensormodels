% test the model with a grid search

clear;

testIndices = 7;
catchErrors = true;

% -- data setup --
setup.data.class = @DelsysDataset;

% -- model setup --
setup.model.class = @JumpModel;

% --- evaluation setup ---
setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 5;
setup.eval.RandomSeed = 1234;
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
            name = 'SamplingTest2';
            setup.model.args.ModelType = 'Linear';
            setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'XCMeanConv';
            setup.model.args.ContinuousEncodingArgs.NumComponents = 10;

            setup.eval.KFoldRepeats = 5;

            parameters = [ "data.args.Proportion", ...
                           "data.class", ...
                           "model.args.EncodingType", ...
                           "data.args.Instance" ];
            values = {0.2:0.2:1.0, ...
                      {@SmartphoneDataset, @DelsysDataset}, ...
                      {'Continuous', 'Discrete'}, ...
                      1:10};
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup, catchErrors );
            
            myInvestigation{i}.run;

            myInvestigation{i}.aggregateResults( 4 );
                
        case 2
            name = 'ContAlignTest3';
            setup.model.args.EncodingType = 'Continuous';
            setup.model.args.ModelType = 'Lasso';

            setup.eval.KFoldRepeats = 25;

            parameters = [ "data.class", ...
                           "model.args.ContinuousEncodingArgs.AlignmentMethod" ];
            values = { {@SmartphoneDataset, @DelsysDataset}, ...
                       {'XCRandom', 'XCMeanConv', 'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual'} };
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup, catchErrors );
            
            myInvestigation{i}.run;

        case 3
            name = 'ModelTest3';
            setup.model.args.EncodingType = 'Continuous';
            setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';

            setup.eval.KFoldRepeats = 25;

            parameters = [ "data.class", ...
                           "model.args.EncodingType", ...
                           "model.args.ModelType"];
            values = { {@SmartphoneDataset, @DelsysDataset}, ...
                       {'Discrete', 'Continuous'}, ...
                       {'Linear', 'Ridge', 'Lasso', 'SVM', 'XGBoost'} };
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup, catchErrors );
            
            myInvestigation{i}.run;

        case 4
            name = 'VerificationTest1';
            setup.model.args.ModelType = 'XGBoost';
            setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoffActual';
            
            setup.eval.KFoldRepeats = 1;

            parameters = [ "data.class", ...
                           "model.args.EncodingType" ];
            values = {{@SmartphoneDataset, @DelsysDataset}, ...
                      {'Discrete', 'Continuous'}};
            
            myInvestigation{i} = Investigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;

        case 5
            name = 'FilteringTest1';
            setup.model.args.ModelType = 'Linear';
            setup.model.args.EncodingType = 'Discrete';
            
            setup.eval.KFoldRepeats = 25;

            parameters = [ "data.class", ...
                           "model.args.DiscreteEncodingArgs.FilterCutoff" ];
            values = {{@SmartphoneDataset, @DelsysDataset}, ...
                      5:5:50};
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;
           
        case 6
            name = 'OnsetTest1';
            setup.model.args.ModelType = 'Linear';
            setup.model.args.EncodingType = 'Discrete';
            
            setup.eval.KFoldRepeats = 25;

            parameters = [ "data.class", ...
                           "model.args.DiscreteEncodingArgs.DetectionMethod", ...
                           "model.args.DiscreteEncodingArgs.ReturnVar" ];
            values = {{@SmartphoneDataset, @DelsysDataset}, ...
                      {'Absolute', 'SDMultiple'}, ...
                      {'t0', 'tUB', 'tBP', 'tTO'}};
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;
           
        case 7
            name = 'OnsetTest2';
            setup.model.args.ModelType = 'Linear';
            setup.model.args.EncodingType = 'Discrete';
            setup.model.args.DiscreteEncodingArgs.ReturnVar = 't0';
            setup.model.args.DiscreteEncodingArgs.DetectionMethod = 'SDMultiple';
            setup.eval.KFoldRepeats = 2;

            parameters = [ "model.args.DiscreteEncodingArgs.AccDetectionThreshold", ...
                           "model.args.DiscreteEncodingArgs.WindowAdjustment", ...
                           "data.class", ...
                           "model.args.DiscreteEncodingArgs.WindowMethod" ];
            values = {0.25:0.25:2.00, ...
                      0.50:0.25:2.00, ...
                      {@SmartphoneDataset, @DelsysDataset}, ...
                      {'Fixed', 'Dynamic'}};
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup, catchErrors );
            
            myInvestigation{i}.run;


    end


end