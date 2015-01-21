library(reshape)
library(ggplot2)
library(ellipse)

source('ml.R')

# Util stuff
load.filter <- function(path) {
  setAs("character", "POSIXct",
        function(from){as.POSIXct(from, origin = "1970-01-01")})
  a <- read.csv(path, check.names = T, 
                colClasses = c("integer",rep("factor",2), rep("integer", 6),
                               rep("factor", 3), rep("integer", 18),
                               rep("double", 3), "integer",  "factor",
                               "integer", "double", "integer",
                               "factor", "factor"))
  
  a$conflict <- a$conflict == "true"
  a$conflict <- as.factor(a$conflict)
  a$forward_links <- a$forward_links == "true"
  a$forward_links <- as.factor(a$forward_links)
  a$main_team_member <- a$main_team_member == "true"
  a$main_team_member <- as.factor(a$main_team_member)
  a$intra_branch <- a$intra_branch == "true"
  a$intra_branch <- as.factor(a$intra_branch)
  a$merged <- !is.na(a$merged_at)
  a$merged <- as.factor(a$merged)
  # Take care of cases where csv file production was interupted, so the last
  # line has wrong fields
  a <- subset(a, !is.na(intra_branch))
  a
}

# Actual analysis
data <- load.filter('rails.csv') 

# See what data types we have in our dataset
str(data)

# Remove factors and columns not interesting for the analysis
excluded <- c(2, 3, 4, 5, 6, 7, 10, 11, 12, 35, 39, 40, 41)

# Plot histograms for interesting variables
c <- melt(data[,-excluded], id.vars = 'pull_req_id')
ggplot(c, aes(x = value)) + 
  facet_wrap(~variable, scales = "free") + 
  #scale_x_log10()+
  geom_histogram() +
  theme_bw(base_size = 10) 
  
#Cross correlation analysis
ctab <- cor(data[,-excluded], method = "spearman", use='complete.obs')
colorfun <- colorRamp(c("#ff0000","white","#0000ff"), space="rgb")
plotcorr(ctab,
         col=rgb(colorfun((ctab+1)/2), maxColorValue=255),
         outline = FALSE)

# ML Task : Predict whether a pull request will be merged or not
model <- merged ~ team_size + num_commits + files_changed +
  perc_external_contribs + sloc + src_churn + test_churn + num_comments +
  commits_on_files_touched +  test_lines_per_kloc + prev_pullreqs +
  requester_succ_rate + main_team_member + conflict + forward_links + 
  num_participants

# Split dataset into training and testing
samples <- sample(nrow(data), size = 0.25 * nrow(data))
test.data <- data[samples,]
train.data <- data[-samples,]

# Initial experiments with rf
rf <- randomForest(model, data = train.data, importance = T, do.trace = T)
print(rf)
plot(rf)
importance(rf)

# Make a function for the above and start tuning
plot.rf <- function(rf) {
  print(rf)
  plot(rf)
  importance(rf)
}

# Perhaps more variables per tree?
rf <- randomForest(model, data = train.data, importance = T, do.trace = T, mtry = 10)
plot.rf(rf)

# Perhaps some dataset balancing?
nrow(subset(data, merged == T))
minority.class <- nrow(subset(train.data, merged == F))
rf <- randomForest(model, data = train.data, importance = T, do.trace = T, ntree = 400,
                   sampsize = c('FALSE' = minority.class, 
                                'TRUE' = (2 * minority.class)))
plot.rf(rf)

# Let's throw in some other learners in the mix
# in parallel!
registerDoMC(3)

# Train a random forest model
rf.metrics <- random.forest(model, data)

# Train a binary logistic regression model
blr.metrics <- binary.logistic.regression(model, data)

# Train a naive bayes model
bayes.metrics <- naive.bayes(model, data)

all.metrics <- rbind(rf.metrics, blr.metrics, bayes.metrics)
all.metrics <- all.metrics[, -which(names(all.metrics) %in% c("tnr","tpr", "w.acc", "train.size", "test.size"))] 
melted.metrics <- melt(all.metrics, id.vars = c('classifier', 'run'))
ggplot(melted.metrics)+
  aes(x = run, y = value, colour = classifier) +
  geom_point(aes(shape = classifier), size = 3) +
  scale_shape(solid = F) +
  geom_line() +
  facet_wrap(~variable, scales="free_y") +
  xlab("Number of fine-grained changes") +
  theme_bw() +
  theme(axis.title.y = element_blank()) +
  theme(axis.text.x = element_text(size = 8)) +
  theme(axis.text.y = element_text(size = 8)) +
  theme(legend.key = element_blank()) +
  theme(legend.position = "top")
