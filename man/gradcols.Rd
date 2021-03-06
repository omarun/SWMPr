% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gradcols.R
\name{gradcols}
\alias{gradcols}
\title{Get colors for plots}
\usage{
gradcols(col_vec = NULL)
}
\arguments{
\item{col_vec}{chr string of plot colors to use. Any color palette from RColorBrewer can be used as a named input. Palettes from grDevices must be supplied as the returned string of colors for each palette.}
}
\value{
A character vector of colors in hexidecimal notation.
}
\description{
Get gradient default colors for plots
}
\details{
This is a convenience function for retrieving a color palette.  Palettes from RColorBrewer will use the maximum number of colors.  The default palette is 'Spectral'.
}

