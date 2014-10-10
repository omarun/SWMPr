# SWMPr package for estuarine monitoring data

This repository contains materials to retrieve, organize, and analyze estuarine monitoring data from the System Wide Monitoring Program (<a href="http://nerrs.noaa.gov/RCDefault.aspx?ID=18">SWMP</a>) implemented by the National Estuarine Research Reserve System (<a href="http://nerrs.noaa.gov/">NERRS</a>).  SWMP was initiated in 1995 to provide continuous monitoring data at over 300 stations in 28 estuaries across the United States.  SWMP data are maintained online by the Centralized Data Management Office (CDMO). This R package will provide several functions to retrieve, organize, and analyze SWMP data from the CDMO.  Information on the CDMO web services are available <a href="http://cdmo.baruch.sc.edu/webservices.cfm">here</a>.  Your computer's IP address must be registered with the CDMO website to use most of the data retrieval functions, see contact info in the link.  All other functions can be used after obtaining data from the CDMO, as described below. 

The package has many dependencies, the most important being the SSOAP package for retrieving data from the CDMO using a SOAP client interface. The SSOAP package is not required to use SWMPr but is necessary for using most of the data retrieval functions.  The SSOAP package is currently removed from CRAN but accessible at <a href="http://www.omegahat.org/SSOAP/">http://www.omegahat.org/SSOAP/</a>.  Functions that require SSOAP will install the package automatically or it can be installed as follows:


```r
install.packages("SSOAP", repos="http://www.omegahat.org/R", dependencies = T,  type =  "source")
```

All data obtained from the CDMO should be <a href="http://cdmo.baruch.sc.edu/data/citation.cfm">cited</a> using the format:

National Estuarine Research Reserve System (NERRS). 2012. System-wide Monitoring Program. Data accessed from the NOAA NERRS Centralized Data Management Office website: http://cdmo.baruch.sc.edu/; accessed 12 October 2012.

To cite this package:

Beck MW. 2014. SWMPr: An R package for the National Estuarine Research Reserve System.  Version 0.2.0. https://github.com/fawda123/SWMPr

##Accessing the repository

This repository is currently under development and will later be uploaded as a package repository.  This will allow use of the `install.packages` function for direct install within R.  For now, Github users can fork and pull the materials to create a local clone of the current form.  Otherwise, the `funcs.r` file contains all currently developed (and partially tested) functions.  Package dependencies can be found in `.RProfile`.  Files ending in `retrieval.r` were used to test the functions.   

##Data retrieval

SWMP data can be obtained directly from the CDMO through an online query or by using the retrieval functions provided in this package.  In the latter case, the IP address for the computer making the request must be registered with CDMO.  This can be done by following instructions <a href="http://cdmo.baruch.sc.edu/webservices.cfm">here</a>.  The <a href="http://cdmo.baruch.sc.edu/data/metadata.cfm">metadata</a> should also be consulted for available data, including the parameters and date ranges for each monitoring station.  Metadata are included as a .csv file with data requested from the CDMO and can also be obtained using the `site_codes` (all sites) or `site_codes_ind` (individual site) functions.  


```r
# retrieve metadata for all sites
site_codes()

# retrieve metadata for a single site
site_codes_ind('apa')
```

Due to rate limitations on the server, the retrieval functions in this package return a limited number of records.  The functions are more useful for evaluating short time periods, although these functions could be used iteratively (i.e., with `for` or `while` loops) to obtain longer time series.  Data retrieval functions to access the CDMO include `all_params`, `all_params_dtrng`, and `single_param`.  These are functions that call the available methods on the CDMO SOAP interface.  `all_params` returns the most recent 100 records of all parameters at a station, `all_params_dtrng` returns all records within a date range for all parameters or a single parameter, and `single_param` is identical to `all_params` except that a single parameter is requested.    


```r
# all parameters for a station, most recent
all_params('sfbfmwq')

# get all parameters within a date range
all_params_dtrng('hudscwq', c('09/10/2012', '02/8/2013'))

# get single parameter within a date range
all_params_dtrng('hudscwq', c('09/10/2012', '02/8/2013')),
  param = 'do_mgl')

# single parameter for a station, most recent
single_param('tjrtlmet', 'wspd')
```

