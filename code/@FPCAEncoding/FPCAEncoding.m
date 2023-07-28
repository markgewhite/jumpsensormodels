classdef FPCAEncoding < Encoding
    % Class for features based on functional principal component analysis

    properties  
        XSmooth
    end

    methods

        function self = FPCAEncoding( thisDataset )
            % Initialize the model
            arguments 
                thisDataset         ModelDataset
            end

            XSmth = funcSmoothData( thisDataset.X );

            self = self@Encoding( thisDataset );

            self.XSmooth = XSmth;
            %self.Features = self.extractFeatures( X );

        end

    end

end