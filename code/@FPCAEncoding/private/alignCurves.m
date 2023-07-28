function [ alignedX, offsets ] = alignCurves( X, args )
    % Align X series using cross correlation with a reference signal
    arguments
        X               double
        args.Reference  string ...
                    {mustBeMember( args.Reference, ...
                        {'First', 'Random'})} = 'Random'
    end

    [sigLength, numSignals, numDim] = size( X );
    
    % shift dimensions
    X = permute( X, [1 3 2] );

    % select the reference signal
    switch args.Reference
        case 'First'
            refIdx = 1;
        case 'Random'
            refIdx = randi(numSignals);
    end

    % initialize
    alignedX = zeros( sigLength, numDim, numSignals );
    refX = X( :, :, refIdx );
    alignedX( :, :, refIdx ) = refX;  % no need to align the reference signal
    offsets = zeros( numSignals, 1 );
    
    for i = 2:numSignals
    
        dimOffset = zeros( numDim, 1 );
        for d = 1:numDim
            dimOffset(d) = computeOffset( refX(:,d), X(:,d,i) );
        end
        offsets(i) = round(median(dimOffset), 0);
    
        % Adjust the signal based on the offset. This is a simple shift.
        % For more complex adjustments, you may need to interpolate.
        if offsets(i) > 0
            alignedX(:,:,i) = [zeros(offsets(i), numDim); X(1:end-offsets(i),:,i)];
        elseif offsets(i) < 0
            alignedX(:,:,i) = [X(-offsets(i):end, :, i); zeros(-offsets(i)-1, numDim)];
        else
            alignedX(:,:,i) = X(:,:,i);
        end
    end

    % shift back
    alignedX = permute( alignedX, [1 3 2] );

end


function lagDiff = computeOffset( reference, target )

    [c, lags] = xcorr( reference, target ); 
    [~, I] = max(abs(c));
    lagDiff = lags(I);

end