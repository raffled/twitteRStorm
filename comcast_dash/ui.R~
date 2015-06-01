#### Set up the user interface
shinyUI(fluidPage(
    titlePanel("Comcast Streaming Simulation"),
    sidebarLayout(
        sidebarPanel(
            p("This is a simulation showing how a reporting dashboard for a Storm streaming analysis of incoming tweets might look."),
            p("Click the \"play\" arrow on the Time in Stream slider to start the stream"),
            hr(),
            h4("Simulation"),
            sliderInput("timeInStream", "Time in Stream (min)",
                        min = 0, max = 60, value = 0, step = 1,
                        animate = animationOptions(interval = 3000)),
            hr(),
            h4("Wordcloud Options"),
            sliderInput("wordcloud.freq", "Minimum Frequency:",
                        min = 1,  max = 50, value = 5),
            sliderInput("wordcloud.max", "Maximum Number of Words:",
                        min = 1,  max = 300,  value = 100),
            hr(),
            h4("Polarity Cloud Options"),
            sliderInput("polarcloud.max", "Maximum Number of Words:",
                        min = 1,  max = 300,  value = 20)
        ), ## close sidebarPanel
        mainPanel(
            ## row for clouds
            fluidRow(
                column(5,
                       h3("Word Cloud"),
                       plotOutput("wordcloud")),
                column(5,
                       h3("Polarity Cloud"),
                       plotOutput("polaritycloud"))
            ), ## close cloud row
            ## row for timeplots
            fluidRow(
                column(10, plotOutput("timeplots"))
            ) ## close timeplot row
        ) ## close mainPanel
    ) ## close sidebarLayout
)) ## close fluidPage/shinyUI
