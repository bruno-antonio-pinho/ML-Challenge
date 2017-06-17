%% Get data from the data file.
clear all;
clc;

fid = fopen('data');
tline = fgetl(fid);
count = 1;
index = 1;

% Create a empty cell variable with the size of the number of lines of
% interest in the data file, in this case the lines that have an 
% product id, to speed up the processing.
training_data = cell(1,569580);


while ischar(tline)
    % Start geting the data from the first line that have an product id.
    if(count >= 1570764)
        training_data(index) = parse_json(tline);
        index = index + 1;
    end
    tline = fgetl(fid);
    count = count + 1;
end
fclose(fid);

% Separate the data in a training set and test set.
% The training set will be used to do the training and have the id of the
% products viwed by the users.
training_set = training_data(1:545617);

% The test set will be used to verify the accuracy of the model produced by
% the training set and have the id of the purchased products. 
test_set = training_data(545618:end);

% Save the variables on a mat file so is not necessary process all the data again. 
save 'training_data.mat' 'training_set' 'test_set'

%% Create a table for the training of the model.
% The table is made from all page views of products and contain: the gender
% of the user wich view the page, the product id, the category, 
% the subcategory and the subsubcategory ids of the product. 

% Create empty vectors to speed up the process.
product  = zeros(545617,40);
labels =  zeros(545617,1);
category =  zeros(545617,40);
subcategory =  zeros(545617,40);
subsubcategory =  zeros(545617,40);

% import the catlog as a table and convert it to a cell;
catalog = readtable('catalog', 'Delimiter', ',');
catalog_cell = table2cell(catalog);


for index = 1:545617
    labels(index,1) =  training_set{1, index}.gender;
    product(index,:) =  training_set{1, index}.productId;
    for pos = 1:19091
        % Search in the catolog for the product id to get the category,
        % subcategory and subsubcategory of that product.
        if(isequal(training_set{1, index}.productId,catalog_cell{pos,1}))
            category(index,:) = catalog_cell{pos,4};
            subcategory(index,:) = catalog_cell{pos,5};
            subsubcategory(index,:) = catalog_cell{pos,6};
            break;
        end
    end
end

training_table = table (char(labels), char(product), char(category), char(subcategory), char(subsubcategory));
training_table.Properties.VariableNames = {'Gender' 'Product' 'Category' 'Subcategory' 'Subsubcategory'};
% Naive Bayes to create the model and use the category, subcategory and
% subsubcategory to do the training.
model = fitcnb(training_table(:,3:end), training_table(:,1));
save 'trained_model.mat' 'training_table' 'model'

%% Sort the test data by the user id.
sorted_test = struct;
for index = 1:23963
    if(index > 1)
        % Verify if the user entry already exist.
        for(pos = 1:size(sorted_test,2))
            % In case the user entry already exist just add the purchased
            % products to a new position on the predictors struct.
            if(test_set{1,index}.uid == sorted_test(pos).uid)
                sorted_test(pos).predictors(end+1).products = test_set{1, index}.products;
                break;
                
            % In case the user don't exist, create a new entry.
            elseif(pos == size(sorted_test,2))
                sorted_test(pos+1).uid = test_set{1, index}.uid;
                sorted_test(pos+1).gender = test_set{1, index}.gender;
                sorted_test(pos+1).predictors(1).products = test_set{1, index}.products;
            end
        end
        
    % Create the first user entry. 
    else
        sorted_test(index).uid = test_set{1, index}.uid;
        sorted_test(index).gender = test_set{1, index}.gender;
        sorted_test(index).predictors(1).products = test_set{1, index}.products;
    end
end

% Save the variable on a mat file.
save 'sorted_test.mat' 'sorted_test'

%% Create a table to make the predictions.
% Create empty vectors to speed up the process.
uid  = char(14325,40);
product  = char(300000,40);
labels =  char(14325,1);
category =  char(300000,40);
subcategory =  char(300000,40);
subsubcategory =  char(300000,40);
quantity =  zeros(300000,1);
teste_bench = cell(1,14325);

