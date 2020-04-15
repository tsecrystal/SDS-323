library(gamlr)
library(tidyverse)
library(mosaic)

green = read.csv("greenbuildings.csv")

# LASSO, refer to cheese_demand.R
# but do the elasticities differ by store and display status?
# we're going to have trouble for some of the stores here...
xtabs(~cluster + age, data=green)

# So let's allow interactions, but penalize them
# remember that -1 removes the intercept; gamlr will put one in for you
# X_cheese = sparse.model.matrix(~ log(price) + disp + store + store:log(price) + store:disp + store:disp:log(price), data=cheese)[,-1]
# y_cheese = log(cheese$vol)

X_green = sparse.model.matrix(~ class_a + age + cluster + cluster:class_a + cluster:age + cluster:age:class_a, data=green)[,-1]
y_green = log(green$Rent)

# the first 3 coefficients in this matrix correspond to main effects
# we want to leave these in!
# don't penalize main effects if you want to use the lasso to search for interactions
colnames(X_green)

# the "free" argument tells gamlr which coefficients not to penalize
# see ?gamlr
lasso1 = cv.gamlr(X_green, y_green, free=1:3)
beta_hat = coef(lasso1)
coef_names = rownames(coef(lasso1))

# main effects
beta_hat[1:3,]

