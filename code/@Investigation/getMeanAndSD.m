function [trnTbl, valTbl] = getMeanAndSD( self, fld, args )
    % Combine Mean and SD into one tables of strings
    arguments
        self                Investigation
        fld                 char
        args.Reshape        double ...
            {mustBeNonnegative, mustBeInteger} = 1
        args.Format         string = '%1.3f'
    end

    trnTbl = combineArrays( self.TrainingResults.Mean.(fld), ...
                            self.TrainingResults.SD.(fld), ...
                            args.Reshape, ...
                            args.Format );

    try
        valTbl = combineArrays( self.ValidationResults.Mean.(fld), ...
                                self.ValidationResults.SD.(fld), ...
                                args.Reshape, ...
                                args.Format );
    catch
        valTbl = [];
    end


end


function tbl = combineArrays( mn, sd, d, format )
    % Generate the combined table
    arguments
        mn      double
        sd      double
        d       double 
        format  char
    end

    if size(mn)~=size(sd)
        error('Mean and SD arrays are not the same size');
    end

    mn = make2D( mn, d );
    sd = make2D( sd, d );

    formatFcn = @(s) string(num2str( s, format ));

    [ rows, cols ] = size( mn );
    valstr = strings( rows, cols );
    for i = 1:rows
        for j = 1:cols
            valstr(i,j) = strcat( formatFcn(mn(i,j)), ...
                              " ", char(177), " ", ...
                              formatFcn(sd(i,j)) );
        end
    end
    tbl = array2table( valstr );

end


function x1 = make2D( x0, d )

    shape = size( x0 );

    x1 = reshape( x0, shape(d), [] );

end


