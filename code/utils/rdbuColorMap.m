function cmap = rdbuColorMap
    % Define the color values for red, white, and blue
    red = [1, 0, 0];
    white = [1, 1, 1];
    blue = [0, 0, 1];
    
    % Define the positions of the color values
    positions = [0, 0.5, 1];
    
    % Create a color matrix
    colors = [red; white; blue];
    
    % Interpolate the color values to create a smooth colormap
    N = 256;
    cmap = interp1(positions, colors, linspace(0, 1, N));
end
