# Documenting and Publishing your Data Worksheet

# Preparing Data for Publication
library(tidyverse)

stm_dat <- read_csv("data/StormEvents.csv")

head(stm_dat)
tail(stm_dat)
str(stm_dat)

unique(stm_dat$EVENT_NARRATIVE) 

dir.create('storm_project', showWarnings = FALSE)
write_csv(stm_dat, "storm_project/StormEvents_d2006.csv")

# Creating metadata
library(dataspice) ; library(EML)

#install.packages("devtools"); devtools::install_github("ropenscilabs/dataspice") # had to do this bc wouldn't let me install 

create_spice(dir = "storm_project")

range(stm_dat$YEAR) #date range
range(stm_dat$BEGIN_LAT, na.rm=TRUE) #geographic range
range(stm_dat$BEGIN_LON, na.rm=TRUE)

edit_biblio(metadata_dir = "storm_project/metadata")

edit_creators(metadata_dir = "storm_project/metadata")

prep_access(data_path = "storm_project",
            access_path = "storm_project/metadata/access.csv")
edit_access(metadata_dir = "storm_project/metadata")

prep_attributes(data_path = "storm_project",
                attributes_path = "storm_project/metadata/attributes.csv")
edit_attributes(metadata_dir = "storm_project/metadata")

write_spice(path ='storm_project/metadata')
build_site(path = "storm_project/metadata/dataspice.json")


library(emld) ; library(EML) ; library(jsonlite)

json <- read_json("storm_project/metadata/dataspice.json")
eml <- as_emld(json)
write_eml(eml, "storm_project/metadata/dataspice.xml")

# Creating a data package (Video 3)
library(datapack) ; library(dataone)

dp <- new("DataPackage") # create empty data package

emlFile <- "storm_project/metadata/dataspice.xml"
emlId <- paste("urn:uuid:", UUIDgenerate(), sep = "")

... <- new("DataObject", id = ..., format = "eml://ecoinformatics.org/eml-2.1.1", file = ...)

dp <- ...(dp, ...)  # add metadata file to data package

... <- "storm_project/StormEvents_d2006.csv"
... <- paste("urn:uuid:", UUIDgenerate(), sep = "")

... <- new("DataObject", id = ..., format = "text/csv", filename = ...) 

dp <- ...(dp, ...) # add data file to data package

dp <- ...(dp, subjectID = ..., objectIDs = ...)

serializationId <- paste("resourceMap", UUIDgenerate(), sep = "")
filePath <- file.path(sprintf("%s/%s.rdf", tempdir(), serializationId))
status <- serializePackage(..., filePath, id=serializationId, resolveURI = "")

... <- serializeToBagIt(...) # right now this creates a zipped file in the tmp directory
file.copy(..., "storm_project/Storm_dp.zip") # now we have to move the file out of the tmp directory

# this is a static copy of the DataONE member nodes as of July, 2019
read.csv("data/Nodes.csv")






