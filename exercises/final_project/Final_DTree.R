library(tidyverse)
library(rpart)
library(naniar)
library(dplyr)

bank = read_delim("~/Desktop/SDS 323/final/data/bank-additional-full.csv", delim = ";")

bank10 = read_delim("~/Desktop/SDS 323/final/data/bank-additional.csv", delim = ";")

bank <- bank %>% replace_with_na_all(condition = ~.x == "unknown")

bank <- select(bank, -default, -nr.employed, -loan, -duration )
bank = arrange(bank, y)
N = nrow(bank)

bank <- bank %>% 
  mutate(age_distri = cut(age, c(20,40, 60, 80, 100)))
summary(bank)



# split into a training and testing set
train_frac = 0.8
N_train = floor(train_frac*N)
N_test = N - N_train
train_ind = sample.int(N, N_train, replace=FALSE) %>% sort
load_train = bank10[train_ind,]
load_test = bank10[-train_ind,]


library(rpart)
library(rpart.plot)
fit.tree <- rpart(y~., data = bank10, method = 'class')
rpart.plot(fit.tree, extra = 106)



nbig = length(unique(fit.tree$where))
nbig

# look at the cross-validated error
plotcp(fit.tree) 
head(fit.tree$cptable, 100)

# a helper function for pruning the tree at the 
# min + 1se complexlity threshold
prune_1se = function(treefit) {
  # calculate the 1se threshold
  errtab = treefit$cptable
  xerr = errtab[,"xerror"]
  jbest = which.min(xerr)
  err_thresh = xerr[jbest] + errtab[jbest,"xstd"]
  j1se = min(which(xerr <= err_thresh))
  cp1se = errtab[j1se,"CP"]
  prune(treefit, cp1se)
}



cvtree = prune_1se(fit.tree)
length(unique(cvtree$where))

# still a pretty deep tree
plot(cvtree)
log2(length(unique(cvtree$where)))


# calculate test_set RMSE
rmse = function(y, yhat) {
  sqrt(mean((y-yhat)^2))
}




######## I don't know how to calculate the RMSE.
rmse(load_test$y, predict(cvtree, load_test))



#I want to predict which clients are more likely to sunscribe after the collision from the test set.

predict <-predict(fit.tree, load_test, type = 'class')

# Create a table to count how many clients are classified as subcribe compare to the correct classification                
table_mat <- table(load_test$y, predict)
table_mat

# The accuracy test from the confusion matrix
accuracy_Test <- sum(diag(table_mat)) / sum(table_mat)


print(paste('Accuracy for test', accuracy_Test))



