classdef Investigation < handle
    % Class defining a model investigation, a grid search

    properties
        Name                % name of the investigation
        Path                % file path for storing results
        NumParameters       % number of search parameters
        SearchDims          % dimensions of the parameter search
        Parameters          % named parameters
        GridSearch          % the grid search values for those parameters
        BaselineSetup       % structure recording the baseline
        Setups              % structure of all individual evaluations
        NumEvaluations      % total number of grid searches
        EvaluationNames     % names of all evaluations
        Evaluations         % array of evaluation objects
        IsComplete          % whether the evaluations were completed successfully
        ErrorMessages       % record of error messages returned
        TrainingResults     % structure summarising results from evaluations
        ValidationResults   % structure summarising results from evaluations
        CatchErrors         % flag indicating if try-catch should be used
        SaveEvaluations     % whether to save evaluations as investigation progresses
    end


    methods

        function self = Investigation( name, path, parameters, ...
                                       searchValues, setup, ...
                                       catchErrors, saveEvaluations )
            % Construct an investigation comprised of evaluations
            arguments
                name            string
                path            string
                parameters      string
                searchValues
                setup           struct
                catchErrors     logical = false
                saveEvaluations logical = false
            end

            % initialize properties
            self.Name = name;
            self.Path = path;
            self.CatchErrors = catchErrors;
            self.SaveEvaluations = saveEvaluations;

            % create a folder for this investigation
            setup.model.args.path = fullfile( path, name );
            if ~isfolder( setup.model.args.path )
                mkdir( setup.model.args.path )
            end

            self.BaselineSetup = setup;
            self.Parameters = parameters;
            self.GridSearch = searchValues;

            % setup the grid search
            self.NumParameters = length( parameters );
            self.SearchDims = cellfun( @length, self.GridSearch ); 
            self.NumEvaluations = prod( self.SearchDims );
            self.IsComplete = false( self.NumEvaluations, 1 );
            self.ErrorMessages = strings( self.NumEvaluations, 1 );

            % initialize evaluation arrays 
            if length( self.SearchDims ) > 1
                allocation = self.SearchDims;
            else
                allocation = [ self.SearchDims, 1 ];
            end

            self.Evaluations = cell( allocation );
            self.EvaluationNames = strings( allocation );
            self.Setups = cell( allocation );

            for i = 1:self.NumEvaluations
        
                idx = getIndices( i, self.SearchDims );
                idxC = num2cell( idx );

                self.EvaluationNames( idxC{:}) = strcat( self.Name, constructName(idx) );

                % apply the respective settings
                self.Setups{ idxC{:} } = self.BaselineSetup;
                for j = 1:self.NumParameters
        
                    self.Setups{ idxC{:} } = applySetting( ...
                                                    self.Setups{ idxC{:} }, ...
                                                    self.Parameters{j}, ...
                                                    self.GridSearch{j}(idx(j)) );
                
                end               
           
            end
            
        end           


        % class methods

        self = aggregateResults( self, d )

        evaluateAll( self )

        datasets = getDatasets( self, args )

        [QTrn, QVal] = getEvaluationValue( self, fld )

        grid = getGridIndices( self, i )

        [trnTbl, valTbl] = getMeanAndSD( self, args )

        results = getMultiVarTable( self, flds, set, args )
        
        report = getResults( self )

        value = getResultArray( self, fld, set )

        [model, data] = linearModel( self, outcome, args )

        obj = makeBoxPlot( self, ax, fld, set )

        [model, data] = mixedModel( self, outcome, args )

        reload( self )

        run( self )

        save( self )

        report = saveReport( self )

    end

end