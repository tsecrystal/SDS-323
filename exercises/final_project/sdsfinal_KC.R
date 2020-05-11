library(plotROC) # ROC Curve with ggplot [geom_roc()]
library(pROC) # AUC computation [auc()]
library(PRROC) # AUPR computation [pr.curve()]

packs <- c("tidyverse","tidyr","corrplot","caret","cluster","mosaic","glmnet","gamlr","dplyr","lubridate",
           "dendextend","kableExtra","ggcorrplot","mosaic","psych","gridExtra","LICORS","forcats","naniar",
           "randomForest","pdp","gmodels","ROCR", "yardstick","funModeling","lime","recipes","rsample",
           "ggthemes","rpart","rpart.plot","ggpubr","ggplot2","RColorBrewer")
lapply(packs, library, character.only = TRUE)

#big bank data set
bank <- read.csv("data/bank-additional-full.csv",
                    header = TRUE, sep =";")

sum(is.na.data.frame(bank))
bank <- bank %>% dplyr::rename("deposit"="y")
bank <- bank[!duplicated(bank), ]
bank$duration <- NULL
bank$default <- NULL
bank$pdays <- NULL
bank$deposit <- factor(bank$deposit)
xtabs(~bank$deposit)
month_recode = c("mar" = "(03)mar",
                 "apr" = "(04)apr",
                 "may" = "(05)may",
                 "jun" = "(06)jun",
                 "jul" = "(07)jul",
                 "aug" = "(08)aug",
                 "sep" = "(09)sep",
                 "oct" = "(10)oct",
                 "nov" = "(11)nov",
                 "dec" = "(12)dec")

bank = bank %>% 
  mutate(month = recode(month, !!!month_recode))

day_recode = c("mon" = "(01)mon","tue" = "(02)tue","wed" = "(03)wed","thu" = "(04)thu","fri" = "(05)fri")

bank = bank %>% 
  mutate(day_of_week = recode(day_of_week, !!!day_recode))

fxtable = function(df, var1, var2){
  # df: dataframe containing both vars
  # var1, var2: columns to cross together.
  CrossTable(df[, var1], df[, var2],
             prop.r = T,
             prop.c = F,
             prop.t = F,
             prop.chisq = F,
             dnn = c(var1, var2))
}

bank2 <- bank %>% 
  mutate(age = if_else(age > 60, "high", if_else(age > 30, "mid", "low")))

#fxtables
fxtable(bank2, "age","deposit")
fxtable(bank2, "job", "deposit")
fxtable(bank2,"marital","deposit")
fxtable(bank2,"education", "deposit")
fxtable(bank2,"default","deposit")
fxtable(bank2,"housing","deposit")
fxtable(bank2,"loan","deposit")
fxtable(bank2,"contact","deposit")
fxtable(bank2,"month","deposit")
fxtable(bank2,"day_of_week","deposit")
fxtable(bank2,"campaign","deposit")
fxtable(bank2, "previous", "deposit")
fxtable(bank2, "poutcome","deposit")
fxtable(bank2,"pdays_d","deposit")

# DATA ADJUSTMENT -----
#filtered out 
bank <- bank %>% 
  filter(job != "unknown") %>% 
  filter(marital !="unkown") %>%
  filter(education !="illiterate")

bank[bank == "unknown"] <- NA
bank <-bank[complete.cases(bank), ]

# EDA -----
tab1 <- table(bank$deposit)
prop.table(tab1)

ggplot(bank, aes(x=fct_rev(fct_infreq((job))))) +
  geom_bar(fill="darkblue")+
  coord_flip()+
  theme_bw()+
  labs(x="Job Title", y="Count")

ggplot(bank, aes(x=fct_rev(fct_infreq(marital)), fill=deposit)) + 
  geom_bar() +
  coord_flip() + 
  theme_bw() + 
  labs(x="Marital Status", y="Count")

ggplot(bank, aes(x=euribor3m, fill=deposit)) + 
  geom_histogram(bins=30)+
  facet_wrap(~deposit)

aggregate(bank[, 18], list(bank$deposit), median)

ggplot(bank, aes(x=month, fill=deposit)) + 
  geom_bar()

bank %>% 
  select(emp.var.rate, cons.price.idx, cons.conf.idx, euribor3m, nr.employed) %>% 
  cor() %>% 
  corrplot(method = "number",
           type = "upper",
           tl.cex = 0.8,
           tl.srt = 35,
           tl.col = "black")

# LOGISTIC -----
bank3 <- bank
bank3$loan <- NULL
bank3$nr.employed <- NULL
bank3$deposit <- (as.numeric(bank3$deposit) -1)
xtabs(~bank3$deposit)

set.seed(343)
ind = createDataPartition(bank3$deposit,
                          times = 1,
                          p = 0.75,
                          list = F)
bank3_train = bank3[ind, ]
bank3_test = bank3[-ind, ]

b_mod0 <- glm(deposit~.,family="binomial", data=bank3)
car::vif(b_mod0)

b_mod <- glm(deposit ~ ., family="binomial", data=bank3_train)
summary(b_mod)
b_modpred = predict(b_mod, bank3_test, type = "response")

bpred <- ifelse(b_modpred>0.5, 1, 0)

table(y=bank3_test$deposit, yhat=bpred)
confusionMatrix(data=factor(bpred), reference = factor(bank3_test$deposit))


