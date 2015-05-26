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
## save(comcast.df, file = "comcastTweetsDF.bin")
load("comcastTweetsDF.bin")

################################ Topology ################################
topo <- Topology(comcast.df)

get.text <- function(tuple, ...){
    text <- tuple$text
    timestamp <- as.Date(tuple$created)
    Emit(Tuple(data.frame(text = text,
                          timestamp = timestamp)))
}
topo <- AddBolt(topo, Bolt(get.text, listen = 0, boltID = 1))

strip.text <- function(tuple, ...){
    text.clean <- tuple$text %>%
        ## convert to UTF-8
        sapply(iconv, to = "UTF-8") %>%
        ## strip URLs
        sapply(function(i) gsub("\\bhttps*://.+\\b", "", i)) %>% 
        ## force lower case
        sapply(tolower) %>%
        ## get rid of possessive's
        sapply(function(i) gsub("'s\\b", "", i)) %>%
        ## strip html special characters
        sapply(function(i) gsub("&.*;", "", i)) %>%
        ## make all whitespace into spaces
        sapply(function(i) gsub("[[:space:]]", " ", i)) %>%
        ## strip punctuation
        sapply(removePunctuation)
    timestamp <- tuple$timestamp
    Emit(Tuple(data.frame(text = text.clean,
                          timestamp = timestamp)))
}
topo <- AddBolt(topo, Bolt(strip.text, listen = 1, boltID = 2))

strip.stopwords <- function(tuple, ...){
    text.content <- removeWords(tuple$text,
                                removePunctionation(stopwords("SMART")))
    timestamp <- tuple$timestamp
    Emit(Tuple(data.frame(text = text.content,
                          timestamp = timestamp)))
}
topo <- AddBolt(topo, Bolt(strip.stopwords, listen = 2, boltID = 3))

store.words <- function(tuple, ...){
    word.df <- GetHash("word.df")
    timestamp <- tuple$timestamp
    this.df <- data.frame(text = tuple$text,
                          timestamp = timestamp)
    SetHash("word.df", rbind(word.df, this.df))
}
topo <- AddBolt(topo, Bolt(store.words, listen = 3, boltID = 4))

RStorm(topo, .debug = TRUE)

