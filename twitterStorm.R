#### load packages for twitter, storm, etc
library(RStorm)
library(twitteR)
library(sentiment)
library(wordcloud)
library(dplyr)
library(tidyr)

#### authorize API access
## consumer.key <- "********"
## consumer.secret <- "********"
## access.token <- "********"
## access.secret <- "********"
## setup_twitter_oauth(consumer.key, consumer.secret,
##                     access.token, access.secret)

source("twitterAuth.R") ## stored credentials doesn't seem to work,
                        ## hack around w/ authorization script

#### Grab some tweets about Comcast
comcast.list <- searchTwitter("comcast", n = 1500, lang = "en")
comcast.df <- twListToDF(comcast.list)
head(comcast.df)
dim(comcast.df)

#### extract and clean text
comcast.text <- comcast.df %>% select(text)
comcast.clean <- comcast.text %>%
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

#### strip stop words
comcast.clean <- sapply(comcast.clean, removeWords,
                        words = removePunctuation(stopwords("SMART")))

names(comcast.clean) <- NULL
head(comcast.clean)

#### create a corpus, wordcloud
comcast.corpus <- Corpus(VectorSource(comcast.clean))
wordcloud(comcast.corpus)

#### Polarity stuff, comparison clound
## classify polarity of tweets
comcast.polar <- factor(classify_polarity(comcast.clean)[,4])
comcast.polar[is.na(comcast.polar)] <- "unknown"
## get levels of polarity
l.polar <- levels(comcast.polar)
n.polar <- length(l.polar)
## create a vector of words at each level of polarity
by.polar <- sapply(l.polar, function(p)
    paste(comcast.clean[comcast.polar == p], collapse = " "))
## turn polar word vectors into a corpus
polar.corpus <- Corpus(VectorSource(by.polar))
## get a document (count of each word w/in level of polarity)
polar.doc.mat <- as.matrix(TermDocumentMatrix(polar.corpus))
colnames(polar.doc.mat) <- l.polar
## make a comparison cloud of positive vs. negative
comparison.cloud(polar.doc.mat[,-2])
