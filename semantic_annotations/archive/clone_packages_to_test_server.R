### This script copies packages from the Arctic Data Center production node (arcticdata.io) to the test server (test.arcticdata.io).  The packages copied can currently be
### annotated (as of 9/24/2018) with terms from ECSO. The test packages will be used for testing the semantic annotations interface. 
### Note: you will need to insert your token from the ADC.

# Libraries
library(dataone)
library(datamgmt)
library(arcticdatautils)
library(dplyr)

#Downgrade the Curl package to 2.7 to avoid the (413) Request Entity Too Large error
#remotes::install_github("jeroen/curl@v2.7")

# Initialize variables for nodes
from = dataone::D1Client("PROD", "urn:node:ARCTIC")
to   = dataone::D1Client("STAGING", "urn:node:mnTestARCTIC")


# Read in list of identifiers
identifiers_df <- read.csv("identifiers_to_clone.csv", stringsAsFactors = FALSE)

# Create list of resource maps from the identifiers
for (counter in 1:nrow(identifiers_df)){
	
	if(grepl("doi:", identifiers_df$current_identifier[counter])){
		
		identifiers_df$resource_map[counter] <- paste0("resource_map_",identifiers_df$current_identifier[counter])
		
	} else {
		
		identifiers_df$resource_map[counter] <- identifiers_df$current_identifier[counter]
	}
	
}

# Create list of unique identifiers to clone
unique_identifiers_to_clone <- distinct(identifiers_df)

write.csv(unique_identifiers_to_clone, file = "unique_identifiers_to_clone.csv", row.names = FALSE)

# Get unique resource maps
identifiers_to_clone_df <- select(identifiers_df, resource_map) %>%
	unique()


# Clone each resource map
for (counter in 1:nrow(identifiers_to_clone_df)){
	pid <- identifiers_to_clone_df$resource_map[counter]
	
	cloned_package <- tryCatch(clone_package(resource_map_pid = pid,
									
																	from = from,
																	to = to,
																	add_access_to = arcticdatautils:::get_token_subject(),
																	public = TRUE,
																	new_pid = FALSE), 
														 					error = function(e) print(paste0(pid, " did not clone") )
	)
}

