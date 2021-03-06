
library(shiny)
library(tidyverse)
library(forcats)
library(ggthemes)
library(RColorBrewer)
library(ggrepel)
library(DT)

#Ui lays out the web page for the app- converts to HTML
ui <- fluidPage(

  titlePanel("LT Special Edition: Determining the best GM of all time"),

  tags$div(
    tags$p("There are number of different ways in which to assess each GMs performance over their respective tenures.
           However, there has been substantial variation in performance. For example, Kris finished 1st in year 1 but last in year 2.
           Has Kristians overall performance better or worse than Cody who has finished in Top 3 twice, but has so far failed to win?"),
    tags$p("I attempt to quantify the relative difference between GM performance over the past 4 seasons in two different ways:
           regular season performance and playoff performance. The two inevitably will be correlated as you obviously won't have playoff success
           if you do not make playoffs. "),
    tags$p("The issue with comparing years is that there are different numbers of weeks, different number of categories and different numbers of GMs.
           In order to compare year to year performance in the regular season I developed a standardized metric that is comparable year to year.
           Each year there is a theoretical maximum number of points a GM could get if they won every category every week.
           For example in 2014 we had 10 categories and there were 22 weeks, meaning that the maximum possible points a GM could get in a season would be 440 points.
           If in each year I divide the points obtained by the end of the regular season and divide by the maximum number of points I have a winning percentage
           comparable year to year. Now that I have a standardized measure for each year I can compare GMs with differing lengths of tenure by dividing the
           sum of the total number of points by the total number of maximum points for each year you were in the league."),
    tags$p("Here is a summary of GM performance in regular season and playoffs from 2014/15 to 2020/21:"),

    DT::dataTableOutput("regseasonsummary"),

      tags$p("I can then rank GMs through measures of deviance, that is how much better or worse than the average performance you are. Here I quantify
           regular season performance through Z-scores, which is a way of comparing how much better or worse a GMs average performance is than the league average performance.
           A z-score of 0 represents the league average, with  positive values representing above average and negative values representing below average values."),
    tags$p("But who cares about the regular season really? I need to be able to compare playoff performances between GMs to get a good idea of success.
           A simple and valid way to be to simply rank GMs by average winnings. But I will go a little further by adding a bit of nuance to these rankings.
           Here I make a few assumptions. Namely that 1) Finishing anywhere outside top 4 is virtually meaningless and 2) that finishing first is 4 times better than
           finishing second, 9 times better than third. This is roughly equivalent to the difference in cash payout between first, second and third place.
           To come up with a playoff score that is comparable across seasons (season 1 only had 10 GMS) I use the following formula:")
  ),
  tags$div(
    tags$blockquote(
      HTML(paste("(Number of GMs in a Season ",tags$em("x")," / Playoff Finish)", tags$sup(2), sep = ""))
      )),
  tags$div(
    tags$p("I can then plot  rgular season z-scores by play-off z scores to get an idea of overall performances. Because the relative weighting schemes for play-off performance are somewhat arbitrary
           in the plot below you can adjust the weights, to give more or less weight to finishing first.")
  ),



  sidebarLayout(
    sidebarPanel(
      sliderInput(inputId = "num",
              label = "Choose a weighting scheme (higher = greater weight on 1st place)",
              value = 2, min = 1, max = 6),
      tableOutput("weights")
      ),

    mainPanel(
      plotOutput("regseason")
    )

  ),

  tags$div(
    tags$p("How this plot is interpreted is: the further to the right, the better a regular season performer you are. The closer to the top, the better a
           playoff performer you are. Whichever quadrant you land in says something about your overall performances in both regular season and playoffs:"),
    tags$ul(
    tags$li("If you are in the bottom left you are \"Overall Poor Performers\"  where you have both poor regular seasons and playoff finishes. Lots of room for improvement."),
    tags$li("If you are in the bottom right quadrant you are \"Underachievers\", with good regular seasons, but poor playoff finishes. The League's perennial chokers."),
    tags$li("If you are in the top left you are either wildly inconsistent or really lucky, with good playoff performances but bad regular seasons. Just Luis."),
    tags$li("The top right is where the elite all around GMs reside, the \"All Time Greats\". These GMs have decent to excellent regular season performances, but more importantly,
top finishes in playoffs")
    ),
    tags$p("Regrettably, the numbers clearly show that the #1 GM over the course of his tenure is Nik. We should note that Nik's 2017/18 championship victory is mired in controversy with allegations of collusion between himself and disgraced former GM Clem.")
    )
)

#
server <- function(input, output) {

  results <- read_csv("FantasyHockeyResults.csv") %>%
    separate(WLT,c("WINS","LOSSES","TIES"),convert=TRUE) %>%
    mutate(NUM_CAT= ifelse(YEAR==2015,10,NA),
                      NUM_WEEKS = ifelse(YEAR==2015,22,NA)) %>%
    mutate(NUM_CAT= ifelse(YEAR==2016,12,NUM_CAT),
           NUM_WEEKS = ifelse(YEAR==2016,21,NUM_WEEKS)) %>%
    mutate(NUM_CAT= ifelse(YEAR==2017,13,NUM_CAT),
           NUM_WEEKS = ifelse(YEAR==2017,20,NUM_WEEKS))  %>%
    mutate(NUM_CAT= ifelse(YEAR==2018,13,NUM_CAT),
           NUM_WEEKS = ifelse(YEAR==2018,20,NUM_WEEKS))  %>%
    mutate(NUM_CAT= ifelse(YEAR==2019,13,NUM_CAT),
           NUM_WEEKS = ifelse(YEAR==2019,20,NUM_WEEKS))  %>%
    mutate(NUM_CAT= ifelse(YEAR==2020,13,NUM_CAT),
           NUM_WEEKS = ifelse(YEAR==2020,21,NUM_WEEKS))  %>%
    mutate(NUM_CAT= ifelse(YEAR==2021,13,NUM_CAT),
           NUM_WEEKS = ifelse(YEAR==2021,13,NUM_WEEKS))  %>%
    mutate(MAX_PTS = NUM_CAT*2*NUM_WEEKS) %>%
    mutate(MAX_PTS_PERCENTAGE = round(PTS/MAX_PTS*100,1))



  output$mytable = DT::renderDataTable({
    results
  })

  summary <- results %>%
    group_by(TEAM) %>%
    summarize(seasons = n(),
              total_points=sum(PTS,na.rm=TRUE),
              total_possible_points = sum(MAX_PTS,na.rm=TRUE),
              total_points_percentage = round(total_points/total_possible_points*100,2),
              times_made_playoffs = seasons - (sum(RANK>6 & YEAR==2015) + sum(RANK>8 & YEAR>2015,na.rm = TRUE)),
              times_made_finals = sum(RANK<=2,na.rm=TRUE),
              total_championships = sum(RANK==1,na.rm=TRUE)
    ) %>%
    arrange(desc(total_points_percentage))


  output$regseasonsummary = DT::renderDataTable({

    summary


  })

  output$regseason <- renderPlot({


  results <- results %>%
    group_by(YEAR) %>%
    mutate(rank_pct2 = (n()/RANK)^(input$num))


  results_team <- results %>%
    group_by(TEAM) %>%
    summarize(seasons = n(),
              max_rank = min(RANK,na.rm=TRUE),
              min_rank = max(RANK,na.rm=TRUE),
              pts=sum(PTS,na.rm=TRUE),
              avg_playoff_score = sum(rank_pct2,na.rm=TRUE)/n(),
              max_pts = sum(MAX_PTS,na.rm=TRUE),
              min_max_pts_percentage = min(MAX_PTS_PERCENTAGE,na.rm=TRUE),
              avg_max_pts_percentage = sum(PTS,na.rm=TRUE)/sum(MAX_PTS,na.rm=TRUE),
              max_max_pts_percentage = max(MAX_PTS_PERCENTAGE,na.rm=TRUE),
              `.groups`="drop_last") %>%
    arrange(desc(avg_max_pts_percentage)) %>%
    mutate(reg_season_z_score =  (avg_max_pts_percentage-mean(avg_max_pts_percentage))/sd(avg_max_pts_percentage),
           playoff_z_score = (avg_playoff_score-mean(avg_playoff_score))/sd(avg_playoff_score))

    results_team$`GM Category` <- ifelse(results_team$playoff_z_score < 0 & results_team$reg_season_z_score < 0 , "Overall Poor Performers", NA)  # above / below avg flag
  results_team$`GM Category` <- ifelse(results_team$playoff_z_score > 0 & results_team$reg_season_z_score < 0 , "One Hit Wonders",   results_team$`GM Category`)  # above / below avg flag
  results_team$`GM Category` <- ifelse(results_team$playoff_z_score > 0 & results_team$reg_season_z_score > 0 , "All Time Greats",   results_team$`GM Category`)  # above / below avg flag
  results_team$`GM Category` <- ifelse(results_team$playoff_z_score < 0 & results_team$reg_season_z_score > 0 , "Underachievers",   results_team$`GM Category`)  # above / below avg flag


  results_team %>% ggplot(aes(x=reg_season_z_score,y=playoff_z_score,col=`GM Category`)) +
    geom_hline(yintercept = 0)+
    geom_vline(xintercept = 0)+
    geom_label_repel(aes(label = TEAM))+
    geom_point(
      aes(size=seasons),
      alpha=0.85
    ) +
    scale_color_manual(values = c("All Time Greats"="#1A9850",
                                  "One Hit Wonders"="#6BAED6",
                                  "Underachievers"="#FDAE61",
                                 "Overall Poor Performers"="#A50026")) + theme_minimal() +
    theme(axis.title = element_text()) +
    scale_size_continuous(name="GM Tenure",range = c(2,6),
                          breaks = c(1,2,3,4,5,6,7)) +
    labs(y="Playoff Z-Score",
         x="Regular Season Z-Score")

  })

  output$weights <- renderTable({

    playoff <- function(x){

      return( (length(x)/x)^(input$num))

    }

    x <- data.frame("Playoff Finish" = c(1:12),Points = round(playoff(c(1:12)),1))
    x$`How much worse than finishing first?` <- round(x$Points[1]/x$Points,0)

    x




  })
}


shinyApp(ui = ui, server = server)
