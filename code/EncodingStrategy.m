classdef EncodingStrategy < handle
    % Super class for feature encoding algorithms

    methods
        
        function self = EncodingStrategy
            % Initialize the overarching encoding strategy 

        end


    end

    methods(Abstract)

        features = extractFeatures(self, X, ZDim);

    end

end