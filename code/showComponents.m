% Show the functional principal components

clear

numComp = 3;

path = fileparts( which('code/showComponents.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMLanding';
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

%% Delsys evaluation
setup.data.class = @DelsysDataset;
contEvalDelsys = ModelEvaluation( 'ContVariationDelsys', path, setup, args{:} );

%% plot the spread in X across the folds
titleSuffix = ['(Continuous: Alignment = '  ...
               setup.model.args.ContinuousEncodingArgs.AlignmentMethod ')'];
tRange = [ 8, 11 ];

figFPCSmart = plotFPCSpread( contEvalSmart, numComp, ...
                             ['Smartphone ' titleSuffix], [9 11] );
figFPCDelsys = plotFPCSpread( contEvalDelsys, numComp, ...
                              ['Delsys ' titleSuffix], [7 10] );















