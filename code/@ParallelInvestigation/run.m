function self = run( self )
    % Run a parallel grid search
    arguments
        self            ParallelInvestigation
    end

    % check if any evaluations have already been done
    isToBeDone = cellfun(@(x) ~isa(x, 'ModelEvaluation'), self.Evaluations );
    toDoIdx = find( isToBeDone );

    % use temporary flattened arrays for parallel procesing
    % so the indexing is unambiguous
    path = self.Path;
    setups = self.Setups(isToBeDone);
    names = self.EvaluationNames(isToBeDone);
    catchErrors = self.CatchErrors;

    nEval = sum( isToBeDone, 'all' );
    thisEvaluation = cell( nEval, 1 );
    isComplete = false( nEval, 1 );
    errorMessages = strings( nEval, 1 );

    % run the evaluation loop
    parfor i = 1:nEval

        try
            argsCell = namedargs2cell( setups{i}.eval );
        catch
            argsCell = {};
        end

        disp(['Running evaluation = ' char(names(i)) ' ...']);
        if catchErrors
            try
                thisEvaluation{i} = ModelEvaluation( names(i), ...
                                                     path, ...
                                                     setups{i}, ...
                                                     argsCell{:} );
            catch ME
                warning(['***** Evaluation failed in ' char(names(i)) ' *****'])
                disp(['Error Message: ' ME.message]);
                errorMessages(i) = ME.message;
                continue
            end
        
        else
            thisEvaluation{i} = ModelEvaluation( names(i), ...
                                                 path, ...
                                                 setups{i}, ...
                                                 argsCell{:} );

        end

        % save the evaluations
        thisEvaluation{i}.save;
        isComplete(i) = true;

    end

    % store the results
    for i = 1:nEval

        idx = getIndices( toDoIdx(i), self.SearchDims );
        idxC = num2cell( idx );

        self.Evaluations{ idxC{:} } = thisEvaluation{i};
        try
            self.logResults( idxC, size(self.Setups) );
        catch
            disp(['Unable to log results for ' char(names(i))]);
        end

    end
    self.IsComplete = isComplete;
    self.ErrorMessages = errorMessages;

    % save the current state of the investigation
    self.save;
    
end   