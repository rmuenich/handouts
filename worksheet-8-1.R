#make sure you load library(shiny)
# User Interface
ui <- navbarPage(title = 'Hello, Shiny World!')

# Server
server <- function(input,output) {}

# Create the Shiny App
shinyApp(ui, server) #creates the run app function
