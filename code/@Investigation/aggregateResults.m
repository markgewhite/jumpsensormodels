function self = aggregateResults( self, d )
    % Aggregate results all a specific dimension
    arguments
        self            Investigation
        d               double ...
            {mustBeNonnegative, mustBeInteger} = 1
    end

    flds = fieldnames( self.TrainingResults.Mean );
    for i = 1:length(flds)
        self.TrainingResults.Mean.(flds{i}) = ...
                            mean( self.TrainingResults.Mean.(flds{i}), d );
        self.TrainingResults.SD.(flds{i}) = ...
                            mean( self.TrainingResults.SD.(flds{i}), d );
    end

    flds = fieldnames( self.ValidationResults.Mean );
    for i = 1:length(flds)
        self.ValidationResults.Mean.(flds{i}) = ...
                        mean( self.ValidationResults.Mean.(flds{i}), d );
        self.ValidationResults.SD.(flds{i}) = ...
                        mean( self.ValidationResults.SD.(flds{i}), d );
    end
    
end