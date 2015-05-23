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
comcast.df$clean <- comcast.clean
write.table(comcast.df, "comcastTweetsDF.tsv", sep="\t")

#### create a corpus, wordcloud
comcast.corpus <- Corpus(VectorSource(comcast.clean))
wordcloud(comcast.corpus, scale = c(2, .5))

#### Polarity stuff, comparison clound
## classify polarity of tweets
polar.df <- data.frame(classify_polarity(comcast.clean))
polar.df[1:3] <- apply(polar.df[1:3], 2, as.numeric)
comcast.polar <- polar.df$BEST_FIT
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

#### clustering
library(flexclust)
comcast.doc.mat <- t(as.matrix(TermDocumentMatrix(comcast.corpus)))
dim(comcast.doc.mat)
dist.mat <- dist(comcast.doc.mat, method = "binary")
comcast.hclust <- hclust(dist.mat)
plot(comcast.hclust)

ggplot(polar.df, aes(x = POS, y = NEG, color = BEST_FIT)) +
    geom_point()

ctrl <- list(iter.max = 20, tolerance = 0.001)
f.ctrl <- as(ctrl, "flexclustControl")
foo <- kcca(x = comcast.doc.mat[30,],
            k = 2,
            family = kccaFamily("kmedians"),
            control = f.ctrl)
image(foo)
