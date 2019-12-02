What follows is a step-by-step protocol for ingesting a city/wave of data.

Preparation
    if linkage was managed in an external file,
        
        verify linkage 
            test that all user/device assignments listed in linkage have data and that all data has a corresponding user/device record

        verify filename format 
            test that all user data files in target dir are formed correctly, and encode the serial number data referenced in the linkage file

    ingest linkage


Ingest Level_0 tables
    run sensedoc_ingest

    examine log file for reported problems

        once problems found and corrected, make a record in the exceptions list so they won't be reported in future ingests and need to be re-investigated

Product ToP tables

Drop level_0 tables

Update portal dashboard status
