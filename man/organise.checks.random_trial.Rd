% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ORGANISE__functions.R
\name{organise.checks.random_trial}
\alias{organise.checks.random_trial}
\title{Return a randomly selected trial for detailed checks.}
\usage{
organise.checks.random_trial(fixreport_df)
}
\arguments{
\item{fixreport_df}{object Input fixation report.}
}
\value{
Single trial as a data.table, which can be printed to the console for your viewing.
}
\description{
Return a randomly selected trial for detailed checks.
}
\examples{
data(fixationreport)
print(organise.checks.random_trial(fixationreport))
}
