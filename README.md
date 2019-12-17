What follows is a step-by-step protocol for ingesting a city/wave of data.

Preparation
    if linkage was managed in an external file,
        
        verify linkage 
            test that all user/device assignments listed in linkage have data and that all data has a corresponding user/device record

            cmd: linkage_verify LINKAGE.CSV SDBDIR

        verify filename format 
            test that all user data files in target dir are formed correctly, and encode the serial number data referenced in the linkage file

            Also handled by the above cmd.

    ingest linkage


Ingest Level_0 tables
    run sensedoc_ingest

    examine log file for reported problems

        once problems found and corrected, make a record in the exceptions list so they won't be reported in future ingests and need to be re-investigated

        run some basic stats on the log file to examine record retention rates. (Low rates may signal a problem with the data.)
            grep -o -E "RATE=[0-9.]+" logfile | cut -d=  -f 2 | jdescribe

    if log is clean, put it in the Logs directory, named to reflect city/wave/date of ingest
    if not, figure out what went wrong, fix it, and then reingest


Product ToP tables
    Technically, ToP would be considered a Digest script, as it is a transformation of existing tables, but since it needs to be run at ingest time, I'm including it here.

    Run the script in:
        tableofpower/top_generation.py

Drop level_0 tables

Update portal dashboard status
