function exportTableToLatex( tbl, filename )
    % Export a table to latex format - written by GPT4
    arguments
        tbl         table
        filename    char
    end

    % Open file to write
    filename = [filename '.tex'];
    fid = fopen(filename, 'w');
    
    % Check if file is opened successfully
    if fid == -1
        error('Failed to open file: %s', filename);
    end
    
    % Construct the column format specifier dynamically based on table width
    colFormat = repmat('C', 1, width(tbl));
    headerFormat = strjoin(arrayfun(@(x) '\\textbf{%s}', 1:width(tbl), 'UniformOutput', false), ' & ');
    
    % Begin tabularx environment
    fprintf(fid, '\\begin{tabularx}{\\textwidth}{%s}\n', colFormat);
    fprintf(fid, '\\toprule\n');
    fprintf(fid, [headerFormat '\\\\\n'], tbl.Properties.VariableNames{:});
    fprintf(fid, '\\midrule\n');
    
    % Loop through each row of the table
    for i = 1:height(tbl)
        dataFormat = strjoin(arrayfun(@(x) '%s', 1:width(tbl), 'UniformOutput', false), ' & ');
        fprintf(fid, [dataFormat '\\\\\n'], tbl{i,:});
    end
    
    % End tabularx environment
    fprintf(fid, '\\bottomrule\n');
    fprintf(fid, '\\end{tabularx}\n');
    
    % Close file
    fclose(fid);
    
    % Inform the user
    fprintf('LaTeX table code has been written to %s\n', filename);
end
