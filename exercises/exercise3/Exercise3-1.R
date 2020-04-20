library(tidyverse)
library(ISLR)
library(glmnet)
library(doMC)  # for parallel computing
library(gamlr)
library(tidyr)
library(dplyr)

# Green Buildings

#Given a large dataset on characteristics of commercial rental properties within the United States, our goal is to build the best predictive model possible for the price. Some of the characteristics included in the dataset include the building's age, number of stories, electricity costs, and average rent within the geographic region. 

#In addition, we also want to use this model to quantify the average change in rental income per square foot associated with buildings that have green certification. 
greenb = read.csv("greenbuildings.csv")
names(greenb)

greenb <- select(greenb, -CS_PropertyID)
greenb <- greenb %>% 
  mutate(green_t = LEED + Energystar )

greenb <- greenb %>% 
  mutate(green_certified = ifelse(green_t > 0, "1", "0"))

greenb <- select(greenb, -LEED,-Energystar, -green_t, -Rent) 
# We collapse LEED and EnergyStar certifications into a new dummy variable that encompasses all "green certified" buildings.  Forward selection is used to select the predictive variables that add significant variability to the statistical model. 

lm0 = lm(Rent ~ 1, data = greenb)
lm_forward = step(lm0, direction = 'forward',
                  scope =~(cluster + size + empl_gr +  leasing_rate + stories + age + renovated + class_a + class_b + green_certified + green_rating+ net +amenities + cd_total_07 +  hd_total07 + total_dd_07 + Precipitation + Gas_Costs + Electricity_Costs + cluster_rent )^2)
summary(lm_forward)


#There are 43 variables chosen by the forward selection technique. However, this linear model contains too many coefficients and interactions and leads to an overfitting of the model. 
getCall(lm_forward)
coef(lm_forward)
length(coef(lm_forward))

# Aside from linear regression, we fit a model containing all p predictors using ridge regression and the lasso that constrains or regularizes the coefficient estimates. First, we fit a ridge regression model on the training set with lambda chosen by cross-validation and report the test error obtained.
greenb = na.omit(greenb)
x =  model.matrix(Rent~., greenb)[,-1] 

y = greenb %>% 
  select(Rent) %>% 
  unlist() %>% 
  as.numeric()

grid = 10^seq(10, -2, length = 100)
ridge_mod = glmnet(x, y, alpha = 0, lambda = grid)

#Associated with each value of  ?? is a vector of ridge regression coefficients, stored in a matrix that can be accessed.  
dim(coef(ridge_mod))
plot(ridge_mod, 
     sub = "Figure 1")

predict(ridge_mod, s = 50, type = "coefficients")[1:21,]


# Split the samples into a training set and a test set in order to estimate the test error of ridge regression and the lasso.
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


# Next we fit a ridge regression model on the training set, and evaluate its MSE on the test set.
ridge_mod = glmnet(x_train, y_train, alpha=0, lambda = grid, thresh = 1e-12)
ridge_pred = predict(ridge_mod, s = 4, newx = x_test)
mean((ridge_pred - y_test)^2)
#The test MSE is 88.67
#Because we had instead simply fit a model with just an intercept,  we would have predicted each test observation using the mean of the training observations. 
MSE = mean((mean(y_train) - y_test)^2)
print(MSE)
#The test MSE is 216.10


# We created a model for ridge regression using training set with gamma chosen by cross-validation.
set.seed(1)
cv.out = cv.glmnet(x_train, y_train, alpha = 0) 
# We select lamda that minimizes training MSE
bestlam = cv.out$lambda.min  
bestlam
#The value of  ?? that results in the smallest cross-validation error is 1.16
# Below is a plot of the relationship between training MSE and a function of lambda. The MSE increases as ?? increases.
plot(cv.out,
     sub = "Figure 2")


#The test MSE associated with this value of  ?? is shown below.
ridge_pred = predict(ridge_mod, s = bestlam, newx = x_test)
mean((ridge_pred - y_test)^2)
# The test MSE is 86.09

# Compute RMSE from true and predicted values
eval_results <- function(true, predicted, df) {
  SSE <- sum((predicted - true)^2)
  SST <- sum((true - mean(true))^2)
  
  RMSE = sqrt(SSE/nrow(df))
  
  data.frame(
    RMSE = RMSE
    
  )
  
}

# Prediction and evaluation on train data and test data. We got the RMSE = 27.02 for the training data.
predictions_train <- predict(ridge_mod, s = bestlam, newx = x)
eval_results(y_train, predictions_train, train)

# We got the RMSE = 9.28 for the test data.
predictions_test <- predict(ridge_mod, s = bestlam, newx = x_test)
eval_results(y_test, predictions_test, test)

# Fit ridge regression model on full dataset
out = glmnet(x, y, alpha = 0) 
# Display coefficients using lambda chosen by CV
predict(out, type = "coefficients", s = bestlam)[1:21,] 

# Because none of the coefficients are exactly zero - ridge regression does not perform variable selection! 
#LASSO is a penalized regression method that improves OLS and Ridge regression. LASSO does shrinkage and variable selection simultaneously for better prediction and model interpretation. Therefore, we decide to create a model for lasso regression using training set with gamma chosen by cross-validation.

lasso_mod = glmnet(x_train, 
                   y_train, 
                   alpha = 1, 
                   lambda = grid) 



set.seed(1)
# Fitting model to the test set and checking accuracy. 
cv.out = cv.glmnet(x_train, y_train, alpha = 1) 
# The plot shows the relationship between training MSE and a function of lambda
plot(cv.out,
     sub = "Figure 3")

# When lamda is 0.017, we get the minimizes training MSE
bestlam = cv.out$lambda.min
bestlam

# And then, we use best lambda to predict test data
lasso_pred = predict(lasso_mod, s = bestlam, newx = x_test)
eval_results(y_test, lasso_pred, test)
# We got the testRMSE = 9.24

mean((lasso_pred - y_test)^2) 
# The test MSE is 85.30


out = glmnet(x, y, alpha = 1, lambda = grid)
# Display coefficients using lambda chosen by cross-validation
lasso_coef = predict(out, type = "coefficients", s = bestlam)[1:21,] 
lasso_coef

# Selecting only the predictors with non-zero coefficients, we see that the lasso model with ??.
lasso_coef[lasso_coef != 0]


# Conclusion

#The performance of the models is summarized below:

#Ridge Regression Model: Test set RMSE of 9.28
#Lasso Regression Model: Test set RMSE of 9.24

#The regularized regression models are performing better than the linear regression model. Overall, all the models are performing well with stable RMSE values.

# Holding other features of the building constant, the rental income per square foot will increase 0.293 when the building change from non green certificate to green certificate.
