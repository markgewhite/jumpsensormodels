function [pValues, KS, critValues] = kolmogorovSmirnov( model )
    % Calculate the KS test predictors of a linear model
    arguments
        model       LinearModel
    end

    % Set the predictor matrix, ensure only predictor variables are included
    X = table2array(model.Variables(:, model.PredictorNames));

    % Number of predictors
    p = width(X);

    % Initialize
    pValues = zeros(p, 1);
    KS = zeros(p, 1);
    critValues = zeros(p, 1);

    % Calculate for each predictor
    for i = 1:p
        [~, pValues(i), KS(i), critValues(i)] = kstest( X(:,i) );
    end
    
end
