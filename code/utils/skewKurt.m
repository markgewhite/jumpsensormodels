function [s, k] = skewKurt( model )
    % Calculate the skew and kurtosis of predictors of a linear model
    arguments
        model       LinearModel
    end

    % Set the predictor matrix, ensure only predictor variables are included
    X = table2array(model.Variables(:, model.PredictorNames));

    % calculate measures over each predictor
    s = skewness( X, 1, 1 );
    k = kurtosis( X, 1, 1 );
    
end