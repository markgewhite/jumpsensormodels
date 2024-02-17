classdef EncodingStrategy < handle
    % Super class for feature encoding algorithms

    properties
        Names           % names of the features
        SamplingFreq    % sampling frequency
    end

    methods
        
        function self = EncodingStrategy( names )
            % Initialize the overarching encoding strategy 
            arguments
                names               string
            end

            self.Names = names;
                
        end


    end

    methods(Abstract)

        fit( self, thisDataset )

        features = extractFeatures(self, thisDataset);

    end

end