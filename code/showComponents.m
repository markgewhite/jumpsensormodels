% Show the functional principal components

clear

numComp = 3;

path = fileparts( which('code/showComponents.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = numComp;

eval.CVType = 'KFold';
eval.KFolds = 2;
eval.KFoldRepeats = 25;
eval.RandomSeed = 1234;
eval.InParallel = true;
args = namedargs2cell( eval );

%% Smartphone evaluation
setup.data.class = @SmartphoneDataset;
contEvalSmart = ModelEvaluation( 'ContVariationSmart', path, setup, args{:} );

%% Accelerometer evaluation
setup.data.class = @AccelerometerDataset;
contEvalAccelerometer = ModelEvaluation( 'ContVariationAccelerometer', path, setup, args{:} );

%% plot the spread in X across the folds
titleSuffix = ['(Continuous: Alignment = '  ...
               setup.model.args.ContinuousEncodingArgs.AlignmentMethod ')'];

tRngSmart = [3 6]; %[ 9, 11 ];
tRngAccelerometer = [2 5]; %[ 7, 10 ];

figFPCSmart = plotFPCSpread( contEvalSmart, numComp, ...
                             ['Smartphone ' titleSuffix], tRngSmart );
figFPCAccelerometer = plotFPCSpread( contEvalAccelerometer, numComp, ...
                              ['Accelerometer ' titleSuffix], tRngAccelerometer );

saveGraphicsObject( figFPCSmart, path, 'SmartComponents' );
saveGraphicsObject( figFPCAccelerometer, path, 'AccelerometerComponents' );















