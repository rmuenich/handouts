## Web Scraping (Video 1)
## script will read html information online and store data
#r can be a client like chrome

library(httr)

response <- GET('http://research.jisao.washington.edu/pdo/PDO.latest') #all text document with climate data; change in temp by month compared to avg over time
response #has a binary body - so we need a program to process this for us then (use rvest package)

library(rvest) 

pdo_doc <- read_html(response)
pdo_doc #all html code in one string; all data inside element called p

pdo_node <- html_node(pdo_doc, "p") #extracts individual elements from html document
pdo_text <- html_text(pdo_node) #extract text only, still another long text string

library(stringr)
pdo_text_2017 <- str_match(pdo_text, "(?<=2017).*.(?=\\n2018)") #find anything between strings 2017 and 2018

str_extract_all(pdo_text_2017[1], "[0-9-.]+") #separate out  numerical values from substring to give vector of values that are characters and can be converted to numbers
#note this process is difficult and specific to this webpage; just demo of manual process


## HTML Tables (Video 2)
#human read websites not set up like this, but other webdata sites may still be

census_vars_doc <- read_html('https://api.census.gov/data/2017/acs/acs5/variables.html')

table_raw <- html_node(census_vars_doc, 'table') #if you look at it most data in tbody

census_vars <- html_table(table_raw, fill = TRUE) #took like 8 min
head(census_vars) #20,000+ rows

library(tidyverse)

census_vars %>%
  set_tidy_names() %>% #some titles of columns are not valid character strings
  select(Name, Label) %>% 
  filter(grepl('Median household income', Label))

## Web Services (Video 3) 
#get data from web from an API (application programming interface; intended for programmers to extract data more systematically)

path <- 'https://api.census.gov/data/2018/acs/acs5' #census service to collect data from census over  years
query_params <- list('get' = 'NAME,B19013_001E', #get median houshold income variable
                     'for' = 'county:*', #all counties
                     'in' = 'state:24') #code for state of Maryland

response = GET(path, query = query_params)
response #already translated from binary to text
#apis usually return JSON or XML; we can see from this that it is JSON
response$headers['content-type'] #another way to see JSON format; need to convert to data fram


## Response Content

library(jsonlite)

county_income <- response %>%
  content(as = 'text') %>%
  fromJSON() #converts from json to data frame

head(county_income) #didn't recognize there were headers so we'd need to fix this; so careful of API returns; if you can, use a specialized package

## Specialized Packages (Video 4)
#preferred way to get API data if possible

library(tidycensus)
source('census_api_key.R') #everyone has to get their own API key

variables <- c('NAME', 'B19013_001E') #name and income code

county_income <- get_acs(geography = 'county',
                         variables = variables,
                         state = 'MD',
                         year = 2018,
                         geometry = TRUE) #spatial data in case want to make a map
head(county_income)

ggplot(county_income) + #make a map of data with lowest (dark) to highest (light) median household income
  geom_sf(aes(fill = estimate), color = NA) + 
  coord_sf() + 
  theme_minimal() + 
  scale_fill_viridis_c()

## Paging & Stashing (Video 5)
#many APIs limit number of times you can request so this helps
source('datagov_api_key.R')

api <- 'https://api.nal.usda.gov/fdc/v1/'
path <- 'foods/search'

query_params <- list('api_key' = Sys.getenv('DATAGOV_API_KEY'),
                     'query' = 'fruit')

doc <- GET(paste0(api, path), query = query_params) %>%
  content(as = 'parsed')
names(doc)
doc$totalHits #18,000 hits
length(doc$foods) #query only returned first page of results (eg first 50 items) so we need to do it many times and loop through

fruit <-doc$foods[[1]]
fruit$description

nutrients <- map_dfr(fruit$foodNutrients, #create data frame for nutrients in the one fruit in fruit
                     ~ data.frame(name = .$nutrientName, 
                                  value = .$value))
head(nutrients) #see that we have nutrients by weight


#that was all for one; want to do this iteratively to get full database
library(DBI) 
library(RSQLite)

fruit_db <- dbConnect(SQLite(), 'fruits.sqlite') #where we will store our results

query_params$pageSize <- 100 #can request so many per page to reduce number of queries we need

for (i in 1:10) { #get first 1000 records
  # Advance page and query
  query_params$pageNumber <- i #pull page number times page size
  response <- GET(paste0(api, path), query = query_params) #get response from API like above
  page <- content(response, as = 'parsed') # parse as we did above for the single page

  # Convert nested list to data frame (fcns from purr package)
  values <- tibble(food = page$foods) %>% 
    unnest_wider(food) %>%
    unnest_longer(foodNutrients) %>%
    unnest_wider(foodNutrients) %>%
    filter(grepl('Sugars, total', nutrientName)) %>%
    select(fdcId, description, value) %>%
    setNames(c('foodID', 'name', 'sugar'))
  
  # Stash in database; write the data frame to the database connection
  dbWriteTable(fruit_db, name = 'Food', value = values, append = TRUE) #will append to existing table
  
}

fruit_sugar_content <- dbReadTable(fruit_db, name = 'Food') #pull records from database back into data frame
head(fruit_sugar_content)

dbDisconnect(fruit_db) #always disconnect when done
