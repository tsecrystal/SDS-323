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
bank <- bank %>% replace_with_na_all(condition = ~.x == "unknown")
bank <-bank[complete.cases(bank10), ] 



bank <- bank %>% 
  mutate(Outcome = factor(y, levels = c("no","yes"),
                        labels = c("Not Subscribed", "Subscribed")))


bank <- transform( bank,
                       job = ordered(job, levels = names( sort(-table(job)))))



ggplot(bank) + 
  geom_bar(aes(x = job)) +
  facet_grid(. ~ Outcome) +
  theme_few()





bank <- transform( bank,
                   education = ordered(education, levels = names( sort(-table(education)))))

ggplot(bank) + 
  geom_bar(aes(x = education)) +
  facet_grid(. ~ Outcome) +
  theme_few() 

bank <- transform( bank,
                   marital = ordered(marital, levels = names( sort(-table(marital)))))


ggplot(bank) + 
  geom_bar(aes(x = marital)) +
  facet_grid(. ~ Outcome) +
  theme_few() 




ggplot(mutate(bank, loan = fct_infreq(loan))) + geom_bar(aes(x = loan))
ggplot(bank) + 
  geom_bar(aes(x = loan)) +
  facet_grid(. ~ Outcome) +
  theme_few() 


bank <- transform( bank,
                   month = ordered(month, levels = names( sort(-table(month)))))

ggplot(bank) + 
  geom_bar(aes(x = month)) +
  facet_grid(. ~ Outcome) +
  theme_few() 


ggplot(data = bank) +
  geom_bar(mapping = aes(x = education, fill = poutcome),position = "fill") +
  scale_fill_brewer( palette = "orange")



# Cut age to different 
bank <- bank %>% 
  mutate(age_distri = cut(age, c(20,40, 60, 80, 100)))
summary(bank)


#Continue to dig in 
ggplot(data = bank) +
  geom_bar(mapping = aes(x = age_distri, y = job, 
                         fill = Outcome), stat='identity', position ='dodge') +
  theme_few() +
  scale_fill_brewer( palette = "Blues")+
  labs(title = "Age distribution with job",
       y = "Job",
       x = "Age distribution",
       fill = "Outcome")  

ggplot(data = bank, mapping = aes(x = loan, y = cons.conf.idx, color = Outcome)) +
  geom_boxplot() +
  facet_wrap(facets = vars(job)) 


