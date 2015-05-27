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
load("comcastTweetsDF.bin")  ## loads data.frame comcast.df

################################ Topology ################################
topo <- Topology(comcast.df)

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
    polarity <- classify_polarity(tuple$text)
    Emit(Tuple(data.frame(text = tuple$text,
                          t.stamp = tuple$t.stamp,
                          polarity = polarity)
}

store.tweet <- function(tuple, ...){
    tweet.df <- GetHash("tweet.df")
    if(!is.data.frame(tweet.df)) tweet.df <- data.frame()
    word.df <- rbind(tweet.df, tuple)
    SetHash("tweet.df", word.df)
}
topo <- AddBolt(topo, Bolt(store.words, listen = 3))

result <- RStorm(topo)
foo <- GetHash("word.df", result)
foo$count <- sapply(foo$text, function(i)
    length(unlist(strsplit(as.character(i), " "))), USE.NAMES = FALSE)

ggplot(foo, aes(x = t.stamp, y = count)) + geom_line()

