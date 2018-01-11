# ECSO Tasks and Issues List

### Tasks
1. Ensure that ECSO contains terms for describing carbon cycling issues in the Arctic
  1 .a  requires identifying terms we currently have that are relevant and correctly modeled
  1 .b. requires collecting additional terms that we do not yet know about or have not yet incorporated
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.b.1. requires mining metadata and extracting needed terms for incorporation into ECSO (R script)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.b.2. requires gaining familiarity with carbon cycling concepts, vocabulary, measurements and units (read background papers, examine relevant databases [e.g. Ameriflux (http://ameriflux.lbl.gov/) and Fluxnet (https://daac.ornl.gov/cgi-bin/dataset_lister.pl?p=9)])

2. Prepare the permafrost synthesis working group datasets as a use case
  2.1. need to examine the Schuur data files and extract information to add to the Google spreadsheet: https://drive.google.com/open?id=1u0rCkml8EHfMXYHPXv3PGlvdbA06WVPoju-vmxmaHAU
    2.1.1. requires examining, understanding and extracting measurement attributes and how they are described, including units, methods, and instruments (could be done manually or automated with scripts; potential task for interns)
  2.2 requires adding relevant terms obtained from the working group files to the ontology   
    2.2.1 requires finding any missing data objects and adding them to the ADC (at least 5 data packages have no data objects)
    2.2.2. requires adding attribute-level metadata to the Schuur data objects (task for interns)
    2.2.3. requires examining the attribute-level metadata to create new terms to add to the ontology

3. Demonstrate how semantic annotations improve search results in the ADC
  3.1. need to decide on query terms and how to evaluate precision/recall 
    3.1.1. requires writing scripts for performing batch queries on data objects without attribute-level metadata (https://github.nceas.ucsb.edu/NCEAS/adc-controlled-voc/blob/master/dataone-query.R) and with attribute-level metadata (https://github.nceas.ucsb.edu/NCEAS/adc-controlled-voc/tree/master/Attribute_metadata)
    3.1.2. requires comparing ADC search results with and without semantic annotations
    3.1.3. requires developing metrics for evaluating precision and recall
		
### Issues with ECSO 1.0 (found here: https://github.com/DataONEorg/sem-prov-ontologies/blob/ArcticECSO/observation/d1-ECSO.owl)
1. Class terms need to be reorganized in the hierarchy
  1.1. requires identifying terms currently at the root level that should be nested (e.g. CHEBI_33300)
  1.2. requires checking subsumption (class/subclass) relations between terms (e.g. "carbon flux"" is a sibling class of "carbon dioxide flux" when it should be a superclass)
  1.3. requires searching for redundant terms in the ontology

2. Ensure all terms have consistent annotation properties
  2.1. requires agreeing upon and verifying consistent use of annotation properties (e.g. alternative label)
    2.1.1. requires verifying that each term contains a populated "rdfs:label" field
	2.1.2. requires verifying that each term contains a populated "definition" field
	2.1.3. requires verifying that each term contains a populated "id" field
		
3. Ensure that each term contains a fully resolvable IRI using HTTP
  3.1. requires verifying that each term contains a fully resolvable IRI using HTTP	
	