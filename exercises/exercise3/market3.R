library(mosaic)
library(tidyverse)
library(ggplot2)
library(LICORS)  # for kmeans++
library(foreach)
library(reshape2)
library(knitr)
library(kableExtra)

############################
# attempt PCA
# PCA is a good method since tweets may overlap in subject matter and there is noisy data
# compute average number of tweets by subject matter across all followers
tweets = read.csv("social_marketing.csv")
genres = colnames(tweets)

# remove points that are spam and adult
tweets <- subset(tweets, !(spam > 0 | adult > 0))

# remove these variables from the data frame
tweets = subset(tweets, select = -c(spam, adult) )
# Now look at PCA of the (average) survey responses.  
# This is a common way to treat survey data
PCAtweet = prcomp(tweets %>% select(-X), scale=TRUE)

# variance plot
fviz_screeplot(PCAtweet, addlabels=TRUE) + geom_vline(xintercept=15, linetype=5, col="red")

# first few pcs
components <- 15
round(PCAtweet$rotation[,1:components],2) 

tweets = merge(tweets,
               PCAtweet$x[,1:components],
               by = "row.names")

###############
# try replicating NCI60.R with hierarchical clustering
# now calculate a distance matrix based on the first five principal components
# key idea: using the PC scores (K=5) rather than the full data matrix(P=6830)
# is a form of denoising.
my_scores = PCAtweet$x

D_tweets = dist(my_scores[,1:components])
hclust_tweets = hclust(D_tweets, method='complete')
# plot(hclust_tweets, labels=genres[-1])

# Examine the principal components
# first, what are PCs themselves?
my_loadings = PCAtweet$rotation

# these are the 20 tweet categories most negatively associated with PC1
my_loadings[,1] %>% sort %>% head(10)

# these are the 20 tweet categories most positively associated with PC1
my_loadings[,1] %>% sort %>% tail(10)


###############
# try K-means++ clustering
# Center and scale the data
# PCAtweet = scale(PCAtweet %>% select(-X, -Row.names), center=TRUE, scale=TRUE)

# Extract the centers and scales from the rescaled data (which are named attributes)
mu = attr(PCAtweet,"scaled:center")
sigma = attr(PCAtweet,"scaled:scale")

# tweets_long <- reshape2::melt(PCAtweet)  # convert matrix to long dataframe
# tweets <- spread(tweets_long, Var2, value)# convert long dataframe to wide

# Run k-means plus plus.
clust2 = kmeanspp(PCAtweet, k=3, nstart=25)

c1 = clust2$center[1,]*sigma + mu
c2 = clust2$center[2,]*sigma + mu
c3 = clust2$center[3,]*sigma + mu

# A few plots with cluster membership shown
ggplot(data = tweets,
       aes(x = sports_fandom, y = photo_sharing, color = factor(clust2$cluster))) +
  geom_point(position = "jitter")

ggplot(data = tweets,
       aes(x = sports_fandom, y = parenting, color = factor(clust2$cluster))) +
  geom_point(position = "jitter")


# large portion of their market is focused on health/nutrition and personal fitness
ggplot(data = tweets,
       aes(x = health_nutrition, y = personal_fitness, color = factor(clust2$cluster))) +
  geom_point(position = "jitter")

# show the variables that are above 4
# print(c2>4)
print(c1[order(c1, decreasing = TRUE)][1:5])
print(c2[order(c2, decreasing = TRUE)][1:5])
print(c3[order(c3, decreasing = TRUE)][1:5])