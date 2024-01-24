% test the model with a grid search

clear;

testIndices = 4;
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
            setup.model.args.ModelType = 'Linear';

            setup.eval.KFoldRepeats = 1;

            parameters = [ "model.args.ContinuousEncodingArgs.NumComponents", ...
                           "data.class", ...
                           "model.args.ContinuousEncodingArgs.AlignmentMethod"];
            values = { 2:2:16, ...
                       {@SmartphoneDataset, @DelsysDataset}, ...
                       {'XCRandom', 'XCMeanConv', 'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual'} };
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup, catchErrors );
            
            myInvestigation{i}.run;

        case 3
            name = 'ModelTest2';
            setup.model.args.EncodingType = 'Continuous';
            setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'XCMeanConv';

            setup.eval.KFoldRepeats = 25;

            parameters = [ "model.args.ContinuousEncodingArgs.NumComponents", ...
                           "data.class", ...
                           "model.args.ModelType"];
            values = { 2:2:16, ...
                       {@SmartphoneDataset, @DelsysDataset}, ...
                       {'Linear', 'LinearReg', 'SVM', 'XGBoost'} };
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup, catchErrors );
            
            myInvestigation{i}.run;

        case 4
            name = 'VerificationTest1';
            setup.model.args.ModelType = 'Linear';
            setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoffActual';
            setup.model.args.DiscreteEncodingArgs.LegacyCode = false;
            setup.model.args.DiscreteEncodingArgs.Filtering = true;
            setup.model.args.DiscreteEncodingArgs.FilterForStart = true;
            
            setup.eval.KFoldRepeats = 25;

            parameters = [ "data.class", ...
                           "model.args.EncodingType" ];
            values = {{@DelsysDataset}, ...
                      {'Discrete', 'Continuous'}};
            
            myInvestigation{i} = ParallelInvestigation( name, path, parameters, values, setup );
            
            myInvestigation{i}.run;

    end


end