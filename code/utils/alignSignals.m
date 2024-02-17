function [ alignedX, offsets ] = alignSignals( X, offsets )
    % Align signals that have been padded to arrays
    % offsets may be provided from a previous alignment
    arguments
        X               double
        offsets         double = []
    end

    [sigLength, numSignals] = size( X );
    
    meanX = mean( X, 2 );
    alignedX = zeros( sigLength, numSignals );

    doAlignment = isempty( offsets );
    if doAlignment
        offsets = zeros( numSignals, 1 );
    end

    for i = 1:numSignals
    
        if doAlignment
            offsets(i) = computeOffset( meanX, X(:,i) );
        end

        if offsets(i) > 0
            alignedX(:, i) = [X(1,i).*ones(offsets(i), 1); 
                               X(1:end-offsets(i), i)];
        elseif offsets(i) < 0
            alignedX(:, i) = [X(-offsets(i):end, i); 
                               X(end, i).*ones(-offsets(i)-1, 1)];
        else
            alignedX(:, i) = X(:,i);
        end

    end

end


function lagDiff = computeOffset( reference, target )

    [c, lags] = xcorr( reference, target ); 
    [~, I] = max(abs(c));
    lagDiff = lags(I);

end