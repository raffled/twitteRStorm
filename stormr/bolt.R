## Load Storm Library
library(Storm)

## create the Storm object
storm <- Storm$new()

## create bolt function
storm$lambda <- function(s){
    tuple <- s$tuple
    words <- unlist(strsplit(as.character(tuple$input[2]), " "))
    sapply(words, function(word){
               tuple$output <- vector("character", 1)
               tuple$output[1] <- word
               s$emit(tuple)
           })
    
}
storm$run()
