#### load packages for twitter, storm, etc
library(RStorm)
library(twitteR)
library(sentiment)
library(wordcloud)
library(dplyr)
library(tidyr)

######## Authorize Twitter
## consumer.key <- '********'
## consumer.secret <- '********'
## access.token <- '********'
## access.secret <- ' ********'
## setup_twitter_oauth(consumer.key, consumer.secret,
##                     access.token, access.secret)
source("tutorial/twitterAuth.R")

## Search Twitter
## small n for dev
tweet.list <- searchTwitter(searchString = "comcast", n = 1500, lang = "en")
tweet.df <- twListToDF(tweet.list)
colnames(tweet.df)
dim(tweet.df)
tweet.df <- tweet.df[order(tweet.df$created),]

################################ Topology ################################
#### Saves some pain with working with strings in bolts
options(stringsAsFactors = FALSE)

#### create the topology
topo <- Topology(tweet.df)

#### Grabs the current time stamp, looks at recent time stamps, and
#### calculates tweets per minute (tpm)
track.rate <- function(tuple, ...){
    t.stamp <- tuple$created
    ## track current time stamp
    t.stamp.df <- GetHash("t.stamp.df")
    if(!is.data.frame(t.stamp.df)) t.stamp.df <- data.frame()
    t.stamp.df <- rbind(t.stamp.df, data.frame(t.stamp = t.stamp))
    SetHash("t.stamp.df", t.stamp.df)
    
    ## get all time stamps find when a minute ago was
    t.stamp.past <- t.stamp.df$t.stamp
    last.min <- t.stamp - 60
    ## get tpm if we're a minute into the stream
    if(last.min >= min(t.stamp.past)){
        in.last.min <-  (t.stamp.past >= last.min) & (t.stamp.past <= t.stamp)
        tpm <- length(t.stamp.past[in.last.min])
    } else {
        tpm <- length(t.stamp.past)
    }
    TrackRow("tpm.df", data.frame(tpm = tpm, t.stamp = t.stamp))
}
topo <- AddBolt(topo, Bolt(track.rate, listen = 0, boltID = 1))

get.text <- function(tuple, ...){
    Emit(Tuple(data.frame(text = tuple$text,
                          t.stamp = tuple$created)), ...)
}
topo <- AddBolt(topo, Bolt(get.text, listen = 0, boltID = 2))

clean.text <- function(tuple, ...){
    text.clean <- tuple$text %>%
        ## convert to UTF-8
        iconv(to = "UTF-8") %>%
        ## strip URLs
        gsub("\\bhttps*://.+\\b", "", .) %>% 
        ## force lower case
        tolower %>%
        ## get rid of possessives
        gsub("'s\\b", "", .) %>%
        ## strip html special characters
        gsub("&.*;", "", .) %>%
        ## strip punctuation
        removePunctuation %>%
        ## make all whitespace into spaces
        gsub("[[:space:]]+", " ", .)
        
    names(text.clean) <- NULL ## needed to avoid RStorm missing name error?
    Emit(Tuple(data.frame(text = text.clean, t.stamp = tuple$t.stamp)), ...)
}
topo <- AddBolt(topo, Bolt(clean.text, listen = 2, boltID = 3))

strip.stopwords <- function(tuple, ...){
    text.content <- removeWords(tuple$text,
                                removePunctuation(stopwords("SMART"))) %>%
        gsub("[[:space:]]+", " ", .)
    if(text.content != " " && !is.na(text.content)){
        Emit(Tuple(data.frame(text = text.content,
                              t.stamp = tuple$t.stamp)), ...)
    }
}
topo <- AddBolt(topo, Bolt(strip.stopwords, listen = 3, boltID = 4))

