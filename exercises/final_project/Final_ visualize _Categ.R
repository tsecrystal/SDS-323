install.packages(ggthemes)
library(mosaic)
library(tidyverse)
library(forcats)
library(ggthemes)
library(ggplot2)
library(RColorBrewer)
library(ISLR)
library(glmnet)
library(doMC)  
library(gamlr)
library(tidyr)
library(dplyr)
library(pdp)
library(lubridate)
library(naniar)
library(rpart)
library(fastDummies)




bank = read_delim("~/Desktop/SDS 323/final/data/bank-additional-full.csv", delim = ";")
bank10 = read_delim("~/Desktop/SDS 323/final/data/bank-additional.csv", delim = ";")

# get rid of observations that have unknowns
# bank10 %>% mutate_if(is.character, list(~na_if(., "unknown"))) %>% na.omit()
bank10 <- bank10 %>% replace_with_na_all(condition = ~.x == "unknown")
bank10 <-bank10[complete.cases(bank10), ] # went from 4119 to 3090 obs


# add dummy variables for housing, loan, target variable
#bank10 = mutate(bank10, 
#                default = ifelse(default == "yes", 1, 0),
#                housing = ifelse(housing == "yes", 1, 0),
#                loan = ifelse(loan == "yes", 1, 0),
#                 y = ifelse(y == "yes", 1, 0))



ggplot(mutate(bank10, job = fct_infreq(job))) + geom_bar(aes(x = job))
bank10 <- bank10 %>% 
  mutate(Outcome = factor(y, levels = c("no","yes"),
                        labels = c("Subscribed", "Not Subscribed")))


ggplot(bank10) + 
  geom_bar(aes(x = job)) +
  facet_grid(. ~ Outcome) +
  theme_few() 



ggplot(mutate(bank10, education = fct_infreq(education))) + geom_bar(aes(x = education))
ggplot(bank10) + 
  geom_bar(aes(x = education)) +
  facet_grid(. ~ Outcome) +
  theme_few() 



ggplot(mutate(bank10, marital = fct_infreq(marital))) + geom_bar(aes(x = marital))
ggplot(bank10) + 
  geom_bar(aes(x = marital)) +
  facet_grid(. ~ Outcome) +
  theme_few() 



ggplot(mutate(bank10, housing = fct_infreq(housing))) + geom_bar(aes(x = housing))
ggplot(bank10) + 
  geom_bar(aes(x = housing)) +
  facet_grid(. ~ Outcome) +
  theme_few() 

ggplot(mutate(bank10, loan = fct_infreq(loan))) + geom_bar(aes(x = loan))
ggplot(bank10) + 
  geom_bar(aes(x = loan)) +
  facet_grid(. ~ Outcome) +
  theme_few() 


ggplot(mutate(bank10, month = fct_infreq(month))) + geom_bar(aes(x = month))
ggplot(bank10) + 
  geom_bar(aes(x = month)) +
  facet_grid(. ~ Outcome) +
  theme_few() 


ggplot(data = bank10) +
  geom_bar(mapping = aes(x = education, fill = poutcome),position = "fill") +
  scale_fill_brewer( palette = "orange")



# Cut age to different range
bank10 <- bank10 %>% 
  mutate(age_distri = cut(age, c(20,40, 60, 80, 100)))
summary(bank10)


#Continue to dig in 
ggplot(data = bank10) +
  geom_bar(mapping = aes(x = age_distri, y = job, 
                         fill = Outcome), stat='identity', position ='dodge') +
  theme_few() +
  scale_fill_brewer( palette = "Blues")+
  labs(title = "Age distribution with job",
       y = "Job",
       x = "Age distribution",
       fill = "Outcome")  

