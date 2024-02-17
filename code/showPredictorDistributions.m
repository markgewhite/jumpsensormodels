% Present predictor distributions

clear;

varSelection = 1:5;

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
                                   "Smartphone (Discrete)" );
figDDistDelsys = plotDistributions( discreteXDelsys, ...
                                    discreteEncoding.Names, ...
                                    varSelection, ...
                                    "Delsys (Discrete)" );

% Continuous encodings
numComp = max(varSelection);
contEncodingSmart = FPCAEncodingStrategy( NumComponents = numComp );
contEncodingSmart = contEncodingSmart.fit( smartData );
contXSmart = contEncodingSmart.extractFeatures( smartData );

contEncodingDelsys = FPCAEncodingStrategy( NumComponents = numComp );
contEncodingDelsys = contEncodingDelsys.fit( delsysData );
contXDelsys = contEncodingDelsys.extractFeatures( delsysData );

figCDistSmart = plotDistributions( contXSmart, ...
                                   contEncodingSmart.Names, ...
                                   varSelection, ...
                                   "Smartphone (Continuous)" );
figCDistDelsys = plotDistributions( contXDelsys, ...
                                    contEncodingDelsys.Names, ...
                                    varSelection, ...
                                    "Delsys (Continuous)" );


%% Variations arising from subsampling
path = fileparts( which('code/showPredictorDistributions.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'LMTakeoff';
setup.model.args.ContinuousEncodingArgs.NumComponents = 10;

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
                                      varSelection, ...
                                      ['Smartphone ' titleSuffix]);

contXDelsysKFold = cellfun( @(mdl) table2array(mdl.Model.Variables), ...
                           contEvalDelsys.Models, UniformOutput=false );

figCDistVarDelsys = plotDistributions( contXDelsysKFold, ...
                                       contEncodingDelsys.Names, ...
                                       varSelection, ...
                                       ['Delsys ' titleSuffix]);


