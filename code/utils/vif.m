function VIF = vif( model )
    % Calculate the VIFs for a linear model (written by GPT-4)
    arguments
        model       LinearModel
    end

    % Set the predictor matrix, ensure only predictor variables are included
    X = table2array(model.Variables(:, model.PredictorNames));

    % Number of predictors
    p = width(X);

    % Initialize VIF vector
    VIF = zeros(p, 1);

    % Suppress specific warning about rank deficiency
    warning('off', 'stats:regress:RankDefDesignMat');

    % Calculate VIF for each predictor
    for i = 1:p
        % Define the target and predictor variables for the ith variable
        targetVar = X(:, i);
        predictorVars = X(:, setdiff(1:p, i));
        
        % Fit the regression model: targetVar = B0 + B1*predictorVars + e
        [~,~,~,~,stats] = regress(targetVar, [ones(size(predictorVars, 1), 1) predictorVars]);
        
        % R-squared value
        Rsq = stats(1);
        
        % Calculate VIF
        VIF(i) = 1 / (1 - Rsq);
    end

    % Re-enable the rank deficiency warning
    warning('on', 'stats:regress:RankDefDesignMat');
    
end
