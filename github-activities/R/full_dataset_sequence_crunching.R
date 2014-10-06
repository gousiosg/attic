setwd("/Users/Aron/github/local/github-activities/R")
library(TraMineR)
library(cluster)
library(sqldf)
library(sna)

# Function for reading sequence data
read_seqdata <- function(data, startdate, stopdate){
  data <- read.table(data, sep = ",", header = TRUE)
  data <- subset(data, select = c("pull_req_id", "action", "created_at"))
  colnames(data) <- c("id", "event", "time")
  data <- sqldf(paste0("SELECT * FROM data WHERE strftime('%Y-%m-%d', time,
    'unixepoch', 'localtime') >= '",startdate,"' AND strftime('%Y-%m-%d', time,
    'unixepoch', 'localtime') <= '",stopdate,"'"))
  data$end <- data$time
  data <- data[with(data, order(time)), ]
  data$time <- match( data$time , unique( data$time ) )
  data$end <- match( data$end , unique( data$end ) )
  slmax <- max(data$time)
  (data)
}

# Function for calculating sequence lengths (no. of events)
length <- function(data){
  slmax <- max(data$time)
  sequences.seqe <- seqecreate(data)
  sequences.sts <- seqformat(data, from="SPELL", to="DSS", begin="time", end="end", id="id", status="event", limit=slmax)
  sequences.sts <- seqdef(sequences.sts, right = "DEL", left = "DEL")
  (mean(seqlength(sequences.sts)))
}

# Function for calculating entropies
entropy <- function(data){
  slmax <- max(data$time)
  sequences.sts <- seqformat(data, from="SPELL", to="STS", begin="time", end="end", id="id", status="event", limit=slmax)
  sequences.sts <- seqdef(sequences.sts)
  sequences.ent <- seqient(sequences.sts, norm = FALSE) # This stores the entropies
  (mean(sequences.ent))
}

# Function for calculating turbulence
turbulence <- function(data){
  slmax <- max(data$time)
  sequences.sts <- seqformat(data, from="SPELL", to="STS", begin="time", end="end", id="id", status="event", limit=slmax)
  sequences.sts <- seqdef(sequences.sts)
  sequences.turb <- seqST(sequences.sts) # This stores the entropies
  (mean(sequences.turb))
}

# Function for generating a dissimilarity value  
dissimilarity <- function(data){
  slmax <- max(data$time)
  sequences.seqe <- seqecreate(data)
  sequences.seqe <- seqformat(data, from="SPELL", to="STS", begin="time", end="end", id="id", status="event", limit=slmax)
  sequences.sts <- seqdef(sequences.seqe, left = "DEL", right = "DEL", gaps = "DEL")
  ccost <- seqsubm(sequences.sts, method = "CONSTANT", cval = 2, with.missing=TRUE)
  sequences.OM <- seqdist(sequences.sts, method = "OM", sm = ccost, with.missing=TRUE)
  (mean(sequences.OM))
}

# Function for opening network data
read_netdata <- function(data){
  data <- read.table(data, sep = ",")
  data <- as.network(data[, 1:2])
  (data)
}

# SNA functions
lubness()
connectedness()
efficiency()
hierarchy()