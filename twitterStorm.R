#### load packages for twitter, storm, etc
library(RStorm)
library(twitteR)
library(sentiment)
library(wordcloud)

#### authorize API access
consumer.key <- "********"
consumer.secret <- "********"
access.token <- "********"
access.secret <- "********"
setup_twitter_oauth(consumer.key, consumer.secret,
                    access.token, access.secret)
source("twitterAuth.R")

