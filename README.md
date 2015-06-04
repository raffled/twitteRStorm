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
presentation | Folder containing presentation source code
`twitteRStorm_v1.R` | Old prototype of stream. 
`twitteRStorm_v2.R` | Current prototype of stream w/ branchin topology
`scratch.R`      | Statis analysis of tweets, used to get ideas for analysis.
`comcastTweets.bin` | Binary file of R data.frame `comcast.df`, used to store tweets for consistency in development.
`wordCountEx.R` | Example of using RStorm for word counts in sentences from RStorm doc.
`README.md` | Readme file for project.
`license.md` | License document for project.

### Running twitteRStorm.R
Assuming the packages are isntalled, running the RStorm stream is very
straightforward. **Dependencies** for a list of required packages and
instructions for installing `sentiment`.

#### Authorizing `twitteR`
The only modifications you need to make are in the commented section
at the head of the documents. In order to search for tweets with
`twitteR`, you need to have a valid Twitter account. In the commented
region at the top of `twitteRStorm.R`, you will need to enter your
consumer key and secret and access token and secret, then call
`setup_twitter_oath()` with these strings.  To get your access key,
secret, and tokens: 

1. Have a valid Twitter Account
2. Go to [https://apps.twitter.com/](https://apps.twitter.com/)
3. Click `Create New App`
4. You can fill in dummy values for Name, Description, and Website
5. Once you're in your App, click on `Keys and Access Tokens`
6. The consumer key and secret will already exist, but click `Create
   my access token` for the access token and secret
7. Copy and paste these values in `R` and use them to run
   `setup_twitter_oath()`

From here, you can search for tweets with `searchTwitter()` and
convert the results to a data.frame with `twListToDF()`.  At this
point, all code should run as-is, with the exception of the name of
your tweet data.frame.

If you plan on developing the stream over time, saving the tweet
data.frame and loading it at the start of each session will ensure
that you have consistent data between sessions and save you the time
of authorizing each session.

### Viewing the Dashboard
The dashboard is designed to prototype how a dashboard for monitoring
tweets might took.  You can run the app locally by calling
`shiny::runApp()` in `R` from within the `comcast_dash` directory.

Alternatively, you can run the app from [shinyapps.io](shinyapps.io)
using the link:
[https://raffled.shinyapps.io/comcast_dash](https://raffled.shinyapps.io/comcast_dash).
