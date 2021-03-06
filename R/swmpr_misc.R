######
#' Create a swmpr object
#' 
#' Wrapper for creating a swmpr object
#' 
#' @param  stat_in \code{data.frame} of swmp data
#' @param  meta_in chr string for station code (7 or 8 characters), can be multiple stations if data are combined
#' 
#' @export swmpr
#' 
#' @return Returns a swmpr object to be used with S3 methods
#' 
#' @details 
#' This function is a simple wrapper to \code{\link[base]{structure}} that is used internally within other functions to create a swmpr object.  The function does not have to be used explicitly.  Attributes of a swmpr object include \code{names}, \code{row.names}, \code{class}, \code{station}, \code{parameters}, \code{qaqc_cols}, \code{date_rng}, \code{timezone}, \code{stamp_class}, \code{metabolism} (if present), and \code{metab_units} (if present). 
#' 
swmpr <- function(stat_in, meta_in){
    
  if(!is.data.frame(stat_in)) 
    stop('stat_in must be data.frame')
  
  # qaqc attribute
  qaqc_cols <- FALSE
  if(any(grepl('^f_', names(stat_in)))) qaqc_cols <- TRUE
  
  # parameters attribute
  parameters <- grep('datetimestamp|^f_', names(stat_in), invert = TRUE, value = TRUE)
  
  # get stations, param_types attribtues
  param_types <- param_names()
  param_types <- unlist(lapply(param_types, function(x) any(x %in% parameters)))
  param_types <- names(param_names())[param_types]
  station <- grep(paste0(param_types, collapse = '|'), meta_in, value = TRUE)

  # remove trailing blanks in qaqc columns
  if(qaqc_cols){
   
    fcols <- grep('^f_', names(stat_in),value = TRUE)
    stat_in[, fcols] <- sapply(fcols, function(x){
      
      out <- gsub('\\s+$', '', stat_in[, x])
      return(out)
      
    })
    
  }
  
  # timezone using time_vec function
  timezone <- time_vec(station_code = station, tz_only = TRUE)

  # create class, with multiple attributes
  structure(
    .Data = stat_in, 
    class = c('swmpr', 'data.frame'), 
    station = station,
    parameters = parameters, 
    qaqc_cols = qaqc_cols,
    date_rng = range(stat_in$datetimestamp),
    timezone = timezone, 
    stamp_class = class(stat_in$datetimestamp),
    metabolism = NULL, 
    metab_units = NULL
    )
  
}

######
#' Parse web results for swmpr
#' 
#' Parsing function for objects returned from CDMO web services
#' 
#' @param  resp_in web object returned from CDMO server, response class from httr package
#' @param  parent_in chr string of parent nodes to parse
#' 
#' @import XML
#' 
#' @export
#' 
#' @details 
#' This function parses XML objects returned from the CDMO server, which are further passed to \code{\link{swmpr}}.  It is used internally by the data retrieval functions, excluding \code{\link{import_local}}.  The function does not need to be called explicitly.
#' 
#' @return Returns a \code{data.frame} of parsed XML nodes
parser <- function(resp_in, parent_in = 'data'){

  # convert to XMLDocumentContent for parsing
  raw <- xmlTreeParse(resp_in, useInternalNodes = TRUE)

  # get parent data nodes
  parents <- xpathSApply(
    raw,
    paste0('//', parent_in)
  )
  
  # get children nodes from data parents
  out <- lapply(parents, 
    function(x) getChildrenStrings(x)
    )
  out <- do.call('rbind', out)
  out <- data.frame(out)
  names(out) <- tolower(names(out))
  
  # return output
  return(out)
  
}

