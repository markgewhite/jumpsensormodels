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

%% Delsys evaluation
setup.data.class = @DelsysDataset;
contEvalDelsys = ModelEvaluation( 'ContVariationDelsys', path, setup, args{:} );

%% plot the spread in X across the folds
titleSuffix = ['(Continuous: Alignment = '  ...
               setup.model.args.ContinuousEncodingArgs.AlignmentMethod ')'];

figFPCSmart = plotFPCSpread( contEvalSmart, numComp, ['Smartphone ' titleSuffix] );
figFPCDelsys = plotFPCSpread( contEvalDelsys, numComp, ['Delsys ' titleSuffix] );


function [fig, ax] = plotFPCSpread( thisEvaluation, numComp, figTitle )
    % Plot the spread of components from the evaluation
    arguments
        thisEvaluation      ModelEvaluation
        numComp             double {mustBeInteger, mustBePositive}
        figTitle            string
    end

    % get the mean curves for each fit and then align them
    XMean = cellfun( @(mdl) eval_fd( mdl.EncodingStrategy.TSpan, ...
                                     mdl.EncodingStrategy.MeanFd ), ...
                            thisEvaluation.Models, ...
                            UniformOutput=false );
    
    [XMean, offsets] = alignSignals( padData(XMean, Location='Right') );
    
    % setup the plot
    fig = figure;
    fig.Position(3) = numComp*200 + 100;
    fig.Position(4) = 200;

    layout = tiledlayout( 1, numComp, TileSpacing ='compact' );
    ax = gobjects( numComp, 1 );
    cmap = lines(4);
    
    for i = 1:numComp

        % get the component curves for each fit
        XComp = cellfun( @(mdl) eval_fd( mdl.EncodingStrategy.TSpan, ...
                                         mdl.EncodingStrategy.CompFd(i) ), ...
                         thisEvaluation.Models, ...
                         UniformOutput=false );
        % align them using the same offestes as those of the mean
        XComp = alignSignals( padData(XComp, Location='Right'), offsets );
    
        % compute the component shift from the mean
        XCompPlus = XMean + 2*XComp;
        XCompMinus = XMean - 2*XComp;
    
        % plot the components
        ax(i) = nexttile( layout );   
        plotSpread( ax(i), XCompPlus, [], cmap(2,:) );
        plotSpread( ax(i), XCompMinus, [], cmap(4,:) );
        plotSpread( ax(i), XMean, [], cmap(1,:) );

        % format plot
        xlabel( ax(i), 'Time' );
        ylabel( ax(i), 'Acc' );
        title( ax(i), ['Component ' num2str(i)] );

    end

    sgtitle( fig, figTitle );

end












