#shortcut to load multiple packages at once
packs <- c("tidyverse", "tidyr", "corrplot", "factoextra", "cluster", "dendextend")
lapply(packs, library, character.only = TRUE)

wine <- read.csv("data/wine.csv")
#remove the categorical variables and scale
wine_s <- scale(wine[,1:11])
head(wine_s)
summary(wine_s)

set.seed(343)

#EDA-----
ggplot(wine, aes(quality, fill=color))+
  geom_histogram(binwidth = 0.5, col="black") +  
  facet_grid(color ~ .)+
  labs(title="Wine Quality For Red and White")

wine %>%
  gather(Attributes, value, 1:11) %>%
  ggplot(aes(x=value, fill=Attributes)) +
  geom_histogram(colour="black", show.legend=FALSE) +
  facet_wrap(~Attributes, scales="free_x") +
  labs(x="Values", y="Frequency",
       title="Wine Attributes Histograms") +
  theme_bw()

#cor() must be numeric
corrplot(cor(wine_s), type="upper", method="ellipse", tl.cex=0.9)


#PCA-----
mypr <- prcomp(wine[, 1:11], scale=TRUE)
summary(mypr)
plot(mypr)
biplot(mypr)
str(mypr)
wine2 <- cbind(wine, mypr$x)

ggplot(wine2, aes(x=PC1, y=PC2, col = color, fill = color)) +
  geom_point(shape = 21, col = "black") +
  stat_ellipse(geom = "polygon", col = "black", alpha = 0.5)
  
cor(wine[, 1:11], wine2[, 14:24])



#K-MEANS-----
kfit <- kmeans(wine_s, 3)

k <- list()
for(i in 1:10){
  k[[i]] <- kmeans(wine_s, i)
}

k


#do elbow plot for k means, and also do gap statistic, need cluster library
#for cars:
#library(cluster)
#cars_gap = clusGap(cars, FUN=kmeans, nstart=50, K.max=10, B=100)
#cars_gap


#put optimal kmeans model in for k2 
fviz_cluster(k2, data=wine_s)

set.seed(123)
gap_stat <- clusGap(wine_s, FUN = kmeans, nstart = 25,
                    K.max = 10, B = 25)
fviz_gap_stat(gap_stat)
#optimal kmeans model
# opt_k <- ...
final <- kmeans(wine_s, 5, nstart = 25)
fviz_cluster(final, data=wine_s)

#pipe this into kable
wine_s %>%
  mutate(Cluster = final$cluster) %>%
  group_by(Cluster) %>%
  summarise_all("mean")



?clusGap

#HIERARCHICAL CLUSTERING-----
wine_dist <- dist(wine_s)
h1 <- hclust(wine_dist, method="average")
plot(h1)
rect.hclust(h1, k = 3, border = "red") 
clusters <- cutree(h1, k = 3) 
plot(wine, col = clusters)

#gap statistic for hieraarchical
mydist <- function(x) as.dist((1-cor(t(x)))/2)
mycluster <- function(x, k) cutree(hclust(mydist(x), method = "average"),k=k)
myclusGap <- clusGap(data.selection03,
                     FUN = mycluster, 
                     K.max = 10, 
                     B = 100)
mycluster <- function(x, k) list(cluster=cutree(hclust(mydist(x), method = "average"),k=k))

#elbow graph
fviz_nbclust(wine_s, FUN = hcut, method = "wss")

#gap statistic
gap_stat <- clusGap(wine_s, FUN=hcut, nstart=15, K.max=20, B=10)
fviz_gap_stat(gap_stat)

