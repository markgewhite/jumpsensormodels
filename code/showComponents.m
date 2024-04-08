% Show the functional principal components

clear

method = {'LMTakeoffPeak', 'XCMeanConv'};
tRng = {[3 6; 2 5], [1 4; 2 5]};
id = {'ac', 'bd'};

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.NumComponents = 3;

% LMTakeoffPeak components
evalAndPlot( setup, method{1}, tRng{1}, id{1} );

% XCMeanConv components
evalAndPlot( setup, method{2}, tRng{2}, id{2} );


function evalAndPlot( setup, method, tRng, id )

    path = fileparts( which('code/showComponents.m') );
    path = [path '/../results/'];

    eval.CVType = 'KFold';
    eval.KFolds = 2;
    eval.KFoldRepeats = 25;
    eval.RandomSeed = 1234;
    eval.InParallel = true;
    args = namedargs2cell( eval );

    setup.model.args.ContinuousEncodingArgs.AlignmentMethod = method;
    numComp = setup.model.args.ContinuousEncodingArgs.NumComponents;

    % Smartphone evaluation
    setup.data.class = @SmartphoneDataset;
    contEvalSmart = ModelEvaluation( 'ContVariationSmart', path, setup, args{:} );
    
    % Accelerometer evaluation
    setup.data.class = @AccelerometerDataset;
    contEvalAccel = ModelEvaluation( 'ContVariationAccelerometer', path, setup, args{:} );

    % plot the spread in X across the folds
    titleSuffix = ['(Continuous: Alignment = '  ...
                   setup.model.args.ContinuousEncodingArgs.AlignmentMethod ')'];
    
    figFPCSmart = plotFPCSpread( contEvalSmart, numComp, ...
                                 ['Smartphone ' titleSuffix], id(1), tRng(1,:) );
    figFPCAccelerometer = plotFPCSpread( contEvalAccel, numComp, ...
                                  ['Accelerometer ' titleSuffix], id(2), tRng(2,:) );

    % save
    saveGraphicsObject( figFPCSmart, path, ['FPCSmart-' method] );
    saveGraphicsObject( figFPCAccelerometer, path, ['FPCAccel-' method] );

end








