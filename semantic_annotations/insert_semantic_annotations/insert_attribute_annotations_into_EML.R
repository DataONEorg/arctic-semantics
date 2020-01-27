### This script inserts attribute semantic annotation elements into EML files. It reads in entity-attribute metadata stored in a CSV file that has been annotated with ECSO IDs. An example input file is:
### https://docs.google.com/spreadsheets/d/1juuOR7e9_cG0wRLiI3Dz3o_Pd85UjTZhbzWLgfTNxZY/edit#gid=971517520. Other input files are OWL files for the OBOE-Core, OBOE-Standards,
### ECSO, and Unit Ontology ontologies. The EML files associated with the identifiers in the spreadsheet are downloaded and  have annotation elements inserted. The annotation tags are added to 
### attribute elements. The annotations are matched to the spreadsheet based on both entity and attribute names. Modified versions of the XML files are output into a subfolder and the downloaded 
### XML files are preserved.

### The OBOE-Core and OBOE-Standard URIs and labels used in this script will need to be changed after the edits to those ontologies are completed.

# Author: Steven Chong, https://orcid.org/0000-0003-1264-1166

## NOTE: Authentification is required to view ADC system metadata. Copy and paste your token to the RStudio console.
## The token can be obtained from the profile settings in the Arctic Data Center after logging in. 

#Libraries
library(eatocsv) # remotes::install_github("amoeba/eatocsv")
library(xml2)		 # install.packages("xml2")
library(dplyr) 	 # install.packages("dplyr")
library(stringr) # install.packages("stringr")
library(dataone) # install.packages("dataone")
library(remotes) # install.packages("remotes")
library(arcticdatautils) # remotes::install_github("nceas/arcticdatautils")
library(EML) # remotes::install_github("ropensci/EML")
library(stringi)  # install.packages("stringi")


## Set Node to production and Arctic Data Center
cn <- CNode("PROD")
mn <- getMNode(cn, "urn:node:ARCTIC")


#Specify the OBOE-Core object properties for the annotations
property_names <- c( "containsMeasurementsOfType", "hasUnit" )

#For each input file, specify a text string present in the file name that uniquely identifies the file
oboe_core_file      <- "oboe-core"
oboe_standards_file <- "oboe-standards"
ECSO_ontology_file  <- "ECSO8"
unit_ontology_file  <- "uo.owl"

# Subdirectory to store the downloaded XML files
XMLsubDir <- "/downloaded_XML_files"
dir.create(file.path(getwd(), XMLsubDir), showWarnings = FALSE)


### Functions
# Reads in input OWL or Turtle files and converting them to text.The argument is a text string found in the file name.
ontology_as_text <- function(x) {
  list.files(full.names = TRUE, pattern = x) %>%
    lapply(readLines) %>%
    unlist(use.names = FALSE) %>%
    trimws() %>%
    paste0(collapse = " ")
  
}

# Function for changing a XML node attribute value. The arguments are the source node containing the attribute, attribute name, and value the attribute should be set to.
change_node_attribute <- function(source, attribute_name, new_value ){
  xml_attr(source, attribute_name) <- NULL
  xml_attr(source, attribute_name) <- new_value
}