For larger requests, it's easier to obtain data outside of R using the CDMO query system.  Data can be retrieved from the CDMO several ways.  Data from single stations can be requested from the <a href="http://cdmo.baruch.sc.edu/get/export.cfm">data export system</a>, whereas data from multiple stations can be requested from the <a href="http://cdmo.baruch.sc.edu/aqs/">advanced query system</a>.  The `import_local` function is used to import local data into R that were downloaded from the CDMO with the <a href="http://cdmo.baruch.sc.edu/aqs/zips.cfm">zip downloads</a> feature within the advanced query system.  The downloaded data will include multiple .csv files by year for a given data type (e.g., apacpwq2002.csv, apacpwq2003.csv, apacpnut2002.csv, etc.).  It is recommended that all stations at a site and the complete date ranges are requested to avoid repeated requests to CDMO.  The `import_local` function can be used once the downloaded files are extracted to a local path. 


```r
# import data for apaebmet from 'zip_ex' path
import_local('data/zip_ex', 'apaebmet') 
```

In all cases, the imported data need to assigned to an object in the workspace for use with other functions:


```
## Loading SWMPr
```


```r
# import data and assign to dat
dat <- import_local('data/zip_ex', 'apaebmet', trace = F) 

# view first six rows
head(dat$station_data)
```

```
##         datetimestamp atemp f_atemp rh f_rh   bp f_bp wspd f_wspd maxwspd
## 1 2011-01-01 00:00:00  15.4    <0>  94 <0>  1019 <0>   2.6   <0>      3.4
## 2 2011-01-01 00:15:00  15.2    <0>  95 <0>  1019 <0>   2.7   <0>      4.0
## 3 2011-01-01 00:30:00  15.2    <0>  95 <0>  1019 <0>   2.8   <0>      3.5
## 4 2011-01-01 00:45:00  15.3    <0>  95 <0>  1019 <0>   3.1   <0>      4.2
## 5 2011-01-01 01:00:00  15.3    <0>  95 <0>  1018 <0>   3.2   <0>      4.4
## 6 2011-01-01 01:15:00  15.3    <0>  95 <0>  1018 <0>   3.6   <0>      4.9
##   f_maxwspd wdir f_wdir sdwdir f_sdwdir totpar  f_totpar totprcp f_totprcp
## 1      <0>   145   <0>       8     <0>     0.8 <1> (CSM)       0      <0> 
## 2      <0>   146   <0>       7     <0>     0.8 <1> (CSM)       0      <0> 
## 3      <0>   139   <0>       7     <0>     0.8 <1> (CSM)       0      <0> 
## 4      <0>   140   <0>       7     <0>     0.8 <1> (CSM)       0      <0> 
## 5      <0>   144   <0>       6     <0>     0.8 <1> (CSM)       0      <0> 
## 6      <0>   141   <0>       7     <0>     0.8 <1> (CSM)       0      <0> 
##   cumprcp f_cumprcp totsorad f_totsorad
## 1       0      <0>        NA      <-1> 
## 2       0      <0>        NA      <-1> 
## 3       0      <0>        NA      <-1> 
## 4       0      <0>        NA      <-1> 
## 5       0      <0>        NA      <-1> 
## 6       0      <0>        NA      <-1>
```

##swmpr object class

All data retrieval functions return a swmpr object that includes relevant data and several attributes describing the dataset.  The data include a datetimestamp column in the appropriate timezone for a station.  Note that the datetimestamp is standard time for each timezone and does not include daylight savings. Additional columns include parameters for a given data type (weather, nutrients, or wtaer quality) and correspondingg QAQC columns if returned from the initial data request.  The attributes for a swmpr object include `names` of the dataset, `class` (swmpr) `station name` (7 or 8 characters), `qaqc_cols` (logical), `date_rng` (POSIX vector), `timezone` (text string in country/city format), `stamp_class` (class of datetimestamp vector, POSIX or Date), and `parameters` (character vector).  Attributes of a swmpr object can be viewed as follows:


```r
# verify that dat is swmpr class
class(dat)
```

```
## [1] "swmpr"
```

```r
# all attributes of dat
attributes(dat)
```

