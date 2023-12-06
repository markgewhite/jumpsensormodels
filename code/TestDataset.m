classdef TestDataset < ModelDataset
    % Subclass for generating synethic test data

    properties
    end

    methods

        function self = TestDataset( set, superArgs, args )
            % Load the countermovement jump GRF dataset
            arguments
                set                string ...
                    {mustBeMember( set, ...
                            {'Training', 'Testing', 'Combined'} )}
                superArgs.?ModelDataset
                args.NumObs        double = 100
            end

            [ XRaw, Y, SubjectID ] = TestDataset.generate( args.NumObs );

            labels = { 'Acc' };

            % process the data and complete the initialization
            superArgsCell = namedargs2cell( superArgs );

            self = self@ModelDataset( XRaw, Y, SubjectID, ...
                                      superArgsCell{:}, ...
                                      Name = "Test Data", ...
                                      channelLabels = labels, ...
                                      SampleFreq = 250, ...
                                      CutoffFreq = 50);


        end


    end
    

    methods (Static)

        function [ XCell, Y, S ] = generate( N )

            XCell = cell( N, 1 );
            Y = zeros( N, 1 );
            S = zeros( N, 1 );

            t = 0:0.02:2*pi;
            for i = 1:N
                XCell{i} = rand*sin(randn+t)';
                Y(i) = trapz(XCell{i});
                S(i) = i;
            end

       end

   end


end


