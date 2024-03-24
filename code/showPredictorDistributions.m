% Present predictor distributions

clear;

doc = input('Document = ', 's');
switch doc
    case 'Main'
        varSelection = 1:5;
        compSelection = 1:5;
        figLetters = 'abcd';
    case 'Supp'
        varSelection = 1:26;
        compSelection = 1:15;
        figLetters = 'acbd';
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
                                   "Smartphone dataset (discrete encoding)", ...
                                   figLetters(1) );
figDDistAccelerometer = plotDistributions( discreteXAccelerometer, ...
                                    discreteEncoding.Names, ...
                                    varSelection, ...
                                    "Accelerometer dataset (discrete encoding)", ...
                                    figLetters(2) );

% Continuous encodings
numComp = max(compSelection);
contEncodingSmart = FPCAEncodingStrategy( NumComponents = numComp );
contEncodingSmart = contEncodingSmart.fit( smartData );
contXSmart = contEncodingSmart.extractFeatures( smartData );

contEncodingAccelerometer = FPCAEncodingStrategy( NumComponents = numComp );
contEncodingAccelerometer = contEncodingAccelerometer.fit( accelData );
contXAccelerometer = contEncodingAccelerometer.extractFeatures( accelData );

figCDistSmart = plotDistributions( contXSmart, ...
                                   contEncodingSmart.Names, ...
                                   compSelection, ...
                                   "Smartphone dataset (continuous encoding)", ...
                                   figLetters(3) );

figCDistAccelerometer = plotDistributions( contXAccelerometer, ...
                                    contEncodingAccelerometer.Names, ...
                                    compSelection, ...
                                    "Accelerometer dataset (continuous encoding)", ...
                                    figLetters(4) );

switch doc
    case 'Main'
        saveGraphicsObject( figDDistSmart, path, 'DiscDistSmartPredictors' );
        saveGraphicsObject( figDDistAccelerometer, path, 'DiscDistAccelerometerPredictors' );
        saveGraphicsObject( figCDistSmart, path, 'ContDistSmartPredictors' );
        saveGraphicsObject( figCDistAccelerometer, path, 'ContDistAccelerometerPredictors' );
    case 'Supp'
        saveGraphicsObject( figDDistSmart, path, 'DiscDistSmartPredictors2' );
        saveGraphicsObject( figDDistAccelerometer, path, 'DiscDistAccelerometerPredictors2' );
        saveGraphicsObject( figCDistSmart, path, 'ContDistSmartPredictors2' );
        saveGraphicsObject( figCDistAccelerometer, path, 'ContDistAccelerometerPredictors2' );
end


%% Variations arising from subsampling
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

contXSmartKFold = cellfun( @(mdl) table2array(mdl.Model.Variables), ...
                           contEvalSmart.Models, UniformOutput=false );

figCDistVarSmart = plotDistributions( contXSmartKFold, ...
                                      contEncodingSmart.Names, ...
                                      compSelection, ...
                                      ['Smartphone dataset ' titleSuffix], figLetters(3) );

contXAccelerometerKFold = cellfun( @(mdl) table2array(mdl.Model.Variables), ...
                           contEvalAccelerometer.Models, UniformOutput=false );

figCDistVarAccelerometer = plotDistributions( contXAccelerometerKFold, ...
                                       contEncodingAccelerometer.Names, ...
                                       compSelection, ...
                                       ['Accelerometer dataset ' titleSuffix], figLetters(4));
switch doc
    case 'Main'
        saveGraphicsObject( figCDistVarSmart, path, 'ContVarDistSmartPredictors' );
        saveGraphicsObject( figCDistVarAccelerometer, path, 'ContVarDistAccelerometerPredictors' );
    case 'Supp'
        saveGraphicsObject( figCDistVarSmart, path, 'ContVarDistSmartPredictors2' );
        saveGraphicsObject( figCDistVarAccelerometer, path, 'ContVarDistAccelerometerPredictors2' );
end



