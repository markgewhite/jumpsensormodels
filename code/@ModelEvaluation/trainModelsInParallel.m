function trainModelsInParallel( self, modelSetup )
    % Run the cross-validation training loop
    arguments
        self                ModelEvaluation
        modelSetup          struct
    end

    % prepare the bespoke arguments
    try
        argsModel = namedargs2cell( modelSetup.args );
    catch
        argsModel = {};
    end

    % setup the data sets in series and initialize the models
    if self.Verbose
        disp('Initializing data partitions and models ...');
    end
    
    thisTrnSet = cell( self.NumModels, 1 );
    thisValSet = cell( self.NumModels, 1 );
    for k = 1:self.NumModels

        switch self.CVType
            case 'Holdout'
                % set the training and holdout data sets
                thisTrnSet{k} = self.TrainingDataset;
                thisValSet{k} = self.ValidationDataset;
            case 'KFold'
                % set the kth partitions
                thisTrnSet{k} = self.TrainingDataset.partition( self.Partitions(:,k) );
                thisValSet{k} = self.TrainingDataset.partition( ~self.Partitions(:,k) );
        end

        % initialize the model
        if self.NumModels > 1
            foldName = [char(self.Name) '-Fold' num2str( k, '%02d' )];
        else
            foldName = self.Name;
        end
        self.Models{k} = modelSetup.class( thisTrnSet{k}, ...
                                           argsModel{:}, ...
                                           Name = foldName );
        
    end
    
    % take copies of variables for first-level slicing
    numModels = self.NumModels;
    models = self.Models;
    randomSeedResets = self.RandomSeedResets;
    randomSeed = self.RandomSeed;
    verbose = self.Verbose;

    % run the cross validation loop in parallel
    parfor k = 1:numModels
    
        if randomSeedResets && ~isempty( randomSeed )
            % reset the random seed for the model
            rng( randomSeed );
        end

        % train the model and time it
        if verbose
            disp(['Fold ' num2str(k) '/' num2str(numModels) ...
                    ': Evaluating the model in parallel ...']);
        end
        tStart = tic;
        models{k}.train( thisTrnSet{k} );
        models{k}.Timing.Training.TotalTime = toc(tStart);

        % evaluate the model
        tStart = tic;
        models{k}.evaluate( thisTrnSet{k}, thisValSet{k} );
        models{k}.Timing.Validation.TotalTime = toc(tStart);

    end

    % store all models
    self.Models = models;

end