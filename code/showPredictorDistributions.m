% Present predictor distributions

clear;

alignMethod = input('Alignment Method = ', 's');
switch alignMethod
    case 'LMTakeoffPeak'
        figLetters = 'adbe';
    case 'XCMeanConv'
        figLetters = 'adcf';
    otherwise
        error('Unrecognised method for these plots');
end

doc = input('Document = ', 's');
switch doc
    case 'Main'
        varSelection = 1:5;
        compSelection = 1:5;
    case 'Supp'
        varSelection = 1:23;
        compSelection = 1:15;
    otherwise
        error('Unrecognised doc');
end

path = fileparts( which('code/showPredictorDistributions.m') );
path = [path '/../results/'];

% load data
smartData = SmartphoneDataset( 'Combined' );
accelData = AccelerometerDataset( 'Combined' );

% Discrete encodings
discreteEncoding = DiscreteEncodingStrategy;
discreteXSmart = discreteEncoding.extractFeatures( smartData );
discreteXAccelerometer = discreteEncoding.extractFeatures( accelData );

figDDistSmart = plotDistributions( discreteXSmart, ...
                                   discreteEncoding.Names, ...
                                   varSelection, ...
                                   "Smartphone Dataset (Discrete)", ...
                                   figLetters(1) );
figDDistAccelerometer = plotDistributions( discreteXAccelerometer, ...
                                    discreteEncoding.Names, ...
                                    varSelection, ...
                                    "Accelerometer Dataset (Discrete)", ...
                                    figLetters(2) );

% Continuous encodings
numComp = max(compSelection);
contEncodingSmart = FPCAEncodingStrategy( AlignmentMethod = alignMethod, ...
                                          NumComponents = numComp );
contEncodingSmart = contEncodingSmart.fit( smartData );
contXSmart = contEncodingSmart.extractFeatures( smartData );

contEncodingAccelerometer = FPCAEncodingStrategy( AlignmentMethod = alignMethod, ...
                                                  NumComponents = numComp );
contEncodingAccelerometer = contEncodingAccelerometer.fit( accelData );
contXAccelerometer = contEncodingAccelerometer.extractFeatures( accelData );

figCDistSmart = plotDistributions( contXSmart, ...
                                   contEncodingSmart.Names, ...
                                   compSelection, ...
                                   ['Smartphone Dataset (Continuous - ' alignMethod ')'], ...
                                   figLetters(3) );

figCDistAccelerometer = plotDistributions( contXAccelerometer, ...
                                    contEncodingAccelerometer.Names, ...
                                    compSelection, ...
                                    ['Accelerometer Dataset (Continuous - ' alignMethod ')'], ...
                                    figLetters(4) );

switch doc
    case 'Main'
        saveGraphicsObject( figDDistSmart, path, 'DiscDistSmartPredictors' );
        saveGraphicsObject( figDDistAccelerometer, path, 'DiscDistAccelPredictors' );
        saveGraphicsObject( figCDistSmart, path, ['ContDistSmartPredictors-' alignMethod]);
        saveGraphicsObject( figCDistAccelerometer, path, ['ContDistAccelPredictors-' alignMethod] );
    case 'Supp'
        saveGraphicsObject( figDDistSmart, path, 'DiscDistSmartPredictors2' );
        saveGraphicsObject( figDDistAccelerometer, path, 'DiscDistAccelPredictors2' );
        saveGraphicsObject( figCDistSmart, path, ['ContDistSmartPredictors2-' alignMethod] );
        saveGraphicsObject( figCDistAccelerometer, path, ['ContDistAccelPredictors-' alignMethod] );
end


%% Variations arising from subsampling
setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = alignMethod;
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
titleSuffix = ['(Continuous - '  ...
               setup.model.args.ContinuousEncodingArgs.AlignmentMethod ')'];

contXSmartKFold = cellfun( @(mdl) table2array(mdl.Model.Variables), ...
                           contEvalSmart.Models, UniformOutput=false );

figCDistVarSmart = plotDistributions( contXSmartKFold, ...
                                      contEncodingSmart.Names, ...
                                      compSelection, ...
                                      ['Smartphone Dataset ' titleSuffix], figLetters(3) );

contXAccelerometerKFold = cellfun( @(mdl) table2array(mdl.Model.Variables), ...
                           contEvalAccelerometer.Models, UniformOutput=false );

figCDistVarAccelerometer = plotDistributions( contXAccelerometerKFold, ...
                                       contEncodingAccelerometer.Names, ...
                                       compSelection, ...
                                       ['Accelerometer Dataset ' titleSuffix], figLetters(4));
switch doc
    case 'Main'
        saveGraphicsObject( figCDistVarSmart, path, ['ContVarDistSmartPredictors-' alignMethod] );
        saveGraphicsObject( figCDistVarAccelerometer, path, ['ContVarDistAccelPredictors-' alignMethod] );
    case 'Supp'
        saveGraphicsObject( figCDistVarSmart, path, ['ContVarDistSmartPredictors2-' alignMethod] );
        saveGraphicsObject( figCDistVarAccelerometer, path, ['ContVarDistAccelPredictors2-' alignMethod] );
end



