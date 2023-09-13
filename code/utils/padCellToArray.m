function X = padCellToArray( XCell )
    % Create a padded array from a cell array
    % using a standard set of parameters
    arguments
        XCell           cell
    end

    X = padData( XCell, 0, 0, ...
                 Longest = true, ...
                 Same = true, ...
                 Location = 'Right' );

end
    