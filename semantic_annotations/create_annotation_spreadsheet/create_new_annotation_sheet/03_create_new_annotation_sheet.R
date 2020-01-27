### This script downloads all of the attribute-level metadata in the Arctic Data Center into a CSV file. It then creates
### a subset of the attributes that is based on the data packages returned from carbon-related queries. The resulting
### CSV file from this script can store data needed to create semantic annotations with the script found here:
### https://github.nceas.ucsb.edu/NCEAS/adc-controlled-voc/tree/master/semantic_annotations/insert_semantic_annotations


#Libraries
library(dplyr)
library(eatocsv)
library(dataone)
library(readr)
library(xml2)

### Step 1: Download all attribute-level metadata from the ADC

# Query for records to download
CN <- CNode("PROD")
arcticdata.io <- dataone::MNode("https://arcticdata.io/metacat/d1/mn/v2")

query_url <- paste0(arcticdata.io@baseURL,
										"/v2/query/solr/",
										"?fl=identifier",
										'&q=formatType:METADATA+AND+datasource:"urn:node:ARCTIC"+AND+-obsoletedBy:*+AND+attribute:*',
										"&rows=5000",
										"&start=0",
										"&wt=csv")

query_datetime <- Sys.time() # Save querytime for later
documents <- readr::read_csv(query_url)

# Subdirectory to store the downloaded XML files
XMLsubDir <- "/downloaded_XML_files"
dir.create(file.path(getwd(), XMLsubDir), showWarnings = FALSE)


# Download the EML files
download_objects(CN, documents$identifier, path = "./downloaded_XML_files")

# Parse and extract entities and their attributes from the downloaded files
document_paths <- list.files("./downloaded_XML_files", full.names = TRUE, pattern = "*.xml")
all_attributes_df <- extract_ea(document_paths)


### Step 2: Create a subset of all the ADC attributes that represents the data packages returned by the query results

#Create identifiers from the package IDs
all_attributes_df$identifier <- NA

counter <- 1
for (pid in all_attributes_df$packageId){
	
	if (grepl("knb-lter", pid ) ){
		clean_pid <- gsub("\\.", "\\/", pid)
		identifier <- paste0("https://pasta.lternet.edu/package/metadata/eml/", clean_pid)
	
		all_attributes_df$identifier[counter] <- identifier
	
	} else {
		
		all_attributes_df$identifier[counter] <- pid
	}	
	
	counter = counter + 1
	
}

# Reorder the columns in the all attributes data frame and remove package IDs
all_attributes_df <- all_attributes_df[c("identifier", "entityName", "attributeName", "attributeLabel", "attributeDefinition", "attributeUnit", "query_datetime_utc" )]

# Read in the CSV file containing the merged query results
query_results_df <- read.csv(file = "merged_query_results.csv", stringsAsFactors = FALSE)

# Join the two data frames together by identifier
combined_data <- right_join(all_attributes_df, query_results_df, by='identifier')


combined_data <- combined_data %>%
	select(identifier, entityName, attributeName, attributeDefinition, attributeLabel, attributeUnit) %>%
	distinct %>%
	filter(attributeName != "")

combined_data <- data.frame(lapply(combined_data, as.character), stringsAsFactors = FALSE)

combined_data[is.na(combined_data)] <- ""

# Add more columns
combined_data$ECSO_ <- ""
combined_data$who <- ""
combined_data$notes <-"" 


# Create the output CSV file
write.csv(combined_data , file = paste0(format(query_datetime, "%Y%m%d%H%M%S"), "_annotation_sheet.csv") , row.names = FALSE)
