function results = getMultiVarTable( self, flds, set, format )
    % Build table of multiple fields showing mean and SD as string
    arguments
        self                Investigation
        flds                string
        set                 ...
            {mustBeMember(set, {'Training', 'Validation'})} = 'Training'
        format              string = '%1.3f'
    end

    numFields = length(flds);
    numColumns = numFields + self.NumParameters;
    results = table( Size = [self.NumEvaluations, numColumns], ...
                    VariableType = repelem( "string", numColumns, 1), ...
                    VariableNames = [ self.Parameters flds ] );
    p = self.NumParameters;

    % define the formatting function
    formatFcn = @(s) string(num2str( s, format ));

    % get either the training or validation results
    reference = self.([set 'Results']);

    for i = 1:numFields

        % extract the set of results for this field
        mnValues = reference.Mean.(flds(i));
        sdValues = reference.SD.(flds(i));

        for j = 1:self.NumEvaluations

            % translate evaluation number to result index
            idx = getIndices( j, self.SearchDims );
            idxC = num2cell( idx );

            % extract the result for this evalation
            results{j,i+p} = strcat( formatFcn( mnValues(idxC{:}) ), ...
                              " ", char(177), " ", ...
                              formatFcn( sdValues(idxC{:}) ) );

            if i==1
                % add the evaluation name in the first columns
                for k = 1:p
                    paramValue = self.GridSearch{k}{idx(k)};
                    if isa(paramValue, 'function_handle')
                        paramValue = func2str(paramValue);
                    end
                    results{j,k} = string(paramValue);
                end
            end

        end

    end

end



