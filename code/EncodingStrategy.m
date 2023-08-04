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

        fit( self, thisDataset ) 
        features = extractFeatures(self, X, ZDim);

    end

end