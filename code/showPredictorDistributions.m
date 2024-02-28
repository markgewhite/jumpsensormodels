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
delsysData = DelsysDataset( 'Combined' );

% Discrete encodings
discreteEncoding = DiscreteEncodingStrategy;
discreteXSmart = discreteEncoding.extractFeatures( smartData );
discreteXDelsys = discreteEncoding.extractFeatures( delsysData );

figDDistSmart = plotDistributions( discreteXSmart, ...
                                   discreteEncoding.Names, ...
                                   varSelection, ...
                                   "Smartphone dataset (discrete encoding)", ...
                                   figLetters(1) );
figDDistDelsys = plotDistributions( discreteXDelsys, ...
                                    discreteEncoding.Names, ...
                                    varSelection, ...
                                    "Delsys dataset (discrete encoding)", ...
                                    figLetters(2) );

% Continuous encodings
numComp = max(compSelection);
contEncodingSmart = FPCAEncodingStrategy( NumComponents = numComp );
contEncodingSmart = contEncodingSmart.fit( smartData );
contXSmart = contEncodingSmart.extractFeatures( smartData );

contEncodingDelsys = FPCAEncodingStrategy( NumComponents = numComp );
contEncodingDelsys = contEncodingDelsys.fit( delsysData );
contXDelsys = contEncodingDelsys.extractFeatures( delsysData );

figCDistSmart = plotDistributions( contXSmart, ...
                                   contEncodingSmart.Names, ...
                                   compSelection, ...
                                   "Smartphone dataset (continuous encoding)", ...
                                   figLetters(3) );

figCDistDelsys = plotDistributions( contXDelsys, ...
                                    contEncodingDelsys.Names, ...
                                    compSelection, ...
                                    "Delsys dataset (continuous encoding)", ...
                                    figLetters(4) );

switch doc
    case 'Main'
        saveGraphicsObject( figDDistSmart, path, 'DiscDistSmartPredictors' );
        saveGraphicsObject( figDDistDelsys, path, 'DiscDistDelsysPredictors' );
        saveGraphicsObject( figCDistSmart, path, 'ContDistSmartPredictors' );
        saveGraphicsObject( figCDistDelsys, path, 'ContDistDelsysPredictors' );
    case 'Supp'
        saveGraphicsObject( figDDistSmart, path, 'DiscDistSmartPredictors2' );
        saveGraphicsObject( figDDistDelsys, path, 'DiscDistDelsysPredictors2' );
        saveGraphicsObject( figCDistSmart, path, 'ContDistSmartPredictors2' );
        saveGraphicsObject( figCDistDelsys, path, 'ContDistDelsysPredictors2' );
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

%% Delsys evaluation
setup.data.class = @DelsysDataset;
contEvalDelsys = ModelEvaluation( 'ContVariationDelsys', path, setup, args{:} );

%% plot the spread in X across the folds
titleSuffix = ['(Continuous: Alignment = '  ...
               setup.model.args.ContinuousEncodingArgs.AlignmentMethod ')'];

contXSmartKFold = cellfun( @(mdl) table2array(mdl.Model.Variables), ...
                           contEvalSmart.Models, UniformOutput=false );

figCDistVarSmart = plotDistributions( contXSmartKFold, ...
                                      contEncodingSmart.Names, ...
                                      compSelection, ...
                                      ['Smartphone dataset ' titleSuffix], figLetters(3) );

contXDelsysKFold = cellfun( @(mdl) table2array(mdl.Model.Variables), ...
                           contEvalDelsys.Models, UniformOutput=false );

figCDistVarDelsys = plotDistributions( contXDelsysKFold, ...
                                       contEncodingDelsys.Names, ...
                                       compSelection, ...
                                       ['Delsys dataset ' titleSuffix], figLetters(4));
switch doc
    case 'Main'
        saveGraphicsObject( figCDistVarSmart, path, 'ContVarDistSmartPredictors' );
        saveGraphicsObject( figCDistVarDelsys, path, 'ContVarDistDelsysPredictors' );
    case 'Supp'
        saveGraphicsObject( figCDistVarSmart, path, 'ContVarDistSmartPredictors2' );
        saveGraphicsObject( figCDistVarDelsys, path, 'ContVarDistDelsysPredictors2' );
end



