### This script enables you to programmatically query the Arctic Data Center's general and data attribute search boxes by using as input a CSV file containing search 
### terms. The query results contain the identifier, title, abstract, creator and URL for each record and each query result set 
### is stored in an individual CSV file. The output files are stored in a subfolder called "01_query_results". The numbering reflects the step in the workflow.


### Libraries, install as needed
library(dataone)   #install.packages("dataone")
library(dplyr)     #install.packages("dplyr")

### CONSTANTS ----


## Set Node to production and Arctic Data Center
cn <- CNode("PROD")
mn <- getMNode(cn, "urn:node:ARCTIC")


# Read in a csv file containing the list of search terms (assumes there is a header row)
carbon_terms <- list.files(full.names = TRUE, pattern = "Carbon_Cycling_Terms.csv") %>%
	lapply(read.csv, stringsAsFactors = FALSE) %>%
	unlist()

# Set the type of queries to be performed
query_types <- c("general", "data_attribute")

for (query_type in query_types){
	
	# Iterate through the list of search terms
	for (term in carbon_terms){
	
		term <-	trimws(term)
		my_search_terms <- gsub(" ", ";", term )
		
		
		## ONLY needed to access none public data packages (that you have permission to access)
		## Authentification set your token: Token can be obtained from profile settings on DataONE search loggin 
		## https://search.dataone.org/
		# options(dataone_token = "insert token here") 
		
		
		
		### FUNCTIONS  ----
		
		keywords_splitter <- function(kewords_list){
			# Split the string into keywords vector
			search_term_list <- unlist(strsplit(kewords_list,";"))
			# test for several terms
			if (length(search_term_list) > 1) {
				# Construct the query (AND only as now)
				search_term_list <- paste(search_term_list, collapse = " ")
			}
			# Add the first and last part of the query
			search_term_list <- paste0("\"", search_term_list, "\"")
			return(search_term_list)
		}
		
		
		metadata_query_builder <- function(keywords_query, n=5000){
			if (query_type == "general") { 
			
				query_terms <- sprintf("formatType:METADATA+-obsoletedBy:*+%s", keywords_query)
			
			} else if (query_type == "data_attribute"){
				
				query_terms <- sprintf("formatType:METADATA+-obsoletedBy:*+attribute:%s", keywords_query)
			}
			
			
			search_terms <- list(q = query_terms,
													 fl =" identifier,title,abstract,origin", #fields to be returned
													 rows = n, # bump the limit on datasets returned from 10 (default) to 5,000
													 sort = "dateUploaded+desc")
			
			## Query the DataONE API
			query_results <- query(mn, solrQuery=search_terms)
			
			return(query_results)
			
		}
		
		
		query_formatter <- function (raw_query_results){
			# Checks if there are any results
			if(length(raw_query_results) != 0 ){
				
				formatted_results <- lapply(raw_query_results, function(data_package) {
					
					# Collapse multi-valued origin into comma-separated char vector
					data_package$origin <- paste0(unlist(data_package$origin), collapse = "; ")
					
					# Provide the best possible URL for the identifier
					if (grepl("doi", data_package$identifier)) {
						# Build DOI URL
						data_package$url <- paste0("https://doi.org/", data_package$identifier)  
					} else {
						# Build ADC URL
						data_package$url <- paste0("https://arcticdata.io/catalog/#view/", data_package$identifier)
					}
					return(data_package)
				})
				
				
				#Create a dataframe from the list
				return(as.data.frame(matrix(unlist(formatted_results),
																		ncol = 5, byrow = TRUE,
																		dimnames = list(c(), c("identifier", "abstract", "title", "creator", "url"))),
														 stringsAsFactors = FALSE))
			} else {
				
				
				#If no results return a dataframe with just column names
				return(setNames(data.frame(matrix(ncol = 5, nrow = 0)), c("identifier", "abstract", "title", "creator", "url")))
			}
			
		}
		
		# Main function to call to launch the query
		packages_finder <- function(search_terms){
			## Transform the keywords into a solr query
			search_terms_logical <- keywords_splitter(search_terms)
			
			## Build the query terms
			qr_results <- metadata_query_builder(search_terms_logical)
			
			## Reformat output into dataframe
			results_enhanced <- query_formatter(qr_results)
			

				# If performing a search in the general search box
				if (query_type == "general" ){
					
					## Export to csv
					# Build filename
					output_file <- paste0(gsub(";", "_", search_terms), "-general_query.csv")
					
					# Write csv to a subdirectory in your current directory
					subDir <- "/01_query_results"
					dir.create(file.path(getwd(), subDir), showWarnings = FALSE)
					
					write.csv(results_enhanced,
										file = file.path(paste0(getwd(), subDir),output_file),
										row.names = FALSE)
					
					print(paste0(gsub(";", "_", search_terms), "-general_query.csv created"))
				
				# If performing a search in the data attribute search box		
				} else if (query_type == "data_attribute") {
					
					## Export to csv
					# Build filename
					output_file <- paste0(gsub(";", "_", search_terms), "-attribute_query.csv")
					
					# Write csv to a subdirectory in your current directory
					subDir <- "/01_query_results"
					dir.create(file.path(getwd(), subDir), showWarnings = FALSE)
					
					write.csv(results_enhanced,
										file = file.path(paste0(getwd(), subDir),output_file),
										row.names = FALSE)
					
					print(paste0(gsub(";", "_", search_terms), "-attribute_query.csv created"))
					
				}
			
			return(results_enhanced)
		}
		
		
		### MAIN ----
		
		## Allow command line call of the script
		## run as: Rscript dataone-query.R "keword1;keyword2"
		# check if the script is run interactively at the console or from command line
		if (!interactive()) {
			# Get the arguments
			args <- commandArgs(trailingOnly = TRUE)
			if (length(args) == 0) {
				stop("USAGE: $ Rscript dataone-query.R \"keword1;keyword2\"", call. = FALSE)
			} else {
				my_search_terms <- args[1]
			}
		}
		
		## Call the main function
		my_results <- packages_finder(my_search_terms)
	
	}

}	