# Function for adding an annotation node. The arguments are the attribute node, property label and URI, and the value (subject) label and URI.
add_annotation_node <- function (node, property_label, property_URI, value_label, value_URI){
	
	xml_add_child(node, read_xml(paste0("<annotation id=\"", stri_rand_strings(1, 10, pattern = "[A-Za-z0-9]") , "\">
																			<propertyURI label=\"", property_label,"\">", property_URI, "</propertyURI>
																			<valueURI label= \"", value_label, "\">", value_URI, "</valueURI>
																			</annotation>")	)	)		
}

### STEP 1: Read input files

#Read OBOE-Core file 
oboe_core <- ontology_as_text(oboe_core_file)

#Read OBOE-Standards file
oboe_standards <- ontology_as_text(oboe_standards_file)

#Read Unit Ontology file as XML
unit_ontology <- list.files(full.names = TRUE, pattern = unit_ontology_file) %>%
  read_xml()

#Read ECSO OWL file as XML
ECSO_ontology <- list.files(full.names = TRUE, pattern = ECSO_ontology_file)	%>% 
  read_xml()


#Read annotations spreadsheet, remove rows without ECSO equivalent classes and subset the resulting dataframe
annotations_df <- list.files(full.names = TRUE, pattern = (".csv") ) %>%
  read.csv(stringsAsFactors = FALSE) %>%
  filter(ECSO_ != "" ) %>%
	filter(ECSO_ != "x" ) %>%
  select (identifier, entityName, attributeName, attributeUnit, ECSO_)

#Format ECSO IDs to 8 digits
annotations_df$ECSO_ <- sprintf("%08s", annotations_df$ECSO_)

# Get unique identifiers in annotation_df to download the XML files
unique_identifiers <- unique(annotations_df$identifier)


# Empty list to store the results of the Solr query
results_list <- list()

# Solr query identifying the identifiers that have been revised
for (doi in unique_identifiers) {
  new_doi <- sprintf("identifier:\"%s\"",doi)
  
  search_parameters <- list(q= new_doi,
                            fl="identifier, obsoletedBy, authoritativeMN",
                            rows="5000")
  
  search_result_df <- query(mn, solrQuery=search_parameters, as = "data.frame")
  
  #Store query results data frames in a list
  results_list[[doi]] <- search_result_df
}

# Combine Solr results into a single dataframe
results_df <- do.call(bind_rows, results_list)

#If there isn't an obsoletedBy column (no updated identifiers), add one
if (!"obsoletedBy" %in% colnames(results_df)){
	results_df$obsoletedBy <- results_df$identifier
} 

# Get unique identifiers into a dataframe to merge with the Solr query results
unique_identifiers_df <- data.frame(identifier = unique(annotations_df$identifier), stringsAsFactors = FALSE)

# Merge the Solr results with the unique identifiers
original_to_current_dois_df <- merge(x = unique_identifiers_df, y = results_df, by = "identifier", all.x = TRUE) %>%
	filter (grepl ("urn:node:ARCTIC", authoritativeMN )) # Filter out packages not managed by the ADC


# Replace the identifiers in the obsoletedBy column with the latest version of each identifier (i.e. the values that are not NA in the obsoletedBy column are replaced 
# with the last version of the identifier in the obsolescence chain)

obsolete_identifiers <- which(is.na(original_to_current_dois_df$obsoletedBy) == FALSE )

for (obsolete_identifier in obsolete_identifiers){
  
  original_to_current_dois_df$obsoletedBy[obsolete_identifier] <- 
    get_all_versions(mn,original_to_current_dois_df$obsoletedBy[obsolete_identifier])[length(get_all_versions(mn,original_to_current_dois_df$obsoletedBy[obsolete_identifier]))]
}

#Replace all NA values in the obsoletedBy column with the values from the identifier column
original_to_current_dois_df$obsoletedBy[is.na(original_to_current_dois_df$obsoletedBy)] <- original_to_current_dois_df$identifier[is.na(original_to_current_dois_df$obsoletedBy)]

# Rename the identifier and obsoletedBy columns
original_to_current_dois_df = original_to_current_dois_df %>%
  rename(original_identifier = identifier) %>%
  rename(current_identifier = obsoletedBy) 


# Merge the current identifiers to the annotations dataframe
annotations_df <- merge(x = annotations_df, y = original_to_current_dois_df, by.x = "identifier", by.y = "original_identifier", all.x = TRUE)

# Find duplicate rows (attribute names duplicated in same entity, to remove from the annotation list)
annotations_df$duplicate <- duplicated(annotations_df) | duplicated(annotations_df, fromLast = TRUE)

#Rename and reorder identifier columns in the annotations dataframe
annotations_df = annotations_df %>%
	filter ( !is.na(current_identifier)) %>% # Filter out packages not managed by the ADC (LTER packages)
	filter ( duplicate == FALSE) %>% # Filter out duplicate attribute names in the same entity
  select(current_identifier, entityName, attributeName, attributeUnit, ECSO_)


#Group the rows in the annotations spreadsheet into a list of lists for each identifier	
annotations_list <- split(annotations_df, annotations_df$current_identifier)

### STEP 2: Download the XML files

#For each current identifier that was annotated
for (identifier in original_to_current_dois_df$current_identifier){
  
  #Download XML file for each DOI in the list
  download_objects(mn, pids = identifier, path = "./downloaded_XML_files")
  
  
  #File name for downloaded XML file	
  eml_file_name <- identifier %>%
  { gsub("[:./-]","_", .) } %>%
  { paste0(. , ".xml") }
  
  
  #If the XML file is not found, print a message
  if(file_test("-f", paste0("./downloaded_XML_files/", eml_file_name)) == FALSE ){
    print(paste0( eml_file_name, " was not downloaded"))
  }
  
}
  	
### STEP 3: Create annotations    

downloaded_files_list <- list.files(path = "./downloaded_XML_files", full.names = TRUE, pattern = ".xml")

for (downloaded_file in downloaded_files_list){
	
    #	Read in XML file
    doc <- read_xml(downloaded_file, encoding = "UTF-8")
    
    # Update the version numbers in the EML node attributes
    change_node_attribute(doc, "xmlns:eml", "https://eml.ecoinformatics.org/eml-2.2.0")
    change_node_attribute(doc, "xmlns:stmml", "http://www.xml-cml.org/schema/stmml-1.2" )
    
    if (xml_has_attr(doc, "xmlns:ds") ){
      change_node_attribute(doc, "xmlns:ds", "https://eml.ecoinformatics.org/dataset-2.2.0")
      
    }  
    
    # Increment the eml version number in xsi:schemaLocation for PASTA files
    if (grepl("eml://ecoinformatics.org/eml-2.1.0 http://nis.lternet.edu/schemas/EML/eml-2.1.0/eml.xsd", xml_attr(doc, "schemaLocation"))  ){
      
      change_node_attribute(doc, "xsi:schemaLocation", "https://eml.ecoinformatics.org/eml-2.2.0 http://nis.lternet.edu/schemas/EML/eml-2.2.0/eml.xsd")
      
    } else {  # else change the xsi:schemaLocation for other files
          
      change_node_attribute(doc, "xsi:schemaLocation", "https://eml.ecoinformatics.org/eml-2.2.0 eml.xsd")
    }
    
    # Update the version numbers in the unitList attributes 
    if (length(xml_find_first(doc, "//unitList") ) != 0) {
    
      unitList_node <- xml_find_first(doc, "//unitList")
    
      change_node_attribute(unitList_node, "xmlns:eml", "https://eml.ecoinformatics.org/eml-2.2.0")
      change_node_attribute(unitList_node, "xmlns:stmml", "http://www.xml-cml.org/schema/stmml-1.2")
    
    }
    
    # Update the version numbers in the stmml:unitList attributes
    
    if (length(xml_find_first(doc, "//stmml:unitList") ) != 0) {
      
      stmml_unitList_node <- xml_find_first(doc, "//stmml:unitList")
      xml_name(stmml_unitList_node) <- "stmml:unitList"
      
      
      if (grepl("http://www.xml-cml.org/schema/stmml-1.1 http://nis.lternet.edu/schemas/EML/eml-2.1.0/stmml.xsd", xml_attr(stmml_unitList_node, "schemaLocation"))  ){
      
        # Increment the xsi:schemaLocation version numbers for PASTA files
        change_node_attribute(stmml_unitList_node, "xsi:schemaLocation", "http://www.xml-cml.org/schema/stmml-1.2 http://nis.lternet.edu/schemas/EML/eml-2.2.0/stmml.xsd")
      
      } 
      
      #  Increment the xmlns:stmml version number   
      change_node_attribute(stmml_unitList_node, "xmlns:stmml", "http://www.xml-cml.org/schema/stmml-1.2")
      
    }
    #If the stmml:unitList node is additionalMetadata/metadata, increment the stmml version number
    metadata_node <- xml_find_all(doc, './additionalMetadata/metadata' )
    
    if (length(metadata_node) > 0 ){
    	
    	stmml_unitList_node <- xml_child(metadata_node)
    
    	xml_attr(stmml_unitList_node, "xmlns:stmml") <- "http://www.xml-cml.org/schema/stmml_1.2"

    	# Change unitList tag name
  	 	xml_name(stmml_unitList_node, ns = character()) <- "stmml:unitList"
    }
  	 
    
    #Iterate through each identifier grouping in the annotations list
    for (annotation in annotations_list){
    	
    	#Set variables (each identifier grouping can have more than one attribute and entity)
    	package_id <- unlist(annotation$current_identifier)
    	attributeName <- unlist(annotation$attributeName)
    	entityName <- unlist(annotation$entityName)
    	ECSO_id <- unlist(annotation$ECSO_) # Get ECSO ID for each row in the identifier grouping
    	
    	#Trim whitespaces in the entity and attribute names
    	attributeName <- trimws(attributeName) %>%
    	{ gsub('"', '', .) } # replace quotation marks
    	
    	
    	entityName <- trimws(entityName)
    	
    	# Change package ID to the file format
    	package_id <- package_id %>%
    	{ gsub("[:./-]","_", .) } %>%
    	{ paste0(. , ".xml") }
 
    	
    	# Check if each package ID in the spreadsheet matches the file name
    	if (grepl(basename(downloaded_file), package_id[1] ) ){
    	
    		#Iterate through each attribute in each entity 
    		for (counter in 1:length(attributeName)){
    		
    		
    			#Check which schema the object property belongs to
    			for (property_name in property_names){
    			
    				oboe_property_label <- ""
    				oboe_property_URI   <- ""
    				unit_label          <- ""
    				unit_URI            <- ""
    			
    			
    				#If the object property is in OBOE-Core
    				if (grepl(paste0("<!-- http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#",property_name, " -->" ), oboe_core) ){
    				
    					#Create OBOE-Core property label by splitting based on case
    					oboe_property_label <- gsub('([[:upper:]])', ' \\1', property_name) %>%
    						tolower()
    				
    					oboe_property_URI <- paste0("http://ecoinformatics.org/oboe/oboe.1.2/oboe-core.owl#", property_name)
    				
    				}
    			
    			
    				# Look up the ECSO ID in the ontology to get the class label and URI
    				class_node <- xml_find_first (ECSO_ontology, paste0("//owl:Class[contains(@rdf:about,'",ECSO_id[counter] ,"')]" ) )
    			
    				class_URI <- trimws(as.character (class_node) ) %>%
    				{ sub('[\n].*', "", . ) } %>%
    				{ sub('.*=', "", . ) } %>%
    				{ sub('>.*', "", . ) } %>%
    				{ gsub('["]', "", . ) }
    			
    			
    				#If the ECSO ID was found in the ontology
    				if(length(class_node) != 0 ){
    				
    					#Check if there's a rdfs:label field, otherwise, use the preferred label field for the label
    					if(grepl("rdfs:label", as.character(class_node) ) ){
    					
    						class_label <- xml_find_first(class_node, "./rdfs:label/text()") %>%
    							as.character()
    					
    					} else {
    						class_label <- xml_find_all(class_node, "./skos:prefLabel/text()") %>%
    							as.character()
    					}

    				}	
    				
    				# Print message if an ID in the spreadsheet isn't found in the ECSO OWL file
    				if(length(class_node) == 0 )  {
    					
    					print(paste0(ECSO_id[counter], " not found in ", basename(list.files(full.names = TRUE, pattern = ECSO_ontology_file) ), " !"  ))
    				
    				}
    			
    			
    				#Retrieves the dataTable node that contains both the entityName and attributeName of interest
    				dataTable <- xml_find_all(doc, paste0('//dataTable[./entityName="', entityName[counter], '" and ./attributeList/attribute/attributeName="', attributeName[counter], '"]' ))
    			
    				#Retrieves the attribute that matches the attribute name within the dataTable node (i.e. retrieves the attributes from the current (dataTable) node, where attributeName matches the variable)
    				attribute_node <- xml_find_all(dataTable, paste0('./attributeList/attribute[./attributeName="', attributeName[counter], '"]' ))
    			
    				
    				#Retrieves unit information
    				standardUnit <- xml_find_first(attribute_node, './measurementScale/ratio/unit/standardUnit/text()')  
    				customUnit <- xml_find_first(attribute_node, './measurementScale/ratio/unit/customUnit/text()')

    				   				
    				# If the standardUnit element is not empty
    				if (length(standardUnit) == 1 && is.na(standardUnit) == FALSE  ){ 
    				
    					unit_label <- as.character(standardUnit)
    				
    				# If the standardUnit element is empty, use the customUnit element value
    				} else if (length(customUnit) == 1 && is.na(standardUnit) == FALSE ) { 
    				
    					unit_label <- as.character(customUnit)
    				
    				}
    			
    				#If there is an open left parenthesis in the unit label, escape it
    				if (grepl("\\(", unit_label) && grepl("\\)", unit_label ) == FALSE ){
    					unit_label <- gsub("\\(",   "\\\\(", unit_label)
    				}
    			
    				# Label format for the Unit Ontology
    				UO_unit_label <- gsub('([[:upper:]])', ' \\1', unit_label) %>%
    					tolower()
    			
    				UO_unit_singular_label <- gsub("s per ", " per ", UO_unit_label)
    			
    				# If the unit label isn't blank and it is present in the OBOE-Standards document, create a URI
    				if (length(unit_label) != 0  && grepl(paste0('owl:Class rdf:about="&oboe-standards;', unit_label,'"'), oboe_standards, ignore.case = TRUE)) {
    				
    					#Capitalize first letter in the unit label
    					unit_label <- paste(toupper(substr(unit_label, 1, 1)), substr(unit_label, 2, nchar(unit_label)), sep = "" ) 
    					unit_URI <- paste0("http://ecoinformatics.org/oboe/oboe.1.2/oboe-standards.owl#", unit_label)
    				
    				
    					# If the unit label isn't blank and it or its singular form is in the Unit Ontology	
    					} else if (length(unit_label) != 0 && (length(xml_find_all(unit_ontology, paste0("//owl:Class[rdfs:label/text()='", UO_unit_label , "']")) ) != 0 
    																						 || length(xml_find_all(unit_ontology, paste0("//owl:Class[rdfs:label/text()='", UO_unit_singular_label , "']")) ) != 0) ){
    				
    					# If the unit label is in the Unit Ontology (match based on the rdfs:label field)
    					if (length( xml_find_first(unit_ontology, paste0("//owl:Class[rdfs:label/text()='", UO_unit_label , "']") )) != 0 ){
    					
    						unit_class <- xml_find_first(unit_ontology, paste0("//owl:Class[rdfs:label/text()='", UO_unit_label , "']") )
    					
    					} else {
    					
    						#Check the singular version of the units to find the correct rdfs:label and class URI
    						unit_class <- xml_find_first(unit_ontology, paste0("//owl:Class[rdfs:label/text()='", UO_unit_singular_label , "']") )
    					}
    				
    					unit_label <- xml_find_first(unit_class, "./rdfs:label/text()" )
    					unit_URI   <- as.character(xml_attrs(unit_class) ) 
    				
    				}
    			
    			
    				#Create annotation nodes, if there are class and unit labels and URIs
    			
    				if (property_name == "containsMeasurementsOfType" && class_label != "") {	
    					add_annotation_node(attribute_node, oboe_property_label, oboe_property_URI, class_label, class_URI)
    				
    				} else if (property_name == "hasUnit" && oboe_property_label != "" && unit_label != "" && unit_URI != "") {
    					add_annotation_node(attribute_node, oboe_property_label, oboe_property_URI, unit_label, unit_URI	)
    				
    				}
    			
    			
    				# If there is an attribute node to be annotated, add an ID attribute if there isn't one
    				if (length(attribute_node) == 1 ){
    				
    					if (xml_has_attr(attribute_node, "id") == FALSE ){
    					
    					xml_attr(attribute_node, "id") <- stri_rand_strings(1, 10, pattern = "[A-Za-z0-9]") # add a random 10-character string to the attribute node
    					}
    				
    				}
    			
    			
    			}	
    		
    		}
    	
    	} #if statement for checking that package IDs match in the annotation spreadsheet and EML file
    	
    } # iterate through identifier groupings in annotation spreadsheet
    
    # Change the eml namespace declaration
    xml_name(doc) <- "eml:eml"
    
    # Write output file to a subdirectory in the current directory
    subDir <- "/output_XML_files"
    dir.create(file.path(getwd(), subDir), showWarnings = FALSE)
    
    #File name for output XML file	
    output_file_name <- downloaded_file %>%
    { gsub(".*/","", .) } %>%
    { gsub(".xml", "",.) }
    
    # Output XML file
    write_xml (doc, file = file.path(paste0(getwd(), subDir), paste0( output_file_name, "_edited.xml") ))
  
} # for each current identifier that was annotated

### STEP 4: Validate the output files
output_file_list <- list.files(path = "./output_XML_files", full.names = TRUE, pattern = ".xml")

# Set options for EML2 package
options("emld_db" = "eml-2.2.0")

counter <- 1

# Check each output XML file
for (xml_file in output_file_list){
  tryCatch({ 
    eml_file <- read_xml(xml_file)
    
    # Print message if the EML file did not validate
    if (eml_validate (eml_file) == FALSE) {
      
      print (paste0(basename(xml_file), " is not valid" ))
      counter <- counter + 1
    } 
  },
  error = function(err) {print(paste0(basename(xml_file), " is not valid"))},
  
  {	counter <- counter + 1
  })
}

if (counter == 1){
  print ("All of the output XML files are valid")
}
