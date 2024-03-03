function grid = getGridIndices( self, i )
    % Convert an evaluation counter to grid search indices
    arguments
        self            Investigation
        i               double {mustBeInteger, mustBePositive}
    end

    idx = getIndices( i, self.SearchDims );
    idxC = num2cell( idx );

    grid = cat(1, idxC{:});

end