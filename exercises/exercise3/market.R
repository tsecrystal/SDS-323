library(mosaic)
library(tidyverse)
library(ggplot2)
library(LICORS)  # for kmeans++
library(foreach)
library(reshape2)

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


# try K-means++ clustering
# mkt <- subset(mkt, select = -c(X))  # remove the anonymous identifier
# Center and scale the data
# NOT SURE WE NEED TO DO THIS IF EVERYTHING IS A COUNT
mkt = scale(mkt[-1], center=TRUE, scale=TRUE)

# Extract the centers and scales from the rescaled data (which are named attributes)
mu = attr(mkt,"scaled:center")
sigma = attr(mkt,"scaled:scale")

# Run k-means plus plus.
clust2 = kmeanspp(mkt[-1], k=6, nstart=25)

clust2$center[1,]*sigma + mu
clust2$center[2,]*sigma + mu
clust2$center[4,]*sigma + mu

# A few plots with cluster membership shown
# qplot is in the ggplot2 library

mkt_long <- melt(mkt)  # convert matrix to long dataframe
mkt <- spread(mkt_long, Var2, value)# convert long dataframe to wide

qplot(travel, food, data=mkt, color=factor(clust2$cluster))
qplot(photo_sharing, family, data=mkt, color=factor(clust2$cluster))


