## Vector Data (Video 1)

library(sf) #work with vector data (polygon shapefiles, not rasters/gridded data)

shp <- 'data/cb_2016_us_county_5m'#US county boundaries
counties <- st_read(
    shp,
    stringsAsFactors = FALSE) #include when reading in data frame style data to make sure text columns are strings
head(counties) #multipolygon has special information about shape/geometry

sesync <- st_sfc( #creating  point shape with lat/long
    st_point(c(-76.503394, 38.976546)), 
    crs = st_crs(counties)) #crs = coordinate reference system; here it is same as counties

st_crs(counties) #check coordinate system
st_bbox(counties) #bounding box with min/max coordinates

## Bounding box

library(dplyr)
counties_md <- filter(
    counties,
    STATEFP == "24" #state of MD
)
st_bbox(counties_md) #see range of coordinates much smaller

#bounding box cannot be plotted as-is!

## Grid

grid_md <- st_make_grid(counties_md, n = 4) #n=4 means 4x4 grid around state of MD
#warning reminds you that we are working with unprojected lat/long which is fine at small scales

## Plot Layers (Video 2)

plot(grid_md)
plot(counties_md['ALAND'], add = TRUE) #add adds new objects on top of preceding project. works bc same coordinate system.
plot(sesync, col = "green", pch = 20, add = TRUE) #pch is shape, in this case solid circle

st_within(sesync, counties_md) #checks if point is within counties; result is 5 meaning SESYNC is in the 5th polygon row 

## Coordinate Transforms

shp <- 'data/huc250k'
huc <- st_read(
    shp,
    stringsAsFactors = FALSE) #projection is different than counties
st_crs(counties_md)
st_crs(huc)

prj <- '+proj=aea +lat_1=29.5 +lat_2=45.5 \
    +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0    \
    +ellps=GRS80 +towgs84=0,0,0,0,0,0,0   \
    +units=m +no_defs'

counties_md <- st_transform(
    counties_md,
    crs = prj)
huc <- st_transform(huc, crs = prj)
sesync <- st_transform(sesync, crs = prj)

plot(counties_md$geometry)
plot(huc$geometry,
     border = 'blue', add = TRUE)
plot(sesync, col = 'green',
     pch = 20, add = TRUE)

## Geometric Operations (Video 3)

state_md <- st_union(counties_md) #creating single object (not ind. counties) and lost attribute data for ind counties
plot(state_md)
state_md

huc_md <- st_intersection(huc, state_md) #intersect and keep only areas in MD and HUC
#warning means attributes are not recomputed, eg area

plot(huc_md, border = 'blue',
     col = NA, add = TRUE)

## Raster Data (Video 4)

library(raster)
nlcd <- raster('data/nlcd_agg.grd')
nlcd #print shows summary of raster files
plot(nlcd)

## Crop

extent <- matrix(st_bbox(huc_md), nrow = 2)
nlcd <- crop(nlcd, extent)
plot(nlcd)
plot(huc_md, col = NA, add = TRUE)
nlcd[1,1] #lower left hand corner, 1st pixel - returns code 41
head(nlcd@data@attributes[[1]]) #look at head of attribute table

## Raster data attributes

nlcd_attr <- nlcd@data@attributes
lc_types <- nlcd_attr[[1]]$Land.Cover.Class
levels(lc_types)

## Raster math

pasture <- mask(nlcd, nlcd == 81,
    maskvalue = FALSE) #set all pixels to NA/mask away if not pasture
plot(pasture)

nlcd_agg <- aggregate(nlcd, #reduce resolution/plot to make easier to work with
    fact = 25,
    fun = modal) #aggregate by mode (common value) in each block
nlcd_agg@legend <- nlcd@legend #supply original legend to aggregated
plot(nlcd_agg)

## Mixing rasters and vectors (Video 5)

plot(nlcd)
plot(sesync, col = 'green',
     pch = 16, cex = 2, add = TRUE)

sesync_lc <- extract(nlcd, st_coordinates(sesync))
sesync_lc #returns 23
lc_types[sesync_lc+1]#bc R counts at 1 but table starts at 0

county_nlcd <- extract(nlcd_agg, counties_md[1,])
table(county_nlcd) #frequency distribution of land cover types

modal_lc <- extract(nlcd_agg, huc_md, fun = modal)
huc_md <- huc_md %>%
    mutate(modal_lc = lc_types[modal_lc + 1])
huc_md #now has new attribute (modal_lc) most common land cover in each HUC

## Leaflet (Video 6) 
#can be used to put a interactive map on web

library(leaflet)
leaflet() %>% #creates blank map that you can add layers to with pipe statement
    addTiles() %>% #imports imagery from openstreetmap
    setView(lng = -77, lat = 39, 
        zoom = 7)

#can add local data as well if local data is in lat/long. Leaflet will automatically reproject
leaflet() %>%
    addTiles() %>%
    addPolygons(
        data = st_transform(huc_md, 4236)) %>% #4 is the EPSG code (coordinate system)
    setView(lng = -77, lat = 39, 
        zoom = 7)

#leaflet can also pull in webdata
leaflet() %>%
    addTiles() %>%
    addWMSTiles(
        "http://mesonet.agron.iastate.edu/cgi-bin/wms/nexrad/n0r.cgi",
        layers = "nexrad-n0r-900913", group = "base_reflect",
        options = WMSTileOptions(format = "image/png", transparent = TRUE),
        attribution = "weather data © 2012 IEM Nexrad") %>%
    setView(lng = -77, lat = 39, 
        zoom = 7)
