% Show alignments achieved by the methods available for FPCA
clear

path = fileparts( which('code/showAlignments.m') );
path = [path '/../results/'];

% load data
data{1} = SmartphoneDataset( 'Combined', SignalType='VerticalAcc' );
data{2} = SmartphoneDataset( 'Combined', SignalType='VerticalAcc', SignalAligned=false );
data{3} = SmartphoneDataset( 'Combined', SignalType='ResultantAcc' );
data{4} = AccelerometerDataset( 'Combined' );
numDatasets = length(data);

titles = {'Smartphone Dataset (Vertical)', 'Smartphone Dataset (Pseudo-Vertical)', ...
          'Smartphone Dataset (Resultant)', 'Accelerometer Dataset'};
letters = 'abcd';
filesnames = {'AlignmentSmart', 'AlignmentSmart2', 'AlignmentSmart3', 'AlignmentAccel'};

% alignment methods
methods = {'XCMeanConv', 'XCRandom', 'LMTakeoff', 'LMLanding', ...
            'LMTakeoffDiscrete', 'LMTakeoffActual'};
xCentre = [ 2.0, 5.5, 4.0, 4.0, 4.0, 4.0, 4.0;
            2.0, 5.5, 4.0, 4.0, 4.0, 4.0, 4.0;
            5.5, 1.5, 4.0, 5.5, 4.0, 5.5, 4.0;  
            3.5, 4.0, 3.5, 3.5, 3.5, 3.5, 3.5 ];
xWidth = 1.5;

% iterate over methods
numMethods = length( methods );
numRows = 2;
numCols = ceil(numMethods/numRows);
ax = gobjects( numDatasets, numMethods );
fig = gobjects( numMethods, 1 );

rng('default');
for k = 1:numDatasets

    fig(k) = figure;
    fontname( fig(k), 'Arial' );
    fig(k).Position(3) = 900;
    fig(k).Position(4) = 500;
    
    layout = tiledlayout( numRows, numCols, TileSpacing='compact' );

    for i = 1:numMethods

        if i==6 && k<3
            % no ground truth takeoff times for Smartphone
            continue
        end

        ax(k,i) = nexttile( layout );

        encoding = FPCAEncodingStrategy( PenaltyOrder=1, ...
                                         AlignmentMethod=methods(i), ...
                                         StoreXAligned=true, ...
                                         ShowConvergence=true, ...
                                         AlignSquareDiff=false );

        % perform the encodings
        try
            encoding.fit( data{k} );
        catch
            continue
        end

        % calculate metrics
        metrics = encoding.calcMetrics(data{k});

        disp(['*** ' methods{i} ' ***']);
        disp(['RMSE = ' num2str(metrics.rmse, '%.3f')]);
        disp(['PCC  = ' num2str(metrics.pcc, '%.3f')]);
        disp(['NCC  = ' num2str(metrics.ncc, '%.3f')]);
        disp(['TDE  = ' num2str(metrics.tde, '%.3f')]);
        disp(['MI   = ' num2str(metrics.mi, '%.3f')]);
        disp(['SNR  = ' num2str(metrics.snr, '%.3f')]);

        % compute alignment error
        if ~isempty(encoding.RefAlignmentIdx) && ~isempty(encoding.FittedAlignmentIdx) &&  ~isempty(encoding.LMAlignmentIdx)
            fittedPositionIdx = encoding.LMAlignmentIdx-encoding.FittedAlignmentIdx;
            alignmentRMSE = sqrt(mean((fittedPositionIdx-encoding.RefAlignmentIdx).^2));
            disp(['Alignment RMSE = ' num2str(alignmentRMSE, '%6.2f')]);
        end

        % plot the aligned signals
        t = linspace( 0, length(encoding.XAlignedPts), length(encoding.XAlignedPts) )/data{k}.SampleFreq;
        
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

