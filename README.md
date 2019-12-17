What follows is a step-by-step protocol for ingesting a city/wave of data.

INGEST STEPS
    VERIFY checksums valid for SDB dirs
        script: exactfile-verify
        
    CREATE a new empty directory for working with SDB files
        cmd: mkdir <SDBROOT>_copy

    COPY and MERGE the SDB file hierarchy into a duplicate tree
        for each SDBDIR in batch dir
            cp -rf <BATCHDIR/<SDBDIR> <SDBROOT>_copy/

    MERGE all SDB directories/batches into single hierarchy
        helper script: sdb_directory_refactor on <SDBROOT>_copy
        helper script: verify_refactor on <SDBROOT>_copy and <SDBROOT>
        
    VERIFY SDB folders are named in the form <IID>_<deviceid>
        ALTER if necessary
        helper script: sdb_generate_fname

        some sdb files may not know their deviceid/revno
        if the sdb_generate_fname script can't figure it out from the supplementary files, we may have a problem.

    Since we know the SDBROOT passed its checksums, and the verify_refactor works by comparing file checksums between the original and refactored directories, we know that the files in SDBROOT_copy are all good. So we can now build a new checksum file for the unified directory which we'll use from now on.

    CREATE a new, unified checksum file for <SDBROOT>_copy
        helper script: exactfile-generate

    VERIFY linkage.csv file has column names expected by verifier
        ALTER as necessary

    VERIFY .sdb files named in the form SD<DEVID>fw<REVNO>_DATESTAMP.sdb
        ALTER if necessary


    COPY <SDBROOT>_copy hierarchy to permanent_archive
    COPY unified checksum file to permanent_archive

    COPY linkage file to permanent_archive





    VERIFY all assignments in linkage file have associated data dirs
    VERIFY all sdb data dirs are associated with known participants

    ALTER sdb filenames to 

    INGEST linkage file into sensedoc_assignments
    INGEST SDB folders

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
