library(mosaic)
library(tidyverse)
library(ggplot2)
library(LICORS)  # for kmeans++
library(foreach)
library(reshape2)
library(knitr)
library(kableExtra)

mkt = read.csv("social_marketing.csv")

# try hierarchical clustering
# convert integer variables to numeric to use scale() function
# mkt[2:37] <- lapply(mkt[2:37], as.numeric)
# mkt = mkt[-1] %>% mutate_if(is.numeric, scale(mkt, center=TRUE, scale=TRUE)) 

# Form a pairwise distance matrix using the dist function
mkt_distance_matrix = dist(mkt[-1], method='euclidean')

# Now run hierarchical clustering
hier_mkt = hclust(mkt_distance_matrix, method='complete')
# Plot the dendrogram
# plot(hier_mkt, cex=0.8)

cluster1 = cutree(hier_mkt, k=5)
summary(factor(cluster1))

###############
# try K-means++ clustering
# mkt <- subset(mkt, select = -c(X))  # remove the anonymous identifier

# shows that there are currently points that are spam and adult...want to remove
ggplot(data = mkt, 
       aes(x = spam, y = adult)) +
  geom_point()

mkt <- subset(mkt, !(spam > 0 | adult > 0))

ggplot(data = mkt, 
       aes(x = spam, y = adult)) +
  geom_point()

mkt = subset(mkt, select = -c(spam, adult) )
# Center and scale the data
# NOT SURE WE NEED TO DO THIS IF EVERYTHING IS A COUNT
mkt = scale(mkt[-1], center=TRUE, scale=TRUE)

# Extract the centers and scales from the rescaled data (which are named attributes)
mu = attr(mkt,"scaled:center")
sigma = attr(mkt,"scaled:scale")

mkt_long <- reshape2::melt(mkt)  # convert matrix to long dataframe
mkt <- spread(mkt_long, Var2, value)# convert long dataframe to wide


# Run k-means plus plus.
clust2 = kmeanspp(mkt[-1], k=3, nstart=25)

c1 = clust2$center[1,]*sigma + mu
c2 = clust2$center[2,]*sigma + mu
c3 = clust2$center[3,]*sigma + mu

# A few plots with cluster membership shown
ggplot(data = mkt,
       aes(x = sports_fandom, y = photo_sharing, color = factor(clust2$cluster))) +
  geom_point(position = "jitter")

ggplot(data = mkt, 
       aes(x = sports_fandom, y = parenting, color = factor(clust2$cluster))) +
  geom_point(position = "jitter")


# large portion of their market is focused on health/nutrition and personal fitness
ggplot(data = mkt, 
       aes(x = health_nutrition, y = personal_fitness, color = factor(clust2$cluster))) +
  geom_point(position = "jitter")

# show the variables that are above 4 
# print(c2>4)
print(c1[order(c1, decreasing = TRUE)][1:5])
print(c2[order(c2, decreasing = TRUE)][1:5])
(c3[order(c3, decreasing = TRUE)][1:5]) %>% kable() %>% kableExtra::kable_styling()

# attempt PCA
# PCA is a good method since tweets may overlap in subject matter and there is noisy data
# compute average number of tweets by subject matter across all followers
tweets = read.csv("social_marketing.csv")
tweets = subset(tweets, select = -c(spam, adult) )
# Now look at PCA of the (average) survey responses.  
# This is a common way to treat survey data
PCAtweet = prcomp(tweets %>% select(-X), scale=TRUE)

# variance plot
plot(PCAtweet)
summary(PCAtweet)

# first few pcs
components <- 15
round(PCAtweet$rotation[,1:components],2) 

tweets = merge(tweets,
               PCAtweet$x[,1:components],
               by = "row.names")
# tweets = merge(tweets, 
#                PCAtweet$x[,1:components],
#                by = "x")

ggplot(tweets) + 
  geom_text(aes(x=PC1, y=PC2, label=X), size=3)

# principal component regression
lm1 = lm(food ~ PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 +
           PC10 + PC11 + PC12 + PC13 + PC14+ PC15, data=tweets)
summary(lm1)

lm2 = lm(health_nutrition ~ PC1 + PC2 + PC3 + PC4 + PC5 + PC6 + PC7 + PC8 + PC9 +
           PC10 + PC11 + PC12 + PC13 + PC14+ PC15, data=tweets)
summary(lm2)

# Conclusion: we can predict engagement and ratings
# with PCA summaries of the pilot survey
ggplot(data = tweets, aes(x = fitted(lm1), y = food)) + geom_point(position = "jitter")
ggplot(data = tweets, aes(x = fitted(lm2), y = health_nutrition)) + geom_point(position = "jitter")
