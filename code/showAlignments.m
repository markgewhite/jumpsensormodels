% Show alignments achieved by the methods available for FPCA
clear

% load data
data{1} = SmartphoneDataset( 'Combined' );
data{2} = DelsysDataset( 'Combined' );

vertLabels = {'Acc (Smartphone)', 'Acc (Delsys)'};

% alignment methods
methods = {'XCRandom', 'XCMeanConv', 'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual'};
xCentre = [ 5.5, 5.5, 10.0, 9.0, 10.0, 10.0;
            3.5, 3.0, 9.0, 8.0, 9.0, 9.0 ];
xWidth = 1.5;

% iterate over methods
numMethods = length( methods );

fig = figure;
fig.Position(3) = numMethods*200 + 100;
fig.Position(4) = 2*200+50;

layout = tiledlayout( 2, numMethods, TileSpacing='compact' );
ax = gobjects( 2, numMethods );
rng('default');
for k = 1:2

    for i = 1:numMethods

        ax(k,i) = nexttile( layout );
        if i==6 && k==1
            % no ground truth takeoff times for Smartphone
            title( ax(k,i), methods(i) );
            set( ax(k,i), 'XTick', [], 'YTick', []);
            continue
        end

        encoding = FPCAEncodingStrategy( AlignmentMethod=methods(i), ...
                                         StoreXAligned=true );
    
        % perform the encodings and extract and plot the aligned signals
        encoding.fit( data{k} );
        t = linspace( 0, length(encoding.XAligned), length(encoding.XAligned) )/data{k}.SampleFreq;
        plotSpread( ax(k,i), encoding.XAligned, t );
    
        % format plot
        xlim( ax(k,i), [max(xCentre(k,i)-xWidth,0) xCentre(k,i)+xWidth] );
        if k==1
            ylim( ax(k,i), [-15, 15] );
            title( ax(k,i), methods(i) );
        else
            ylim( ax(k,i), [-10, 20] );
            xlabel( ax(k,i), 'Time (s)' );
        end

        if i==1
            ylabel( ax(k,1), vertLabels(k) );
        end
    
        delete( encoding );

    end

end