for index = 1:14325
    uid(index,1:40) = sorted_test(index).uid;
    labels(index,1) =  sorted_test(index).gender;
    
    % Search in the catolog for each product purchased by user for 
    % the category, subcategory and subsubcategory of that product.
    for k = 1:size(sorted_test(index).predictors,2)
        for c = 1:size(sorted_test(index).predictors(k).products,2)
            for pos = 1:19091
                if(isequal(sorted_test(index).predictors(k).products{1,c}.pid,catalog_cell{pos,1}))
                    product(k*c,1:40) =  sorted_test(index).predictors(k).products{1,c}.pid;
                    category(k*c,1:40) = catalog_cell{pos,4};
                    subcategory(k*c,1:40) = catalog_cell{pos,5};
                    subsubcategory(k*c,1:40) = catalog_cell{pos,6};
                    quantity(k*c,1) = sorted_test(index).predictors(k).products{1,c}.quantity;
                    break;
                end
            end
        end
    end
    % Make an auxiliar cell with the data of the purchases of the user
    % so it can be converted to a table tomake the prediction.
    aux = cell(k*c,5);
    for tmp = 1:k*c
        aux{tmp,1} = char(product(tmp,:));
        aux{tmp,2} = char(category(tmp,:));
        aux{tmp,3} = char(subcategory(tmp,:));
        aux{tmp,4} = char(subsubcategory(tmp,:));
        aux{tmp,5} = quantity(tmp,:);
    end
    
    predictors_table = cell2table(aux);
    predictors_table.Properties.VariableNames = {'Product' 'Category' 'Subcategory' 'Subsubcategory' 'Quantity'};
    teste_bench{1,index}.uid = uid(index,:);
    teste_bench{1,index}.gender = labels(index,:);
    teste_bench{1,index}.predictors = predictors_table;
end

save 'teste_bench.mat' 'teste_bench'


%% Make the prediction of the gender for each user on the test set.

% Create empty char vectors to speed up the process.
uid = char(zeros(14325,40));
gender = char(zeros(14325,1));

for index = 1:14325
     uid(index,:) = teste_bench{1, index}.uid;
     m = 0;
     f = 0;
      
     for k = 1:size(teste_bench{1,index}.predictors(:,2:4),1)
        % Make a prediction for each product purchase and add the
        % quantity purchased for the counter m or f.
        if(isequal(predict(model,teste_bench{1,index}.predictors(k,2:4)),'M'))
            m = m + table2array(teste_bench{1,index}.predictors(k,5));
        else
            f = f + table2array(teste_bench{1,index}.predictors(k,5));
        end
     end
     % Determine the gender based on the value of the counters, based on
     % the fact that there is more males on the data file in case the counters
     % have the same value, there is a greater chance that the user is male.
     if (m >= f)
        gender(index,1) = 'M';
     else
        gender(index,1) = 'F';
     end
end
% Create a table with the uid and the predicted gender.
predicted_table = table (uid, gender);
% Save the table on a mat file.
save 'predicted_table.mat' 'predicted_table'

%% Calculate the accuracy of the test prediction.
c = 0;
e = 0;
for index = 1:14325
     if(isequal(gender(index,1), teste_bench{1, index}.gender))
         c = c+1;
     else 
         e = e + 1;
     end
end
P = c*100/(c+e)

%% Get data from the target file.

fid = fopen('target');
tline = fgetl(fid);
count = 1;
index = 1;
% Create a empty cell variable with the size of the number of lines of
% interest to speed up the processing.
data_target = cell(1,107455);


while ischar(tline)
    aux = parse_json(tline);
    
    % Save only the lines that has a product id, the pruchases and the 
    % page view of products.
    if(isequal(aux{1,1}.event_type,'purchase'))
        data_target(index) = aux;
        index = index + 1;
    elseif (isfield(aux{1,1}, 'page_type'))
        if(isequal(aux{1,1}.page_type,'product'))
            data_target(index) = aux;
            index = index + 1;
        end
    end
    tline = fgetl(fid);
end
fclose(fid);

% Save the variable on a mat file so is not necessary process all the data again. 
save 'data_target.mat' 'data_target'

%% Sort the target data by the user id.
sorted_target = struct;
products = cell(1);

