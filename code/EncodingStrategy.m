classdef EncodingStrategy < handle
    % Super class for feature encoding algorithms

    properties
        NumFeatures     % number of features
    end

    methods
        
        function self = EncodingStrategy( numFeatures )
            % Initialize the overarching encoding strategy 
            arguments
                numFeatures     double {mustBeInteger, mustBePositive}
            end

            self.NumFeatures = numFeatures;

        end


    end

    methods(Abstract)

        features = extractFeatures(self, X, ZDim);

    end

end