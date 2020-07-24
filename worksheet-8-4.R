# Packages
library(dplyr)
library(ggplot2)

# Data
popdata <- read.csv('/home/becca/data/citypopdata.csv')

# User Interface
in1 <- selectInput(
  inputId = 'selected_city',
  label = 'Select a city',
  choices = unique(popdata[['NAME']])
)
in2 <- sliderInput(
  inputId = 'my_xlims',
  label = "Set X axis limits",
  min = 2010,
  max = 2018,
  value = c(2010, 2018))
side <- sidebarPanel('Options', in1, in2)
out1 <- textOutput('city_label')
out2 <- plotOutput('city_plot')
out3 <- dataTableOutput('city_table')
main <- mainPanel(out1, out2, out3)
tab <- tabPanel(
  title = 'City Population',
  sidebarLayout(side, main))
ui <- navbarPage(
  title = 'Census Population Explorer',
  tab)

# Server
server <- function(input, output) {

  slider_years <- reactive({
    seq(input[['my_xlims']][1],
        input[['my_xlims']][2])
  })
  
  output[['city_label']] <- renderText({
    input[['selected_city']]
  })
  
  output[['city_plot']] <- renderPlot({
    df <- popdata %>% 
      filter(NAME == input[['selected_city']]) %>%
      filter(year %in% slider_years())
    ggplot(df, aes(x = year, y = population)) + 
      geom_line()
  })
  
  output[['city_table']] <- renderDataTable({
    df <- popdata %>% 
      dplyr::filter(NAME == input[['selected_city']]) %>%
      filter(year %in% slider_years())
    df
  })
}

# Create the Shiny App
shinyApp(ui = ui, server = server)
