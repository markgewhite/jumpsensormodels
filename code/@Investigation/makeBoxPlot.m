function obj = makeBoxPlot( self, ax, fld, set )
    % Generate one box plots for a given field
    % one box per evaluation
    arguments
        self            Investigation
        ax
        fld             string
        set             {mustBeMember(set, {'Training', 'Validation'})} = 'Training'
    end

    % extract the raw results from a given set 
    value = cellfun( @(mdl) mdl.(fld), ...
                     self.([set 'Results']).Models , ...
                     'UniformOutput', false);

    % flatten each extracted result
    value = cellfun( @(v) reshape(v, 1, numel(v)), value, ...
                     'UniformOutput', false);

    % convert the cell array into a numeric array
    value = cat(1, value{:});

    % create box plot
    obj = boxplot( ax, value, Notch = 'on' );

end