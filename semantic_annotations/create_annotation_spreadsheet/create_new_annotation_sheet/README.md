# Creating a new semantic annotation spreadsheet

For the ADC carbon measurement semantic annotation project, a spreadsheet is used to assign term IDs found in the ECSO ontology to attributes. The spreadsheet is then used as input for the `insert_attribute_annotations_into_EML.R` script to programmatically create the appropriate annotation nodes and insert them into the correct places in the EML documents, found [here](https://github.nceas.ucsb.edu/stevenchong/adc-controlled-voc/tree/master/semantic_annotations/insert_semantic_annotations).

## Workflow
This workflow is for creating a brand new annotation spreadsheet. If you would rather *update* an existing spreadsheet, you should follow the workflow found here.

As an overview, the process we followed allowed us to retrieve the data packages containing carbon-relevant terms and then create a spreadsheet listing the attributes inside those packages. We then used the spreadsheet to assign annotations to the attributes.

### Steps
1) Run the `01_dataone-batch-query_general_and_data_attribute.R` script (found in the [ADC_query_analysis_workflow folder](https://github.nceas.ucsb.edu/NCEAS/adc-controlled-voc/tree/master/ADC_queries/ADC_query_analysis_workflow)) to programmatically query the Arctic Data Center. It takes as input the Carbon_Cycling_Terms.csv file, which contains a list of carbon-relevant terms that may be modified, as needed. The script replicates the results you would receive if you performed searches on the query terms in the general search box and data attribute search box. The results are stored in individual CSV files -- each file contains the results from a particular search type and query term.

2) Run the `02_merge_multiple_query_results.R` script in this folder. This script combines the output CSV files from Step 1 into a single CSV file.

3) Run the `03_create_new_annotation_sheet.R` script in this folder. This script first downloads *all* of the attribute-level metadata for the ADC and then creates a subset based on the packages returned from the carbon-relevant queries. The output is a CSV file suitable for semantic annotation.

## Notes
- This workflow was created specifically to annotate *attributes* in the Arctic Data Center. Currently, only terms from the ECSO vocabulary are used.
- When annotating the attribute-level metadata, the 8-digit numerical identifier for each ECSO term should be input into the spreadsheet.

