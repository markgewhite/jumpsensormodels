% Show alignments achieved by the methods available for FPCA
clear

path = fileparts( which('code/showAlignments.m') );
path = [path '/../results/'];

% load data
data{1} = SmartphoneDataset( 'Combined' );
data{2} = AccelerometerDataset( 'Combined' );

titles = {'Smartphone Dataset', 'Accelerometer Dataset'};
letters = 'ab';
filesnames = {'AlignmentSmart', 'AlignmentAccel'};

% alignment methods
methods = {'XCMeanConv', 'XCRandom', 'LMTakeoff', 'LMLanding', ...
            'LMTakeoffDiscrete', 'LMTakeoffActual'};
xCentre = [ 2.0, 5.5, 4.0, 4.0, 4.0, 4.0, 4.0;
            3.5, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5 ];
xWidth = 1.5;

% iterate over methods
numMethods = length( methods );
numRows = 2;
numCols = ceil(numMethods/numRows);
ax = gobjects( 2, numMethods );
fig = gobjects( numMethods, 1 );

rmse = zeros( 2, numMethods );
pcc = zeros( 2, numMethods );
ncc = zeros( 2, numMethods );
tde = zeros( 2, numMethods );
mi = zeros( 2, numMethods );
alignmentRMSE = zeros( 1, numMethods );

rng('default');
for k = 1:numRows

    fig(k) = figure;
    fontname( fig(k), 'Arial' );
    fig(k).Position(3) = 900;
    fig(k).Position(4) = 500;
    
    layout = tiledlayout( numRows, numCols, TileSpacing='compact' );

    for i = 1:numMethods

        if i==6 && k==1
            % no ground truth takeoff times for Smartphone
            continue
        end

        encoding = FPCAEncodingStrategy( PenaltyOrder=1, ...
                                         AlignmentMethod=methods(i), ...
                                         StoreXAligned=true, ...
                                         ShowConvergence=true, ...
                                         AlignSquareDiff=false );

        % perform the encodings
        encoding.fit( data{k} );

        % calculate metrics
        [rmse(k,i), pcc(k,i), ncc(k,i), tde(k,i), mi(k,i)] = encoding.calcMetrics(data{k});

        disp(['*** ' methods{i} ' ***']);
        disp(['RMSE = ' num2str(rmse(k,i), '%.3f')]);
        disp(['PCC  = ' num2str(pcc(k,i), '%.3f')]);
        disp(['NCC  = ' num2str(ncc(k,i), '%.3f')]);
        disp(['TDE  = ' num2str(tde(k,i), '%.3f')]);
        disp(['MI   = ' num2str(mi(k,i), '%.3f')]);

        % compute alignment error
        if ~isempty(encoding.RefAlignmentIdx) && ~isempty(encoding.FittedAlignmentIdx) &&  ~isempty(encoding.LMAlignmentIdx)
            fittedPositionIdx = encoding.LMAlignmentIdx-encoding.FittedAlignmentIdx;
            alignmentRMSE(i) = sqrt(mean((fittedPositionIdx-encoding.RefAlignmentIdx).^2));
            disp(['Alignment RMSE = ' num2str(alignmentRMSE(i), '%6.2f')]);
        end

        % plot the aligned signals
        t = linspace( 0, length(encoding.XAlignedPts), length(encoding.XAlignedPts) )/data{k}.SampleFreq;

        ax(k,i) = nexttile( layout );
        
        plotSpread( ax(k,i), encoding.XAlignedPts+9.81, t );
    
        % format plot
        xlim( ax(k,i), [max(xCentre(k,i)-xWidth,0) xCentre(k,i)+xWidth] );
        ylim( ax(k,i), [-10, 50] );
        xlabel( ax(k,i), 'Time (s)' );
        title( ax(k,i), methods(i) );

        if mod(i, numCols)==1
            ylabel( ax(k,i), 'Acceleration (m/s^2)' );
        end

        delete( encoding );

    end

    leftSuperTitle( fig(k), titles(k), letters(k) );

    saveGraphicsObject( fig(k), path, filesnames{k} );

end

