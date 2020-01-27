### This scripts prints various messages indicating which class IDs or unit terms are not being incorporated into the semantic annotations because they are
### not present in the ontologies.


#Libraries
library(eatocsv) # remotes::install_github("amoeba/eatocsv")
library(xml2)		 # install.packages("xml2")
library(dplyr) 	 # install.packages("dplyr")
library(stringr) # install.packages("stringr")
library(dataone) # install.packages("dataone")

#Specify the RDF syntax or OBOE-Core object properties for the annotations
property_names <- c( "rdf:type", "hasUnit" )

#For each input file, specify a text string present in the file name that uniquely identifies the file
rdf_syntax_file 		<- "22-rdf-syntax-ns"
oboe_core_file 			<- "oboe-core"
oboe_standards_file	<- "oboe-standards"
ECSO_ontology_file	<- "ECSO4"
unit_ontology_file  <- "uo.owl"


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


### Read input files

#Read RDF syntax file (if property in RDF syntax file)
rdf_syntax <- ontology_as_text(rdf_syntax_file)

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
annotations_df <- list.files(full.names = TRUE, pattern = ("annotation_spreadsheet") ) %>%
	read.csv(stringsAsFactors = FALSE) %>%
	filter(EC_Carbon_Measurements_Present != "" ) %>%
	select (identifier, entityName, attributeName, attributeUnit, EC_Carbon_Measurements_Present)

###########

### Print message if the object property is not in the RDF syntax or OBOE-Core schemas
for (property_name in property_names){
	
	if (grepl(paste0(property_name, " a rdf:Property"), rdf_syntax) == FALSE  && grepl(paste0("owl:ObjectProperty rdf:about=\"&oboe-core;", property_name), oboe_core ) == FALSE )  {
		print(paste0("'", property_name , "' not found in the RDF syntax schema or OBOE-Core schema object properties") )
	}
	
}

### Print message if ECSO ID in the annotation spreadsheet not found in ontology

# Read in ECSO ontology as text
ECSO_text <- ontology_as_text(ECSO_ontology_file)
UO_text   <- ontology_as_text(unit_ontology_file)

#Get unique IDs present in the annotation spreadsheet 
unique_ECSO_ids <- distinct(annotations_df, EC_Carbon_Measurements_Present) %>%
	unlist()

#Print message if ECSO ID not found in the ontology 
for(unique_id in unique_ECSO_ids){
	
	if (grepl(unique_id, ECSO_text) == FALSE){	
		print(paste0(unique_id, " not found in the ontology file")	 )
	}
	
}


### Print out the annotation units that are not found in the ontology
#		NOTE: This is checking against the OBOE-Standards file found at http://ecoinformatics.org/oboe/oboe.1.2/oboe-standards.owl
# 	Case is ignored for this message printing (the standard capitalizes the first letter in the unit name)

#Get list of unique units in the annotation spreadsheet
unique_attribute_units <- distinct(annotations_df, attributeUnit)


#Iterate through each unique unit in the spreadsheet
for (attribute_unit in unique_attribute_units$attributeUnit ){
	attribute_unit <- as.character(attribute_unit)
	
	#If there is an open left parenthesis in the unit name, escape it
	if (grepl("\\(", attribute_unit) && grepl("\\)", attribute_unit ) == FALSE ){
		attribute_unit <- gsub("\\(",   "\\\\(", attribute_unit)
		
	}
	
	UO_unit_label_equivalent <- gsub('([[:upper:]])', ' \\1', attribute_unit) %>%
		tolower()
	
	UO_unit_singular_label <- gsub("s per ", " per ", UO_unit_label_equivalent)
	
	
	# Check if the unit name is found in the OBOE-Standards file (case is ignored)
	if( (grepl(paste0('owl:Class rdf:about="&oboe-standards;', attribute_unit,'"'), oboe_standards, ignore.case = TRUE) == FALSE ) &&
			grepl(paste0('<rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string">', UO_unit_label_equivalent), UO_text, ignore.case = TRUE) == FALSE &&
			grepl(paste0('<rdfs:label rdf:datatype="http://www.w3.org/2001/XMLSchema#string">', UO_unit_singular_label), UO_text, ignore.case = TRUE) == FALSE ){ 
		
			
		
		print(paste0(attribute_unit, " not found in the OBOE-Standards or Unit Ontology files"))
		
	}

}

