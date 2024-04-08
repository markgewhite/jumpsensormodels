classdef CombinedEncodingStrategy < EncodingStrategy
    % Class that combines discrete and continuous features

    properties
        DiscreteEncodingMethod
        ContinuousEncodingMethod
    end


    methods

        function self = CombinedEncodingStrategy( args )
            % Initialize the encoding
            arguments
                args.DiscreteEncodingArgs       struct
                args.ContinuousEncodingArgs     struct
            end

            self = self@EncodingStrategy( 'TBD' );

            if isfield(args, 'DiscreteEncodingArgs')
                discArgsCell = namedargs2cell(args.DiscreteEncodingArgs);
            else
                discArgsCell = {};
            end
            self.DiscreteEncodingMethod = DiscreteEncodingStrategy( discArgsCell{:} );

            if isfield(args, 'ContinuousEncodingArgs')
                contArgsCell = namedargs2cell(args.DiscreteEncodingArgs);
            else
                contArgsCell = {};
            end
            self.ContinuousEncodingMethod = FPCAEncodingStrategy( contArgsCell{:} );

            % update the names of the features
            self.Names = horzcat( self.DiscreteEncodingMethod.Names, ...
                            self.ContinuousEncodingMethod.Names );

        end


        function self = fit( self, thisDataset )
            % Perform FPCA and other preprocessing
            % (Not required for discrete)
            arguments
                self                CombinedEncodingStrategy
                thisDataset         ModelDataset
            end

            self.SamplingFreq = thisDataset.SampleFreq;

            self.ContinuousEncodingMethod.fit( thisDataset );

        end


        function [Z, offsets] = extractFeatures( self, thisDataset )
            % Extract both discrete and continuous features
            arguments
                self                CombinedEncodingStrategy
                thisDataset         ModelDataset
            end

            [ZD, offsetD] = self.DiscreteEncodingMethod.extractFeatures( thisDataset );

            [ZC, offsetC] = self.ContinuousEncodingMethod.extractFeatures( thisDataset );

            Z = [ZD ZC];
            offsets = floor(mean( [offsetD offsetC], 2 ));

        end


    end

end
