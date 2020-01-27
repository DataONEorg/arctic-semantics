### This script checks if an EML file is valid against the EML-2.2.0 schema.

library(xml2)

eml_file <- "eml_semantic_annotation_example.xml"


### Testing with xml_validate (local file)
test <- read_xml(eml_file)

schema <- read_xml("eml.xsd")

xml_validate(test, schema)






