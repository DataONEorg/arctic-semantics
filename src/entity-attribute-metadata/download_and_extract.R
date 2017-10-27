#' download_and_extract.R
#' Author: Bryce Mecum <mecum@nceas.ucsb.edu>
#'
#' Download and extract Entity-Attribute metadata from EML records present on
#' the Arctic Data Center. This script is intended to be used to get a sense of
#' what attributes already have metadata across the ADC for the purpose of
#' building out ontologies to describe and annotate metadata records.
#'
#' This script generates a CSV with a row for each attribute, for each entity,
#' for each EML record.
#'
#' It is intended to be run line-by-line. It produces a CSV and a ton of XML
#' documents in the current working director.

# Install the remotes package to install a companion package 'eatocsv' I wrote
# just for this purpose
if (!requireNamespace("remotes")) {
  install.packages('remotes')
}
if (!requireNamespace("eatocsv")) {
  remotes::install_github("amoeba/eatocsv")
}

library(eatocsv)
library(dataone)
library(readr)
library(future)
library(xml2)

#' Step 1:
#' Query for records to download
CN <- CNode("PROD")
arcticdata.io <- dataone::MNode("https://arcticdata.io/metacat/d1/mn/v2")

query_url <- paste0(arcticdata.io@baseURL,
                    "/v2/query/solr/",
                    "?fl=identifier",
                    '&q=formatType:METADATA+AND+datasource:"urn:node:ARCTIC"+AND+-obsoletedBy:*+AND+attribute:*',
                    "&rows=1000",
                    "&start=0",
                    "&wt=csv")

query_datetime <- Sys.time() # Save querytime for later
documents <- readr::read_csv(query_url);

#' Step 2:
#' Download in parallel using the future package
future::plan("multiprocess")
download_objects(CN, documents$identifier)

#' Step 3:
#' Parse and extract entities and their attributes
document_paths <- lapply(list.files(full.names = TRUE, pattern = "*.xml"), read_xml)
attributes <- eatocsv::ea_to_csv(document_paths)
write_csv(attributes, paste0(format(query_datetime, "%Y%m%d%H%M%S"), "_attributes.csv"))
