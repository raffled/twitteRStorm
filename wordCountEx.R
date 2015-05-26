library(RStorm)  # Include package RStorm
data(sentences)

# R function that receives a tuple
# (a sentence in this case)
# and splits it into words:
SplitSentence <- function(tuple, ...){
    ## Split the sentence into words
    words <- unlist(strsplit(as.character(tuple$sentence), " "))
    ## For each word emit a tuple
    for (word in words) Emit(Tuple(data.frame(word = word)), ...)
}

# R word counting function:
CountWord <- function(tuple, ...){
    ## Get the hashmap "word count"
    words <- GetHash("wordcount")
    if (tuple$word %in% words$word) {
        ## Increment the word count:
        words[words$word == tuple$word,]$count <- words[words$word == tuple$word,]$count + 1
    } else { # If the word does not exist
        ## Add the word with count 1
        words <- rbind(words, data.frame(
            word = tuple$word, count = 1))
    }
    ## Store the hashmap
    SetHash("wordcount", words)
}

## Setting up the R topology
## Create topology:
topology <- Topology(sentences)
## Add the bolts:
topology <- AddBolt(topology, Bolt(SplitSentence, listen = 0))
topology <- AddBolt(topology, Bolt(CountWord, listen = 1))

# Run the stream:
result <- RStorm(topology)
# Obtain results stored in "wordcount"
counts <- GetHash("wordcount", result)
