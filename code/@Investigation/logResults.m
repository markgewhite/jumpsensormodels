function self = logResults( self, idxC, allocation )
    % Log all results from the evaluation, updating results
    arguments
        self            Investigation
        idxC            cell
        allocation      double
    end

    fields = {'TrainingResults', 'ValidationResults'};
    sets = {'Training', 'Validation'};
    categories = {'CVLoss', 'CVTiming'};

    thisEvaluation = self.Evaluations{ idxC{:} };

    for i = 1:length(fields)
        
        fld = fields{i};
        set = sets{i};

        if ~isfield( self.(fld), 'Models' )
            self.(fld).Models = cell( thisEvaluation.NumModels, 1 );
        end

        for j = 1:length(categories)
    
            cat = categories{j};
            statFld = fieldnames(thisEvaluation.(cat).(set));

            for k = 1:length(statFld)
                if ~isfield(self.(fld), statFld{k})
                    self.(fld).(statFld{k}) = [];
                end
                self.(fld).(statFld{k}) = updateResults( ...
                        self.(fld).(statFld{k}), idxC, allocation, ...
                        thisEvaluation.(cat).(set).(statFld{k}) );
            end

            for k = 1:thisEvaluation.NumModels
                thisModel = thisEvaluation.Models{k};
                self.(fld).Models{k} = updateResults( ...
                    self.(fld).Models{k}, idxC, allocation, ...
                    thisModel.(cat(3:end)).(set) );
            end
            
        end

    end

end