######
#' Format SWMP datetimestamp
#'
#' Format the datetimestamp column of SWMP data
#' 
#' @param  chr_in chr string of datetimestamp vector
#' @param  station_code is chr string for station (three or more characters)
#' @param  tz_only logical that returns only the timezone, default \code{FALSE}
#' 
#' @export
#' 
#' @return  Returns a POSIX vector if \code{tz_only} is true, otherwise the timezone for a station is returned as a chr string
#' 
#' @details 
#' This function formats the datetimestamp column of SWMP data to the \code{\link[base]{POSIXct}} format and the correct timezone for a station.  Note that SWMP data do not include daylight savings and the appropriate location based on GMT offsets is used for formatting.  This function is used internally within data retrieval functions and does not need to be called explicitly.
time_vec <- function(chr_in = NULL, station_code, tz_only = FALSE){
  
  # lookup table for time zones based on gmt offset - no DST!
  gmt_tab <- data.frame(
    gmt_off = c(-4,-5,-6,-8,-9),
    tz = c('America/Virgin', 'America/Jamaica', 'America/Regina',
      'Pacific/Pitcairn', 'Pacific/Gambier'),
    stringsAsFactors = FALSE
    )
  
  # hard-coded gmt offset for each site, from metadata direct from CDMO
  sites <- c('ace', 'apa', 'cbm', 'cbv', 'del', 'elk', 
    'gnd', 'grb', 'gtm', 'hud', 'jac', 'job', 'kac', 
    'lks', 'mar', 'nar', 'niw', 'noc', 'owc', 'pdb', 
    'rkb', 'sap', 'sfb', 'sos', 'tjr', 'wel', 'wkb',
    'wqb')
  gmt_offsets <- c(-5, -5, -5, -5, -5, -8, -6, -5, -5, -5, -5, -4, 
    -9, -6, -6, -5, -5, -5, -5, -8, -5, -5, -8, -8, -8,
    -5, -6, -5)  
  
  # get timezone from above information
  gmt_offset <- gmt_offsets[which(sites %in% substr(station_code, 1, 3))]
  tzone <- gmt_tab[gmt_tab$gmt_off %in% gmt_offset, 'tz']

  # timezone only if T
  if(tz_only) return(tzone)
  
  # format datetimestamp
  out <- as.POSIXct(chr_in, tz = tzone, format = '%m/%d/%Y %H:%M')
  
  # return output
  return(out)
  
}

######
#' Get parameters of a given type
#'
#' Get parameter column names for each parameter type
#' 
#' @param  param_type chr string specifying \code{'nut'}, \code{'wq'}, or \code{'met'}.  Input can be one to three types.
#' 
#' @export
#' 
#' @return Returns a named list of parameters for the \code{param_type}.  The parameter names are lower-case strings of SWMP parameters and corresponding qaqc names (\code{'f_'} prefix)
#' 
#' @details
#' This function is used internally within several functions to return a list of the expected parameters for a given parameter type: nutrients, water quality, or meteorological.  It does not need to be called explicitly. 
param_names <- function(param_type = c('nut', 'wq', 'met')){
  
  # sanity check
  if(any(!param_type %in% c('nut', 'wq', 'met')))
    stop('param_type must chr string of nut, wq, or met')
  
  nut_nms <- c('po4f', 'chla_n', 'no3f', 'no2f', 'nh4f', 'no23f', 'ke_n',
    'urea')
  nut_nms <- paste0(c('', 'f_'), rep(nut_nms, each = 2))
  
  wq_nms <- c('temp', 'spcond', 'sal', 'do_pct', 'do_mgl', 'depth', 
    'cdepth', 'level', 'clevel', 'ph', 'turb', 'chlfluor')
  wq_nms <- paste0(c('', 'f_'), rep(wq_nms, each = 2))
  
  met_nms <- c('atemp', 'rh', 'bp', 'wspd', 'maxwspd', 'wdir', 'sdwdir',
    'totpar', 'totprcp', 'cumprcp', 'totsorad')
  met_nms <- paste0(c('', 'f_'), rep(met_nms, each = 2))
  
  # get names for a given parameter type
  out <- sapply(param_type, function(x) get(paste0(x, '_nms')), simplify = FALSE)
  
  return(out)
  
}

######
#' Locations of NERRS sites
#'
#' Location of NERRS sites in decimal degress and time offset from Greenwich mean time.  Only active sites as of January 2015 are included.  Sites are identified by five letters indexing the reserve and site names.  The dataset is used to plot locations with the \code{\link{map_reserve}} function and to identify metabolic days with the \code{\link{ecometab}} function. 
#' 
#' @format A \code{\link[base]{data.frame}} object with 161 rows and 4 variables:
#' \describe{
#'   \item{\code{station_code}}{chr}
#'   \item{\code{latitude}}{numeric}
#'   \item{\code{longitude}}{numeric}
#'   \item{\code{gmt_off}}{int}
#' }
#' 
#' @seealso \code{\link{ecometab}}, \code{\link{map_reserve}}
"stat_locs"

