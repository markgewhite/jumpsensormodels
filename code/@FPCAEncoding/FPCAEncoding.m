classdef FPCAEncoding < Encoding
    % Class for features based on functional principal component analysis

    properties
    end

    methods

        function self = FPCAEncoding( thisDataset )
            % Initialize the model
            arguments 
                thisDataset         ModelDataset
            end

            X = functSmoothData( thisDataset.X, thisDataset.XLen );



            self.Features = self.extractFeatures( thisDataset );

        end

    end

end