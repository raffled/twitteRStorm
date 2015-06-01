##### Create the dashboard
dashboardPage(skin = "red",
    dashboardHeader(title = "Comcast Tweets"),
    dashboardSidebar(
        h4("Doug Raffle"),
        hr(),
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
                    min = 1,  max = 300,  value = 30)
    ),
    dashboardBody(
        fluidRow(
            column(width = 4,
                   box(title = "Word Cloud",
                       solidHeader = TRUE,
                       status = "danger",
                       width = NULL,
                       plotOutput("wordcloud")),
                   box(title = "Polarity Cloud",
                       solidHeader = TRUE,
                       status = "danger",
                       width = NULL,
                       plotOutput("polaritycloud"))
            ),
            column(width = 8,
                   box(title = "Polarity Over Time",
                       solidHeader = TRUE,
                       status = "danger",
                       width = NULL,
                       plotOutput("poltime")),
                   box(title = "Tweets per Minute",
                       solidHeader = TRUE,
                       status = "danger",
                       width = NULL,
                       plotOutput("tpm"))
            )
        )
    )
)
