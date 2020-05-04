library(mosaic)
library(tidyverse)
library(ggplot2)
library(randomForest)
library(pdp)
library(lubridate)
library(naniar)
library(rpart)
library(dplyr)
library(fastDummies)
library(class)

bank = read_delim("bank-additional-full.csv", delim = ";")
bank10 = read_delim("bank-additional.csv", delim = ";")

# get rid of observations that have unknowns
# bank10 %>% mutate_if(is.character, list(~na_if(., "unknown"))) %>% na.omit()
bank10 <- bank10 %>% replace_with_na_all(condition = ~.x == "unknown")
bank10 <-bank10[complete.cases(bank10), ] # went from 4119 to 3090 obs
  
# add dummy variables for housing, loan, target variable
bank10 = mutate(bank10, 
              default = ifelse(default == "yes", 1, 0),
              housing = ifelse(housing == "yes", 1, 0),
              loan = ifelse(loan == "yes", 1, 0),
              y = ifelse(y == "yes", 1, 0))

# convert the y to a factor to do classification for random forests??
# bank10$y= as.factor(bank10$y)

# training and testing sets
n = nrow(bank10)
n_train = floor(0.8*n)
n_test = n - n_train
train_cases = sample.int(n, size=n_train, replace=FALSE)

bank10_train = bank10[train_cases,]
bank10_test = bank10[-train_cases,]

y_all = bank10$y
x_all = model.matrix(~.-y -duration, data=bank10)
# x_all = model.matrix(~housing + 
#                        loan + campaign +
#                        age + default +
#                        cons.conf.idx+ job + marital +
#                        education + contact + month +
#                        day_of_week + campaign + pdays+
#                        cons.price.idx+ poutcome, data=bank10)


y_train = y_all[train_cases]
x_train = x_all[train_cases,]

y_test = y_all[-train_cases]
x_test = x_all[-train_cases,]

# fit the RF model with default parameter settings
bank_forest1 = randomForest(x=x_train, y=y_train, xtest=x_test, keep.forest = TRUE)
yhat_test = (bank_forest1$test)$predicted

# bank_forest1 = randomForest(y ~ .-duration, data=bank10)

yhat_test = predict(bank_forest1, bank10)
plot(yhat_test, y_test)

# RMSE
# get 0.2995064
(yhat_test - y_test)^2 %>% mean %>% sqrt

plot(bank_forest1)
imp <- varImpPlot(bank_forest1)

# what's the actual effect of each variable on y?
# FOR SOME REASON, CANNOT GET pdp::partial TO WORK. ## debug
# bankp1 = pdp::partial(bank_forest1, train = bank10, pred.var = "euribor3m")
# bankp1
# plot(bankp1)

# try KNN
# Build a KNN classifier using all the available features
# Notes:
# 1) Remember to scale your X's!
# 	1b) remember to scale the test-set X's by the same factor as the training set!
# 2) choose K to optimize out-of-sample error rate
# 3) average over multiple train/test splits to minimize the effect of Monte Carlo variability

# convert to dummy variables for categorical
bank10dum <- fastDummies::dummy_cols(bank10)

X = Filter(is.numeric, bank10dum) %>% dplyr::select(-y, -duration)
y = bank10dum$y
n = length(y)

# check for missing values
bank10dum[!complete.cases(bank10dum),]
bank10dum <- na.omit(bank10dum)

View(bank10dum)
# select a training set
n_train = round(0.8*n)
n_test = n - n_train
train_ind = sample.int(n, n_train)
X_train = X[train_ind,]
X_test = X[-train_ind,]
y_train = y[train_ind]
y_test = y[-train_ind]

# scale the training set features
scale_factors = apply(X_train, 2, sd)
X_train_sc = scale(X_train, scale=scale_factors)

# scale the test set features using the same scale factors
X_test_sc = scale(X_test, scale=scale_factors)


library(foreach)
library(mosaic)

# try just one value and one iteration of K
# Fit two KNN models (notice the odd values of K)
knn3 = class::knn(train=X_train_sc, test= X_test_sc, cl=y_train, k=3)

k_grid = seq(1, 25, by=1)
err_grid = foreach(k = k_grid,  .combine='c') %do% {
  out = do(250)*{
    train_ind = sample.int(n, n_train)
    X_train = X[train_ind,]
    X_test = X[-train_ind,]
    y_train = y[train_ind]
    y_test = y[-train_ind]
    
    # scale the training set features
    scale_factors = apply(X_train, 2, sd)
    X_train_sc = scale(X_train, scale=scale_factors)
    
    # scale the test set features using the same scale factors
    X_test_sc = scale(X_test, scale=scale_factors)
    
    # Fit KNN models (notice the odd values of K)
    knn_try = class::knn(train=X_train_sc, test= X_test_sc, cl=y_train, k=k)
    
    # Calculating classification errors
    sum(knn_try != y_test)/n_test
  } 
  mean(out$result)
}

err_grid

plot(k_grid, err_grid)

