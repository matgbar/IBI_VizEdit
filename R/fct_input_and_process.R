#' Internal utility for loading raw photoplethysmogram (PPG) data
#'
#' \code{load_ppg_data} loads the selected raw PPG data for subsequent processing and editing. Accepts tab-delimited
#' .txt formats only.
#'
#' @param file_name is of type \code{character} and identifies the file path containing the raw PPG signal.
#' @param skip_lines is of type \code{int} and specifies the number of lines in the raw file to skip.
#' @param column is of type \code{int} and specifies the column containing in the raw file containing the desired PPG
#' signal.
#' @param sampling_rate is of type \code{int} and specifies the hardware sampling rate for the raw signal in Hz
#'
#' @return returns a data.frame that contains the pre-processed PPG signal and a corresponding set of time codes,
#' initialized at 0.
#'
#' @export

load_ppg <- function(file_name=NULL, skip_lines=NULL, column=NULL, sampling_rate=NULL){
  if(file.exists(file_name)){
    parsed_file_name <- strsplit(file_name, '.', fixed=TRUE)
    file_extension <- parsed_file_name[[1]][length(parsed_file_name[[1]])]

    if(file_extension != "txt"){
      warning(paste("ibiVizEdit does not support", file_extension, "PPG file formats.", "\n",
                    "Your raw PPG data must be in a tab-delimited .txt file.", "\n",
                    "See documentation for additional details."))
    }
    else{
      ppg_file <- read.table(file = file_name, skip = skip_lines, sep='\t')
      ppg_df <- data.frame(PPG = ppg_file[,column],
                           Time = (0:(nrow(ppg_file)-1))/sampling_rate)
      return(ppg_df)
    }
  }
  else{
    warning(paste(file_name, "\n", "Not found. Check working directory and selected PPG file."))
  }
}


#' Internal utility that creates a down-sampled data.frame of the ppg signal
#' 
#' @param ppg_data \code{data.frame} that contains the processed PPG data 
#' @param sampling_rate the original sampling rate in Hz of the PPG data 
#' @param downsampled_rate the downsampling rate for the PPG waveform to enable easier plotting. Default is 100 Hz
#' @param ppg_col column name in \code{ppg_data} that contains the PPG signal
#' @param time_col column name in \code{ppg_data} that contains the timing information corresponding with the PPG
#' signal
#' 
#' @return a \code{data.frame} with the down-sampled PPG signal
#' @importFrom signal resample
#' @export

downsample_ppg_data <- function(ppg_data, sampling_rate, downsampled_rate=100, ppg_col="PPG", time_col="Time"){
  ds_ppg <- resample(ppg_data[[ppg_col]], p=downsampled_rate, q=sampling_rate)
  ds_time <- seq(min(ppg_data[[time_col]]), max(ppg_data[[time_col]]), length.out = length(ds_ppg))
  df <- data.frame(PPG=ds_ppg, Time=ds_time)
  return(df)
}


#' Internal utility that attempts to maximize raw signal properties to generate more reliable peak locations
#'
#' @param ppg_data \code{data.frame} that contains the processed PPG data 
#' @param sampling_rate the original sampling rate in Hz of the PPG data 
#' @param ppg_col column name in \code{ppg_data} that contains the PPG signal
#' @param time_col column name in \code{ppg_data} that contains the timing information corresponding with the PPG
#' signal
#' 
#' @return a processed and filtered PPG signal - de-noised and with linear trend removed
#' @importFrom seewave bwfilter
#' @export

filter_ppg <- function(ppg_data, sampling_rate, ppg_col="PPG", time_col="Time"){
  ppg_sig <- ppg_data[[ppg_col]]
  tmp_time <- 1:length(ppg_sig)
  ppg_sig <- as.numeric(ppg_sig)
  ppg_sig <- ppg_sig - predict(lm(ppg_sig~tmp_time))
  ppg_sig <- smooth.spline(ppg_sig, nknots=10*sampling_rate)$y
  ppg_sig <- ts(ppg_sig, frequency = sampling_rate)

  ppg_filtered <- bwfilter(ppg_sig, from=50/60, to=180/60, bandpass=TRUE, f=sampling_rate)

  df <- data.frame(PPG = ppg_filtered,
                   Time = ppg_data[[time_col]])

  return(df)
}


