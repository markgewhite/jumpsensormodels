classdef FPCAEncoding < Encoding
    % Class for features based on functional principal component analysis

    properties 
        XSmooth
        Offsets
        Correlations
    end

    methods

        function self = FPCAEncoding( thisDataset )
            % Initialize the model
            arguments 
                thisDataset         ModelDataset
            end

            [XFd, XSmth] = funcSmoothData( thisDataset.X );

            XAligned = alignCurves( XSmth, Reference = 'Random' );

            self = self@Encoding( thisDataset );

            self.XSmooth = XAligned;
            self.Offsets = allOffsets;
            self.Correlations = allR;
            %self.Features = self.extractFeatures( X );

        end

    end

end