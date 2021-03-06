# GENERIC FUNCTION FOR CALCULATING MEANS OF ALL SORTS #############################################################################################################################################################
#' Generic function for calculating means
#'
#' @param fixreport_df Fixation report
#' @param aggregation_column_list List of columns to group by
#' @param output_column_expression Output column expression
#' @param final_output_column_expression Final output column expression
#' @param spss Should the function output for SPSS?
#' @param dvColumnName Column name of the dependent variable
#' @param prefixLabel Prefix label
#' @param debug Should debug information be provided?
#'
#' @return A data.table ready for SPSS analyses, which is also saved to disk as a text file.
#' @export
#'
#' @examples
#' # THIS IS A UTILITY FUNCTION THAT YOU WOULD NOT NORMALLY USE YOURSELF
analyse.calculate.means <- function(fixreport_df, aggregation_column_list, output_column_expression, final_output_column_expression, 
                                    spss, dvColumnName, prefixLabel = "", debug=FALSE){
    
  # CREATE DATA TABLE
  fix_DT <- data.table(fixreport_df)
  setkey(fix_DT, RECORDING_SESSION_LABEL, TRIAL_INDEX)
  
  # CREATE BY-TRIAL MEANS
  aggExpr <- "list(RECORDING_SESSION_LABEL, TRIAL_INDEX "
  finalAggExpr <- "list(RECORDING_SESSION_LABEL "
  graphAggExpr <- "list("
  
  # IF ITS NOT A BLANK COLUMN LIST
  if (length(aggregation_column_list) > 0){
    
    for (i in seq(1:length(aggregation_column_list))){    
      aggExpr <- paste(aggExpr, ", ", aggregation_column_list[i], sep="")
      finalAggExpr <- paste(finalAggExpr, ", ", aggregation_column_list[i], sep="")
      
      # IF THIS IS AFTER THE FIRST ONE, ADD A COMMA FOR THE GRAPHS WHICH HAVE NO RECORDING SESSION LABEL
      if (i>1){
        graphAggExpr <- paste(graphAggExpr, ", ", sep="")
      }
      
      graphAggExpr <- paste(graphAggExpr, aggregation_column_list[i], sep="")
    }
  }
  
  # CLOSE UP THE AGG LISTS
  aggExpr <- paste(aggExpr, ")", sep="")
  finalAggExpr <- paste(finalAggExpr, ")", sep="")
  graphAggExpr <- paste(graphAggExpr, ")", sep="")
  
  # PARSE THE EXPRESSIONS
  aggExprParsed <- parse(text = aggExpr)
  ocExprParsed <- parse(text = output_column_expression)
    
  out_DT <- fix_DT[,
                   eval(ocExprParsed),
                   eval(aggExprParsed)]
  
  if (debug==TRUE){
    message(out_DT)
  }
  
  # PARSE THE MEAN OF THE MEANS
  finalAggExprParsed <- parse(text = finalAggExpr)
  focParsed <- parse(text = final_output_column_expression)
  
  final_DT <- out_DT[,
                     eval(focParsed),
                     eval(finalAggExprParsed)]
    
  # CALCULATE MEANS FOR A GRAPH
  grExprParsed <- parse(text = graphAggExpr)
  graphmeansParsed <- parse(text = paste("list('AVERAGE' = .Internal(mean(", dvColumnName, ")),",
                                         "'SE' = sqrt(var(", dvColumnName, ")/length(", dvColumnName, ")))", sep=""))
                            
  graphs_DT <- final_DT[,
                        eval(graphmeansParsed),
                        eval(grExprParsed)]  
    
  if (spss==FALSE){  
    
    final = list("bytrial" = data.table(out_DT),
                 "byppt" = data.table(final_DT),
                 "graphs" = data.table(graphs_DT))
    
    return(final)
  }
  
  if (spss==TRUE){
        
    df <- data.frame(final_DT)
    df$RECORDING_SESSION_LABEL <- as.factor(df$RECORDING_SESSION_LABEL)
    
    wideExpr <- paste("spss_df <- data.frame(cast(df, RECORDING_SESSION_LABEL", sep="")
    
    for (i in seq(1:length(aggregation_column_list))){
      
      if(i < 2){
        wideExpr <- paste(wideExpr, "~", aggregation_column_list[i])
      }
      
      if(i > 1){
        wideExpr <- paste(wideExpr, "*", aggregation_column_list[i])
      }
      
    }
    
    wideExpr <- paste(wideExpr, ", value=c('", dvColumnName, "')))", sep="")
        
    wideExprParsed <- parse(text = wideExpr)
    
    eval(wideExprParsed)
    
    #write.table(spss_df, paste(prefixLabel, "_", dvColumnName, ".txt", sep=""), row.names=FALSE)
    
    return(data.table(spss_df))
    
  }
}

