function aggrP = calcCVParameters( models, group, set )
    % Average a specified group of parameters from models
    arguments
        models          cell
        group           char ...
            {mustBeMember( group, {'Loss', 'Timing'} )}
        set             char ...
            {mustBeMember( set, {'Training', 'Validation'} )}
    end

    nModels = length( models );
    fields = fieldnames( models{1}.(group).(set) );
    nFields = length( fields );

    for i = 1:nFields

        fldDim = size( models{1}.(group).(set).(fields{i}) );
        P = zeros( [nModels fldDim] );
        for k = 1:nModels
            if isfield( models{k}.(group).(set), fields{i} )
                if ~isempty(models{k}.(group).(set).(fields{i}))
                    P(k,:,:,:) = models{k}.(group).(set).(fields{i});
                else
                    P(k,:,:,:) = NaN;
                end
            else
                P(k,:,:,:) = NaN;
            end
        end
        aggrP.Mean.(fields{i}) = squeeze(mean(P, 1, 'omitnan'));
        aggrP.SD.(fields{i}) = squeeze(std(P,1, 'omitnan'));
        aggrP.Median.(fields{i}) = squeeze(median(P, 1, 'omitnan'));
        aggrP.Prctile5.(fields{i}) = squeeze(prctile(P, 5));
        aggrP.Prctile25.(fields{i}) = squeeze(prctile(P, 25));
        aggrP.Prctile75.(fields{i}) = squeeze(prctile(P, 75));
        aggrP.Prctile95.(fields{i}) = squeeze(prctile(P, 95));
        aggrP.All.(fields{i}) = P;

    end

end