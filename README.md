# ML-Challenge

## Setting up
>Before start using the software is necessary to extract all compressed files.

## Program
>The parse_json.m has the functions for the conversion of the json files.
The user_gender_predictor.m is responsible for do the training, testing 
the accuracy, and make the prediction of the target. After finishing 
each section of the code the processed data, the variables are saved 
in mat files, which can be loaded in the workspace, to avoid having 
to restart all the process again, taking in consideration that the 
processing of the data takes a considerable amount of time. For speeding 
up the process in the matlab is allocated memory previously by creating 
empty vector.

## Data
>In the data files the only lines from which can be directly obtained 
any relevant information, are the lines which contain a pid 
(product id), therefore all other lines are ignored.

## Training
>The training use the data from the products page view, getting the product 
id (pid), which is used get the category, subcategory, subsubcategory from 
the catalog. Using the information acquired is created is created a table
for the training of the model. The table has 5 columns: gender, product, 
category, subcategory and subsubcategory. The category, subcategory and 
subsubcategory are used as predictors and the gender as response.

## Prediction
>To predict the gender of each user is made a prediction for each product 
purchase by the same and taking in consideration the quantity, if there
is the same number of predictions to female and male the gender is 
defined as male as there a more data with the gender male in the file 
making that there are more chances of the user being male.

## Test
>To test the accuracy of the prediction is used the data from the purchases 
of the users on the data file. All data is sorted by uid (user id), putting
all the products purchased by the user together and creating a table with 
the pid, category, subcategory, subsubcategory and quantity of each product. 
After sorting the data is made a prediction of the gender of each user and 
is created a table with the uid and the predicted gender. The accuracy is 7
verified by comparing the predicted gender and the actual gender of the user, 
giving the percentage of correct predictions.

## Target
>The determination of the gender of the users on the target is made similarly 
to the the test, the only difference is that all the data with product id is 
used, that is the purchases and the products page view, instead of using 
only the purchases as in the test. To make all data have the same attributes 
in the prediction is considered that each product page view is equal to a 
purchase of 1 unit of a product, this is made to have more data to make the 
prediction and to ensure that even in case of that a user didn't make an 
purchase he will be analyzed by the program.
