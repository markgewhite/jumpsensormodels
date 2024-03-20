% Show alignments achieved by the methods available for FPCA
clear

path = fileparts( which('code/showAlignments.m') );
path = [path '/../results/'];

% load data
data{1} = SmartphoneDataset( 'Combined' );
data{2} = DelsysDataset( 'Combined' );

titles = {'Smartphone Dataset', 'Delsys Dataset'};
letters = 'ab';
filesnames = {'AlignmentSmart', 'AlignmentDelsys'};

% alignment methods
methods = {'XCRandom', 'XCMeanConv', 'LMTakeoff', 'LMLanding', ...
                        'LMTakeoffDiscrete', 'LMTakeoffActual'};
xCentre = [ 5.5, 2.0, 4.0, 4.0, 4.0, 4.0;
            3.5, 3.5, 4.0, 4.0, 4.0, 4.0 ];
xWidth = 1.5;

% iterate over methods
numMethods = length( methods );
ax = gobjects( 2, numMethods );
fig = gobjects( numMethods, 1 );

rng('default');
for k = 1:2

    fig(k) = figure;
    fontname( fig(k), 'Arial' );
    fig(k).Position(3) = 900;
    fig(k).Position(4) = 400;
    
    layout = tiledlayout( 2, ceil(numMethods/2), TileSpacing='compact' );

    for i = 1:numMethods

        if i==6 && k==1
            % no ground truth takeoff times for Smartphone
            continue
        end

        encoding = FPCAEncodingStrategy( AlignmentMethod=methods(i), ...
                                         StoreXAligned=true, ...
                                         ShowConvergence=true, ...
                                         AlignSquareDiff=false );
    
        % perform the encodings and extract and plot the aligned signals
        encoding.fit( data{k} );
        t = linspace( 0, length(encoding.XAligned), length(encoding.XAligned) )/data{k}.SampleFreq;

        ax(k,i) = nexttile( layout );
        
        plotSpread( ax(k,i), encoding.XAligned+9.81, t );
    
        % format plot
        xlim( ax(k,i), [max(xCentre(k,i)-xWidth,0) xCentre(k,i)+xWidth] );
        ylim( ax(k,i), [0, 30] );
        xlabel( ax(k,i), 'Time (s)' );
        ylabel( ax(k,1), 'Centred Acc (g)' );
        title( ax(k,i), methods(i) );
        
        delete( encoding );

    end

    leftSuperTitle( fig(k), titles(k), letters(k) );

    saveGraphicsObject( fig(k), path, filesnames{k} );

end