#############################################################################################################################################################
# MEAN FIX DURATION - WORKS WITH GLOBAL AND LOCAL #############################################################################################################################################################
#' Analyse mean fixation duration
#'
#' @param fixreport_df Fixation report
#' @param aggregation_column_list List of columns to group by
#' @param spss Should the function save output for SPSS?
#' @param prefixLabel Prefix label
#'
#' @return If spss is set to FALSE (which is the default), you'll get an object containing data.tables 
#' of by-trial means for fixation durations, by-trial means for particpants, and overall descriptive
#' statistics for use when creating graphs based on your data. If spss is set to TRUE, then you'll be 
#' provided with a 'wide' version of the data for analysis in packages such as SPSS. The function will
#' also save a copy of the for-spss file for you as well.
#' @export
#'
#' @examples
#' # BREAK UP BY TARGET-PRESENT AND TARGET-ABSENT TRIALS - THE COLUMN TRIALTYPE_TEXT
#' data(fixationreport)
#' fixDurs <- analyse.fix.duration(fixationreport, aggregation_column_list = list('TRIALTYPE_TEXT'))
analyse.fix.duration <- function(fixreport_df, aggregation_column_list=c(), spss=FALSE, prefixLabel=""){
  
  # SET UP OUTPUT COLUMN EXPRESSION
  ocExpr <- "list('MEAN_FIX_DURATION' = .Internal(mean(CURRENT_FIX_DURATION)))"
  
  # SET UP FINAL OUTPUT COLUMN EXPRESSION
  focExpr <- "list('MEAN_FIX_DURATION' = .Internal(mean(MEAN_FIX_DURATION)))"
  
  # DV COLUMN NAME
  dvColumnName = "MEAN_FIX_DURATION"
  
  # SEND ON TO CALCULATE
  out_df <- analyse.calculate.means(fixreport_df=fixreport_df, aggregation_column_list=aggregation_column_list, 
                                      output_column_expression=ocExpr, final_output_column_expression=focExpr, 
                                      spss, dvColumnName, prefixLabel)
  
  return(out_df)
}
#############################################################################################################################################################

#############################################################################################################################################################
# MEAN FIX COUNT - WORKS WITH GLOBAL AND LOCAL #############################################################################################################################################################
#' Analyse mean fixation count
#'
#' @param fixreport_df Fixation report
#' @param aggregation_column_list List of columns to group by
#' @param spss Should the function save output for SPSS?
#' @param prefixLabel Prefix label
#'
#'
#' @return If spss is set to FALSE (which is the default), you'll get an object containing data.tables 
#' of by-trial means for fixation counts, by-trial means for particpants, and overall descriptive
#' statistics for use when creating graphs based on your data. If spss is set to TRUE, then you'll be 
#' provided with a 'wide' version of the data for analysis in packages such as SPSS. The function will
#' also save a copy of the for-spss file for you as well.
#' @export
#'
#' @examples
#' # BREAK UP BY TARGET-PRESENT AND TARGET-ABSENT TRIALS - THE COLUMN TRIALTYPE_TEXT
#' data(fixationreport)
#' fixCounts <- analyse.fix.count(fixationreport, aggregation_column_list = list('TRIALTYPE_TEXT'))
analyse.fix.count <- function(fixreport_df, aggregation_column_list=c(), spss=FALSE, prefixLabel=""){
  
  # SET UP OUTPUT COLUMN EXPRESSION
  ocExpr <- "list('MEAN_FIX_COUNT' = length(CURRENT_FIX_INDEX))"
  
  # SET UP FINAL OUTPUT COLUMN EXPRESSION
  focExpr <- "list('MEAN_FIX_COUNT' = .Internal(mean(MEAN_FIX_COUNT)))"
  
  # DV COLUMN NAME
  dvColumnName = "MEAN_FIX_COUNT"
  
  # SEND ON TO CALCULATE
  out_df <- analyse.calculate.means(fixreport_df=fixreport_df, aggregation_column_list=aggregation_column_list, 
                                    output_column_expression=ocExpr, final_output_column_expression=focExpr, 
                                    spss, dvColumnName, prefixLabel)
  
  return(out_df)
}
#############################################################################################################################################################

