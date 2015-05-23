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

source("twitterAuth.R") ## stored credentials doesn't seem to work,
                        ## hack around w/ authorization script

comcast.list <- searchTwitter("comcast", n = 1500, lang = "en")
comcast.df <- twListToDF(comcast.list)
head(comcast.df)
dim(comcast.df)

