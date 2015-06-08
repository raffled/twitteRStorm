# twitteRStorm
Doug Raffle  
6/13/2015  



## Topics

- Streaming Data
- The Storm Framework
- Storm Topologies
- Prototyping with `RStorm`
- Case Study: Prototyping a Twitter Tracker
- Bridging the Gap: the `Storm` Package and the Multi-Language Protocol

## Streaming Data
What makes streaming data a special case?

- Information is constantly flowing
- Analysis/Models need to be able to update as new information comes in
- Deliverables are (often) time sensitive
- Data piles up quickly -- Can't store everything


## Meet the Neighbors
Hadoop and Spark:

- Distributed
- Fault Tolerant
- Scalable
- Designed to analyze static data in batches
- Run batch once, get results

Spark has an answer for streaming data:

- Spark Streaming
- Works on "micro-batches" of data

## What is Storm?

Storm [@storm]:

- Distributed
- Fault Tolerant
- Scalable
- Designed for streaming data
- Runs constantly, updates results as new data comes in


## Who uses Storm?
Many companies you (probably) use every day [@usedby]:

- Twitter
- The Weather Channel
- Spotify
- Yahoo!
- WebMD

What do they all have in common?

- New information constantly coming in
- Users who want speed and accuracy

## The Storm Framework
What makes up a storm framework?

The **Topology** specifies:

- Where data comes from
- What gets down to each piece of data
- Where results are stored

Once a topology is running:

- New data enters the topology as it arrives
- The topology extracts relevant information
- Applications or databases are updated

## Storm Topologies
Storm frameworks are specified by "topologies" consisting of spouts and bolts.

**Spouts:**

- Data sources, e.g., Twitter
- Every topology has at least one spout

**Bolts:**

- Process individual pieces of data
- Receive data from spouts or other bolts

## Storm: Data Structures
The basic data structure in Storm is a **tuple**.

- A key-value pair representing an observation
- Spouts *emit* tuples as new data comes in
- Bolts *consume* tuples, process them, and emit 0 or more new tuples to other bolts

To aggregate results, bolts can also read from and write to more persistent data structures.

- Hash Maps -- quick, global storage internal to topology
- Databases -- more persistent storage for outside applications

## The Topology Visualized
<img style="width: 1000px; height: 600px; float: center;" src="sample_topo.png">

## Getting Storm Running
So how do we get Storm up-and-running?

- Storm is a complex framework with many dependencies
- Requires a data engineering team to implement at scale
- Even a local set up is time consuming and requires a fair amount of technical knowledge

Is there a Vagrant box?

- Wirbelsturm [@wirbel] - Germal for "cyclone"
- Comes pre-loaded, but not as user-friendly as Tessera boxes are for Hadoop/Spark
- No step-by-step tutorials

## Developing Topologies
What language do we use to create topologies?  It depends.

Spouts

- Written in a Java Virtual Machine (JVM) languages, e.g. Java, Clojure, Scala

Bolts

- Each one is a separate source file
- Can be written in any language using the Multi-Language Protocol
- Non-JVM languages (e.g. R, Python) must be wrapped in a JVM function

Topology

- Specified in YAML, packaged by Maven

## RStorm
Most statisticians and data scientists aren't fluent in JVM languages.  What do we do?

The `RStorm` package [@rstorm] is designed to *simulate* a Storm topology.

- `R` programmers can develop a topology in a familiar language
- Organizations can evaluate whether or not Storm is appropriate for their project

## RStorm
RStorm is:

- A simulation of Storm
- A first draft or scratch pad

RStorm is **not**:

- An equivalent of `Rhipe`/`RHadoop`/`SparkR`
- A way of communicating with Storm through `R`
- Used to write bolts that Storm can read (though this is an eventual goal)

## `RStorm` Overview
`RStorm` works by simulating topologies with `R` functions and data frames

- A spout is simulated by a `data.frame`, observations are emitted sequentially by row
- A tuple is a one row `data.frame`
- Bolts are functions which take a single tuple (`data.frame`) as input
- Storage is done exclusively in a hash map, where each record is a key-value pair where the key is a character string and the value is a `data.frame`
- Hashes can be read/write from inside the topology, or "trackers," which can only be written to row-by-row from within the topology