#############################################################################################################################################################
# TOTAL FIX TIME (DURATION) - WORKS WITH GLOBAL AND LOCAL #############################################################################################################################################################
#' Analyse total fixation time
#'
#' @param fixreport_df Fixation report
#' @param aggregation_column_list List of columns to group by
#' @param spss Should the function save output for SPSS?
#' @param prefixLabel Prefix label
#'
#' @return If spss is set to FALSE (which is the default), you'll get an object containing data.tables 
#' of by-trial means for total fixation times, by-trial means for particpants, and overall descriptive
#' statistics for use when creating graphs based on your data. If spss is set to TRUE, then you'll be 
#' provided with a 'wide' version of the data for analysis in packages such as SPSS. The function will
#' also save a copy of the for-spss file for you as well.
#' @export
#'
#' @examples
#' # BREAK UP BY TARGET-PRESENT AND TARGET-ABSENT TRIALS - THE COLUMN TRIALTYPE_TEXT
#' data(fixationreport)
#' fixTotaltime <- analyse.fix.totaltime(fixationreport, 
#'      aggregation_column_list = list('TRIALTYPE_TEXT'))
analyse.fix.totaltime <- function(fixreport_df, aggregation_column_list=c(), spss=FALSE, prefixLabel=""){
  
  # SET UP OUTPUT COLUMN EXPRESSION
  ocExpr <- "list('MEAN_FIX_TOTAL_TIME' = sum(CURRENT_FIX_DURATION))"
  
  # SET UP FINAL OUTPUT COLUMN EXPRESSION
  focExpr <- "list('MEAN_FIX_TOTAL_TIME' = .Internal(mean(MEAN_FIX_TOTAL_TIME)))"
  
  # DV COLUMN NAME
  dvColumnName = "MEAN_FIX_TOTAL_TIME"
  
  # SEND ON TO CALCULATE
  out_df <- analyse.calculate.means(fixreport_df=fixreport_df, aggregation_column_list=aggregation_column_list, 
                                    output_column_expression=ocExpr, final_output_column_expression=focExpr, 
                                    spss, dvColumnName, prefixLabel)
  
  return(out_df)
}
#############################################################################################################################################################

#############################################################################################################################################################
# VISIT COUNT - WORKS WITH GLOBAL AND LOCAL #############################################################################################################################################################
#' Analyse visit count
#'
#' @param fixreport_df Fixation report
#' @param aggregation_column_list List of columns to group by
#' @param spss Should the function save output for SPSS?
#' @param prefixLabel Prefix label
#'
#' @return If spss is set to FALSE (which is the default), you'll get an object containing data.tables 
#' of by-trial means for number of visits to each object, by-trial means for particpants, and overall descriptive
#' statistics for use when creating graphs based on your data. If spss is set to TRUE, then you'll be 
#' provided with a 'wide' version of the data for analysis in packages such as SPSS. The function will
#' also save a copy of the for-spss file for you as well.
#' @export
#'
#' @examples
#' # BREAK UP BY TARGET-PRESENT AND TARGET-ABSENT TRIALS - THE COLUMN TRIALTYPE_TEXT
#' data(fixationreport)
#' fixationreport[,CURRENT_FIX_INTEREST_AREA_RUN_ID:=1,]
#' visitCounts <- analyse.visit.count(fixationreport, aggregation_column_list = list('TRIALTYPE_TEXT'))
analyse.visit.count <- function(fixreport_df, aggregation_column_list=c(), spss=FALSE, prefixLabel=""){
  
  # SET UP OUTPUT COLUMN EXPRESSION
  ocExpr <- "list('VISIT_COUNT' = max(CURRENT_FIX_INTEREST_AREA_RUN_ID))"
  
  # SET UP FINAL OUTPUT COLUMN EXPRESSION
  focExpr <- "list('MEAN_VISIT_COUNT' = .Internal(mean(VISIT_COUNT)))"
  
  # DV COLUMN NAME
  dvColumnName = "MEAN_VISIT_COUNT"
  
  # SEND ON TO CALCULATE
  out_df <- analyse.calculate.means(fixreport_df=fixreport_df, aggregation_column_list=aggregation_column_list, 
                                    output_column_expression=ocExpr, final_output_column_expression=focExpr, 
                                    spss, dvColumnName, prefixLabel)
  
  return(out_df)
}
#############################################################################################################################################################

