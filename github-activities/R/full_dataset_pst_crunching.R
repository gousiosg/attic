setwd("/Users/Aron/github/local/github-activities/R")
library(TraMineR)

# Read data
sequences <- read.table("/Users/Aron/github/local/github-activities/data/activity-mojombo-jekyll.txt", sep = ",", header = TRUE)

# Reformat data
sequences <- subset(sequences, select = c("pull_req_id", "action", "created_at"))
colnames(sequences) <- c("id", "event", "time")
sequences$time <- as.POSIXct(sequences$time, origin="1970-01-01 00:00:01")

# Parse data by time
library(sqldf)
sequences_2012_Q1 <- sqldf("SELECT * FROM sequences WHERE strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') >= '2012-01-01' AND strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') <= '2012-03-31'")

sequences_2012_Q2 <- sqldf("SELECT * FROM sequences WHERE strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') >= '2012-04-01' AND strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') <= '2012-06-31'")

sequences_2012_Q3 <- sqldf("SELECT * FROM sequences WHERE strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') >= '2012-07-01' AND strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') <= '2012-09-31'")

sequences_2012_Q4 <- sqldf("SELECT * FROM sequences WHERE strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') >= '2012-10-01' AND strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') <= '2012-12-31'")

sequences_2012 <- sqldf("SELECT * FROM sequences WHERE strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') >= '2012-01-01' AND strftime('%Y-%m-%d', time, 'unixepoch', 'localtime') <= '2012-12-31'")

sequences <- sequences_2012

# Uncomment the line below to test with a smaller dataset
# sequences <- head(sequences, 10)

## Adding a ending time
sequences$end <- sequences$time

## Reducing the total length of sequences
sequences <- sequences[with(sequences, order(time)), ]
sequences$time <- match( sequences$time , unique( sequences$time ) )
sequences$end <- match( sequences$end , unique( sequences$end ) )

## max sequence length
slmax <- max(sequences$time)

sequences.sts <- seqformat(sequences, from="SPELL", to="STS", begin="time", 
      end="end", id="id", status="event", limit=slmax)

sequences.sts <- seqdef(sequences.sts)

# Fit PST model
library(PST)

## ===========================
## PST inluding missing states 
sequences.pst <- pstree(sequences.sts, nmin=2, ymin=0.001, L=2, with.missing=TRUE)

# Prune the tree (reduce unwarranted complexity)
C95 <- qchisq(0.95, length(alphabet(sequences.pst))-1)
sequences.pruned <- prune(sequences.pst, C=C95, gain="G2")
summary(sequences.pruned)

plot(sequences.pruned,
     nodePar=list(node.type="path", lab.type="NA", lab.pos=1, lab.offset=5, lab.cex=0.7, node.size=0.4),
     edgePar=list(type="triangle"),
     withlegend=FALSE
)

# Prune the tree using an AIC/BIC gain function and a cut-off
sequences.gain.pruned <- prune(sequences.pst, gain="G1", C=C95, delete=FALSE, nmin=2)
summary(sequences.gain.pruned)

plot(sequences.gain.pruned,
     nodePar=list(node.type="path", lab.type="prob", lab.pos=1, lab.offset=2, lab.cex=0.7, node.size=0.4),
     edgePar=list(type="triangle"),
     withlegend=FALSE
)

## =========================
## PST without missing states 
sequences.pst <- pstree(sequences.sts, L=5, nmin=1, ymin=0, 
                        with.missing=F)

# Prune the tree (reduce unwarranted complexity)
sequences.pruned <- prune(sequences.pst, L=5, nmin=2)
summary(sequences.pruned)

plot(sequences.pruned,
     nodePar=list(node.type="path", lab.type="prob", lab.pos=1, 
                  lab.offset=2, lab.cex=0.7, node.size=0.2),
     edgePar=list(type="triangle"),
     withlegend=FALSE)