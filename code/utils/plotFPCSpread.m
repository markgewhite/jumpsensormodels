function [fig, ax] = plotFPCSpread( thisEvaluation, numComp, figTitle, tRange )
    % Plot the spread of components from the evaluation
    arguments
        thisEvaluation      ModelEvaluation
        numComp             double {mustBeInteger, mustBePositive}
        figTitle            string
        tRange              double = []
    end

    
    % setup the plot
    fig = figure;
    fig.Position(3) = (numComp+1)*200 + 100;
    fig.Position(4) = 200;

    layout = tiledlayout( 1, numComp+1, TileSpacing ='compact' );
    ax = gobjects( numComp+1, 1 );
    cmap = lines(4);
    
    for i = 0:numComp

        if i==0
            % get the mean curves for each fit 
            X = cellfun( @(mdl) eval_fd( mdl.EncodingStrategy.TSpan, ...
                                             mdl.EncodingStrategy.MeanFd ), ...
                         thisEvaluation.Models, ...
                         UniformOutput=false );
            % align the curves
            [X, offsets] = alignSignals( padData(X, Location='Right') );
            c = cmap(1,:);
            caption = 'Mean';
        
        else
            % get the component curves for each fit
            X = cellfun( @(mdl) eval_fd( mdl.EncodingStrategy.TSpan, ...
                                             mdl.EncodingStrategy.CompFd(i) ), ...
                        thisEvaluation.Models, ...
                        UniformOutput=false );
            % align them using the same offestes as those of the mean
            X = alignSignals( padData(X, Location='Right'), offsets );
            c = cmap(2,:);
            caption = ['Component ' num2str(i)];
        end
    
        % plot the components
        thisAxis = nexttile( layout );

        t = linspace( 0, size(X,1)-1, size(X,1) )/thisEvaluation.TrainingDataset.SampleFreq;
        plotSpread( thisAxis, X, t, c );

        % format plot
        xlabel( thisAxis, 'Time (s)' );
        ylabel( thisAxis, 'Acc (Centred)' );
        title( thisAxis, caption );

        if ~isempty( tRange )
            xlim( thisAxis, tRange );
        end

        ax(i+1) = thisAxis;

    end

    sgtitle( fig, figTitle );

end