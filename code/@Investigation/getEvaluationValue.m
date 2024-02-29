function [QTrn, QVal] = getEvaluationValue( self, fld )
    % Retrieve all values for a given field across evaluations
    arguments
        self            Investigation
        fld             string
    end

    QTrn = cellfun( @(mdl) mdl.(fld), ...
                    self.TrainingResults.Models , 'UniformOutput', false);
    
    try
        QVal = cellfun( @(mdl) mdl.(fld), ...
                    self.ValidationResults.Models , 'UniformOutput', false);
    catch
        QVal = [];
    end

end