# DECISION TREE -----
bank6 = bank
bank6 <- select(bank, -nr.employed)
bank6 = arrange(bank6, deposit)
N = nrow(bank6)
bank6 <- bank6 %>% 
  mutate(age_distri = cut(age, c(20,40, 60, 80, 100)))
summary(bank6)

train_frac = 0.75
N_train = floor(train_frac*N)
N_test = N - N_train
train_ind = sample.int(N, N_train, replace=FALSE) %>% sort
load_train = bank6[train_ind,]
load_test = bank6[-train_ind,]


fit.tree <- rpart(deposit~., data = bank6, method = 'class')
rpart.plot(fit.tree, extra = 106)
nbig = length(unique(fit.tree$where))
nbig

plotcp(fit.tree)
head(fit.tree$cptable, 100)
prune_1se = function(treefit) {
  
  errtab = treefit$cptable
  xerr = errtab[,"xerror"]
  jbest = which.min(xerr)
  err_thresh = xerr[jbest] + errtab[jbest,"xstd"]
  j1se = min(which(xerr <= err_thresh))
  cp1se = errtab[j1se,"CP"]
  prune(treefit, cp1se)
}

tree_pred <-predict(fit.tree, load_test, type = 'class')
tree_predict <-predict(fit.tree, load_test, type = 'prob')

dtr_table <- table(load_test$deposit, predict)
dtr_table
confusionMatrix(tree_pred, load_test$deposit, positive = 'yes')

# RANDOM FOREST -----
n = nrow(bank)
n_train = floor(0.75*n)
n_test = n - n_train
train_cases = sample.int(n, size=n_train, replace=FALSE)
y_all = bank$deposit
x_all = model.matrix(~age+job+marital+education+housing+loan+contact+month+day_of_week
                     +campaign+pdays+previous+poutcome+emp.var.rate+cons.price.idx+cons.conf.idx
                     +euribor3m+nr.employed, data=bank)

y_train = y_all[train_cases]
x_train = x_all[train_cases,]
y_test = y_all[-train_cases]
x_test = x_all[-train_cases,]

bank_train = bank[train_cases,]
bank_test = bank[-train_cases,]

forest1 <- randomForest(deposit ~ ., data=bank_train)

yhat_test = predict(forest1, bank_test)

varImpPlot(forest1)
table(yhat_test,y_test)
confusionMatrix(yhat_test, y_test, positive="yes")


# MODELS FOR ROC -----
bank1<- bank
set.seed(123)

train_test_split <- initial_split(bank1, prop = 0.75, strata = 'deposit')

train_test_split

train_data <- training(train_test_split)
test_data  <- testing(train_test_split)

recipe_obj <- recipe(deposit ~ ., data = train_data) %>% 
  step_zv(all_predictors()) %>% 
  step_center(all_numeric()) %>% 
  step_scale(all_numeric()) %>%
  prep()

train_data <- bake(recipe_obj, train_data)

test_data  <- bake(recipe_obj, test_data)

train_ctr <- trainControl(method = 'cv', number = 3,
                          classProbs = TRUE,
                          summaryFunction = twoClassSummary
)

Logistic_model <- train(deposit ~ ., data = train_data,
                        method = 'glm', family = 'binomial',
                        trControl = train_ctr,
                        metric = 'ROC'
)

rf_model <- train(deposit ~ ., data = train_data,
                  ntree=100,
                  method = 'rf',
                  trControl = train_ctr,
                  tuneLength = 1,
                  metric = 'ROC'
)

dtree_model = train(deposit ~ ., 
                  data=train_data, 
                  method="rpart", 
                  trControl = train_ctr,
                  metric='ROC'
                  )

pred_logistic <- predict(Logistic_model, newdata = test_data, type = 'prob')
pred_rf <- predict(rf_model, newdata = test_data, type = 'prob')
pred_dtr <- predict(dtree_model, newdata=test_data, type='prob')

evaluation_tbl <- tibble(true_class = test_data$deposit,
                         logistic_dep = pred_logistic$yes,
                         rf_dep = pred_rf$yes,
                         dtr_dep=pred_dtr$yes)

options(yardstick.event_first = FALSE)

# PLOTTING ROC -----
# creating data for ploting ROC curve
roc_curve_logistic <- roc_curve(evaluation_tbl, true_class, logistic_dep) %>% 
  mutate(model = 'logistic')

roc_curve_rf <- roc_curve(evaluation_tbl, true_class, rf_dep) %>% 
  mutate(model = 'RF')

roc_curve_dtree <- roc_curve(evaluation_tbl, true_class, dtr_dep) %>% 
  mutate(model = 'decisiontree')

logistic_auc <- roc_auc(evaluation_tbl, true_class, logistic_dep)
rf_auc <- roc_auc(evaluation_tbl, true_class, rf_dep)
dtr_auc <- roc_auc(evaluation_tbl, true_class, dtr_dep)

roc_curve_combine_tbl <- Reduce(rbind, list(roc_curve_logistic, roc_curve_rf, roc_curve_dtree))

roc_curve_combine_tbl %>% 
  ggplot(aes(x = 1- specificity, y = sensitivity, color = model))+
  geom_line(size = 1)+
  geom_abline(linetype = 'dashed')+
  theme_bw()+
  scale_color_tableau()+
  labs(title = 'ROC curve Comparision',
       x = '1 - Specificity',
       y = 'Sensitity')

