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
library(ClustOfVar)


bank = read_delim("bank-additional-full.csv", delim = ";")
bank10 = read_delim("bank-additional.csv", delim = ";")

# get rid of observations that have unknowns
bank10 <- bank10 %>% replace_with_na_all(condition = ~.x == "unknown")
bank10 <-bank10[complete.cases(bank10), ] # went from 4119 to 3090 obs

# maybe it is worth removing pdays since it only occurs 142 times out of the 3090 obs
sum(bank10$pdays != 999)

# remove duration because it is highly correlated with y (duration = 0 --> no)
bank10 = subset(bank10, select = -c(duration, pdays) )

## Hierarchical Clustering
X.quanti <- PCAmixdata::splitmix(bank10)$X.quanti
X.quali <- PCAmixdata::splitmix(bank10)$X.quali
tree <- hclustvar(X.quanti,X.quali)
plot(tree)

part<-cutreevar(tree,6) #cut of the tree
summary(part)
plot.clustvar(part) # plot loadings of each cluster

## K-means clustering revised for qualitative and quantitative mixed data
# maybe edit the number of clusters (init) to be optimal  ##debug
# choice of the number of clusters

# stability: bootstrap approach to help identify number of clusters
# stab <- stability(tree,B=60)

X.quali = mutate(X.quali, 
                default = ifelse(default == "yes", "yes_default", "no_default"),
                housing = ifelse(housing == "yes", "yes_housing", "no_housing"),
                loan = ifelse(loan == "yes", "yes_loan", "no_loan"))
                # y = ifelse(y == "yes", "1", 0))


## debug also increase iter.max later
bank_kmeans = kmeansvar(X.quanti = X.quanti, 
                        X.quali = X.quali, 
                        init = 3,
                        iter.max = 10,
                        nstart = 1, matsim = FALSE)


