function cvLoss = calcCVLoss( models, set )
    % Calculate the aggregate cross-validated losses across all submodels
    % drawing on the pre-computed predictions 
    arguments
        models          cell
        set             char ...
            {mustBeMember( set, {'Training', 'Validation'} )}
    end

    % aggregate all the predictions for each field into one array
    nModels = length( models );
    nObs = cellfun( @(x) length(x.Y.(set)), models );
    nTotalObs = sum( nObs );
        
    YAggr = zeros( nTotalObs, 1 );
    YHatAggr = zeros( nTotalObs, 1 );
    startIdx = 1;
    for k = 1:nModels
        endIdx = nObs(k) + startIdx - 1;
        YAggr( startIdx:endIdx ) = models{k}.Y.(set);
        YHatAggr( startIdx:endIdx ) = models{k}.YHat.(set);
        startIdx = endIdx + 1;
    end

    % mean squared error loss
    cvLoss = sqrt(mean( (YHatAggr-YAggr).^2 ));

end
