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

Most of these packages can be installed from CRAN, but `sentiment` and
one of its dependencies
need to be installed from source:

```
install.packages("tm")
install.packages("http://cran.r-project.org/src/contrib/Archive/Rstem/Rstem_0.4-1.tar.gz",
	             repo = NULL, type = "source")
install.packages("http://cran.r-project.org/src/contrib/Archive/sentiment/sentiment_0.2.tar.gz",
	             repo = NULL, type = "source")
```

### Status
Current Contents:

File             | Description
-----------------|----------------------------
comcast_dash    | Folder containing shiny demo
presentation | Folder containing presentation source code
tutorial | Folder containing tutorial source code
stormr | folder containing `Storm` package example
twitteRStorm.R | Standalone `R` Script of tutorial.
`README.md` | Readme file for project.
`license.md` | License document for project.


### Viewing the Dashboard
The dashboard is designed to prototype how a dashboard for monitoring
tweets might took.  You can run the app locally by calling
`shiny::runApp()` in `R` from within the `comcast_dash` directory.

Alternatively, you can run the app from [shinyapps.io](shinyapps.io)
using the link:
[https://raffled.shinyapps.io/comcast_dash](https://raffled.shinyapps.io/comcast_dash).
