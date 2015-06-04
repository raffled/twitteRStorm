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

## The Topology

## References





















