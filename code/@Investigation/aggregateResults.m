function self = aggregateResults( self, d )
    % Aggregate results all a specific dimension
    arguments
        self            Investigation
        d               double ...
            {mustBeNonnegative, mustBeInteger} = 1
    end

    self.TrainingResults = aggregateSet( self.TrainingResults, d );

    self.ValidationResults = aggregateSet( self.ValidationResults, d );

end


function results = aggregateSet( results, d )

    flds = fieldnames( results.Mean );
    for i = 1:length(flds)
        results.Mean.(flds{i}) = mean( results.Mean.(flds{i}), d );
        results.SD.(flds{i}) = mean( results.SD.(flds{i}), d );
        for j = 1:length(results.Models)
            results.Models{j}.(flds{i}) = mean( results.Models{j}.(flds{i}), d );
        end
    end

end