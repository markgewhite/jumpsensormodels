function self = arrangeComponents( self )
    % Find the optimal arrangement for the sub-model's components
    % by finding the best set of permutations
    arguments
          self        ModelEvaluation
    end

    if strcmp(version, '9.13.0.2116060 (R2022b) Platform Beta')
        return
    end

    aModel = self.Models{1};
    if aModel.ZDimAux > 10
        % astronmical number of permutations
        return
    end
    permOrderIdx = perms( 1:aModel.ZDimAux );
    lb = [ length(permOrderIdx) ones( 1, self.NumModels-1 ) ];
    ub = length(permOrderIdx)*ones( 1, self.NumModels );
    options = optimoptions( 'ga', ...
                            'PopulationSize', 400, ...
                            'EliteCount', 80, ...
                            'MaxGenerations', 1000, ...
                            'MaxStallGenerations', 150, ...
                            'FunctionTolerance', 1E-6, ...
                            'UseVectorized', true, ...
                            'Display', 'off' );

    % pre-compile latent components across the sub-models for speed
    XDim = size( aModel.LatentComponents, 1 );
    latentComp = zeros( XDim, aModel.NumCompLines, ...
                        aModel.ZDimAux, aModel.XChannels, self.NumModels );
    for k = 1:self.NumModels
        latentComp(:,:,:,:,k) = self.Models{k}.LatentComponents;
    end
    
    % setup the objective function
    objFcn = @(p) arrangementError( p, latentComp );
    
    % run the genetic algorithm optimization
    [ componentPerms, componentMSE ] = ...
                        ga( objFcn, self.NumModels, [], [], [], [], ...
                            lb, ub, [], 1:self.NumModels, options );

    % generate the order from list of permutations
    self.ComponentOrder = zeros( self.NumModels, aModel.ZDimAux );
    for k = 1:self.NumModels
        self.ComponentOrder( k, : ) = permOrderIdx( componentPerms(k), : );
    end
    self.ComponentDiffRMSE = sqrt( componentMSE );

end