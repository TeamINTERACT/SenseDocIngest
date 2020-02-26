What follows is a step-by-step protocol for ingesting a city/wave of data.

MIGRATION STEPS
    - [ ] VERIFY checksums valid for each uploaded SDB batch dir
            script: exactfile-verify
            if problem: work with coordinator to get proper files/checksums
        
    MERGING DISTINCT BATCHES INTO A COMMON HIERARCHY
        Usually, coordinators upload SD data in batches, which end up
        being in mulitple folder hierarchies, with a variety of 
        different topologies. But our ingest scripts require a known
        and consistent structure, so after everything has been uploaded.
        we need to go through and enforce that expected structure.

        But we do NOT want to risk damaging the data that has been uploaded.
        So we do this by first making a copy of the entire uploaded tree.

        - [ ] CREATE a new empty directory for working with SDB files
                cmd: mkdir <SDBROOT>_copy

        - [ ] COPY and MERGE the SDB file hierarchy into a duplicate tree
                for each SDBDIR in batch dir
                    cp -rf <BATCHDIR/<SDBDIR> <SDBROOT>_copy/

        MERGE all SDB directories/batches into single hierarchy
            Once the SDB directories have been put into a common folder,
            it is also common to find them organized by IID, rather than
            by IID_DEVID pairs. In such cases, data from multiple devices
            will be in a common IID folder, which is not how the scripts 
            expect to find them. So we need to break them up into different
            folders.

            - [ ] Run helper script: sdb_directory_refactor on <SDBROOT>_copy

        VERIFY refactoring
            After doing all this mucking about with these files, we want to 
            verify that we haven't lost or mangled anything in the process.
            So we run a script that will compare the original batch trees to 
            the reorganized tree and report any files that are missing or that
            have been altered. This is done by comparing MD5 checksums, not
            filenames and sizes, because filenames and paths have been changed.

            - [ ] Run helper script: verify_refactor on <SDBROOT>_copy and <SDBROOT>

    VERIFY participant folders are named in the form <IID>_<deviceid>
        Not all uploads will need extensive refactoring, but all of them still need 
        to be sure that the folders are named in the canonical form.

        ALTER if necessary
        - [ ] helper script: sdb_generate_fname

    VERIFY all SDB files have properly formed filenames
        Similarly, the SDB files themselves need to conform to the expected naming convention.

            SD<DEVID>fw<REVNO>_DATESTAMP(_rtcN).sdb

        Some sdb files may not encode their deviceid/revno
        If the sdb_generate_fname script can't figure it out from the supplementary files, we may have a problem.

        - [ ] Run helper script: sdb_generate_fname

            for f in `find <SDBROOT>_copy -name "SDfw*"` 
            do 
                d=`dirname $f` s=`sdb_generate_fname -f $d`
                echo "$f -> $d/$s"
                # add a mv cmd here
                # EXCEPT THAT THIS merges the foo.sdb and foo_rtc1.sdb variants. So use the 'find' to locate them, but then
                change the fnames manually?
            done

    VERIFY new refactored directory
        This is another good place to verify that we haven't mangled any of the datafiles.

        - [ ] Run: verify_refactor OLD_UNIFIED_DIR NEW_UNIFIED_DIR

    CREATE a new, unified checksum file for <SDBROOT>_copy
        Since we know the SDBROOT passed its checksums, and the verify_refactor works by comparing file checksums between the original and refactored directories, we know that the files in SDBROOT_copy are all good. So we can now build a new checksum file for the unified directory which we'll use from now on.

        - [ ] Run helper script: exactfile-generate

    NORMALIZE the linkage file
        In addition to the SD data folders, the other crucial upload from the coordinators
        (at least, until the linkage portal is operational) are the linkage files that
        provide a mapping between the userids used by our various data partners.
        The linkage file also serves to link users with specific SD devices, and provide
        start and end dates during which the devices were worn.

        Note: the linkage file needs to be in a particular format, with particular column
        names, but coordinators tend to use their own terms and language for this. So the
        first step is to create a normalized copy of the linkage file (never modify the
        original) and make your adjustments there.

        - [ ] Run linkage_verify CSVFILE ROOTDIR
            This will examine all the uploaded files and compare them to the information in
            the linkage file to be sure that we have all the data we're expecting, that 
            the data folders have actual data in them, that the linkage file has proper wear
            dates, and that there are no unexpected data folders. This step is crucial to 
            ensuring that we have all our ducks in a row before we try ingesting anything.

            The linkage_verify script produces a log that will itemize all the problems it 
            found. You'll now have to read that log and work with the coordinators to
            correct any problems. This usually results in the creation of an updated linkage
            file. 

            Repeat this step with the new linkage file, and then again, as many times as 
            necessary until the verify runs cleanly.


    MOVE the restructured hierarchy into the permanent archive
        - [ ] COPY <SDBROOT>_copy hierarchy to permanent_archive
        - [ ] COPY unified checksum file to permanent_archive
        - [ ] COPY linkage file to permanent_archive



