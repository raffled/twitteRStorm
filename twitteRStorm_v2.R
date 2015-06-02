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
#### Saves some pain with working with strings in bols
options(stringsAsFactors = FALSE)

#### create the topology
topo <- Topology(comcast.df[1:200,]) ## subset for testing

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
        in.last.min <-  (t.stamp.past >= last.min) & (t.stamp.past <= t.stamp.current)
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

strip.text <- function(tuple, ...){
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
topo <- AddBolt(topo, Bolt(strip.text, listen = 2, boltID = 3))

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

count.words <- function(tuple, ...){
    words <- unlist(strsplit(tuple$text, " "))
    words.df <- GetHash("words.df")
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
    SetHash("words.df", words.df)
}
topo <- AddBolt(topo, Bolt(count.words, listen = 4, boltID = 5))

get.polarity <- function(tuple, ...){
    polarity <- classify_polarity(tuple$text)[,4]
    Emit(Tuple(data.frame(text = tuple$text,
                          t.stamp = tuple$t.stamp,
                          polarity = polarity)), ...)
}
topo <- AddBolt(topo, Bolt(get.polarity, listen = 4, boltID = 6))

track.polarity <- function(tuple, ...){
    polarity <- tuple$polarity
    
    prop.df <- GetHash("prop.df")
    if(!is.data.frame(prop.df)) prop.df <- data.frame()
    
    
}

#### get results
system.time(result <- RStorm(topo))
comcast.results <- GetHash("tweet.df", result)

#### word cloud
word.df <- GetHash("words.df", result)
words <- word.df$word
counts <- word.df$count
wordcloud(words, counts)
    
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

options(stringsAsFactors = TRUE)