```
## $names
## [1] "station_data"
## 
## $class
## [1] "swmpr"
## 
## $station
## [1] "apaebmet"
## 
## $parameters
##  [1] "atemp"    "rh"       "bp"       "wspd"     "maxwspd"  "wdir"    
##  [7] "sdwdir"   "totpar"   "totprcp"  "cumprcp"  "totsorad"
## 
## $qaqc_cols
## [1] TRUE
## 
## $date_rng
## [1] "2011-01-01 00:00:00 EST" "2013-12-31 23:45:00 EST"
## 
## $timezone
## [1] "America/Jamaica"
## 
## $stamp_class
## [1] "POSIXct" "POSIXt"
```

```r
# a single attribute of dat
attr(dat, 'station')
```

```
## [1] "apaebmet"
```

The swmpr object class was created for use with specific methods and it is suggested that these methods be used for data organization and analysis.  The actual data for a swmpr object (e.g., `dat$station_data` as a data frame) can be assigned to an object in the workspace if preferred, although this is not recommended.  Available methods for the swmpr class are described below and can also be viewed:


```r
# available methods for swmpr class
methods(class = 'swmpr')
```

```
## [1] aggregate.swmpr comb.swmpr      qaqc.swmpr      setstep.swmpr  
## [5] smoother.swmpr  subset.swmpr
```

##swmpr methods

Three categories of functions are available: retrieve, organize, and analyze.  The retrieval functions import the data into R as a swmpr object for use with the organize and analyze functions.  Methods defined for swmpr objects can be applied with the organize and analyze functions.  These methods are available for generic functions specific to this package, in addition to methods for existing generic functions available from other packages.  S3 methods are implemented in all cases.  

The organize functions are used to clean or prepare the data for analysis, including removal of QAQC flags, subsetting, creating a standardized time series vector, and combining data of different types.  The `qaqc` function is a simple screen to retain values from the data with specified QAQC flags, described <a, href="http://cdmo.baruch.sc.edu/data/qaqc.cfm">here</a>.  Each parameter in the swmpr data typically has a corresponding QAQC column of the same name with the added prefix 'f_'.  Values in the QAQC column specify a flag from -5 to 5.  Generally, only data with the '0' QAQC flag should be used, which is the default option for the `qaqc` function.  Data that do not satisfy QAQC criteria are converted to NA values.  Processed data will have QAQC columns removed, in addition to removal of values in the actual parameter columns that do not meet the criteria. 


```r
# qaqc screen for a swmpr object, retain only '0'
qaqc(dat)

# retain all data regardless of flag
qaqc(dat, qaqc_keep = NULL)

# retain only '0' and '-1' flags
qaqc(dat, qaqc_keep = c(0, -1))
```

A subset method added to the existing `subset` function is available for swmpr objects.  This function is used to subset the data by date and/or a selected parameter.  The date can be a single value or as two dates to select records within the range. The former case requires a binary operator input as a character string passed to the argument, such as `>` or `<`.  The subset argument for the date(s) must also be a character string of the format YYYY-mm-dd HH:MM for each element (i.e., %Y-%m%-%d %H:%M in POSIX standards).  Finally, the function can be used to remove rows and columns that do not contain data. 


```r
# select two parameters from dat
subset(dat, select = c('rh', 'bp'))

# subset records greater than or equal to a date
subset(dat, subset = '2013-01-01 0:00', operator = '>=')

# subset records within a date range
subset(dat, subset = c('2012-07-01 6:00', '2012-08-01 18:15'))

# subset records within a date range, select two parameters
subset(dat, subset = c('2012-07-01 6:00', '2012-08-01 18:15'),
  select = c('atemp', 'totsorad'))

# remove rows/columns that do not contain data
subset(dat, rem_empty = T)
```

The `setstep` function formats a swmpr object to a continuous time series at a given time step.  This function is not necessary for most stations but can be useful for combining data or converting an existing time series to a set interval.  The first argument, `timestep` specifies the desired time step in minutes starting from the nearest hour of the first observation.  The second argument, `differ`, specifies the allowable tolerance in minutes for matching existing observations to user-defined time steps in cases where the two are dissimilar.  Values for `differ` that are greater than one half the value of `timestep` are not allowed to prevent duplication of existing data.  Likewise, the default value for `differ` is one half the time step.  Rows that do not match any existing data within the limits of the `differ` argument are not discarded.  Output from the `setstep` function can be used with `subset` and to create a time series at a set interval with empty data removed.


