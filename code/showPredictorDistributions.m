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

figDDistSmart = plotPredictorDistributions( discreteXSmart, ...
                                            discreteEncoding.Names, ...
                                            varSelection, ...
                                            "Smartphone (Discrete)" );
figDDistDelsys = plotPredictorDistributions( discreteXDelsys, ...
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

figCDistSmart = plotPredictorDistributions( contXSmart, ...
                                            contEncodingSmart.Names, ...
                                            varSelection, ...
                                            "Smartphone (Continuous)" );
figCDistDelsys = plotPredictorDistributions( contXDelsys, ...
                                             contEncodingDelsys.Names, ...
                                             varSelection, ...
                                            "Delsys (Continuous)" );


%% Variations arising from subsampling
path = fileparts( which('code/showPredictorDistributions.m') );
path = [path '/../results/'];

setup.model.class = @JumpModel;
setup.model.args.ModelType = 'Linear';
setup.model.args.ContinuousEncodingArgs.AlignmentMethod = 'XCMeanConv';
setup.model.args.ContinuousEncodingArgs.NumComponents = 10;

eval.CVType = 'KFold';
eval.KFolds = 2;
eval.KFoldRepeats = 50;
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
contXSmartKFold = cellfun( @(mdl) table2array(mdl.Model.Variables), ...
                           contEvalSmart.Models, UniformOutput=false );

figCDistVarSmart = plotPredictorDistributions( contXSmartKFold, ...
                                               contEncodingSmart.Names, ...
                                               varSelection, ...
                                               "Smartphone (Continuous)" );

contXDelsysKFold = cellfun( @(mdl) table2array(mdl.Model.Variables), ...
                           contEvalDelsys.Models, UniformOutput=false );

figCDistVarDelsys = plotPredictorDistributions( contXDelsysKFold, ...
                                                contEncodingSmart.Names, ...
                                                varSelection, ...
                                                "Delsys (Continuous)" );


function [fig, ax] = plotPredictorDistributions( X, names, idx, figTitle )
    % Plot distributions for specified variable indices
    arguments
        X           {mustBeA(X, {'double', 'cell'})}
        names       string
        idx         double {mustBePositive, mustBeInteger}
        figTitle    string = ""
    end

    fig = figure;
    numPlots = length(idx);

    [rows, cols] = sqdim( numPlots );
    layout = tiledlayout( rows, cols, TileSpacing= 'compact' );

    ax = cell( numPlots, 1 );
    for i = 1:numPlots
        ax{i} = nexttile( layout );

        % generate probability density function
        if iscell(X)
            [pX, mu, sigma] = plotPDFSpread( ax{i}, X, idx(i) );
        else
            [pY, pX] = kde( X(:,idx(i)) );
            mu = mean( X(:,idx(i)) );
            sigma = std( X(:,idx(i)) );

            plot( ax{i}, pX, pY, LineWidth = 1.5 );
            hold( ax{i}, 'on' );
        end

        % generate equivalent normal distribution
        nY = (1/(sigma*sqrt(2*pi)))*exp(-.5*(((pX-mu)/sigma).^2));
        plot( ax{i}, pX, nY, '--', LineWidth = 1.5, color = 'k' );
        hold( ax{i}, 'off' );

        % format plot
        xlabel( ax{i}, names(idx(i)) );
        ylabel( ax{i}, 'Freq' );

    end

    sgtitle( fig, figTitle );

end


function [pNormX, mu, sigma] = plotPDFSpread( ax, X, idx )

    numFits = length(X);

    % set the bounds
    minX = min(cellfun( @(x) min(x(:,idx)), X ));
    maxX = max(cellfun( @(x) max(x(:,idx)), X ));

    % extend them
    extRngX = (maxX-minX)*0.15;

    % initialise normalised scale
    pNormX = linspace( minX-extRngX, maxX+extRngX, 100 )';
    pNormY = zeros( 100, numFits );

    % fit PDFs for each set
    for i = 1:numFits
        pNormY(:,i) = kde( X{i}(:,idx), EvaluationPoints = pNormX );
    end

    allX = cat(1, X{:} );
    mu = mean( allX(:,idx) );
    sigma = std( allX(:,idx) );

    prc25Y = prctile(pNormY, 25, 2);
    prc50Y = prctile(pNormY, 50, 2);
    prc75Y = prctile(pNormY, 75, 2);

    % draw the shading spread of +/- SD
    cmap = lines(1);
    xSpread = [ pNormX; flip(pNormX) ];
    ySpread = [ prc75Y; flip(prc25Y) ];
    fill( ax, xSpread, ySpread, cmap, FaceAlpha = 0.5, EdgeColor = 'none' );
    hold( ax, 'on' );

    plot( ax, pNormX, prc50Y, LineWidth=1.5, Color=cmap );


end