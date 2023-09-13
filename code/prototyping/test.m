
getUserInput = true;

setup.preproc.initOrientation = [ -1 0 0 ];

setup.preproc.landing.maxSpikeWidth = 30;
setup.preproc.landing.freefallThreshold = 1.00; % (g) limit for freefall
setup.preproc.landing.freefallRange = 65; % 112 period for calculating freefall acc
setup.preproc.landing.idxOffset = -10; % -23 bias
setup.preproc.landing.nSmooth = 5; % moving average window (x*2+1)

setup.preproc.takeoff.idxMaxDivergence = 85;
setup.preproc.takeoff.idxOffset = -1; % bias
setup.preproc.takeoff.nSmooth = 10; % moving average window (x*2+1)
setup.preproc.takeoff.initOrientation = setup.preproc.initOrientation;
setup.preproc.takeoff.doReorientation = true;

% load raw data
path = fileparts( which('code/test.m') );

load([path '/../data/raw_subjects']);
rawData = D;
clear D;

% load adjusted data
load([path '/../data/adjusted_data'], 'adjusted_data');

subjects = fieldnames(adjusted_data);
numSubjects = length(subjects);

% setup input data for processing
signals = cell( 3*numSubjects, 1 );
start = zeros( 3*numSubjects, 1 );
takeoff = zeros( 3*numSubjects, 1 );
landing = zeros( 3*numSubjects, 1 );
criterion = zeros( 3*numSubjects, 1 );

presetsStart = [1791 1799 1966];
presetsLanding = [261 204 205];

k = 0;
for i = 1:numSubjects

    signalData = rawData.(subjects{i});
    processedData = adjusted_data.(subjects{i});

    for j = 1:3
        k = k + 1;
        % get the rraw signal and the crterion take-off index
        signals{k} = signalData.(['CMJ0' num2str(j)]).acc;
        criterion(k) = processedData.(['CMJ0' num2str(j)]).to;

        if getUserInput
            % plot the signal and ask the user to set the start point
            plot(signals{k});
            disp('Set start point');
            [start(k), ~] = ginput(1);
            start(k) = fix(start(k));
            disp(['Start point = ' num2str(start(k))]);
        else
            start(k) = presetsStart(k);
        end
        signals{k} = signals{k}(start(k):start(k)+500, :);

        if numDim==1
            signals{k} = sqrt(sum(signals{k}.^2, 2));
        end
        
        if getUserInput
            % plot the truncated signal and ask the user to mark 
            % the dip before the landing
            plot(signals{k});
            [landing(k), ~] = ginput(1);
            landing(k) = fix(landing(k));
            disp(['Start point = ' num2str(landing(k))]);
        else
            landing(k) = presetsLanding(k);
        end

    end

end

% test the algorithms
%idxLanding = detectJumpTakeoff( signals, criterion, landing, setup.preproc.takeoff );

% Let's assume signals is a cell array where each element is one of your signals
reference = signals{1};  % using the first signal as reference

alignedSignals = cell(size(signals));
alignedSignals{1} = reference;  % no need to align the reference signal
numDim = 1;

for i = 2:numel(signals)

    dimOffset = zeros( numDim, 1 );
    for d = 1:numDim
        dimOffset(d) = computeOffset(reference(:,d), signals{i}(:,d));
    end
    offset = round(median(dimOffset), 0);

    % Adjust the signal based on the offset. This is a simple shift.
    % For more complex adjustments, you may need to interpolate.
    if offset > 0
        alignedSignals{i} = [zeros(offset, numDim); signals{i}];
    else
        alignedSignals{i} = signals{i}(-offset+1:end, :);
    end
end


function lagDiff = computeOffset(reference, target)
    [c, lags] = xcorr(reference, target); 
    [~, I] = max(abs(c));
    lagDiff = lags(I);
end