INGEST PREPARATION STEPS
[Steps not yet play-tested]
    CONFIRM SDB FILES NORMALIZED, CHECKSUMMED, AND ARCHIVED
        VIC confirmed - see logs 2019-09-*
        MTL confirmed - see log 2019-12-17
        VAN confirmed - see log 2020-01-22
        SSK confirmed - see log 2020-02-05
    CONFIRM TREKSOFT LINKAGE
        VIC present
        MTL present
        SSK present
        VAN present
    CONFIRM SENSEDOC LINKAGE
        VIC present
        MTL present
        SSK present - extracted from xlsx file
        VAN present
    CONFIRM SURVEY VIEWS REFRESHED
        VIC present
        MTL present
        SSK missing
        VAN missing



    VERIFY linkage.csv file has column names expected by verifier
        ALTER as necessary
            - also ensure one assignment window per row
            - some coordinators track multiple windows per row by duplicating the start/end columns


    VERIFY all assignments in linkage file have associated data dirs
    VERIFY all sdb data dirs are associated with known participants

    ALTER sdb filenames to 

    INGEST linkage file into sensedoc_assignments
        - [ ] Run load_sdlinkage

    INGEST SDB folders

    If linkage was managed in an external file,
        
        verify linkage 
            test that all user/device assignments listed in linkage have data and that all data has a corresponding user/device record

            cmd: linkage_verify LINKAGE.CSV SDBDIR

        verify filename format 
            test that all user data files in target dir are formed correctly, and encode the serial number data referenced in the linkage file

            Also handled by the above cmd.

    ingest linkage table
        psql interact_db -c "\copy foo bar blat..."


INGEST LEVEL_0 SENSEDOC TABLES
[Steps not yet play-tested]
    run sensedoc_ingest

    examine log file for reported problems

        once problems found and corrected, make a record in the data_disposition col of the linkage table (CSV?) so they won't be reported in future ingests and need to be re-investigated

        run some basic stats on the log file to examine record retention rates. (Low rates may signal a problem with the data.)
            grep -o -E "RATE=[0-9.]+" logfile | cut -d=  -f 2 | jdescribe

    also run: ingest_spotcheck SDBDIR
        This will give a report of how many users are in the SDB directory but did not end up with records in the table.

        It will also give a report of any users with low record counts

        Either of these factors may indicate problems with the ingest.

    if log is clean, put it in the Logs directory, named to reflect city/wave/date of ingest
    if not, figure out what went wrong, fix it, and then reingest


Digest data into ToP tables
    Refresh materialized views of survey for city being ingested

    Confirm that Kole has access to:
        level_0.* tables
        survey.* tables
        portal_dev.* tables

        Some of these tables get dropped and rebuilt during the
        ingest process and that resets all their permissions.

    Technically, ToP would be considered a Digest script, as it is a transformation of existing tables, but since it needs to be run at ingest time, I'm including it here.

    Run the script in:
        tableofpower/top_generation.py
        or have Kole run it

    Ingest the ToP.csv file from wherever Kole put it.
    (Currently in projects/def-dfuller/testing/<cityname>_<waveid>_table_of_power_<YYYY-MM-DD>.csv

        run: Digest/load_ToP fname
                Note: it's in the Digest scripts, not Ingest

    Move CSV file to $PRJ/data_snapshots/<CITY)_W<WAVE>_SD_ToP_1sec_YYYYMMDD.zip

Dump level_0 tables to archive format:
    Be sure to dump only the records for that particular wave/city
    (Just in case there are other wave/cities in the table.)
        copy (select * from TABLENAME where city=1 and wave=1) into 'FNAME' with csv delimiter = ',';
        From the command line, run a command like this:

            psql interact_db -c "\copy level_0.sd_gps to 'montreal_gps_wave1_level0.csv' with (format csv, delimiter ',', header 1, quote '\"');"

        Then do the same thing for the sd_accel file.

        Then tar them both together with:
            tar cvjf montreal_wave1_level0.tar.bz2 montreal_*_wave1_level0.csv

        Compare the row counts of the two tables with the 
        counts in PSQL. 

        And if the row counts match:
            move the tar file to the permanent archive
            delete the .csv files
            drop the sd_gps and sd_accel tables

    The compress saved file:
        permanent_archive/CITYNAME/WaveN/Level0_SD_GPS.csv.bz2
        permanent_archive/CITYNAME/WaveN/Level0_SD_ACCEL.csv.bz2
    These can then be reloaded far more easily than re-ingesting

Drop level_0 tables or DELETE FROM SD_TABLENAME; for both tables.
    Best method: TRUNCATE TABLENAME;
    This is best because delete leaves ghosts that need to be
    garbage collected later. Truncate does not.

    If you DO forget and use DELETE, you can then clean up
    the ghost records by running REINDEX TABLE TABLENAME; afterward.

Update portal dashboard status
