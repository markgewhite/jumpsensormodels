function [model, data] = linearModel( self, outcome, args )
    % Make a generalized linear model from the summary results
    arguments
        self            Investigation
        outcome         string
        args.Set        string {mustBeMember( ...
                        args.Set, {'Training', 'Testing'} )} = 'Training'
        args.Distribution   string {mustBeMember( ...
            args.Distribution, {'Normal', 'Binomial', 'Poisson', ...
                        'Gamma', 'Inverse Gaussian'} )} = 'Normal'
        args.Stepwise   logical = true
        args.Criterion   string {mustBeMember( ...
            args.Criterion, {'Deviance', 'SSE', 'AIC', 'BIC', ...
                             'RSquared', 'AdjRSquared'} )} = 'AIC'
        args.AllCategorical logical = true
        args.Interactions   logical = true
    end

    switch args.Set
        case 'Training'
            results = 'TrainingResults';
        case 'Testing'
            results = 'TestingResults';
    end

    % compile the statistical model's training data
    data = [];
    for j = 1:self.NumParameters
        value = extract( self.GridSearch{j}(1), 1 );
        predictor = strrep(self.Parameters(j), '.', '_' );
        predictor = strrep( predictor, 'model_args_', '' );
        data = [ data table( repmat( value, self.NumEvaluations, 1 ), ...
                     VariableNames = predictor) ]; %#ok<AGROW> 
    end
    data = [ data table( zeros( self.NumEvaluations, 1 ), ...
                         VariableNames = outcome ) ];

    for i = 1:self.NumEvaluations

        idx = getIndices( i, self.SearchDims );
        idxC = num2cell( idx );

        % set the predictor variables
        for j = 1:self.NumParameters
            hyperparam = extract( self.GridSearch{j}, idx(j) );
            data{ i, j } = hyperparam;
        end
        % set the outcome variable
        data{ i, end } = self.(results).Mean.(outcome)(idxC{:});

    end

    % retain only those evaluations that were completed
    data = data( self.IsComplete, : );

    if args.AllCategorical
        varNames = data.Properties.VariableNames;
        pred = varfun(@categorical, data(:,1:end-1), 'OutputFormat', 'table');
        data = [pred data(:,end)];
        data.Properties.VariableNames = varNames;
    end

    % fit the model
    if args.Interactions
        modelSpec = 'interactions';
    else
        modelSpec = 'linear';
    end

    if args.Stepwise
        model = stepwiseglm( data, 'constant', ...
                             Upper = modelSpec, ...
                             Distribution = args.Distribution, ...
                             Criterion = args.Criterion, ...
                             Verbose = 2);
    else
        model = fitglm( data, modelSpec, ...
                        Distribution = args.Distribution );
    end

    % make predictions
    data.Prediction = predict( model, data );

end


function w = extract( v, i )

    if iscell(v)
        if islogical(v{i})
            w = logical(v{i});
        else
            w = string(char(v{i}));
        end
    else
        w = v(i);
    end

end