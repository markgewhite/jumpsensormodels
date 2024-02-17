classdef EncodingStrategy < handle
    % Super class for feature encoding algorithms

    properties
        Names           % names of the features
        SamplingFreq    % sampling frequency
    end

    methods
        
        function self = EncodingStrategy( names, samplingFreq )
            % Initialize the overarching encoding strategy 
            arguments
                names               string
                samplingFreq        double = 100
            end

            self.SamplingFreq = samplingFreq;
            self.Names = names;
                
        end


    end

    methods(Abstract)

        fit( self, thisDataset )

        features = extractFeatures(self, thisDataset);

    end

end