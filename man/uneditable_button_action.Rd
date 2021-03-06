% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_server.R
\name{uneditable_button_action}
\alias{uneditable_button_action}
\title{Server side utility that marks selected points as uneditable}
\usage{
uneditable_button_action(input, ibi_data, selected_points = NULL)
}
\arguments{
\item{input}{{shiny} internal}

\item{ibi_data}{IBI data stored in a list of reactiveValues and edited during the user's {ibiVizEdit} session}

\item{selected_points}{the points defined by using the "drag" or "click" selection method}
}
\description{
Server side utility that marks selected points as uneditable
}
