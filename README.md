# Models of human jump performance based on data from inertial sensors
*A collaboration between Swansea University and the University of Rome, "Foro Italico"*

Code supporting the paper submitted to Journal of Mathematics:

### **Wearable Sensors for Athletic Performance: A Comparison of Discrete and Continuous Feature Extraction Methods for Prediction Models**

*By Mark White ([markgewhite@gmail.com](mailto:markgewhite@gmail.com)), Beatrice De Lazari, Neil Bezodis and Valentina Camomilla*

## Overview
This code supports the investigation comparing the efficacy of using discrete and continuous feature extraction methods for models predicting external peak power in the countermovement jump, a standard test of athleticism in elite sport. The discrete features are handcrafted, guided by domain expertise, while the continuous features are based on functional principal component analysis. The code supports grid searches varying model and data hyperparameters carrying out the full modelling procedure for every training for the k-fold cross validation procedure. Processing may be run in parallel.

## Requirements
- MATLAB 2023b 
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- System Identification Toolbox

- Parallel Computing Toolbox (optional)
- Curve Fitting Toolbox (manuscript plots)

## Usage

The follow analysis scripts carry out the investigation reported in the paper.

- [analyseLinearModel.m](code/analyseLinearModel.m)
- [analyseLassoModel.m](code/analyseLassoModel.m)
- [analyseSampleSize.m](code/analyseSampleSize.m)
- [analyseFeatureSelection.m](code/analyseFeatureSelection.m)

- [showAlignments.m](code/showAlignments.m)
- [showAlignmentQuality.m](code/showAlignmentQuality.m)
- [showComponents.m](code/showComponents.m)
- [showPredictorDistributions.m](code/showPredictorDistributions.m)

## Class Structure

Grid searches are carried out using the following class structure.

- [Investigation](code/@Investigation) class carries out the grid search for the data and model hyperparameters specified over the values specified for each. At each grid point, it creates an [ModelEvaluation](code/@ModelEvaluation) class object to perform the evaluation. Optionally, the [ParallelInvestigation](code/@ParallelInvestigation) class runs evaluations in parallel.

- [Evaluation](code/@ModelEvaluation) class executes the k-fold cross-validation, creating the [ModelDataset](code/ModelDataset.m), partitioning it, fitting the model to the training set and then evaluating the trained model on the training and validation sets.

- [ModelDataset](code/ModelDataset.m) class defines the common data processing methods and properties for the two datasets in the paper, which are themselves defined as subclasses, [SmartphoneDataset](code/SmartphoneDataset.m) and [AccelerometerDataset](code/AccelerometerDataset.m). 

- [JumpModel](code/JumpModel.m) class defines the peak power model (linear regression, lasso regression, support vector machine or XGBoost), carrying out the full modelling procedure within the training fold (extracting features, fitting the model, making predictions using the model).

- [EncodingStrategy](code/EncodingStrategy.m) is a super class defining the basics of a feature extraction method. It has three subclasses: [DiscreteEncodingStrategy](code/DiscreteEncodingStrategy.m) defines the discrete features defined by Mascia et al. (2023); [FPCAEncodingStrategy](code/FPCAEncodingStrategy.m) defines the continuous features based on functional principal component analysis, including the smoothing and alignment procedures; [CombinedEncodingStrategy](code/CombinedEncodingStrategy.m) invokes both encoding strategies and assembles a hybrid feature set.

## Data

The data files are available from Zenodo:

[https://zenodo.org/records/10975077](https://zenodo.org/records/10975077)

Create a new folder called `data` at the same level as the `code` folder. 



