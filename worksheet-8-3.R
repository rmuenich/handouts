# Packages
library(ggplot2)
library(dplyr)

# Data
popdata <- read.csv('/home/becca/data/citypopdata.csv')

# User Interface
in1 <- selectInput(
  inputId = 'selected_city',
  label = 'Select a city',
  choices = unique(popdata[['NAME']])
)

out1 <- textOutput('city_label')
out2 <- plotOutput('city_plot')
side <- sidebarPanel('Options', in1)
main <- mainPanel(out1, out2)
tab1 <- tabPanel(
  title = 'City Population',
  sidebarLayout(side,main))
ui <- navbarPage(
  title = 'Census Population Explorer',
  tab1)

# Server
server <- function(input, output) {
  output[['city_label']] <- renderText({
    input[['selected_city']]
  })
  output[['city_plot']] <- renderPlot({
    df <- popdata %>%
      filter(NAME == input[['selected_city']])
    ggplot(df, aes(x = year, y = population)) +
      geom_line()
  })
}

# Create the Shiny App
shinyApp(ui = ui, server = server)
