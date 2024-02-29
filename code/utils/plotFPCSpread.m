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
    fig.Position(3) = (numComp)*300 + 100;
    fig.Position(4) = 275;

    layout = tiledlayout( 1, numComp, TileSpacing ='compact' );
    ax = gobjects( numComp, 1 );
    cmap = lines(4);
    
   % get the mean curves for each fit 
    XMeans = cellfun( @(mdl) eval_fd(mdl.EncodingStrategy.TSpan, ...
                                     mdl.EncodingStrategy.MeanFd), ...
                      thisEvaluation.Models, ...
                      UniformOutput=false );
    % align the curves
    [XMeans, offsets] = alignSignals( padData(XMeans, Location='Right') );

    % add gravity back to be more intuitive
    XMeans = XMeans + 9.81;
    
    % set the time series
    t = linspace( 0, size(XMeans,1)-1, size(XMeans,1) )/thisEvaluation.TrainingDataset.SampleFreq;

    for i = 1:numComp
        
        % get the component curves for each fit
        XComps = cellfun( @(mdl) eval_fd(mdl.EncodingStrategy.TSpan, ...
                                         mdl.EncodingStrategy.CompFd(i)), ...
                            thisEvaluation.Models, ...
                            UniformOutput=false );
        % align them using the same offests as those of the mean
        XComps = alignSignals( padData(XComps, Location='Right'), offsets );

        % compute the component curves +/- 2SDs (standardised scores SD=1)
        XPlusComps = XMeans + 2*XComps;
        XMinusComps = XMeans - 2*XComps;

        caption = ['Component ' num2str(i)];
    
        % plot the components
        thisAxis = nexttile( layout );

        plotSpread( thisAxis, XPlusComps, t, cmap(2,:), mean(XMeans,2) );
        plotSpread( thisAxis, XMinusComps, t, cmap(3,:), mean(XMeans,2) );
        plotSpread( thisAxis, XMeans, t, cmap(1,:) );

        plot( thisAxis, t, mean(XPlusComps,2), LineWidth=2.5, Color=cmap(2,:) );
        plot( thisAxis, t, mean(XMinusComps,2), LineWidth=2.5, Color=cmap(3,:) );
        plot( thisAxis, t, mean(XMeans,2), LineWidth=2.5, Color=cmap(1,:) );

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