######
#' Example nutrient data for Apalachicola Bay Cat Point station.
#'
#' An example nutrient dataset for Apalachicola Bay Cat Point station.  The data are a \code{\link{swmpr}} object that have been imported into R from csv files using the \code{\link{import_local}} function.  The raw data were obtained from the CDMO data portal but can also be accessed from a zip file created for this package.  See the source below.  The help file for the \code{\link{import_local}} function describes how the data can be imported from the zip file.  Attributes of the dataset include \code{names}, \code{row.names}, \code{class}, \code{station}, \code{parameters}, \code{qaqc_cols}, \code{date_rng}, \code{timezone}, and \code{stamp_class}. 
#'  
#' @format A \code{\link{swmpr}} object and \code{\link[base]{data.frame}} with 215 rows and 13 variables:
#' \describe{
#'   \item{\code{datetimestamp}}{POSIXct}
#'   \item{\code{po4f}}{num}
#'   \item{\code{f_po4f}}{chr}
#'   \item{\code{nh4f}}{num}
#'   \item{\code{f_nh4f}}{chr}
#'   \item{\code{no2f}}{num}
#'   \item{\code{f_no2f}}{chr}
#'   \item{\code{no3f}}{num}
#'   \item{\code{f_no3f}}{chr}
#'   \item{\code{no23f}}{num}
#'   \item{\code{f_no23f}}{chr}
#'   \item{\code{chla_n}}{num}
#'   \item{\code{f_chla_n}}{chr}
#' }
#' 
#' @source \url{https://s3.amazonaws.com/swmpexdata/zip_ex.zip}
#' 
#' @examples 
#' data(apacpnut)
"apacpnut"

######
#' Example water quality data for Apalachicola Bay Cat Point station.
#'
#' An example water quality dataset for Apalachicola Bay Cat Point station.  The data are a \code{\link{swmpr}} object that have been imported into R from csv files using the \code{\link{import_local}} function.  The raw data were obtained from the CDMO data portal but can also be accessed from a zip file created for this package.  See the source below.  The help file for the \code{\link{import_local}} function describes how the data can be imported from the zip file.  Attributes of the dataset include \code{names}, \code{row.names}, \code{class}, \code{station}, \code{parameters}, \code{qaqc_cols}, \code{date_rng}, \code{timezone}, and \code{stamp_class}. 
#'  
#' @format A \code{\link{swmpr}} object and \code{\link[base]{data.frame}} with 70176 rows and 25 variables:
#' \describe{
#'   \item{\code{datetimestamp}}{POSIXct}
#'   \item{\code{temp}}{num}
#'   \item{\code{f_temp}}{chr}
#'   \item{\code{spcond}}{num}
#'   \item{\code{f_spcond}}{chr}
#'   \item{\code{sal}}{num}
#'   \item{\code{f_sal}}{chr}
#'   \item{\code{do_pct}}{num}
#'   \item{\code{f_do_pct}}{chr}
#'   \item{\code{do_mgl}}{num}
#'   \item{\code{f_do_mgl}}{chr}
#'   \item{\code{depth}}{num}
#'   \item{\code{f_depth}}{chr}
#'   \item{\code{cdepth}}{num}
#'   \item{\code{f_cdepth}}{chr}
#'   \item{\code{level}}{num}
#'   \item{\code{f_level}}{chr}
#'   \item{\code{clevel}}{num}
#'   \item{\code{f_clevel}}{chr}
#'   \item{\code{ph}}{num}
#'   \item{\code{f_ph}}{chr}
#'   \item{\code{turb}}{num}
#'   \item{\code{f_turb}}{chr}
#'   \item{\code{chlfluor}}{num}
#'   \item{\code{f_chlfluor}}{chr}
#' }
#' 
#' @source \url{https://s3.amazonaws.com/swmpexdata/zip_ex.zip}
#'
#' @examples 
#' data(apacpwq)
"apacpwq"

