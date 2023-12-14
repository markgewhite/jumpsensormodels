function [ alignedX, offsets ] = landmarkAlignment( X, args )
    % Align X series using a given landmark
    arguments
        X               double
        args.Landmark   string ...
                {mustBeMember( args.Landmark, ...
                    {'LMTakeoff', 'LMLanding'})} = 'LMTakeoff'
    end

    [sigLength, numSignals, numDim] = size( X );
    
    % shift dimensions
    X = permute( X, [1 3 2] );

    % align the squared resultant
    Z = squeeze(sqrt(sum(X.^2, 2)).^2);

    % add some smoothing
    Z = movmean( Z, 3, 1 );

    % initializes
    alignedX = zeros( sigLength, numDim, numSignals );
    offsets = zeros( numSignals, 1 );
    refIdx = fix( size(Z,1)/2 );

    for i = 1:numSignals
    
        lmIdx= findLandmark( Z(:,i), args.Landmark );

        if lmIdx > 0
            % Adjust the signal based on the offset. This is a simple shift.
            offsets(i) = refIdx - lmIdx;
            if offsets(i) > 0
                alignedX(:,:,i) = [X(1,:,i).*ones(offsets(i), numDim); 
                                   X(1:end-offsets(i),:,i)];
            elseif offsets(i) < 0
                alignedX(:,:,i) = [X(-offsets(i):end, :, i); 
                                   X(end,:,i).*ones(-offsets(i)-1, numDim)];
            else
                alignedX(:,:,i) = X(:,:,i);
            end
        else
            alignedX(:,:,i) = X(:,:,i);
        end

    end

    % shift back
    alignedX = permute( alignedX, [1 3 2] );

end


function offset = findLandmark( Z, landmark )

    % find all peaks with a minimum separation
    [~, pkIdx, ~, pkProm] = findpeaks( Z, MinPeakDistance=25 );

    % find the two most prominent
    [~, sortIdx] = sort( -pkProm );

    switch landmark
        case 'LMTakeoff'
            offset = min( pkIdx( sortIdx(1:2) ) );
        case 'LMLanding'
            offset = max( pkIdx( sortIdx(1:2) ) );
        otherwise
            offset = 0;
    end

end