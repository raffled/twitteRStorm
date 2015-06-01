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
                comcast.corpus <- Corpus(VectorSource(head(tweets.df[inds(),]$text, 200)))
                wordcloud(comcast.corpus,
                          min.freq = input$wordcloud.freq,
                          max.words = input$wordcloud.max,
                          scale = c(3, 2),
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
                current.df <- head(tweets.df[inds(),], 200)
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
        output$poltime <- renderPlot({
            ## if we've been here long enough
            if(inds() && TRUE){
                prop.df <- proportion.df[inds(),] %>%
                    gather(Polarity, Proportion, -t.stamp)
                ggplot(prop.df, aes(x = t.stamp, y = Proportion*100, color = Polarity)) +
                    geom_line(size = 1.5) +
                    ylab("Percent") +
                    theme(legend.position = "top",
                          axis.title.y = element_text(size = 15),
                          legend.title = element_text(size = 15),
                          legend.text = element_text(size = 15)) +
                    xlab("Time")
            } else{
                init.plot
            }
        })
        output$tpm <- renderPlot({
            if(inds() && TRUE){
                ggplot(tpm.df[inds(),], aes(x = t.stamp, y = tpm)) +
                    geom_line(size = 1.5) +
                    xlab("Time") +
                    ylab("Tweets per Minute") +
                    theme(axis.title.y = element_text(size = 15),
                          axis.title.x = element_text(size = 15))
            } else{
                init.plot
            }
        }) ## close timeplots
    }
)
                
