library(tidyverse)
library(ISLR)
library(glmnet)
library(doMC)  # for parallel computing
library(gamlr)
library(tidyr)
library(dplyr)


greenb = read.csv("~/Desktop/SDS 323/Exercises/Exercise 3/data/greenbuildings.csv")
names(greenb)
# Creat a new dummy variable to identify LEED and Energystar kind of green certification.
greenb <- select(greenb, -CS_PropertyID)
greenb <- greenb %>% 
  mutate(green_t = LEED + Energystar )

greenb <- greenb %>% 
  mutate(green_certification = ifelse(green_t > 0, "1", "0"))

greenb <- select(greenb, -LEED,-Energystar, -green_t ) 
#Forward selection
lm0 = lm(Rent ~ 1, data = greenb)
lm_forward = step(lm0, direction = 'forward',
                  scope =~(cluster + size + empl_gr +  leasing_rate + stories + age + renovated + class_a + class_b + green_certification + green_rating+ net +amenities + cd_total_07 +  hd_total07 + total_dd_07 + Precipitation + Gas_Costs + Electricity_Costs + cluster_rent )^2)


getCall(lm_forward)
coef(lm_forward)
length(coef(lm_forward))

# Ridge Regression and the Lasso
# Create design matrix.  
# trim off the first column
# leaving only the predictors
greenb = na.omit(greenb)
x =  model.matrix(Rent~., greenb)[,-1] 

y = greenb %>% 
  select(Rent) %>% 
  unlist() %>% 
  as.numeric()

#The glmnet() function has an alpha argument that determines what type of model is fit.If alpha = 0 then a ridge regression model is fit, and if alpha = 1 then a lasso model is fit. We first fit a ridge regression model:

# Ridge Regression (let alpha = 0)
grid = 10^seq(10, -2, length = 100)
ridge_mod = glmnet(x, y, alpha = 0, lambda = grid)

#Associated with each value of  λ is a vector of ridge regression coefficients,stored in a matrix that can be accessed by coef(). 
dim(coef(ridge_mod))
plot(ridge_mod)    

ridge_mod$lambda[50]
coef(ridge_mod)[,50]
sqrt(sum(coef(ridge_mod)[-1,50]^2))




predict(ridge_mod, s = 50, type = "coefficients")[1:22,]


#Estimate the test error of ridge regression and the lasso.
# split the samples into a training set and a test set in order to estimate the test error of ridge regression and the lasso.
set.seed(1)
train = greenb %>%
  sample_frac(0.5)

test = greenb %>%
  setdiff(train)

x_train = model.matrix(Rent~., train)[,-1]
x_test = model.matrix(Rent~., test)[,-1]

y_train = train %>%
  select(Rent) %>%
  unlist() %>%
  as.numeric()

y_test = test %>%
  select(Rent) %>%
  unlist() %>%
  as.numeric()



ridge_mod = glmnet(x_train, y_train, alpha=0, lambda = grid, thresh = 1e-12)
ridge_pred = predict(ridge_mod, s = 4, newx = x_test)
mean((ridge_pred - y_test)^2)
#The test MSE is 88.67
MSE = mean((mean(y_train) - y_test)^2)
print(MSE)# Get MSE
#Because we had instead simply fit a model with just an intercept,  we would have predicted each test observation using the mean of the training observations. 
#The test MSE is 217.90


# use cross-validation to choose the tuning parameter λ (function performs 10-fold cross-validation)
set.seed(1)
# Fit ridge regression model on training data
cv.out = cv.glmnet(x_train, y_train, alpha = 0) 

# Select lamda that minimizes training MSE
bestlam = cv.out$lambda.min  
bestlam
#the value of  λ that results in the smallest cross-validation error is 1.16

#  Draw plot of training MSE as a function of lambda
plot(cv.out)
#the test MSE associated with this value of  λ
ridge_pred = predict(ridge_mod, s = bestlam, newx = x_test)
mean((ridge_pred - y_test)^2)
# The test MSE is 85.18

# Compute R^2 from true and predicted values
eval_results <- function(true, predicted, df) {
  SSE <- sum((predicted - true)^2)
  SST <- sum((true - mean(true))^2)
  
  RMSE = sqrt(SSE/nrow(df))
  
  
  # Model performance metrics
  data.frame(
    RMSE = RMSE
   
  )
  
}

# Prediction and evaluation on train data
#predictions_train <- predict(ridge_mod, s = bestlam, newx = x)
#eval_results(y_train, predictions_train, train)

# Prediction and evaluation on test data
predictions_test <- predict(ridge_mod, s = bestlam, newx = x_test)
eval_results(y_test, predictions_test, test)




# Fit ridge regression model on full dataset
out = glmnet(x, y, alpha = 0) 
# Display coefficients using lambda chosen by CV
predict(out, type = "coefficients", s = bestlam)[1:21,] 


#### none of the coefficients are exactly zero - ridge regression does not perform variable selection!





#The Lasso###############
lasso_mod = glmnet(x_train, 
                   y_train, 
                   alpha = 1, 
                   lambda = grid) 



set.seed(1)
# Fit lasso model on training data
cv.out = cv.glmnet(x_train, y_train, alpha = 1) 
# Draw plot of training MSE as a function of lambda
plot(cv.out) 
# Select lamda that minimizes training MSE
bestlam = cv.out$lambda.min
bestlam



#The optimal lambda value comes out to be 0.001 and will be used to build the ridge regression model.
# Use best lambda to predict test data
lasso_pred = predict(lasso_mod, s = bestlam, newx = x_test)
eval_results(y_test, lasso_pred, test)
# Calculate test MSE
mean((lasso_pred - y_test)^2) 
# The test MSE is 85.30


# Fit lasso model on full dataset
out = glmnet(x, y, alpha = 1, lambda = grid)
# Display coefficients using lambda chosen by CV
lasso_coef = predict(out, type = "coefficients", s = bestlam)[1:21,] 
lasso_coef

# Display only non-zero coefficients
lasso_coef[lasso_coef != 0] 


