% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ORGANISE__functions.R
\name{organise.message.fix_contingencies}
\alias{organise.message.fix_contingencies}
\title{Oganise and markup fixation contingencies.}
\usage{
organise.message.fix_contingencies(fixreport_df, ordered_message_list)
}
\arguments{
\item{fixreport_df}{Fixation report.}

\item{ordered_message_list}{List of messages to markup, in temporal order at which they occurred.}
}
\value{
Marked-up fixation report data.table.
}
\description{
Oganise and markup fixation contingencies.
}
\examples{

data(fixationreport)
data(messagereport)


# REPLACE SPACES IN MESSAGES
messagereport <- organise.message.replace_spaces(messagereport)

# TAKE A LOOK
print(organise.message.descriptives(messagereport))

# MARKUP
fixationreport <- organise.message.markup(message_df=messagereport, 
                                          fixreport_df = fixationreport, message="DISPLAY_START")

fixationreport <- organise.message.markup(message_df=messagereport, 
                                          fixreport_df = fixationreport, message="DISPLAY_CHANGE")

# NOW DO ACCURACY AND RT MARKUP
fixationreport <- organise.responses.markup(fixationreport, "CORRECT_RESPONSE")

# NOW MARK UP FIXATION CONTINGENCIES
fixationreport<-organise.message.fix_contingencies(fixationreport, 
                                          list("DISPLAY_START", "DISPLAY_CHANGE", "RESPONSE_TIME"))
}
