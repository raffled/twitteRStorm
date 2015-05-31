#### Server side code
shinyServer(
    function(input, output, session){
        ## get indices of tweets we need based on time in stream
        inds <- reactive({
            ## get the start time
            start.time <- min(tweets.df$t.stamp)
            tweets.df$t.stamp < (start.time + 60*input$timeInStream)
        })
        ## Generate wordcloud
        output$wordcloud <- renderPlot({
            ## if we've been in the stream long enough
            if(inds() && TRUE){
                ## get the words
                comcast.corpus <- Corpus(VectorSource(tweets.df[inds(),]$text))
                wordcloud(comcast.corpus,
                          min.freq = input$wordcloud.freq,
                          max.words = input$wordcloud.max,
                          scale = c(4, 2),
                          colors = brewer.pal(8, "Dark2"),
                          random.order = FALSE)
            } else{
                init.plot
            }
        }) ## close render wordcloud
        ## Generate Polarity Cloud
        output$polaritycloud <- renderPlot({
            # if we've been in the stream long enough
            if(input$timeInStream >= 3){
                current.df <- tweets.df[inds(),]
                l.polar <- levels(current.df$polarity)
                n.polar <- length(l.polar)
                by.polar <- sapply(l.polar, function(p)
                    paste(current.df$text[current.df$polarity == p],
                          collapse = " "))
                polar.corpus <- Corpus(VectorSource(by.polar))
                polar.doc.mat <- as.matrix(TermDocumentMatrix(polar.corpus))
                colnames(polar.doc.mat) <- l.polar
                comparison.cloud(polar.doc.mat,
                                 scale = c(3, 2),
                                 max.words = input$polarcloud.max,
                                 title.size = 2)
            } else{
                init.plot
            }
        }) ## close rending polar cloud
        ## Generate Timeplots
        output$timeplots <- renderPlot({
            ## if we've been here long enough
            if(inds() && TRUE){
                prop.df <- proportion.df[inds(),] %>%
                    gather(Polarity, Proportion, -t.stamp)
                g1 <- ggplot(prop.df,
                             aes(x = t.stamp, y = Proportion*100, color = Polarity)) +
                          geom_line() +
                          ylab("Percent") +
                          theme(legend.position = "top",
                                axis.text.x = element_blank(),
                                axis.title.y = element_text(size = 15),
                                legend.title = element_text(size = 15),
                                legend.text = element_text(size = 15)) +
                          xlab("")
                g2 <- ggplot(tpm.df[inds(),],
                             aes(x = t.stamp, y = tpm)) +
                          geom_line() + xlab("Time") +
                          ylab("Tweets per Minute") +
                          theme(axis.title.y = element_text(size = 15),
                                axis.title.x = element_text(size = 15))
                multiplot(g1, g2)
            } else{
                init.plot
            }
        }) ## close timeplots
    }
)
                
