function values = getResultArray( self, flds, set )
    % Compile an array for given fields in a set 
    arguments
        self            ModelEvaluation
        flds            string
        set             {mustBeMember(set, {'Training', 'Validation'})} = 'Training'
    end

    numFields = length(flds);
    values = zeros( self.NumModels, numFields );

    for i = 1:numFields
        values(:, i) = self.CVLoss.(set).All.(flds(i));
    end

end