#############################################################################################################################################################
# SACCADE AMPLITUDE #############################################################################################################################################################
#' Analyse saccade amplitude
#'
#' @param fixreport_df Fixation report
#' @param aggregation_column_list List of columns to group by
#' @param spss Should the function save output for SPSS?
#' @param prefixLabel Prefix label
#'
#' @return If spss is set to FALSE (which is the default), you'll get an object containing data.tables 
#' of by-trial means for sacade amplitudes, by-trial means for particpants, and overall descriptive
#' statistics for use when creating graphs based on your data. If spss is set to TRUE, then you'll be 
#' provided with a 'wide' version of the data for analysis in packages such as SPSS. The function will
#' also save a copy of the for-spss file for you as well.
#' @export
#'
#' @examples
#' # BREAK UP BY TARGET-PRESENT AND TARGET-ABSENT TRIALS - THE COLUMN TRIALTYPE_TEXT
#' data(fixationreport)
#' amplitudes <- analyse.sac.amplitude(fixationreport, 
#'     aggregation_column_list = list('TRIALTYPE_TEXT'))
analyse.sac.amplitude<- function(fixreport_df, aggregation_column_list=c(), spss=FALSE, prefixLabel=""){
  
  # REMOVE BLANK SAC AMPLITUDE VALUES
  fixreport_df <- fixreport_df[fixreport_df$NEXT_SAC_AMPLITUDE!='.',]
  fixreport_df$NEXT_SAC_AMPLITUDE <- as.numeric(as.character(fixreport_df$NEXT_SAC_AMPLITUDE))
  
  # SET UP OUTPUT COLUMN EXPRESSION
  ocExpr <- "list('SAC_AMPLITUDE' = .Internal(mean(NEXT_SAC_AMPLITUDE)))"
  
  # SET UP FINAL OUTPUT COLUMN EXPRESSION
  focExpr <- "list('MEAN_SAC_AMPLITUDE' = .Internal(mean(SAC_AMPLITUDE)))"
  
  # DV COLUMN NAME
  dvColumnName = "MEAN_SAC_AMPLITUDE"
  
  # SEND ON TO CALCULATE
  out_df <- analyse.calculate.means(fixreport_df=fixreport_df, aggregation_column_list=aggregation_column_list, 
                                    output_column_expression=ocExpr, final_output_column_expression=focExpr, 
                                    spss, dvColumnName, prefixLabel)
  
  return(out_df)
}
#############################################################################################################################################################

# FIRST FIX DURATION #############################################################################################################################################################
#' Analyse first fixation duration
#'
#' @param fixreport_df Fixation report
#' @param aggregation_column_list List of columns to group by
#' @param spss Should the function save output for SPSS?
#' @param prefixLabel Prefix label
#'
#' @return If spss is set to FALSE (which is the default), you'll get an object containing data.tables 
#' of by-trial means for first fixation durations, by-trial means for particpants, and overall descriptive
#' statistics for use when creating graphs based on your data. If spss is set to TRUE, then you'll be 
#' provided with a 'wide' version of the data for analysis in packages such as SPSS. The function will
#' also save a copy of the for-spss file for you as well.
#' @export
#'
#' @examples
#' # BREAK UP BY TARGET-PRESENT AND TARGET-ABSENT TRIALS - THE COLUMN TRIALTYPE_TEXT
#' data(fixationreport)
#' firstDurations <- analyse.fix.first_duration(fixationreport, 
#'      aggregation_column_list = list('TRIALTYPE_TEXT'))
analyse.fix.first_duration <- function(fixreport_df, aggregation_column_list=c(), spss=FALSE, prefixLabel=""){
  
  # SET UP OUTPUT COLUMN EXPRESSION
  ocExpr <- "list('FIRST_FIX_DURATION' = CURRENT_FIX_DURATION[1])"
  
  # SET UP FINAL OUTPUT COLUMN EXPRESSION
  focExpr <- "list('FIRST_FIX_DURATION' = .Internal(mean(FIRST_FIX_DURATION)))"
  
  # DV COLUMN NAME
  dvColumnName = "FIRST_FIX_DURATION"
  
  # SEND ON TO CALCULATE
  out_df <- analyse.calculate.means(fixreport_df=fixreport_df, aggregation_column_list=aggregation_column_list, 
                                    output_column_expression=ocExpr, final_output_column_expression=focExpr, 
                                    spss, dvColumnName, prefixLabel)
  
  return(out_df)
}

