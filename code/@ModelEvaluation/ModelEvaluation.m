classdef ModelEvaluation < handle
    % Class defining a model evaluation

    properties
        Name                % name of the evaluation
        Path                % folder for storing results
        BespokeSetup        % structure recording the bespoke setup
        TrainingDataset     % training dataset object
        TestingDataset      % testing dataset object
        KFolds              % number of partitions
        KFoldRepeats        % number of k-fold repetitions
        Partitions          % training dataset k-fold partitions
        CVType              % type of cross-validation
        HasIdenticalPartitions % flag for special case of identical partitions
        NumModels           % number of models
        Models              % trained model objects
        LossFcns            % array of loss function objects
        CVLoss              % structure of cross-validated losses
        CVTiming            % structure of cross-validated execution times
        RandomSeed          % for reproducibility
        RandomSeedResets    % whether to reset the seed for each model
        InParallel          % whether to run the evaluation in parallel
        Verbose             % whether to report updates in the console
    end


    methods


        function self = ModelEvaluation( name, path, setup, args )
            % Construct and run a model evaluation object
            arguments
                name                    string
                path                    string {mustBeFolder}
                setup                   struct
                args.CVType             string ...
                        {mustBeMember( args.CVType, ...
                        {'Holdout', 'KFold'} )} = 'Holdout'
                args.KFolds             double ...
                        {mustBeInteger, mustBePositive} = 1
                args.KFoldRepeats       double ...
                        {mustBeInteger, mustBePositive} = 1
                args.HasIdenticalPartitions logical = false
                args.RandomSeed         double ...
                        {mustBeInteger, mustBePositive} = 1234
                args.RandomSeedResets   logical = false;
                args.InParallel         logical = false;
                args.Verbose            logical = true;
            end

            % store the name for this evaluation and its bespoke setup
            self.Name = name;
            self.Path = path;
            self.BespokeSetup = setup;

            % store other arguments
            self.CVType = args.CVType;
            self.KFolds = args.KFolds;
            self.KFoldRepeats = args.KFoldRepeats;
            self.HasIdenticalPartitions = args.HasIdenticalPartitions;
            self.RandomSeed = args.RandomSeed;
            self.RandomSeedResets = args.RandomSeedResets;
            self.InParallel = args.InParallel;
            self.Verbose = args.Verbose;

            if ~isempty( self.RandomSeed )
                % set random seed for reproducibility
                rng( self.RandomSeed );
            end

            if self.Verbose
                disp('Data setup:')
                disp( setup.data.class );
                if isfield( setup.data, 'args' )
                    disp( setup.data.args );
                end
                disp('Model setup:')
                disp( setup.model.class );
                if isfield( setup.model, 'args' )
                    disp( setup.model.args );
                end
            end

            % prepare the data
            self.initDatasets( setup );
            
            % train the model
            startTime = tic;
            if self.InParallel
                self.trainModelsInParallel( setup.model );
            else
                self.trainModels( setup.model );
            end

            % evaluate the trained model
            self.evaluateModels( 'Training' );
            self.evaluateModels( 'Validation' );           

            self.CVTiming.Training.Mean.TotalEvaluationTime = toc(startTime);
            
            if self.Verbose
                disp(['Total Evaluation Time = ' ...
                    num2str(self.CVTiming.Training.Mean.TotalEvaluationTime)]);
    
                disp('Training evaluation:');
                reportResult( self.CVLoss.Training.Mean );
                disp('Validation evaluation:');
                reportResult( self.CVLoss.Validation.Mean );
            end

        end


        % methods

        save( self )

        saveReport( self )


    end

end