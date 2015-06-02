#### load packages for twitter, storm, etc
library(RStorm)
library(twitteR)
library(sentiment)
library(wordcloud)
library(dplyr)
library(tidyr)

################################ Get Tweets ################################
#### authorize API access
## consumer.key <- "********"
## consumer.secret <- "********"
## access.token <- "********"
## access.secret <- "********"
## setup_twitter_oauth(consumer.key, consumer.secret,
##                     access.token, access.secret)

## source("twitterAuth.R") ## stored credentials doesn't seem to work,
##                         ## hack around w/ authorization script

## comcast.list <- searchTwitter("comcast", n = 1500, lang = "en")
## comcast.df <- twListToDF(comcast.list)
## head(comcast.df)
## dim(comcast.df)
## ## Reverse order to emulate streaming data
## comcast.df <- comcast.df[order(comcast.df$created),]
## save(comcast.df, file = "comcastTweetsDF.bin")
load("comcastTweetsDF.bin")  ## loads data.frame comcast.df

################################ Topology ################################
topo <- Topology(comcast.df) ## subset for testing

get.text <- function(tuple, ...){
    Emit(Tuple(data.frame(text = tuple$text,
                          t.stamp = tuple$created)), ...)
}
topo <- AddBolt(topo, Bolt(get.text, listen = 0))

strip.text <- function(tuple, ...){
    text.clean <- tuple$text %>%
        ## convert to UTF-8
        iconv(to = "UTF-8") %>%
        ## strip URLs
        sapply(function(i) gsub("\\bhttps*://.+\\b", "", i)) %>% 
        ## force lower case
        tolower %>%
        ## get rid of possessives
        sapply(function(i) gsub("'s\\b", "", i)) %>%
        ## strip html special characters
        sapply(function(i) gsub("&.*;", "", i)) %>%
        ## make all whitespace into spaces
        sapply(function(i) gsub("[[:space:]]", " ", i)) %>%
        ## strip punctuation
        removePunctuation
    names(text.clean) <- NULL ## needed to avoid RStorm missing name error?
    Emit(Tuple(data.frame(text = text.clean, t.stamp = tuple$t.stamp)), ...)
}
topo <- AddBolt(topo, Bolt(strip.text, listen = 1))

strip.stopwords <- function(tuple, ...){
    text.content <- removeWords(as.character(tuple$text),
                                removePunctuation(stopwords("SMART")))
    Emit(Tuple(data.frame(text = text.content,
                          t.stamp = tuple$t.stamp)), ...)
}
topo <- AddBolt(topo, Bolt(strip.stopwords, listen = 2))

get.polarity <- function(tuple, ...){
    polarity <- classify_polarity(tuple$text)[,4]
    Emit(Tuple(data.frame(text = tuple$text,
                          t.stamp = tuple$t.stamp,
                          polarity = polarity)), ...)
}
topo <- AddBolt(topo, Bolt(get.polarity, listen = 3))

track.tweet <- function(tuple, ...){
    ## build data.frame of tweets
    tweet.df <- GetHash("tweet.df")
    if(!is.data.frame(tweet.df)) tweet.df <- data.frame()
    tweet.df <- rbind(tweet.df, tuple)
    SetHash("tweet.df", tweet.df)

    ## track polarity
    polarity <- tweet.df$polarity
    polar.mat <- cbind(
        p.positive = polarity == "positive",
        p.neutral = polarity == "neutral",
        p.negative = polarity == "negative")
    prop.df <- data.frame(t(colMeans(polar.mat, na.rm = TRUE)),
                          t.stamp = tuple$t.stamp)
    TrackRow("prop.df", prop.df)

    ## get recent tweet rate
    last.min <- tuple$t.stamp - 60
    t.stamp.past <- tweet.df$t.stamp
    t.stamp.current <- tuple$t.stamp
    ## get tweets per minute (tpm) if we're at least a minute into the stream
    if(last.min >= min(t.stamp.past)){
        in.last.min <-  (t.stamp.past >= last.min) & (t.stamp.past <= t.stamp.current)
        tpm <- length(t.stamp.past[in.last.min])
    } else {
        tpm <- length(t.stamp.past <= t.stamp.current)
    }
    TrackRow("tpm.df", data.frame(tpm = tpm, t.stamp = t.stamp.current))
        
    ## pass the tuple through to maintain order of bolts
    Emit(Tuple(tuple), ...)
}
topo <- AddBolt(topo, Bolt(track.tweet, listen = 4))


#### get results
system.time(result <- RStorm(topo))
comcast.results <- GetHash("tweet.df", result)

#### word cloud
word.vec <- paste(comcast.results$text, collapse = " ")
wordcloud(word.vec, min.freq = 10,
          colors = brewer.pal(8, "Dark2"),
          scale = c(4, 1))

#### comparison cloud
l.polar <- levels(foo$polarity)
n.polar <- length(l.polar)
by.polar <- sapply(l.polar, function(p)
    paste(foo$text[foo$polarity == p], collapse = " "))
polar.corpus <- Corpus(VectorSource(by.polar))
polar.doc.mat <- as.matrix(TermDocumentMatrix(polar.corpus))
colnames(polar.doc.mat) <- l.polar
comparison.cloud(polar.doc.mat, scale = c(3, 1),
                 max.words = 100, title.size = 2)

#### timeplot of polarity
prop.df <- GetTrack("prop.df", result)
prop.df.long <- prop.df %>% gather(Polarity, Proportion, -t.stamp)
g1 <- ggplot(prop.df.long, aes(x = t.stamp, y = Proportion, color = Polarity)) +
    geom_point() + geom_line() + theme(legend.position = "top")

## timeplot of tweets per minute
tpm.df <- GetTrack("tpm.df", result)
g2 <- ggplot(tpm.df, aes(x = t.stamp, y = tpm)) + geom_point() +
    geom_line()
source("multiplot.R")
multiplot(g1, g2)

comcast_results <- list(tweets.df = comcast.results,
                        proportion.df = prop.df,
                        tpm.df = tpm.df)
save(comcast_results, file = "comcast_results.bin")
