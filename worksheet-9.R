# Worksheet for SQLite lesson

# First you will need to copy the portal.sqlite file
# to your own workspace so that your changes to the file
# will not affect everyone else in the class!

file.copy('data/portal.sqlite', 'myportal.sqlite')

library(RSQLite)

# Create a connection object
con <- dbConnect(RSQLite::SQLite(), "myportal.sqlite") #kind of database, location
dbListTables(con) #shows there are three tables
dbListFields(con,'species') #explore table species

# Read a table
library(dplyr)

species <- tbl(con, 'species')
species

# Upload a new table
df <- data.frame(
  id = c(1, 2),
  name = c('Alice', 'Bob')
)

dbWriteTable(con, 'observers', df)

# remove existing observers table (Video 2)
dbRemoveTable(con, 'observers') 

# Recreate observers table

dbCreateTable(con, 'observers', list(
  id = 'integer primary key',
  name = 'text'
))

# add data to observers table
# with auto-generated id

df <- data.frame(
  name = c('Alice', 'Bob')
)

dbWriteTable(con, 'observers', df, append = TRUE)
dbReadTable(con, 'observers') #see id column integers and df names

# Try adding a new observer with existing id
df <- data.frame(
  id = c(1),
  name = c('J. Doe')
)

dbWriteTable(con, 'observers', df,
             append = TRUE) #should get error because we already have a record in observers table with ID=1

# Try violating foreign key constraint
dbExecute(con, 'PRAGMA foreign_keys = ON;')

df <- data.frame(
  month = 7,
  day = 16,
  year = 1977,
  plot_id = '100'
)

dbWriteTable(con, 'surveys', df,
             append = TRUE) #should get error bc plot ID constrained to 1-24

# Queries (Video 3)
# basic queries
year <- dbGetQuery(con, "SELECT year FROM surveys")

dbGetQuery(con, "SELECT year, month, day FROM surveys")

dbGetQuery(con, "SELECT * 
FROM surveys")

# limit query response
dbGetQuery(con, "SELECT year, species_id
FROM surveys
LIMIT 4")

# get only unique values
dbGetQuery(con, "SELECT DISTINCT species_id
FROM surveys")

dbGetQuery(con, "SELECT DISTINCT year, species_id
FROM surveys")

# perform calculations 
dbGetQuery(con, "SELECT plot_id, species_id,
  sex, weight / 1000.0
FROM surveys")

dbGetQuery(con, "SELECT plot_id, species_id, sex,
  weight / 1000 AS weight_kg
FROM surveys")

dbGetQuery(con, "SELECT plot_id, species_id, sex,
  ROUND(weight / 1000.0, 2) AS weight_kg
FROM surveys")

# filtering
# hint: use alternating single or double quotes to 
# include a character string within another
dbGetQuery(con, "SELECT *
FROM surveys
WHERE species_id = 'DM'")

dbGetQuery(con, "SELECT *
FROM surveys
WHERE year >= 2000")

dbGetQuery(con, "SELECT *
FROM surveys
WHERE year >=2000 AND species_id = 'DM'")

dbGetQuery(con, "SELECT *
FROM surveys
WHERE (year >=2000 OR year <=1990)
  AND species_id = 'DM'")

# Joins (Video 4)
# one to many 

#these two are in different tables
dbGetQuery(con, "SELECT weight, plot_type 
FROM surveys
JOIN plots
  ON surveys.plot_id = plots.plot_id")

# many to many
dbGetQuery(con, "SELECT weight, genus, plot_type
FROM surveys
JOIN plots
  ON surveys.plot_id = plots.plot_id
JOIN species
  ON surveys.species_id = species.species_id")

