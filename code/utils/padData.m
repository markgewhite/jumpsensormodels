function XP = padData( X, args )
    % Pad time series to a specified length
    arguments
        X               cell             % arrays of time series
        args.PadLen     double = 0       % padding length (ignored if longest)
        args.PadValue   double = 0       % padding value (ignored if same)
        args.Longest    logical = false  % whether to pad to the longest
        args.Same       logical = false  % whether to pad with same value
        args.Location     char {mustBeMember( args.Location, ...
            {'Left', 'Right', 'Both'} )} = 'Left' % padding location
    end
    
    len = cellfun( @length, X );
    allSameLength = (std(len)==0);
    if args.Longest || args.PadLen==0
        padLen = max( len );
    else
        padLen = args.PadLen;
    end
       
    nObs = length( X );
    nDim = size( X{1}, 2 );
    
    XP = zeros( padLen, nObs, nDim );
    
    for i = 1:nObs
    
        if allSameLength
            XP( :, i, : ) = X{i};

        else
            actualLen = size(X{i}, 1);
            trialLen = min( [ actualLen, padLen] );
        
            if args.Same
                xStart = X{i}(1,:);
                xEnd = X{i}(end,:);
            else
                xStart = repelem( args.PadValue, 1, nDim );
                xEnd = repelem( args.PadValue, 1, nDim );
            end
        
            switch args.Location
    
                case 'Left' 
                    % insert padding at the beginning
                    padLeft = ones( padLen-trialLen, 1 )*xStart;
                    padRight = [];
                    startIdx = actualLen - trialLen+1;
                    endIdx = actualLen;
        
                case 'Right'
                    % insert padding at the end
                    padLeft = [];
                    padRight = ones( padLen-trialLen, 1 )*xEnd;
                    startIdx = 1;
                    endIdx = trialLen;
        
                case 'Both'
                    % insert padding at both ends, roughly evenly
                    startLen = fix( (padLen-trialLen)/2 );
                    padLeft = ones( startLen, 1 )*xStart;
                    padRight = ones( padLen-trialLen-startLen, 1 )*xEnd;
                    startIdx = startLen;
                    endIdx = actualLen - startLen+1;

            end
    
            XP( :, i, : ) = [ padLeft; ...
                                X{i}(startIdx:endIdx, :); ...
                                  padRight ];

        end

    end

end

