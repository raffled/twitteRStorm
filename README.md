## twitterRStorm
This repository contains code used to prototype a streaming framework
for analysing Tweets about Comcast using the RStorm packages.

This is primarily being created for a presentation/tutorial at
Interface 2015.

### Purpose
The purpose of the stream is to simulate/prototype a streaming framework for a
someone wishing to analyze tweets matching a given topic, in this case
Comcast.  The stream will:

1. Keep track and visualize (with a wordcloud) common terms associated
   with the topic.
2. Classify and visualize the polarity (positive/negative/neutral) of
   tweets and visual common words in each class.
3. Keep track of the proportion of positive tweets as time goes on.
4. Visualize and report the rate of tweets in a given time frame.

### Dependencies
This project requires several R packages:

- `RStorm`
- `twitteR`
- `sentiment`*
- `wordcloud`
- `dplyr`
- `tidyr`

Most of these packages can be installed from CRAN, but `sentiment`
needs to be installed from source:

```
install.packages("http://cran.r-project.org/src/contrib/Archive/sentiment/sentiment_0.2.tar.gz",
	             repo = NULL, type = "source")
```

### Status
Current Contents:

File             | Description
-----------------|----------------------------
comcast_dash    | Folder containing shiny demo
`twitteRStorm.R` | Current prototype of stream
`scratch.R`      | Statis analysis of tweets, used to get ideas for analysis. 
`comcastTweets.bin` | Binary file of R data.frame `comcast.df`, used to store tweets for consistency in development.
`wordCountEx.R` | Example of using RStorm for word counts in sentences from RStorm doc.
`README.md` | Readme file for project.
`license.md` | License document for project.