get.word.counts <- function(tuple, ...){
    words <- unlist(strsplit(tuple$text, " "))
    words.df <- GetHash("word.counts.df")
    if(!is.data.frame(words.df)) words.df <- data.frame()
    sapply(words, function(word){
               if(word %in% words.df$word){
                   words.df[word == words.df$word,]$count <<-
                       words.df[word == words.df$word,]$count + 1
               } else{
                   words.df <<- rbind(words.df,
                                     data.frame(word = word, count = 1))
               }
           }, USE.NAMES = FALSE)
    SetHash("word.counts.df", words.df)
}
topo <- AddBolt(topo, Bolt(get.word.counts, listen = 4, boltID = 5))

get.polarity <- function(tuple, ...){
    polarity <- classify_polarity(tuple$text)[,4]
    Emit(Tuple(data.frame(text = tuple$text,
                          t.stamp = tuple$t.stamp,
                          polarity = polarity)), ...)
}
topo <- AddBolt(topo, Bolt(get.polarity, listen = 4, boltID = 6))

track.polarity <- function(tuple, ...){
    polarity.df <- GetHash("polarity.df")
    if(!is.data.frame(polarity.df)) polarity.df <- data.frame()
    polarity.df <- rbind(polarity.df,
                         data.frame(polarity = tuple$polarity))
    SetHash("polarity.df", polarity.df)
    polarity <- polarity.df$polarity

    polar.mat <- cbind(p.positive = (polarity == "positive"),
                       p.neutral = (polarity == "neutral"),
                       p.negative = (polarity == "negative"))
    prop.df <- data.frame(t(colMeans(polar.mat, na.rm = TRUE)),
                          t.stamp = tuple$t.stamp)
    TrackRow("prop.df", prop.df)
}
topo <- AddBolt(topo, Bolt(track.polarity, listen = 6, boltID = 7))

store.words.polarity <- function(tuple, ...){
    polar.words.df <- GetHash("polar.words.df")
    if(!is.data.frame(polar.words.df)) polar.words.df <- data.frame()
    
    words <- unlist(strsplit(tuple$text, " "))
    polarity <- tuple$polarity

    sapply(words, function(word){
               if(word %in% rownames(polar.words.df)){
                   polar.words.df[word, polarity] <<-
                       polar.words.df[word, polarity] + 1
               } else {
                   n <- nrow(polar.words.df)
                   this.row <- data.frame(positive = 0, neutral = 0,
                                          negative = 0)
                   this.row[1, polarity] <- 1
                   polar.words.df <<- rbind(polar.words.df,
                                            na.omit(this.row))
                   rownames(polar.words.df)[n + 1] <<- word
               }
           })
    SetHash("polar.words.df", polar.words.df)
}
topo <- AddBolt(topo, Bolt(store.words.polarity, listen = 6, boltID = 8))

#### get results
system.time(result <- RStorm(topo))

#### word cloud
word.df <- GetHash("word.counts.df", result)
words <- word.df$word
counts <- word.df$count
wordcloud(words, counts, scale = c(3, 1), max.words = 100, min.freq = 5, 
          colors = c("black", "red"))
    

#### comparison cloud
polar.words.df <- na.omit(GetHash("polar.words.df", result))
comparison.cloud(polar.words.df, min.freq = 10, scale = c(3, 1),
                 colors = c("black", "cornflowerblue", "red"),
                 random.order = FALSE)

#### timeplot of polarity
prop.df <- GetTrack("prop.df", result)
prop.df.long <- prop.df %>% gather(Polarity, Proportion, -t.stamp)
ggplot(prop.df.long, aes(x = t.stamp, y = Proportion, color = Polarity)) +
    geom_line() + theme(legend.position = "top") + 
    scale_color_manual(values = c("cornflowerblue", "black", "red"))

## timeplot of tweets per minute
tpm.df <- GetTrack("tpm.df", result)
ggplot(tpm.df, aes(x = t.stamp, y = tpm)) + 
      geom_line()

## set stringsAsFactors back for safety.
options(stringsAsFactors = TRUE)