######
#' Example water quality data for Apalachicola Bay Dry Bar station.
#'
#' An example water quality dataset for Apalachicola Bay Dry Bar station.  The data are a \code{\link{swmpr}} object that have been imported into R from csv files using the \code{\link{import_local}} function.  The raw data were obtained from the CDMO data portal but can also be accessed from a zip file created for this package.  See the source below.  The help file for the \code{\link{import_local}} function describes how the data can be imported from the zip file.  Attributes of the dataset include \code{names}, \code{row.names}, \code{class}, \code{station}, \code{parameters}, \code{qaqc_cols}, \code{date_rng}, \code{timezone}, and \code{stamp_class}. 
#'  
#' @format A \code{\link{swmpr}} object and \code{\link[base]{data.frame}} with 70176 rows and 25 variables:
#' \describe{
#'   \item{\code{datetimestamp}}{POSIXct}
#'   \item{\code{temp}}{num}
#'   \item{\code{f_temp}}{chr}
#'   \item{\code{spcond}}{num}
#'   \item{\code{f_spcond}}{chr}
#'   \item{\code{sal}}{num}
#'   \item{\code{f_sal}}{chr}
#'   \item{\code{do_pct}}{num}
#'   \item{\code{f_do_pct}}{chr}
#'   \item{\code{do_mgl}}{num}
#'   \item{\code{f_do_mgl}}{chr}
#'   \item{\code{depth}}{num}
#'   \item{\code{f_depth}}{chr}
#'   \item{\code{cdepth}}{num}
#'   \item{\code{f_cdepth}}{chr}
#'   \item{\code{level}}{num}
#'   \item{\code{f_level}}{chr}
#'   \item{\code{clevel}}{num}
#'   \item{\code{f_clevel}}{chr}
#'   \item{\code{ph}}{num}
#'   \item{\code{f_ph}}{chr}
#'   \item{\code{turb}}{num}
#'   \item{\code{f_turb}}{chr}
#'   \item{\code{chlfluor}}{num}
#'   \item{\code{f_chlfluor}}{chr}
#' }
#' 
#' @source \url{https://s3.amazonaws.com/swmpexdata/zip_ex.zip}
#' 
#' @examples 
#' data(apadbwq)
"apadbwq"

######
#' Example weather data for Apalachicola Bay East Bay station.
#'
#' An example weather dataset for Apalachicola Bay East Bay station.  The data are a \code{\link{swmpr}} object that have been imported into R from csv files using the \code{\link{import_local}} function.  The raw data were obtained from the CDMO data portal but can also be accessed from a zip file created for this package.  See the source below.  The help file for the \code{\link{import_local}} function describes how the data can be imported from the zip file.  Attributes of the dataset include \code{names}, \code{row.names}, \code{class}, \code{station}, \code{parameters}, \code{qaqc_cols}, \code{date_rng}, \code{timezone}, and \code{stamp_class}. 
#'  
#' @format A \code{\link{swmpr}} object and \code{\link[base]{data.frame}} with 70176 rows and 23 variables:
#' \describe{
#'   \item{\code{datetimestamp}}{POSIXct}
#'   \item{\code{atemp}}{num}
#'   \item{\code{f_atemp}}{chr}
#'   \item{\code{rh}}{num}
#'   \item{\code{f_rh}}{chr}
#'   \item{\code{bp}}{num}
#'   \item{\code{f_bp}}{chr}
#'   \item{\code{wspd}}{num}
#'   \item{\code{f_wspd}}{chr}
#'   \item{\code{maxwspd}}{num}
#'   \item{\code{f_maxwspd}}{chr}
#'   \item{\code{wdir}}{num}
#'   \item{\code{f_wdir}}{chr}
#'   \item{\code{sdwdir}}{num}
#'   \item{\code{f_sdwdir}}{chr}
#'   \item{\code{totpar}}{num}
#'   \item{\code{f_totpar}}{chr}
#'   \item{\code{totprcp}}{num}
#'   \item{\code{f_totprcp}}{chr}
#'   \item{\code{cumprcp}}{num}
#'   \item{\code{f_cumprcp}}{chr}
#'   \item{\code{totsorad}}{num}
#'   \item{\code{f_totsorad}}{chr}
#' }
#' 
#' @source \url{https://s3.amazonaws.com/swmpexdata/zip_ex.zip}
#'
#' @examples 
#' data(apaebmet)
"apaebmet"

