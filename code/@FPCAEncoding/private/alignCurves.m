function [ alignedX, offsets, correlations ] = alignCurves( X, args )
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

    % align the squared diff
    Z = squeeze(diff( sqrt(sum(X.^2, 2)) ).^2);

    % select the reference signal
    switch args.Reference
        case 'First'
            refIdx = 1;
            refZ = Z( :, refIdx );
        case 'Random'
            refIdx = randi(numSignals);
            refZ = Z( :, refIdx );
   end

    % initialize
    alignedX = zeros( sigLength, numDim, numSignals );
    offsets = zeros( numSignals, 1 );
    correlations = zeros( numSignals, 1 );

    for i = 1:numSignals

        if i==refIdx
            % no need to align the reference signal
            alignedX( :, :, refIdx ) = refZ;
            continue
        end
    
        [offsets(i), correlations(i)] = computeOffset( refZ, Z(:,i) );

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

    end

    % shift back
    alignedX = permute( alignedX, [1 3 2] );

end


function [lagDiff, cBest] = computeOffset( reference, target )

    [c, lags] = xcorr( reference, target ); 
    [cBest, I] = max(abs(c));
    lagDiff = lags(I);

end