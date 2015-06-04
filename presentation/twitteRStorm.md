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

- Hash Maps
- Databases

## The Topology Visualized
<img style="width: 800px; height: 500px; float: center;" src="storm_topology.png">

## Getting Storm Running
So how do we get Storm up-and-running?

- Storm is a complex framework with many dependencies
- Requires a data engineering team to implement at scale
- Even a local set up is time consuming and requires a fair amount of technical knowledge

Is there a Vagrant box?

- Wirbelsturm [@wirbel]

## Developing Topologies
What language do we use to create topologies?  It depends.

Spouts

- Written in a Java Virtual Machine language (JVM), e.g. Java, Clojure, Scala

Bolts

- Each one is a separate source file
- Can be written in any language using the Multi-Language Protocol
- Non-JVM languages (e.g. R, Python) must be wrapped in a JVM language

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

- An equivalent of Rhipe/RHadoop
- A way of communicating with Storm through R
- Used to write bolts that Storm can read

## Case Study: Twitter
You're a data scientist working for Comcast, and management wants to monitor tweets mentioning you company.  In particular, they want to:

1. Keep track of common terms
2. Keep track of positive and negative tweets (polarity)
3. Know what topics associated with each polarity
4. Track the polarity over time
5. Track of the rate of tweets
6. Have a dashboard for the marketing team to monitor, like [this](http://raffled.shinyapps.io/comcast_dash)

## References




















