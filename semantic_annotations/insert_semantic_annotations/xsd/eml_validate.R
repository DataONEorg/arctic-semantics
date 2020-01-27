### This script checks if an EML file is valid against the EML-2.2.0 schema.

library(eml2)
library(emld)
library(xml2)

eml_file <- "eml_semantic_annotation_example.xml"

test <- read_eml(eml_file)
test<- read_xml(eml_file)

schema <- read_eml("/Users/chong/Desktop/eml_validate/xsd/eml.xsd")

eml_locate_schema(test)



options("emld_db" = "eml-2.2.0")

eml2::eml_validate(test, schema )



### Testing with xml_validate
test2 <- read_xml(eml_file)

schema <- read_xml("eml.xsd")

xml_validate(test2, schema)






