function values = getResultArray( self, flds, set )
    % Compile an array spanning evaluations for given fields in a set 
    arguments
        self            Investigation
        flds            string
        set             {mustBeMember(set, {'Training', 'Validation'})} = 'Training'
    end

    % conveniently extract the model results
    models = self.([set 'Results']).Models;

    numFields = length(flds);
    numModels = length(models);
    values = zeros( numModels, self.NumEvaluations, numFields );

    for i = 1:numFields

        % extract the raw results from a given set 
        vCell = cellfun( @(mdl) mdl.(flds(i)), models , ...
                         UniformOutput = false );
    
        % flatten each extracted result
        vFlat = cellfun( @(v) reshape(v, 1, numel(v)), vCell, ...
                         UniformOutput = false );
    
        % convert the cell array into a numeric array
        values(:,:,i) = cat(1, vFlat{:});

    end

end