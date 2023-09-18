classdef ParallelInvestigation < Investigation
    % Class defining an investigation grid search run in parallel

    properties
    end

    methods

        function self = ParallelInvestigation( name, path, parameters, ...
                                       searchValues, setup, ...
                                       catchErrors )
            % Construct an investigation comprised of evaluations
            arguments
                name            string
                path            string
                parameters      string
                searchValues
                setup           struct
                catchErrors     logical = false
            end

            setup.eval.args.Verbose = false;

            self@Investigation( name, path, parameters, ...
                                searchValues, setup, ...
                                catchErrors );

        end

    end

end