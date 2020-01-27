### Combine general query results then compare to the annotation spreadsheet to see if the all the
### packages found are in the spreadsheet.


### Libraries
library(plyr)
library(tidyverse)
library(dataone)

## Set Node to production and Arctic Data Center
cn <- CNode("PROD")
mn <- getMNode(cn, "urn:node:ARCTIC")


### Read in CSV files to be merged
file_list <- list.files(path = "./general_query_results", full.names = TRUE, pattern = "*.csv")

temp_list = lapply(file_list, read.csv, stringsAsFactors = FALSE)

### Join all the results together by identifier
merged_results <- join_all(temp_list, by = 'identifier', type = 'full')

### Get list of unique identifiers

unique_identifiers <- merged_results %>%
	select (identifier) %>%
	distinct()


# new_IDs are the packages in the current annotation spreadsheet
new_IDs <- list.files(pattern ="new_package_IDs") %>%
	read.csv(stringsAsFactors = FALSE) %>%
	select(identifier)

### these are the IDs that appeared in the general query results and are not in the annotation spreadsheet
general_result_IDs_to_check <- anti_join (unique_identifiers, new_IDs)

## now check if these are in Bryce's results
df_all_attributes <- read.csv(file = "20190424211010_attributes.csv", stringsAsFactors = FALSE) %>%
	rename(identifier = packageId)


# The packages listed below are results from the general queries and also appear in Bryce's spreadsheet
# but are not in the annotation spreadsheet. These packages will have to be added to the spreadsheet.
df_packages_to_add_to_spreadsheet <- merge(general_result_IDs_to_check, df_all_attributes)

# Reorder columns
df_packages_to_add_to_spreadsheet <- df_packages_to_add_to_spreadsheet %>%
	select (identifier, entityName, attributeName, attributeDefinition, attributeLabel, attributeUnit)

# Remove NA's
df_packages_to_add_to_spreadsheet[is.na(df_packages_to_add_to_spreadsheet)] <- ""

write.csv(df_packages_to_add_to_spreadsheet, file = "attributes_to_add_to_annotation_spreadsheet.csv", row.names = FALSE)
