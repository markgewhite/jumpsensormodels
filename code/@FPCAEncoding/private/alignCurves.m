function [ alignedX, offsets, correlations, mse ] = alignCurves( X, args )
    % Align X series using cross correlation with a reference signal
    arguments
        X               double
        args.Reference  string ...
                {mustBeMember( args.Reference, ...
                    {'First', 'Random', 'Mean', 'Median'})} = 'Random'
    end

    [sigLength, numSignals, numDim] = size( X );
    
    % shift dimensions
    X = permute( X, [1 3 2] );

    % select the reference signal
    switch args.Reference
        case 'First'
            refIdx = 1;
            refX = X( :, :, refIdx );
        case 'Random'
            refIdx = randi(numSignals);
            refX = X( :, :, refIdx );
        case 'Mean'
            refX = mean( X, 3 );
        case 'Median'
            refX = median( X, 3 );
   end

    % initialize
    alignedX = zeros( sigLength, numDim, numSignals );
    offsets = zeros( numSignals, 1 );
    correlations = zeros( numSignals, 1 );
    sqErr = zeros( numSignals, 1 );

    for i = 1:numSignals

        %if i==refIdx
        %    % no need to align the reference signal
        %    alignedX( :, :, refIdx ) = refX;
        %    continue
        %end
    
        dimOffset = zeros( numDim, 1 );
        r = zeros( numDim, 1 );
        for d = 1:numDim
            [dimOffset(d), r(d)] = computeOffset( refX(:,d), X(:,d,i) );
        end
%        offsets(i) = round(median(dimOffset), 0);
%        offsets(i) = round(mean(dimOffset), 0);
        offsets(i) = round(sum(dimOffset.*r)/sum(r), 0);

        correlations(i) = sum(r);

        % Adjust the signal based on the offset. This is a simple shift.
        % For more complex adjustments, you may need to interpolate.
        if offsets(i) > 0
            alignedX(:,:,i) = [X(1,:,i).*ones(offsets(i), numDim); 
                               X(1:end-offsets(i),:,i)];
        elseif offsets(i) < 0
            alignedX(:,:,i) = [X(-offsets(i):end, :, i); 
                               X(end,:,i).*ones(-offsets(i)-1, numDim)];
        else
            alignedX(:,:,i) = X(:,:,i);
        end

        sqErr(i) = mean((alignedX(:,:,i) - X(:,:,i)).^2, 'all');

    end

    mse = mean( sqErr );

    % shift back
    alignedX = permute( alignedX, [1 3 2] );

end


function [lagDiff, cBest] = computeOffset( reference, target )

    [c, lags] = xcorr( reference, target ); 
    [cBest, I] = max(abs(c));
    lagDiff = lags(I);

end