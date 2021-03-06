% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fct_input_and_process.R
\name{downsample_ppg_data}
\alias{downsample_ppg_data}
\title{Internal utility that creates a down-sampled data.frame of the ppg signal}
\usage{
downsample_ppg_data(
  ppg_data,
  sampling_rate,
  downsampled_rate = 100,
  ppg_col = "PPG",
  time_col = "Time"
)
}
\arguments{
\item{ppg_data}{\code{data.frame} that contains the processed PPG data}

\item{sampling_rate}{the original sampling rate in Hz of the PPG data}

\item{downsampled_rate}{the downsampling rate for the PPG waveform to enable easier plotting. Default is 100 Hz}

\item{ppg_col}{column name in \code{ppg_data} that contains the PPG signal}

\item{time_col}{column name in \code{ppg_data} that contains the timing information corresponding with the PPG
signal}
}
\value{
a \code{data.frame} with the down-sampled PPG signal
}
\description{
Internal utility that creates a down-sampled data.frame of the ppg signal
}