######
#' Identify metabolic days in a time series
#'
#' Identify metabolic days in a time series based on sunrise and sunset times for a location and date.  The metabolic day is considered the 24 hour period between sunsets for two adjacent calendar days.  The function calls the \code{\link[maptools]{sunriset}} function from the maptools package, which uses algorithms from the National Oceanic and Atmospheric Administration (\url{http://www.esrl.noaa.gov/gmd/grad/solcalc/}).
#' 
#' @param dat_in data.frame
#' @param tz chr string for timezone, e.g., 'America/Chicago'
#' @param lat numeric for latitude
#' @param long numeric for longitude (negative west of prime meridian)
#' @param ... arguments passed to or from other methods
#' 
#' @import maptools
#' 
#' @export 
#' 
#' @details This function is only used within \code{\link{ecometab}} and should not be called explicitly.
#' 
#' @seealso 
#' \code{\link{ecometab}}, \code{\link[maptools]{sunriset}}
#' 
metab_day <- function(dat_in, ...) UseMethod('metab_day')

#' @rdname metab_day
#' 
#' @export
#' 
#' @method metab_day default
metab_day.default <- function(dat_in, tz, lat, long, ...){

  dtrng <- range(as.Date(dat_in$datetimestamp), na.rm = TRUE)
  start_day <- dtrng[1] - 1
  end_day <- dtrng[2] + 1
  lat.long <- matrix(c(long, lat), nrow = 1)
  sequence <- seq(
    from = as.POSIXct(start_day, tz = tz), 
    to = as.POSIXct(end_day, tz = tz),
    by = "days"
    )
  sunrise <- sunriset(lat.long, sequence, direction = "sunrise", 
      POSIXct = TRUE)
  sunset <- sunriset(lat.long, sequence, direction = "sunset", 
      POSIXct = TRUE)
  ss_dat <- data.frame(sunrise, sunset)
  ss_dat <- ss_dat[, -c(1, 3)]
  colnames(ss_dat) <- c("sunrise", "sunset")
  
  # remove duplicates, if any
  ss_dat <- ss_dat[!duplicated(strftime(ss_dat[, 1], format = '%Y-%m_%d')), ]
  ss_dat <- data.frame(
    ss_dat,
    metab_date = as.Date(ss_dat$sunrise, tz = tz)
    )
  ss_dat <- reshape2::melt(ss_dat, id.vars = 'metab_date')
  if(!"POSIXct" %in% class(ss_dat$value))
    ss_dat$value <- as.POSIXct(ss_dat$value, origin='1970-01-01', tz = tz)
  ss_dat <- ss_dat[order(ss_dat$value),]
  ss_dat$day_hrs <- unlist(lapply(
    split(ss_dat, ss_dat$metab_date),
    function(x) rep(as.numeric(x[2, 'value'] - x[1, 'value']), 2) 
    ))
  names(ss_dat)[names(ss_dat) %in% c('variable', 'value')] <- c('solar_period', 'solar_time')
  
  # matches is vector of row numbers indicating starting value that each
  # unique datetimestamp is within in ss_dat
  # output is meteorological day matches appended to dat_in
  matches <- findInterval(dat_in$datetimestamp, ss_dat$solar_time)
  out <- data.frame(dat_in, ss_dat[matches, ])
  row.names(out) <- 1:nrow(out)
  return(out)
   
}