#' Internal utility that trims down the time range of the PPG signal used to edit the data
#'
#' @param ppg_data \code{data.frame} that contains the processed PPG data 
#' @param timing_data \code{data.frame} user defined input data set containing task timing
#' @param time_col column name in \code{ppg_data} that contains the timing information corresponding with the PPG
#' signal
#' 
#' @return a \code{data.frame} that has been restricted to the range of the timing file +/- 3 seconds
#' @export

trim_ppg_window <- function(ppg_data, timing_data, time_col="Time"){
  # Taking the min and max and adding a 3 second-buffer before the start and after the end of the observation period
  min_time <- min(timing_data[["Start"]]) - 3
  max_time <- max(timing_data[["Stop"]]) + 3
  df <- ppg_data[between(ppg_data[[time_col]], min_time, max_time),]
  return(df)
}

#' Internal utility for loading timing file
#'
#' \code{load_timing_data} loads the selected timing information for the targeted file. The timing file must be
#' formatted in such a way that the first column represents the file ID, and each column matches the start and stop of
#' sequential tasks/conditions of interest. Accepts tab-delimited .txt or .csv formats.
#'
#' @param file_name is of type \code{character} and represents the filepath containing timing information for the PPG
#' file of interest, with the first column being a unique identifier.
#' @param case_id is of type \code{character} and represents the unique identifier for the target PPG file. The value
#' is used to match the correct timing information to the target PPG file.
#'
#' @return returns a vector of time stamps that correspond to the start and stop time codes for tasks/conditions of
#' interest
#' @export

load_timing_data <- function(file_name=NULL, case_id=NULL){
  if(file.exists(file_name) & !is.null(case_id)){
    parsed_file_name <- strsplit(file_name, '.', fixed=TRUE)
    file_extension <- parsed_file_name[[1]][length(parsed_file_name[[1]])]
    timing_data <- NULL

    if(file_extension == 'txt'){
      timing_data <- read.table(file_name, header=TRUE, sep='\t')
    }
    else if(file_extension == "csv"){
      timing_data <- read.csv(file_name)
    }
    else{
      warning(paste("ibiVizEdit does not support", file_extension, "timing file formats", "\n",
                    "See documentation for additional details"))
    }

    if(!is.null(timing_data) & case_id %in% timing_data[,1]){
      time_stamps <- timing_data[timing_data[,1] == case_id,]
      
      # Coerce any values imported as strings to numbers
      time_stamps[,2:ncol(time_stamps)] <- as.numeric(time_stamps[,2:ncol(time_stamps)])
      return(time_stamps)
    }
    else{
      warning(paste("Case ID:", case_id, "not found in the selected timing file:", '\n',
                    file_name))
    }
  }
}


#' Utility function for transforming timing file inputs into stacked display-friendly table
#'
#' There needs to be a lot of data formatting checks/errors raised here - lots of unit testing as a result too
#'
#' @param df the original timing data
#' 
#' @return \code{data.frame} formatted for a clean display on the processing tab in the ibiVizEdit \code{RShiny} gui
#' @export

create_gui_timing_table <- function(df=NULL){
  if(!is.null(df)){
    task <- c()
    start <- c()
    stop <- c()
    for(i in 1:ncol(df)){
      if(i%%2 == 0){
        task <- c(task, colnames(df)[i])
        start <- c(start, df[1,i])
        stop <- c(stop, df[1, i+1])
      }
    }
    display_df <- data.frame(Task=task, Start=start, Stop=stop)
    return(display_df)
  }
}

#' Internal utility for ibiVizEdit that centers PPG and IBI timing values a the start of a task file.
#'
#' \code{time_center} takes a PPG and/or IBI file and centers it at the very start of a task file. The effect is to cut
#' off any data prior to the initial time stamp and to set that value to 0, representing the start of the condition or
#' conditions of interest.
#'
#' @param x PPG or IBI \code{data.frame}
#' @param time_col the name of the column in \code{x} that contains the time data
#' @param timing_series the name of the \code{vector} that contains timestamps for the initial task and subsequent tasks.
#' Must be formatted such that the element is the start of the first task/condition, the second element is the end of
#' that task, the third is start of the second condition/task, the fourth is the end of that task and so on.
#'
#' @return a re-coded version of the inputs with new timing
#'
#' @export

time_center <- function(x, time_col = 'Time', timing_series = NULL){
  if(!is.null(timing_series)){
    x[time_col] <- x[time_col] - min(timing_series)
  }
  return(x)
}
