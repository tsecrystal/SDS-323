library(tidyverse)
library(mosaic)
library(foreach)
library(doMC)  # for parallel computing
library(gamlr)
library(dplyr)


greenb = read.csv("~/Desktop/SDS 323/Exercises/Exercise 3/data/greenbuildings.csv")
names(greenb)
# Creat a new dummy variable to identify LEED and Energystar kind of green certification.
greenb <- greenb %>% 
  mutate(green_t = LEED + Energystar )

greenb <- greenb %>% 
  mutate(green_certification = ifelse(green_t > 0, "1", "0"))

  
#Forward selection
lm0 = lm(Rent ~ 1, data = greenb)
lm_forward = step(lm0, direction = 'forward',
                  scope =~(cluster + size + empl_gr +  leasing_rate + stories + age + renovated + class_a + class_b + green_certification + green_rating+ net +amenities + cd_total_07 +  hd_total07 + total_dd_07 + Precipitation + Gas_Costs + Electricity_Costs + cluster_rent )^2)


getCall(lm_forward)
coef(lm_forward)
length(coef(lm_forward))


# Create design matrix.  
# do -1 to drop intercept!
scx = model.matrix(Rent ~ .-1, data=greenb) # do -1 to drop intercept!
scy = greenb$Rent # pull out `y' too just for convenience



sclasso = gamlr(scx, scy, family="binomial")
plot(sclasso)