# BEHAVIOURAL DATA #############################################################################################################################################################
#' Analyse behavioural data
#'
#' @param bd_df Behavioural data frame/table
#' @param aggregation_column_list List of columns to group by
#' @return Provides behavioural information for the experiment as a data.table.
#' @export
#'
#' @examples
#' # BREAK UP BY TARGET-PRESENT AND TARGET-ABSENT TRIALS - THE COLUMN TRIALTYPE_TEXT
#' data(fixationreport)
#' data(messagereport)
#' 
#' 
#' # REPLACE SPACES IN MESSAGES
#' messagereport <- organise.message.replace_spaces(messagereport)
#' 
#' # TAKE A LOOK
#' organise.message.descriptives(messagereport)
#' 
#' # MARKUP
#' fixationreport <- organise.message.markup(message_df=messagereport, 
#'    fixreport_df = fixationreport, message="DISPLAY_START")
#' fixationreport <- organise.message.markup(message_df=messagereport, 
#'    fixreport_df = fixationreport, message="DISPLAY_CHANGE")
#' 
#' # NOW DO ACCURACY AND RT MARKUP
#' fixationreport <- organise.responses.markup(fixationreport, "CORRECT_RESPONSE")
#' 
#' # NOW MARK UP FIXATION CONTINGENCIES
#' fixationreport <-organise.message.fix_contingencies(fixationreport, 
#'    list("DISPLAY_START", "DISPLAY_CHANGE", "RESPONSE_TIME"))
#'
#' # SET UP TRUE RT
#' fixationreport[,TRUE_RT:=RESPONSE_TIME-DISPLAY_START,]
#'
#' behaviouralData <- analyse.behavioural.data(fixationreport, 
#'    aggregation_column_list = list('TRIALTYPE_TEXT'))
analyse.behavioural.data<- function(bd_df, aggregation_column_list=c()){
    
  # CREATE DATA TABLE
  b_DT <- data.table(bd_df)
  setkey(b_DT, RECORDING_SESSION_LABEL, TRIAL_INDEX)
  
  # CREATE BY-TRIAL MEANS
  finalAggExpr <- "list(RECORDING_SESSION_LABEL "
  
  # IF ITS NOT A BLANK COLUMN LIST
  if (length(aggregation_column_list) > 0){   
    for (i in seq(1:length(aggregation_column_list))){     
      finalAggExpr <- paste(finalAggExpr, ", ", aggregation_column_list[i], sep="")
    }
  }
  
  # CLOSE UP THE AGG LISTS AND PARSE
  finalAggExpr <- paste(finalAggExpr, ")", sep="")
  finalAggExprParsed <- parse(text = finalAggExpr)
  
  # RUN IT
  final_DT <- b_DT[,
                     list("MEDIAN_RT" = as.numeric(as.character(median(TRUE_RT[OUTCOME=="CORRECT"]))),
                          "MEAN_RT" = mean(TRUE_RT[OUTCOME=="CORRECT"]),
                          "CORRECT_COUNT" = length(TRIAL_INDEX[OUTCOME=="CORRECT"]),
                          "TOTAL_TRIALS" = length(TRIAL_INDEX)
                          ),
                     eval(finalAggExprParsed)]
  
  final_DT$ACCURACY <- final_DT$CORRECT_COUNT / final_DT$TOTAL_TRIALS
  
  out_df <- data.frame(final_DT)
  
  return(out_df)
}
#############################################################################################################################################################

