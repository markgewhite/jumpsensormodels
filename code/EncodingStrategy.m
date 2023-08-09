classdef EncodingStrategy < handle
    % Super class for feature encoding algorithms

    properties
        NumFeatures     % number of features
    end

    methods
        
        function self = EncodingStrategy
            % Initialize the model

        end


    end

    methods(Abstract)

        features = extractFeatures(self, X, ZDim);

    end

end