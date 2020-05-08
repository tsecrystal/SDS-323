packs <- c("tidyverse","tidyr","corrplot","caret","factoextra","cluster","dendextend","kableExtra","ggcorrplot","mosaic","psych","gridExtra","LICORS", "SDSRegressionR")
lapply(packs, library, character.only = TRUE)

#small bank data set
sbank <- read.csv("data/bank-additional.csv",  stringsAsFactors = TRUE, sep=";")

#big bank data set
bbank <- read.csv("data/bank-additional-full.csv",
                    header = TRUE, sep =";")

bbank <- bbank %>% dplyr::rename("deposit"="y")
bbank$duration <- NULL
tally(~bbank$deposit)
bbank$deposit <- as.numeric(bbank$deposit)
bbank$deposit <- factor(bbank$deposit, levels=c(2,1), labels=c("Yes", "No"))


sum(is.na.data.frame(bbank))
head(bbank)

set.seed(343)

b_mod <- glm(deposit ~ ., family="binomial", data=bbank)
summary(b_mod)

library(rms)
b_mod2 <- lrm(deposit ~ ., bbank)
b_mod2

# EDA -----
library(forcats)
ggplot(bbank, aes(x=fct_rev(fct_infreq(job)))) +
  geom_bar(fill="light green")+
  coord_flip()+
  theme_bw()+
  labs(x="Job Title", y="Count")

ggplot(bbank, aes(x=fct_rev(fct_infreq(deposit)))) + 
  geom_bar(fill="dark blue") +
  coord_flip() + 
  theme_bw() + 
  labs(x="Marital Status", y="Count")

ggplot(bbank, aes(x=euribor3m)) + 
  geom_histogram()+
  facet_wrap(~deposit)


aggregate(bbank[, 18], list(bbank$deposit), median)

tally(~bbank$campaign)
#thankfully, there are only a small number of unkowns

plot(bbank$bbank$deposit)
ggplot(bbank, aes(pdays))+
  geom_histogram()

ggplot(bbank, aes(x=deposit))+
  geom_bar()

ggplot(bbank, aes(x=month)) + 
  geom_bar()
summary(bbank$deposit)

head(bbank)

ggplot(bbank, aes(pdays)) +
  geom_histogram() +
  facet_grid(~deposit)

# Random Forest -----
library(randomForest)
library(pdp)
n = nrow(bbank)
n_train = floor(0.8*n)
n_test = n - n_train
train_cases = sample.int(n, size=n_train, replace=FALSE)
y_all = bbank$deposit
x_all = model.matrix(~age+job+marital+education+default+housing+loan+contact+month+day_of_week
                     +campaign+pdays+previous+poutcome+emp.var.rate+cons.price.idx+cons.conf.idx
                     +euribor3m+nr.employed, data=bbank)

y_train = y_all[train_cases]
x_train = x_all[train_cases,]

y_test = y_all[-train_cases]
x_test = x_all[-train_cases,]

bbank_train = bbank[train_cases,]
bbank_test = bbank[-train_cases,]

forest1 = randomForest(deposit ~ ., data=bbank_train)

yhat_test = predict(forest1, bbank_test)

plot(yhat_test, y_test)

# RMSE
(yhat_test - y_test)^2 %>% mean %>% sqrt

# performance as a function of iteration number
plot(forest1)

# a variable importance plot: how much SSE decreases from including each var
varImpPlot(forest1)

confusionMatrix(yhat_test,y_test)

#fix the y variable with factor


### also try: adaboost (or boosted logistic), kmeans, clustering


library(party)
cforest(deposit ~ ., data=bbank)