for index = 1:107455
    if(index > 1)
         % Verify if the user entry already exist.
        for(pos = 1:size(sorted_target,2))
            % In case the user already exist.
            if(data_target{1,index}.uid == sorted_target(pos).uid)
                % Veirify if the new entry is a page view.
                if(isequal(data_target{1,index}.event_type, 'pageview'))
                    % Create cell with the pid, consider the qauntity
                    % equal to 1 and add to the predictors, this is for all
                    % entries having the same atributes for the prediction.
                    products{1,1}.pid = data_target{1, index}.productId;
                    products{1,1}.quantity = 1;
                    sorted_target(pos).predictors(end+1).products = products;
                else
                    % If it's a purchase add  to the predictor
                    sorted_target(pos).predictors(end+1).products = data_target{1, index}.products;
                end
                break;
               
           
            elseif(pos == size(sorted_target,2))
                % Add a new entry to the sorted_target.
                sorted_target(pos+1).uid = data_target{1, index}.uid;
                if(isequal(data_target{1,index}.event_type, 'pageview'))
                    products{1,1}.pid = data_target{1, index}.productId;
                    products{1,1}.quantity = 1;
                    sorted_target(pos+1).predictors(1).products = products;
                else
                    sorted_target(pos+1).predictors(1).products = data_target{1, index}.products;
                end
            end
        end
        
    else
        % Create the first entry
        sorted_target(index).uid = data_target{1, index}.uid;
        if(isequal(data_target{1,index}.event_type, 'pageview'))
            products{1,1}.pid = data_target{1, index}.productId;
            products{1,1}.quantity = 1;
            sorted_target(index).predictors(1).products = products;
        else
            sorted_target(index).predictors(1).data_target = test_set{1, index}.products;
        end
    end
end

save 'sorted_target.mat' 'sorted_target'

%% Create a table to make the predictions.
uid  = zeros(3209,40);
product  = zeros(300000,40);
category =  zeros(300000,40);
subcategory =  zeros(300000,40);
subsubcategory =  zeros(300000,40);
quantity =  zeros(300000,1);
target = cell(1,3209);

for index = 1:3209
    uid(index,1:40) = sorted_target(index).uid;
    
    % Search in the catolog for each product purchased by user for 
    % the category, subcategory and subsubcategory of that product.
    for k = 1:size(sorted_target(index).predictors,2)
        for c = 1:size(sorted_target(index).predictors(k).products,2)
            for pos = 1:19091
                if(isequal(sorted_target(index).predictors(k).products{1,c}.pid,catalog_cell{pos,1}))
                    product(k*c,1:40) =  sorted_target(index).predictors(k).products{1,c}.pid;
                    category(k*c,1:40) = catalog_cell{pos,4};
                    subcategory(k*c,1:40) = catalog_cell{pos,5};
                    subsubcategory(k*c,1:40) = catalog_cell{pos,6};
                    quantity(k*c,1) = sorted_target(index).predictors(k).products{1,c}.quantity;
                    break;
                end
            end
        end
    end
    % Make an auxiliar cell with the data of the purchases of the user
    % so it can be converted to a table tomake the prediction.
    aux = cell(k*c,5);
    for tmp = 1:k*c
        aux{tmp,1} = char(product(tmp,:));
        aux{tmp,2} = char(category(tmp,:));
        aux{tmp,3} = char(subcategory(tmp,:));
        aux{tmp,4} = char(subsubcategory(tmp,:));
        aux{tmp,5} = quantity(tmp,:);
    end
    predictors_table = cell2table(aux);
    predictors_table.Properties.VariableNames = {'Product' 'Category' 'Subcategory' 'Subsubcategory' 'Quantity'};
    target{1,index}.uid = uid(index,:);
    target{1,index}.predictors = predictors_table;
end
save 'target.mat' 'target'

%% Make the prediction of the gender for each user on the target.
uid = char(zeros(3209,40));
gender = char(zeros(3209,1));
for index = 1:3209
     uid(index,:) = target{1, index}.uid;
     m = 0;
     f = 0;
     
     % Make a prediction for each product purchase and add the
     % quantity purchased for the counter m or f.
     for k = 1:size(target{1,index}.predictors(:,2:4),1)
        if(isequal(predict(model,target{1,index}.predictors(k,2:4)),'M'))
            m = m + table2array(target{1,index}.predictors(k,5));
        else
            f = f + table2array(target{1,index}.predictors(k,5));
        end
     end
     
     % Determine the gender based on the value of the counters, based on
     % the fact that there is more males on the data file in case the counters
     % have the same value, there is a greater chance that the user is male.
     if (m >= f)
        gender(index,1) = 'M';
     else
        gender(index,1) = 'F';
     end
end

% Create atable with the uid and the predicted gender.
target_predicted_table = table (uid, gender);
% Save the table with the uid and the predicted gender on a csv
writetable(target_predicted_table, 'Answer.csv')
