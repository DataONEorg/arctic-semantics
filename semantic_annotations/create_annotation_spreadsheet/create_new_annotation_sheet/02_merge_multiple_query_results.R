### This script combines the separate ADC query results CSV files into a single spreadsheet

### Libraries
library(plyr) #install.packages("plyr")

### Read in query results CSV files to be merged
file_list <- list.files(path = "01_query_results", full.names = TRUE, pattern = "*.csv")

results_list = lapply(file_list, read.csv, stringsAsFactors = FALSE)

### Join all the results together by identifier
merged_results <- join_all(results_list, by = 'identifier', type = 'full')


### Format column headers
names(merged_results) <- gsub(x = names(merged_results), pattern = "X\\.", replacement = '\\"')
names(merged_results) <- gsub(x = names(merged_results), pattern = "\\.\\.\\.", replacement = ': \\"')
names(merged_results) <- gsub(x = names(merged_results), pattern = "\\.\\.", replacement =  '\\" ')
names(merged_results) <- gsub(x = names(merged_results), pattern = "\\.", replacement = " ")
names(merged_results) <- gsub(x = names(merged_results), pattern = " $", replacement = '"')


### Create the output CSV file
merged_queries_output <- sapply(merged_results, as.character)
merged_queries_output[is.na(merged_queries_output)] <- ""


write.csv(merged_queries_output, file = "merged_query_results.csv", row.names = FALSE)

