classdef FPCAEncoding < Encoding
    % Class for features based on functional principal component analysis

    properties  
        XSmooth
        Offsets
        Correlations
        MSE
    end

    methods

        function self = FPCAEncoding( thisDataset, numAlignments )
            % Initialize the model
            arguments 
                thisDataset         ModelDataset
                numAlignments       double
            end

            XSmth = funcSmoothData( thisDataset.X );

            XAligned = XSmth;
            allOffsets = zeros( size(XSmth,2), numAlignments );
            allR = zeros( size(XSmth,2), numAlignments );
            mse = zeros( numAlignments, 1 );
            for i = 1:numAlignments
                [XAligned, offsets, allR(:,i), mse(i)] = ...
                            alignCurves( XAligned, Reference = 'Random' );
                allOffsets(:,i) = offsets - mean(offsets);
            end

            self = self@Encoding( thisDataset );

            self.XSmooth = XAligned;
            self.Offsets = allOffsets;
            self.Correlations = allR;
            self.MSE = mse;
            %self.Features = self.extractFeatures( X );

        end

    end

end