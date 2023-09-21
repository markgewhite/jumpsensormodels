classdef EncodingStrategy < handle
    % Super class for feature encoding algorithms

    methods
        
        function self = EncodingStrategy
            % Initialize the overarching encoding strategy 

        end


    end

    methods(Abstract)

        fit( self, thisDataset )

        features = extractFeatures(self, thisDataset);

    end

end