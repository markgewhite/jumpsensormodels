function leftSuperTitle(fig, heading, identifier)
    % Create a left-aligned super title above all subplots in the specified figure
    % with part of the title emboldened using LaTeX or TeX formatting.
    arguments
        fig         
        heading     char
        identifier  char
    end

    % Create an empty super title to generate space at top
    sgtitle(fig, ' ');

    % Ensure the new axes are added to the specified figure for the super title
    ha = axes(fig, 'Unit', 'Normalized', 'Position', [0, 0, 1, 1], 'Visible', 'off');

    % Find the leftmost position of the first subplot, considering TightInset
    axesChildren = findobj(fig, 'Type', 'axes');
    % Initialize an array to hold the effective left positions
    effectiveLefts = [];
    for i = 1:length(axesChildren)
        if axesChildren(i) ~= ha % Exclude the super title axes
            pos = axesChildren(i).Position;
            inset = axesChildren(i).TightInset;
            effectiveLeft = pos(1) - inset(1); % Calculate effective left considering TightInset
            effectiveLefts = [effectiveLefts, effectiveLeft]; %#ok<AGROW>
        end
    end
    % Find the minimum effective left position
    minEffectiveLeft = min(effectiveLefts);

    % Construct the title string with LaTeX formatting for the bold part
    fullTitle = ['\bf{(', identifier, ')} \rm', heading];

    % Adjust text position to align with the left outer position of the subplot
    text(ha, minEffectiveLeft, 0.98, fullTitle, 'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', 'Units', 'Normalized', ...
        'Interpreter', 'tex', 'FontSize', 12);
end