```r
# convert time series to two hour invervals
# tolerance of +/- 30 minutes for matching existing data
setstep(dat, timestep = 120, differ = 30)

# convert a nutrient time series to a continuous time series
# then remove empty rows and columns
dat_nut <- import_local('data/zip_ex', 'apacpnut')
dat_nut <- setstep(dat_nut, timestep = 60)
subset(dat_nut, rem_rows = T, rem_cols = T)
```

The `comb` function is used to combine multiple swmpr objects into a single object with a continuous time series at a given step.  The `timestep` function is used internally such that `timestep` and `differ` are accepted arguments for `comb`.  The function requires one or more swmpr objects as input as separate, undefined arguments.  The remaining arguments must be called explicitly since an arbitrary number of objects can be used as input.  In general, the function combines data by creating a master time series that is used to iteratively merge all swmpr objects.  The time series for merging depends on the value passed to the `method` argument.  Passing `union` to `method` will create a time series that is continuous starting from the earliest date and the latest date for all input objects.  Passing `intersect` to `method` will create a time series that is continuous from the set of dates that are shared between all input objects.  Finally, a seven or eight character station name passed to `method` will merge all input objects based on a continuous time series for the given station.  The specified station must be present in the input data.  Currently, combining data types from different stations is not possible, excluding weather data which are typically at a single, dedicated station.  


```r
# get nuts, wq, and met data as separate objects for the same station
# note that most sites usually have one weather station
swmp1 <- import_local('data/zip_ex', 'apacpnut')
swmp2 <- import_local('data/zip_ex', 'apacpwq')
swmp3 <- import_local('data/zip_ex', 'apaebmet')

# combine nuts and wq data by union
comb(swmp1, swmp2, method = 'union')

# combine nuts and wq data by intersect
comb(swmp1, swmp3, method = 'intersect')

# combine nuts, wq, and met data by nuts time series, two hour time step
comb(swmp1, swmp2, swmp3, timestep = 120, method = 'apacpnut')
```

The analysis functions range from general purpose tools for time series analysis to more specific functions for working with continuous monitoring data in estuaries.  The latter category includes a limited number of functions that were developed by myself or others.  The general purpose tools are swmpr methods that were developed for existing generic functions in the R base installation or relevant packages.  These functions include swmpr methods for `aggregate`, `filter`, and `approx` to deal with missing or noisy data and more general functions for exploratory data analaysis.  The analysis functions may or may not return a swmpr object depending on whether further processing with swmpr methods is possible from the output.    

The `aggregate` function aggregates parameter data for a swmpr object by set periods of observation.  This function is most useful for aggregating noisy data to evaluate trends on longer time scales, or to simply reduce the size of a dataset.  Data can be aggregated by years, quarters, months, weeks, days, or hours for a user-defined function, which defaults to the mean.  A swmpr object is returned for the aggregated data, although the datetimestamp vector will be converted to a date object if the aggregation period is a day or longer.  Days are assigned to the date vector if the aggregation period is a week or longer based on the `round` method for IDate objects (<a href="http://cran.r-project.org/web/packages/data.table/index.html">data.table</a> package).  This approach was used to facilitate plotting using predefined methods for Date and POSIX objects.  Additionally, the method of treating NA values for the aggregation function should be noted since this may greatly affect the quantity of data that are returned (see the example below).  Finally, the default argument for `na.action` is set to `na.pass` for swmpr objects to preserve the time series of the input data.


```r
# combine, qaqc, remove empty columns
dat <- comb(swmp1, swmp2, method = 'union')
dat <- qaqc(dat)
swmpr_in <- subset(dat, rem_cols = T)

# get mean DO by quarters
aggregate(swmpr_in, 'quarters', params = c('do_mgl'))

# get mean DO by quarters, remove NA when calculating means
fun_in <- function(x) mean(x, na.rm = T)
aggregate(swmpr_in, FUN = fun_in, 'quarters', 
  params = c('do_mgl'))

# get variance of DO by years, remove NA when calculating variance
# omit NA data in output
fun_in <- function(x)  var(x, na.rm = T)
aggregate(swmpr_in, FUN = fun_in, 'years', na.action = na.exclude)
```

