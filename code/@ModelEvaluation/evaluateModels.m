function evaluateModels( self, set )
    % Evaluate the trained models
    arguments
        self            ModelEvaluation
        set             char ...
            {mustBeMember( set, {'Training', 'Validation'} )}
    end

    self.CVLoss.(set) = calcCVParameters( self.Models, 'Loss', set );

    self.CVLoss.(set).Aggregate = calcCVLoss( self.Models, set );

    self.CVTiming.(set) = calcCVParameters( self.Models, 'Timing', set );

    if ~self.RetainAllParameters
        self.CVLoss.(set) = rmfield( self.CVLoss.(set), 'All' );
        self.CVTiming.(set) = rmfield( self.CVTiming.(set), 'All' );
    end
   
end