######
#' Calculate oxygen mass transfer coefficient
#' 
#' Calculate oxygen mass transfer coefficient using equations in Thiebault et al. 2008.  Output is used to estimate the volumetric reaeration coefficient for ecosystem metabolism.
#'
#' @param temp numeric for water temperature (C)
#' @param sal numeric for salinity (ppt)
#' @param atemp numeric for air temperature (C)
#' @param wspd numeric for wind speed (m/s)
#' @param bp numeric for barometric pressure (mb)
#' @param height numeric for height of anemometer (meters)
#'
#' @import oce
#' 
#' @export
#' 
#' @details
#' This function is used within the \code{\link{ecometab}} function and should not be used explicitly.
#' 
#' @references
#' Ro KS, Hunt PG. 2006. A new unified equation for wind-driven surficial oxygen transfer into stationary water bodies. Transactions of the American Society of Agricultural and Biological Engineers. 49(5):1615-1622.
#' 
#' Thebault J, Schraga TS, Cloern JE, Dunlavey EG. 2008. Primary production and carrying capacity of former salt ponds after reconnection to San Francisco Bay. Wetlands. 28(3):841-851.
#' 
#' @seealso 
#' \code{\link{ecometab}}
#' 
calckl <- function(temp, sal, atemp, wspd, bp, height = 10){
  
  #celsius to kelvin conversion
  CtoK <- function(val) val + 273.15 
    
  Patm <- bp * 100; # convert from millibars to Pascals
  zo <- 1e-5; # assumed surface roughness length (m) for smooth water surface
  U10 <- wspd * log(10 / zo) / log(height / zo)
  tempK <- CtoK(temp)
  atempK <- CtoK(atemp)
  sigT <- swSigmaT(sal, temp, 10) # set for 10 decibars = 1000mbar = 1 bar = 1atm
  rho_w <- 1000 + sigT #density of SW (kg m-3)
  Upw <- 1.002e-3 * 10^((1.1709 * (20 - temp) - (1.827 * 10^-3 * (temp - 20)^2)) / (temp + 89.93)) #dynamic viscosity of pure water (sal + 0);
  Uw <- Upw * (1 + (5.185e-5 * temp + 1.0675e-4) * (rho_w * sal / 1806.55)^0.5 + (3.3e-5 * temp + 2.591e-3) * (rho_w * sal / 1806.55))  # dynamic viscosity of SW
  Vw <- Uw / rho_w  #kinematic viscosity
  Ew <- 6.112 * exp(17.65 * atemp / (243.12 + atemp))  # water vapor pressure (hectoPascals)
  Pv <- Ew * 100 # Water vapor pressure in Pascals
  Rd <- 287.05  # gas constant for dry air ( kg-1 K-1)
  Rv <- 461.495  # gas constant for water vapor ( kg-1 K-1)
  rho_a <- (Patm - Pv) / (Rd * atempK) + Pv / (Rv * tempK)
  kB <- 1.3806503e-23 # Boltzman constant (m2 kg s-2 K-1)
  Ro <- 1.72e-10     #radius of the O2 molecule (m)
  Dw <- kB * tempK / (4 * pi * Uw * Ro)  #diffusivity of O2 in water 
  KL <- 0.24 * 170.6 * (Dw / Vw)^0.5 * (rho_a / rho_w)^0.5 * U10^1.81  #mass xfer coef (m d-1)
  
  return(KL)
  
  }

######
#' Dissolved oxygen at saturation
#'
#' Finds dissolved oxygen concentration in equilibrium with water-saturated air. Function and documentation herein are from archived wq package.
#'
#' @param t tem temperature, degrees C
#' @param S salinity, on the Practical Salinity Scale
#' @param P pressure, atm
#'
#' @details Calculations are based on the approach of Benson and Krause (1984), using Green and Carritt's (1967) equation for dependence of water vapor partial pressure on \code{t} and \code{S}. Equations are valid for temperature in the range 0-40 C and salinity in the range 0-40.
#'
#' @return Dissolved oxygen concentration in mg/L at 100\% saturation. If \code{P = NULL}, saturation values at 1 atm are calculated.
#'
#' @references
#' Benson, B.B. and Krause, D. (1984) The concentration and isotopic fractionation of oxygen dissolved in fresh-water and seawater in equilibrium with the atmosphere. \emph{Limnology and Oceanography} \bold{29,} 620-632.
#'
#' Green, E.J. and Carritt, D.E. (1967) New tables for oxygen saturation of seawater. \emph{Journal of Marine Research} \bold{25,} 140-147.
oxySol <- function (t, S, P = NULL)
{
    T = t + 273.15
    lnCstar = -139.34411 + 157570.1/T - 66423080/T^2 + 1.2438e+10/T^3 -
        862194900000/T^4 - S * (0.017674 - 10.754/T + 2140.7/T^2)
    Cstar1 <- exp(lnCstar)
    if (is.null(P)) {
        Cstar1
    }
    else {
        Pwv = (1 - 0.000537 * S) * exp(18.1973 * (1 - 373.16/T) +
            3.1813e-07 * (1 - exp(26.1205 * (1 - T/373.16))) -
            0.018726 * (1 - exp(8.03945 * (1 - 373.16/T))) +
            5.02802 * log(373.16/T))
        theta = 0.000975 - 1.426e-05 * t + 6.436e-08 * t^2
        Cstar1 * P * (1 - Pwv/P) * (1 - theta * P)/((1 - Pwv) *
            (1 - theta))
    }
}