## Top-Level `RStorm` Functions
These functions are used to specify the topology, run it, and get the results:

Function | Purpose
---------|------------
`Topology(spout, ...)` | Creates a topology from a `data.frame`
`Bolt(FUNC, listen = 0, ...)` | Creates a bolt from a function, `listen` specifies the source of tuples
`AddBolt(topology, bolt, ...)` | Adds a bolt to the topology
`RStorm(topology, ...)` | Runs a fully-specified topology
`GetHash(name, topology)` | Retrieves a hash from the finished topology
`GetTrack(name, topology)` | Retrieves a track from a completed topology

## Within-Bolt Functions
These functions are called within bolts to perform operations:

Function | Purpose
---------|--------------
`Tuple(x, ...)` | Generates a tuple from a one-row `data.frame`
`GetHash(name, ...)` | Retreives a hash from within the topology
`SetHash(name, data)` | Saves a `data.frame` to the hash with key `name`
`TrackRow(name, data)`| Row binds a one-row `data.frame` to a tracked `data.frame`
`Emit(x, ...)` | Emits a tuple from within a bolt

## Example: Summing Values
As a small example, consider the following:

- Observations coming in are numbers
- The final result is the sum of the numbers
- We want to track the sum over time

We will write a small sample topology to illustrate the ideas of `RStorm`

## Example Topology
<img style="width: 900px; height: 600px; float: center;" src="example_topo.png">


## The Spout

```r
library(RStorm)
(dat <- data.frame(X = 1:5))
```

```
##   X
## 1 1
## 2 2
## 3 3
## 4 4
## 5 5
```

```r
topology <- Topology(dat)
```

```
## Created a topology with a spout containing  5 rows.
```

## Bolt 1: Current Sum

```r
get.sum <- function(tuple, ...){
  current.val <- tuple$X
  
  past.sum <- GetHash("current.sum")
  if(!is.data.frame(past.sum)) past.sum <- data.frame(c.sum = 0)
  
  current.sum <- past.sum$c.sum + current.val
  SetHash("current.sum", data.frame(c.sum = current.sum))
  Emit(Tuple(data.frame(c.sum = current.sum)), ...)
}
topology <- AddBolt(topology, Bolt(get.sum, listen = 0, boltID = 1))
```

```
## [1] "Added bolt get.sum to position 1 which listens to 0"
```

## Bolt 2: Track Sum

```r
track.sum <- function(tuple, ...){
  current.sum <- tuple$c.sum
  TrackRow("track.sum", data.frame(c.sum = current.sum))
}
topology <- AddBolt(topology, Bolt(track.sum, listen = 1, boltID = 2))
```

```
## [1] "Added bolt track.sum to position 2 which listens to 1"
```

```r
topology
```

```
## Topology with a spout containing 5 rows 
##  - Bolt ( 1 ): * get.sum * listens to 0 
##  - Bolt ( 2 ): * track.sum * listens to 1 
## No finalize function specified
```

## Get the Results

```r
results <- RStorm(topology)
GetHash("current.sum", results)
```

```
##   c.sum
## 1    15
```

```r
t(GetTrack("track.sum", results))
```

```
##       1 2 3  4  5
## c.sum 1 3 6 10 15
```

## Case Study: Twitter
You're a data scientist working for Comcast, and management wants to monitor tweets mentioning your company.  In particular, they want to know:

