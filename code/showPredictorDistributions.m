% Present predictor distributions

clear;

% --- evaluation setup ---
setup.eval.CVType = 'KFold';
setup.eval.KFolds = 2;
setup.eval.KFoldRepeats = 5;
setup.eval.RandomSeed = 1234;

% results location
path = fileparts( which('code/showPredictorDistributions.m') );
path = [path '/../results/'];

% Discrete encodings


smartData = SmartphoneDataset( 'Combined' );
discreteEncoding = DiscreteEncodingStrategy( smartData.SampleFreq );
discreteFeatures = discreteEncoding.extractFeatures( smartData );

plotPredictorDistributions( discreteFeatures, ...
                            discreteEncoding.Names, ...
                            1:26 );


function [fig, ax] = plotPredictorDistributions( X, names, idx )
    % Plot distributions for specified variable indices
    arguments
        X           double
        names       string
        idx         double {mustBePositive, mustBeInteger}
    end

    fig = figure;
    numPlots = length(idx);

    [rows, cols] = sqdim( numPlots );
    layout = tiledlayout( rows, cols, TileSpacing= 'compact' );

    ax = cell( numPlots, 1 );
    for i = 1:numPlots
        ax{i} = nexttile( layout );

        % generate probability density function
        [pY, pX] = kde( X(:,idx(i)) );
        plot( ax{i}, pX, pY, LineWidth = 1.5 );
        hold( ax{i}, 'on' );

        % generate equivalent normal distribution
        mu = mean( X(:,idx(i)) );
        sigma = std( X(:,idx(i)) );
        nY = (1/(sigma*sqrt(2*pi)))*exp(-.5*(((pX-mu)/sigma).^2));
        plot( ax{i}, pX, nY, '--', LineWidth = 1, color = 'k' );
        hold( ax{i}, 'off' );

        % format plot
        xlabel( ax{i}, names(idx(i)) );
        ylabel( ax{i}, 'Freq' );

    end

end