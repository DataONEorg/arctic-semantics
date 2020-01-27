# Inserting Semantic Annotations into EML Files

The `insert_attribute_annotations_into_EML.R` script creates semantic annotations from data contained within an annotation spreadsheet and inserts the XML annotation nodes into existing EML 2.1 files and converts them to EML 2.2. This script was made as part of the project to annotate attributes in the Arctic Data Center related to carbon measurements. As of today (August 21, 2019), the script is constrained to annotating attributes in the ADC.  

## Steps
The script is divided into 4 steps that may be run separately, however, they should be run in sequential order. Prior to running the script, you should obtain a token from the ADC so that you have permission to access the system metadata for getting the latest data package versions.

1. Reads in input files, including the ontology files:
- ECSO (https://github.com/DataONEorg/sem-prov-ontologies/tree/ECSO8-add_non-carbon_measurements/observation)
- OBOE-Core and OBOE-Standards (https://github.com/NCEAS/oboe)
- Unit Ontology (http://www.ontobee.org/ontology/UO)
- RDF Syntax (RDFS) (http://www.w3.org/1999/02/22-rdf-syntax-ns#)

... and the annotation spreadsheet. The spreadsheet is a modified version of the output CSV file from [this package](https://github.com/amoeba/eatocsv) that downloads all attribute-level metadata from the ADC. An additional `ECSO_` column was added for the ADC carbon measurement annotation process to store the unique 8 digit numerical identifier for ECSO terms. If a package identifier has been updated, this script will update the identifier to the latest version.

2. Downloads the XML files for each of the current package identifiers and stores them locally in a subfolder.

3. Creates the XML annotation nodes and inserts them into the appropriate attribute nodes in the XML files. The edited files are saved in a subfolder and are renamed with an `_edited` suffix.

4. (optional) This step validates the output XML files using Ropensci's [EML](https://github.com/ropensci/EML) package. Note that there is a known issue where a subset of valid XML files will fail validation due to how the namespaces for units were assigned. A description of the issue may be found [here](https://github.com/ropensci/emld/issues/34). It is expected the issue will be resolved in a future release of the EML package. 

## Notes
This script: 
- currently only annotates EML attributes.
- currently can only create annotation nodes with the OBOE `contains measurements of type` and `has unit` object properties.
- uses the annotation spreadsheet to search for specific attributes contained within specific entities in specific data packages. If there are duplicate attribute names within the same entity, the script will skip the annotation for those attributes as it can't unambiguously find a match to a specific attribute.
- updates the namespace of the output documents to the following format: `https://eml.ecoinformatics.org/eml-2.2.0`
- updates the STMML version number to 1.2 in the output documents
- updates the `xsi:schemaLocation` to `https://eml.ecoinformatics.org/eml-2.2.0 eml.xsd` in the output documents
- updates the `xmlns:ds` node attribute to `https://eml.ecoinformatics.org/dataset-2.2.0`