1. What are people talking about?
2. Are they saying positive or negative things?
3. What are the common topics of the good and bad tweets?
4. Can we track the percentage of good and bad tweets over time?
5. Can you tell us when people start talking about us more?
6. Can they have a dashboard for the marketing team to monitor, like [this](http://raffled.shinyapps.io/comcast_dash)?

## Twitter: Translating to Stats
First, we need to translate the requests to techniques and visualizations.

What are people talking about?

- Word frequencies $\to$ wordclouds

Are they saying positive or negative things?

- Classify the polarity (sentiment analysis)

What are common topics of good and bad tweets?

- Word frequencies by polarity $\to$ comparison clouds

## Twitter: Translating to Stats

Can we track the percentage of good and bad tweets over time?

- Track percent of each polarity classification over time $\to$ timeplots

Can you tell us when people start talking about us more?

- Track rate of tweets $\to$ timeplot

Can they get a dashboard?

- `shinydash`, Tableau, or Javascript

## Twitter: Which Platform?

**Small $n$, not time sensitive**

- Batch processing in `R` by day or week is probably good enough

**Small $n$, time sensitive**

- We can probably get away with an automated script and writing to a file/data base from within `R`

**Large $n$, not time sensitive**

- Hadoop or Spark batches run daily or weekly

**Large $n$, time sensitive**

- Storm (or Spark Streaming).  Assume this is the case.

## Prototyping the Stream
For our stream, we'll need:

- A `data.frame` of tweets for a spout

Bolts to:

- Track the rate of tweets using their time stamps
- Clean the text for sentiment analysis and word counts
- Count the words for the word cloud
- Classify the polarity
- Calculate the polarity over time
- Keep track of the words used in each polarity class

## Hashes
To store the tweets and track the information we need, we'll need hashes and trackers.

Hashes (read/write):

- Word Counts
- Polarity of each tweet

Trackers (write row-by-row):

- Tweets per Minute (TPM) at each new tweet
- Polarity Percentages updated as tweets come in



## Implementing the Twitter Stream
Implementing the stream is the topic of the tutorial, for now we will:

- Describe the topology
- Describe the bolts needed
- Describe the hashes and trackers
- Use the results

## The Topology
<img style="width: 750px; float: center;" src="my_topology.png">

## The Bolts
Bolt | Purpose
-----|-------------
`track.rate()` | Calculate and track tweets per minute over time
`get.text()` | Extract text from tweet
`clean.text()` | Clean special characters, links, punctuation, etc.
`strip.stopwords()` | Clean conjunctions, prepositions, etc.
`get.word.counts()` | Create and update word counts
`get.polarity()` | Classify polarity of a tweet
`track.polarity()` | Track percentage of positive/negative/neutral tweets over time
`store.words.polarity()` | Store words for each polarity level

## Data Frames

`data.frame` | Role | Description
-------------|------|---------------
`comcast.df` | Spout | Table to simulate tweets 
`word.counts.df` | Hash | Stores word frequencies
`t.stamp.df` | Hash | Store unique time stamps
`tpm.df` | Tracker | Track tweets per minute over time
`prop.df` | Tracker | Track percentage per polarity over time
`polarity.df` | Hash | Store polarity per tweet
`polar.words.df` | Hash | Keep track of words associated with each polarity

## Running the Topology

```r
topo
```

```
## Topology with a spout containing 200 rows 
##  - Bolt ( 1 ): * track.rate * listens to 0 
##  - Bolt ( 2 ): * get.text * listens to 0 
##  - Bolt ( 3 ): * clean.text * listens to 2 
##  - Bolt ( 4 ): * strip.stopwords * listens to 3 
##  - Bolt ( 5 ): * get.word.counts * listens to 4 
##  - Bolt ( 6 ): * get.polarity * listens to 4 
##  - Bolt ( 7 ): * track.polarity * listens to 6 
##  - Bolt ( 8 ): * store.words.polarity * listens to 6 
## No finalize function specified
```

```r
result <- RStorm(topo)
```

## Analyzing the Results
To analyze the results we need to:

- Read `word.counts.df` and make a wordcloud
- Read `polar.words.df` and make a comparison cloud
- Read `tpm.df` and make a timeplot
- Read `prop.df` and make a timeplot

We will see the code for this in the tutorial, but for now we'll just look at the plots

## Wordcloud
<img src="twitteRStorm_files/figure-html/unnamed-chunk-8-1.png" title="" alt="" style="display: block; margin: auto;" />

## Comparison Cloud
<img src="twitteRStorm_files/figure-html/unnamed-chunk-9-1.png" title="" alt="" style="display: block; margin: auto;" />

## Polarity over Time
<img src="twitteRStorm_files/figure-html/unnamed-chunk-10-1.png" title="" alt="" style="display: block; margin: auto;" />

## Tweet Rate over Time
<img src="twitteRStorm_files/figure-html/unnamed-chunk-11-1.png" title="" alt="" style="display: block; margin: auto;" />



## References





















