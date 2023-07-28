classdef FPCAEncoding < Encoding
    % Class for features based on functional principal component analysis

    properties  
        XSmooth
        Offsets
    end

    methods

        function self = FPCAEncoding( thisDataset )
            % Initialize the model
            arguments 
                thisDataset         ModelDataset
            end

            XSmth = funcSmoothData( thisDataset.X );

            [XAligned, offsets] = alignCurves( XSmth );

            self = self@Encoding( thisDataset );

            self.XSmooth = XAligned;
            self.Offsets = offsets;
            %self.Features = self.extractFeatures( X );

        end

    end

end