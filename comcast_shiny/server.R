#### Server side code
shinyServer(
    function(input, output, session){
        ## get indices of tweets we need based on time in stream
        inds <- reactive({
            ## get the start time
            start.time <- tweets.df$t.stamp[1]
            tweets.df$t.stamp < (start.time + 60*input$timeInStream)
        })
        ## Generate wordcloud
        output$wordcloud <- renderPlot({
            ## if we've been in the stream long enough
            if(inds() && TRUE){
                ## get the words
                word.vec <- paste(tweets.df[inds(),]$text,
                                  collapse = " ")
                wordcloud(word.vec,
                          min.freq = input$wordcloud.freq,
                          max.words = input$wordcloud.max,
                          scale = c(4, 1),
                          colors = brewer.pal(8, "Dark2"),
                          random.order = FALSE)
            } else{
                init.plot
            }
        })
        
    }
)
                
