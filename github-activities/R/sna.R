setwd("/Users/Aron/github/local/github-activities/R")
library(network)
library(sna)

summarize_network <- function(data){
  network <- read.table(data, sep = ",")
  network <- as.network(network[, 1:2])
  cat("density: ") 
  cat(network.density(network),"\n")
  cat("dyad count: ")
  cat(network.dyadcount(network),"\n")
  cat("edge count: ")
  cat(network.edgecount(network),"\n")
  cat("triad census: ", "\n")
  print(triad.census(network, mode = "digraph"))
  plot(network)
}

summarize_network("/Users/Aron/github/local/github-activities/data/graph-mojombo-jekyll-u-6-2-1380915302-1381449217.txt")