######
#' Decompose a time series
#' 
#' The function decomposes a time series into a long-term mean, annual, seasonal and "events" component. The decomposition can be multiplicative or additive, and based on median or mean centering. Function and documentation herein are from archived wq package.
#'
#' @param x a monthly time series vector
#' @param event whether or not an "events" component should be determined
#' @param type the type of decomposition, either multiplicative ("mult") or additive ("add")
#' @param center the method of centering, either median or mean
#' 
#' @details
#' The rationale for this simple approach to decomposing a time series, with examples of its application, is given by Cloern and Jassby (2010). It is motivated by the observation that many important events for estuaries (e.g., persistent dry periods, species invasions) start or stop suddenly. Smoothing to extract the annualized term, which can disguise the timing of these events and make analysis of them unnecessarily difficult, is not used.
#' 
#' A multiplicative decomposition will typically be useful for a biological community- or population-related variable (e.g., chlorophyll-a) that experiences exponential changes in time and is approximately lognormal, whereas an additive decomposition is more suitable for a normal variable. The default centering method is the median, especially appropriate for series that have large, infrequent events.
#' 
#' If \code{event = TRUE}, the seasonal component represents a recurring monthly pattern and the events component a residual series. Otherwise, the seasonal component becomes the residual series. The latter is appropriate when seasonal patterns change systematically over time. 
#' 
#' @seealso \code{\link{decomp_cj}}
#' 
#' @return
#' A monthly time series matrix with the following individual time series:
#' \item{original }{original time series}
#' \item{annual }{annual mean series}
#' \item{seasonal }{repeating seasonal component}
#' \item{events }{optionally, the residual or "events" series}
#' 
#' @references
#' Cloern, J.E. and Jassby, A.D. (2010) Patterns and scales of phytoplankton variability in estuarine-coastal ecosystems. \emph{Estuaries and Coasts} \bold{33,} 230--241.
decompTs <-
function(x, event = TRUE, type = c("add", "mult"),
         center = c("mean", "median")) {

  # Validate input
  if (!is.ts(x) || !identical(frequency(x), 12)) {
    stop("x must be a monthly 'ts' vector")
  }
  type = match.arg(type)
  center = match.arg(center)

  # Set the time window
  startyr <- start(x)[1]
  endyr <- end(x)[1]
  x <- window(x, start = c(startyr, 1), end = c(endyr, 12), extend=TRUE)

  # Choose the arithmetic typeations, depending on type
  if (type == "mult") {
    `%/-%` <- function(x, y) x / y
    `%*+%` <- function(x, y) x * y
  } else {
    `%/-%` <- function(x, y) x - y
    `%*+%` <- function(x, y) x + y
  }

  # Choose the centering method, depending on center
  if (center == "median") {
    center <- function(x, na.rm=FALSE) median(x, na.rm=na.rm)
  } else {
    center <- function(x, na.rm=FALSE) mean(x, na.rm=na.rm)
  }

  # Long-term center
  grand <- center(x, na.rm=TRUE)

  # Annual component
  x1 <- x %/-% grand
  annual0 <- aggregate(x1, 1, center, na.rm=TRUE)
  annual1 <- as.vector(t(matrix(rep(annual0, 12), ncol=12)))
  annual <- ts(annual1, start=startyr, frequency=12)

  # Remaining components
  x2 <- x1 %/-% annual
  if (event) {
  	# Seasonal component
    seasonal0 <- matrix(x2, nrow=12)
    seasonal1 <- apply(seasonal0, 1, center, na.rm=TRUE)
    seasonal <- ts(rep(seasonal1, endyr - startyr + 1), start=startyr,
                   frequency=12)
	  # Events component
    x3 <- x2 %/-% seasonal
    # result
    ts.union(original=x, grand, annual, seasonal, events=x3)
  } else {
    ts.union(original=x, grand, annual, seasonal=x2)
  }
}

#' @importFrom stats var end frequency is.ts start ts.union window
NULL