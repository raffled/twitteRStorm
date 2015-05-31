#### load required libraries
library(shiny)
library(sentiment)
library(wordcloud)
library(dplyr)
library(tidyr)
library(RColorBrewer)

#### load results to simulat
load("../comcast_results.bin")
#### extract the three data.frames
tweets.df <- na.omit(comcast_results$tweets.df)
proportion.df <- na.omit(comcast_results$proportion.df)
tpm.df <- na.omit(comcast_results$tpm.df)

## placeholder graph for time 0
foo <- data.frame(x = 0, y = 0,
                  label = "Initializing Stream . . . ")
init.plot <- ggplot(foo, aes(x = x, y = y, label = label)) +
    geom_text(size = 15) +
        theme(axis.line=element_blank(),
              axis.text.x=element_blank(),
              axis.text.y=element_blank(),
              axis.ticks=element_blank(),
              axis.title.x=element_blank(),
              axis.title.y=element_blank(),
              panel.background=element_blank(),
              panel.border=element_blank(),
              panel.grid.major=element_blank(),
              panel.grid.minor=element_blank(),
              plot.background=element_blank())

