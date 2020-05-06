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

# split into quantitative and qualitative data frames for kmeansvar of ClustOfVar
# bank_quant = dplyr::select_if(bank10, is.numeric)
# bank_qual = dplyr::select_if(bank10, is.character)

## Hierarchical Clustering
X.quanti <- PCAmixdata::splitmix(bank10)$X.quanti
X.quali <- PCAmixdata::splitmix(bank10)$X.quali
tree <- hclustvar(X.quanti,X.quali)
plot(tree)


## K-means clustering revised for qualitative and quantitative mixed data
# maybe edit the number of clusters (init) to be optimal  ##debug
# choice of the number of clusters
# bank_quant = as.matrix(as.data.frame(lapply(bank_quant, as.numeric)))

# tree <- hclustvar(X.quanti=bank_quant)
# stab <- stability(tree,B=60)

bank_qual = mutate(bank_qual, 
                default = ifelse(default == "yes", "yes_default", "no_default"),
                housing = ifelse(housing == "yes", "yes_housing", "no_housing"),
                loan = ifelse(loan == "yes", "yes_loan", "no_loan"))
                # y = ifelse(y == "yes", "1", 0))

# xcor = cor(bank_quant)
# write.csv(xcor, 'xcor.csv')

library(digest)
bank_qual2 = bank_qual[!duplicated(lapply(bank_qual, digest))]

## debug also increase iter.max later
bank_kmeans = kmeansvar(X.quanti = bank_quant, 
                        X.quali = bank_qual2, 
                        init = 3,
                        iter.max = 10,
                        nstart = 1, matsim = FALSE)