Time series can be smoothed to better characterize a signal independent of noise.  Although there are many approaches to smoothing, a moving window average is intuitive and commonly used.  The `smoother` function can be used to smooth parameters in a swmpr object using a specified window size.  This method is a simple wrapper to `filter`.  The `window` argument specifies the number of observations included in the moving average.  The `sides` argument specifies how the average is calculated for each observation (see the documentation for `filter`).  A value of 1 will filter observations within the window that are previous to the current observation, whereas a value of 2 will filter all observations withing the window centered at zero lag from the current observation. As before, the `params` argument specifies which parameters to smooth.


```r
# import data
swmp1 <- import_local('data/zip_ex', 'apadbwq')

# qaqc and subset imported data
dat <- qaqc(swmp1)
dat <- subset(dat, subset = c('2012-07-09 00:00', '2012-07-24 00:00'))

#filter
test <- smoother(dat, window = 50, params = 'do_mgl')
test <- test$station_data

# plot to see the difference
plot(do_mgl ~ datetimestamp, data = dat$station_data, type = 'l')
lines(test$datetimestamp, test$do_mgl, col = 'red', lwd = 2)
```

![plot of chunk unnamed-chunk-14](./README_files/figure-html/unnamed-chunk-14.png) 

##Functions

Three main categories of functions are available: retrieve, organize, and analyze.  Other miscellaneous functions are helpers/wrappers to these  functions or those used to obtain metadata.

<b>retrieve</b>

`all_params` Retrieve up to 100 records starting with the most recent at a given station, all parameters.  Wrapper to `exportAllParamsXMLNew` function on web services. 

`all_params_dtrng` Retrieve records of all parameters within a given date range for a station.  Optional argument for a single parameter.  Maximum of 1000 records. Wrapper to `exportAllParamsDateRangeXMLNew`.

`single_param` Retrieve up to 100 records for a single parameter starting with the most recent at a given station.  Wrapper to `exportSingleParamXMLNew` function on web services. 

`import_local` Import files from a local path.  The files must be in a specific format, specifically those returned from the CDMO using the <a href="http://cdmo.baruch.sc.edu/aqs/zips.cfm">zip downloads</a> option for a reserve.

<b>organize</b>

`qaqc.swmpr` Remove QAQC columns and remove data based on QAQC flag values for a swmpr object.  Only applies if QAQC columns are present.  

`subset.swmpr` Subset by dates and/or columns for a swmpr object.  This is a method passed to the generic `subset' function provided in the base package.

`setstep.swmpr` Format data from a swmpr object to a continuous time series at a given timestep.  The function is used in `comb.swmpr` and can also be used with individual stations.

`comb.swmpr` Combines swmpr objects to a common time series using setstep, such as combining the weather, nutrients, and water quality data for a single station. Only different data types can be combined.

<b>analyze</b> 

`aggregate.swmpr` Aggregate swmpr objects for different time periods - years, quarters, months,  weeks, days, or hours.  Aggregation function is user-supplied but defaults to mean. 

`smoother.swmpr` Smooth swmpr objects with a moving window average.  Window size and sides can be specified, passed to `filter`.

<b>miscellaneous</b>

`swmpr` Creates object of swmpr class, used internally in retrieval functions.

`parser` Parses html returned from CDMO web services, used internally in retrieval functions.

`time_vec` Converts time vectors to POSIX objects with correct time zone for a site/station, used internally in retrieval functions.

`site_codes` Metadata for all stations, wrapper to `exportStationCodesXMLNew` function on web services.

`site_codes_ind` Metadata for all stations at a single site, wrapper  to `NERRFilterStationCodesXMLNew` function on web services.

`param_names` Returns column names as a list for the parameter type(s) (nutrients, weather, or water quality).  Includes QAQC columns with 'F_' prefix. Used internally in other functions.

##Forthcoming

Analysis functions... approx, EDA, metab, trend analysis, etc.

Better documentation...

DOI/release info when done (see <a href="http://computationalproteomic.blogspot.com/2014/08/making-your-code-citable.html">here</a>)
