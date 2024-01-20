classdef EncodingStrategy < handle
    % Super class for feature encoding algorithms

    properties
        SamplingFreq    % sampling frequency
    end

    methods
        
        function self = EncodingStrategy( samplingFreq )
            % Initialize the overarching encoding strategy 
            arguments
                samplingFreq        double = 100
            end

            self.SamplingFreq = samplingFreq;
                
        end


    end

    methods(Abstract)

        fit( self, thisDataset )

        features = extractFeatures(self, thisDataset);

    end

end