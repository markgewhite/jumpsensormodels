classdef LassoModel
    properties
        Alpha           % elastic net mixing parameter
        Lambda          % regularization parameter
        Beta            % fitted coefficients
        Intercept       % intercept term
    end

    methods

        function self = LassoModel(X, y, args )
            % Constructor for the LassoModel class
            arguments
                X               table
                y               table
                args.Alpha      double {mustBeInRange(args.Alpha, 0, 1)} = 1
                args.Lambda     double
             end

            X = table2array(X);
            y = table2array(y);
            if isfield(args, 'Lambda')
                [B, fitInfo] = lasso(X, y, 'Alpha', args.Alpha, 'Lambda', args.Lambda);
                bestModel = 1;
                self.Lambda = args.Lambda;
            else
                [B, fitInfo] = lasso(X, y, 'Alpha', args.Alpha);
                [~, bestModel] = min(fitInfo.MSE);
                self.Lambda = fitInfo.Lambda( bestModel );
            end
            self.Alpha = args.Alpha;
            self.Beta = B(:, bestModel);
            self.Intercept = fitInfo.Intercept( bestModel );

        end

        
        function yHat = predict(self, X)
            % Predict method for the LassoModel class
            arguments
                self            LassoModel
                X               double
            end

            yHat = X * self.Beta + self.Intercept;
        
        end
        
    end
end