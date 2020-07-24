## Tidy Concept

trial <- read.delim(sep = ',', header = TRUE, text = "
block, drug, control, placebo
    1, 0.22,    0.58,    0.31
    2, 0.12,    0.98,    0.47
    3, 0.42,    0.19,    0.40
")

## Pivot wide to long 

library(tidyr)
tidy_trial <- pivot_longer(trial,
                  cols = c(drug, control, placebo), #which ones pivot to longer format
                  names_to = 'treatment',
                  values_to = 'response')

## Pivot long to wide 

survey <- read.delim(sep = ',', header = TRUE, text = "
participant,   attr, val
1          ,    age,  24
2          ,    age,  57
3          ,    age,  13
1          , income,  30
2          , income,  60
")

tidy_survey <- pivot_wider(survey,
                   names_from = attr, #new column for each option in this column
                   values_from = val)

tidy_survey <- pivot_wider(survey,
                           names_from = attr,
                           values_from = val,
                           values_fill = 0) #fill in missing data

## Sample Data 

library(data.table)
cbp <- fread('data/cbp15co.csv')

cbp <- fread(#fip states and counties not correct format
  'data/cbp15co.csv',
  colClasses = c(
    FIPSTATE='character',
    FIPSCTY='character'
 ))

acs <- fread(
  'data/ACS/sector_ACS_15_5YR_S2413.csv',
  colClasses = c(FIPS = 'character'))

## dplyr Functions 

library(dplyr) 
cbp2 <- filter(cbp,#want NAICS code to be 2 digits long only
  grepl('----',NAICS),
  !grepl('------', NAICS))

library(stringr) #alternative approach
cbp2 <- filter(cbp,
  str_detect(NAICS, '[0-9]{2}----')) #looking for integer[0-9] followed by 2 integers {2} followed by four dashes ----

cbp3 <- mutate(cbp2, #alter columns; rewrite or create new; 
  FIPS = str_c(FIPSTATE,FIPSCTY)) #new data frame with combined state and county code

cbp3 <- mutate(cbp2, #example of multiple transformations
  FIPS = str_c(FIPSTATE, FIPSCTY),
  NAICS = str_remove(NAICS, '-+')) #rewriting NAICS to remove dashes

cbp <-cbp %>%  #piping multiple commands
  filter(
    str_detect(NAICS, '[0-9]{2}----') #output here is input to next function
  ) %>%
  mutate(
    FIPS = str_c(FIPSTATE, FIPSCTY),
    NAICS = str_remove(NAICS, '-+')
  )

cbp %>% #select specific columns
  select(
    FIPS,
    NAICS,
    starts_with('N')
  )

## Join

sector <- fread(
  'data/ACS/sector_naics.csv', # relates NAICS code to sector data
  colClasses = c(NAICS = 'character'))

cbp <- cbp %>% #many to one join(inner join)
  inner_join(sector) #has to have same column name; but we lost many rows after join due to sector data with no data; innerjoin only keeps data where code is in both try other functions

## Group By; bc some sectors have multiple codes

cbp_grouped <- cbp %>%
  group_by(FIPS, Sector) #each group has unique FIPS and unique sector; doesn't change data, but internally groups

## Summarize handling redundancy?

cbp <- cbp %>% #split, apply, combine?
  group_by(FIPS, Sector) %>% #sum values for each unique FIPS and sector?
  select(starts_with('N'),-NAICS) %>%
  summarize_all(sum)


acs_cbp <- cbp %>% #combine cbp data to acs data; relate with FIPS and sector
  inner_join(acs)
