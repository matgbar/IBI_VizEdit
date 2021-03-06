% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_server.R
\name{average_button_action}
\alias{average_button_action}
\title{Server side function to facilitate averaging multiple points}
\usage{
average_button_action(ibi_data, selected_points = NULL, status = NULL)
}
\arguments{
\item{ibi_data}{IBI data stored in a list of reactiveValues and edited during the user's {ibiVizEdit} session}

\item{selected_points}{the points defined by using the "drag" or "click" selection method}

\item{status}{the status of the average button - whether it can be used or not}
}
\description{
Takes a single point and divides it into n points as determined by the user-specified denominator - defaults to 2 in
the UI
}
