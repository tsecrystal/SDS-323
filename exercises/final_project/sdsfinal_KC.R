library(gmodels) # Cross Tables [CrossTable()]
library(ggmosaic) # Mosaic plot with ggplot [geom_mosaic()]
library(corrplot) # Correlation plot [corrplot()]
library(ggpubr) # Arranging ggplots together [ggarrange()]
library(cowplot) # Arranging ggplots together [plot_grid()]
library(caret) # ML [train(), confusionMatrix(), createDataPartition(), varImp(), trainControl()]
library(ROCR) # Model performance [performance(), prediction()]
library(plotROC) # ROC Curve with ggplot [geom_roc()]
library(pROC) # AUC computation [auc()]
library(PRROC) # AUPR computation [pr.curve()]
library(rpart) # Decision trees [rpart(), plotcp(), prune()]
library(rpart.plot) # Decision trees plotting [rpart.plot()]
library(MLmetrics) # Custom metrics (F1 score for example)
library(tidyverse) # Data manipulation


packs <- c("tidyverse","tidyr","corrplot","caret","factoextra","cluster",
           "dendextend","kableExtra","ggcorrplot","mosaic","psych","gridExtra","LICORS","forcats",
           "randomForest","pdp")
lapply(packs, library, character.only = TRUE)

#small bank data set
sbank <- read.csv("data/bank-additional.csv",  stringsAsFactors = TRUE, sep=";")

#big bank data set
bbank <- read.csv("data/bank-additional-full.csv",
                    header = TRUE, sep =";")

bbank <- bbank %>% dplyr::rename("deposit"="y")
bbank <- bbank[!duplicated(bbank), ]
bbank$duration <- NULL
tally(~bbank$deposit)
bbank$deposit <- as.numeric(bbank$deposit)
bbank$deposit <- factor(bbank$deposit, levels=c(2,1), labels=c("Yes", "No"))

sum(is.na.data.frame(bbank))
head(bbank)

bbank3 <- bbank
levels(bbank3$deposit)=1:0
set.seed(343)

ind = createDataPartition(bbank3$deposit,
                          times = 1,
                          p = 0.75,
                          list = F)
bbank3_train = bbank3[ind, ]
bbank3_test = bbank3[-ind, ]

b_mod <- glm(deposit ~ ., family="binomial", data=bbank3_train)
summary(b_mod)

b_modpred = predict(b_mod, bbank3_test, type = "response")

bpred <- ifelse(b_modpred<0.5, 1, 0)

table(y=bbank3_test$deposit, yhat=bpred)
confusionMatrix(data=factor(bpred), reference = factor(bbank3_test$deposit))

# EDA -----
ggplot(bbank, aes(x=fct_rev(fct_infreq((job))))) +
  geom_bar(fill="blue")+
  coord_flip()+
  theme_bw()+
  labs(x="Job Title", y="Count")

ggplot(bbank, aes(x=fct_rev(fct_infreq(deposit)))) + 
  geom_bar(fill="darkblue") +
  coord_flip() + 
  theme_bw() + 
  labs(x="Marital Status", y="Count")

ggplot(bbank, aes(x=euribor3m)) + 
  geom_histogram()+
  facet_wrap(~deposit)


aggregate(bbank[, 18], list(bbank$deposit), median)

tally(~bbank$campaign)

#thankfully, there are only a small number of unkowns

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

# performance as a function of iteration number
plot(forest1)

# a variable importance plot: how much SSE decreases from including each var
varImpPlot(forest1)

confusionMatrix(yhat_test,y_test)

p1 = pdp::partial(forest1, pred.var = 'job')
p1
plot(p1)


### also try: adaboost (or boosted logistic), kmeans, clustering

tally(~bbank$month)
tally(~bbank$day_of_week)

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
#mar,apr,may,jun,jul,aug,sep,oct,nov,dec
bbank = bbank %>% 
  mutate(month = recode(month, !!!month_recode))

day_recode = c("mon" = "(01)mon",
               "tue" = "(02)tue",
               "wed" = "(03)wed",
               "thu" = "(04)thu",
               "fri" = "(05)fri")

bbank = bbank %>% 
  mutate(day_of_week = recode(day_of_week, !!!day_recode))

bank_data = bank_data %>% 
  mutate(pdays_dummy = if_else(pdays == 999, "0", "1")) %>% 
  select(-pdays)


bbank2 <- bbank
bbank2 <- bbank2 %>% 
  mutate(age = if_else(age > 60, "high", if_else(age > 30, "mid", "low")))

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

#fxtables
fxtable(bbank2, "age","deposit")
fxtable(bbank2, "job", "deposit")
fxtable(bbank2,"marital","deposit")
fxtable(bbank2,"education", "deposit")
fxtable(bbank2,"default","deposit")
fxtable(bbank2,"housing","deposit")
fxtable(bbank2,"contact","deposit")
fxtable(bbank2,"month","deposit")
fxtable(bbank2,"day_of_week","deposit")
fxtable(bbank2,"campaign","deposit")
fxtable(bbank2, "previous", "deposit")
fxtable(bbank2, "poutcome","deposit")

#filtered out 
bank_data = bank_data %>% 
  filter(job != "unknown") %>% 
  filter(marital !="unkown") %>%
  filter(education !="illiterate") %>% 
  filter(campaign<=10) %>% 
  mutate(pdays_d=if_else(pdays==999, "0","1")) %>% 
  select(-pdays)


fxtable(bbank2,"pdays_d","deposit")




prop_row = fun_crosstable(bank_data, "campaign", "y")$prop.row %>% 
  as.data.frame() %>% 
  filter(y == 1)

prop_row %>% 
  ggplot() +
  aes(x = x,
      y = Freq) +
  geom_point() +
  geom_hline(yintercept = 0.085, 
             col = "red")


df_new['campaign_buckets'] = pd.qcut(df_new['campaign_cleaned'], 20, labels=False, duplicates = 'drop')

#group by 'balance_buckets' and find average campaign outcome per balance bucket
mean_campaign = df_new.groupby(['campaign_buckets'])['deposit_bool'].mean()

#plot average campaign outcome per bucket 
plt.plot(mean_campaign.index, mean_campaign.values)
plt.title('Mean % subscription depending on number of contacts')
plt.xlabel('number of contacts bucket')
plt.ylabel('% subscription')
plt.show()








