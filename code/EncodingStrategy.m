classdef EncodingStrategy < handle
    % Super class for feature encoding algorithms

    properties
        NumFeatures     % number of features
    end

    methods
        
        function self = EncodingStrategy( numFeatures )
            % Initialize the model
            arguments 
                numFeatures         double ...
                    {mustBeInteger, mustBePositive}
            end

            self.NumFeatures = numFeatures;

        end


    end

    methods(Abstract)

        fitModel( self ) 
        features = extractFeatures(self, X, ZDim);

    end

end