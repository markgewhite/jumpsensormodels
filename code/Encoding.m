classdef Encoding < handle
    % Super class for feature encoding algorithms

    properties
        Features        % encoded features
    end

    methods
        
        function self = Encoding( thisDataset )
            % Initialize the model
            arguments 
                thisDataset         ModelDataset
            end

            self.Features = [];
            %self.extractFeatures( thisDataset );

        end

    end

    %methods(Abstract)
    %    features = extractFeatures(self, dataset);
    %end

end