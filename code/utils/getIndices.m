function idx = getIndices( i, dims )
    % Convert counter to set of indices based on dimensions
    arguments
        i       double
        dims    double
    end

    if i>prod(dims)
        error('Requested index exceeds dimensions.');
    end

    dims = fliplr( dims );
    nDim = length( dims );
    idx = zeros( 1, nDim );
    for k = 1:nDim-1
        base = prod( dims(k+1:end) );
        idx(k) = ceil( i/base );
        i = mod( i, base );
        if idx(k)==0
            idx(k) = dims(k);
        end
    end
    if i==0
        idx(nDim) = dims(nDim);
    else
        idx(nDim) = i;
    end
    idx = fliplr( idx );

end