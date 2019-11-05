2019-09-26
----------
    Summary
    - Cautious ingest scheme w wave rollback - causing temp DB bloat 
        - cedar has 1TB, hard DB limit (for now)
        - revised scheme to forgo rollback at wave level
            - could use PREPARE TRANSACTION, COMMIT/ROLLBACK PREPARED
            - but this pushes entire state to storage, duplicating bloat
        - reingested Mtl and Vic
        - Adoption of Brin-type index would reduce DB size by 50%
    - 1.1% ingest leakage
        It's not coming from the null/illegal value filter (app 0.002%)
        Investigating source of leakage
        Won't do re-ingest until this is figured out
    - Devised new Migration step: linkage validation
        - identified a number of issues with Mtl, Vic, and Sk data
            - missing files
            - mislabeled files (wrong iid)
            - unexpected files
        - all issues have been resolved
        - everything will need to be re-ingested again
    - Vancouver files received and checksum validated, sort of
        Outer checksums matched, but files were double-zipped
        Some internal unzips reported checksum mismatch (4)
        Apparently Vault forces zip downloads, so no workaround
        When zipped checksum complains, no way to know which file
        Working my way through raw file validations
        Directories still need to be refactored (handy script)
        Migration waiting for linkage validation
    - DB size cap: 
        920 GB after Mtl and Vic
        Short term: restructure DB indices 
            Btree index appx equal size to tables they index
                New BRIN index virt. eliminates index size
                420GB vs 20MB
                Also faster to ingest
                Also faster for most common queries on timeseries data
                Should buy us enough space for Sk and Van
            Not implementing until Oct 15
            Will reingest everything once Van is ready
        Long term:
            CC is working on expanding storage limit
            No response yet on whether a diff cluster wld be larger

2019-09-24
----------
    We've hit the DB size cap. After ingesting just Montreal and Victoria Wave 1 data, the DB is already at 920 GB, just shy of our 1TB limit. Curiously, 424GB of that size is taken up by the accel table's index. I'm now going to try several different index configurations to see which one gives us the best trade-off between index size and performance.

    For the record, the current index is a default btree, multi-column index, combining both iid and ts, which together should be unique for every record. But since we don't really know what kinds of queries are going to be performed on the data, we might be better off with single indices on each column. Additionally, the newer BRIN-style index appears to have HUMONGOUS space savings, dropping from 400 GB to just 25MB. They also seem to be more efficient for the kinds of queries we're most likely to do, but I want to experiment with a few different configurations and see what happens.

    My plan is to create each kind of index (btree and brin) as both a multi-index on iid/ts, and as individual indices. Then I'll analyse some sample queries and see which indices the planner chooses.

2019-09-23
----------
    During ingest of Montreal, there was an unexpected rate of data 
    loss. I assumed at first that it was dropping rows due to duplicated 
    timestamps, so I wrote duplication_sniffer to investigate.
    Montreal ingest reports having lost 400,000 rows (1.1%) but the sniffer reports that only 905 rows (0.0024%) were duplicates, 
    so the cause of the leakage must lie elsewhere.

    Possible avenues to investigate:
        - I can figure out some way to report ingested vs dropped
          rows for every file ingested and then re-run the ingest
          to identify the rows in question. (But this is expensive.)
            - Since the GPS is the one being used to guide ingest 
              and it's comparatively small, I can run this test 
              without interfering with the production tables if I 
              ingest ONLY the gps, and do so into a dummy side table.
            - Or why not a dummy schema? Yes. level_null.
        - Could the records somehow be NOT unique on iid/ts? If so, 
          that constraint could be causing redundant records to be dropped. (This seems unlikely, since we're pre-screening
          the SDB files for a given IID to ensure they have no overlapping timestamps.)

        - We're also dropping records with NULL fields. Accel rows
          with NULL for x, y, or z get dropped, and GPS rows are dropped if they have an illegal value for any of lat/lon/alt/course/speed/sat*.
        - I'm going to run a test on the Victoria SDB set to see how 
          many rows those filters are culling.
        - Nope, those validation filters only account for a row drop rate
          of about 0.003%. Nowhere near the 1.1% we're seeing.
        - Looks like I'm going to have to go ahead with the instrumented
          ingest mentioned above.

2019-09-12
----------
    SenseDoc Ingest Process: Assumptions and Changes
    ================================================

    This document summarizes the decisions and assumptions made regarding our handling of the incoming SenseDoc data during ingest. In particular, we're discussing changes to the original ingest prototype.


    File Handling
    -------------
    Perhaps the biggest change in the new process is the number of times we process each file. The prototype took an iterative approach, converting the SDB files into CSV, culling bad records, merging multiple files together for each participant, and then finally ingesting the resulting table data into the DB. This process read, wrote, traversed and/or modified each datafile four or five times before it was fully ingested.

    By contrast, the new process reads each file just once, filtering and normalizing the fields and data rows as part of the extraction from the SDB. But instead of storing the extracted file in an intermediate CSV on disk, it is fed directly into the DB as we read it.

    The result is many fewer "touches" to each record and much less time spent waiting for hard drive I/O. This process should be significantly faster than the prototype and require much less disk storage for archiving purposes. 

    One potential problem with this change is that if the ingest of a particular participant's data fails, we will have to reingest it from scratch - there will be no intermediate files on hand to serve as a checkpoint. 


    File Naming
    -----------
    Within the root folder for a particular SenseDoc ingest, the subfolders are expected to be named in the form {INTERACT_ID}_{SD_ID}. Although some older waves only used the INTERACT_ID, in which case it is assumed that all SDB files for a given user are within that single INTERACT_ID folder. 

    At present, the ingest script does NOT search recursively through subdirectories within the INTERACT_ID folder to find additional SDB files as we assume they will all be at the top level of the folder.

    COORDINATORS: Are the two assumptions listed here safe ones?


    Redundant Dates
    ---------------
    Previous versions of the ingest process preserved both the integer microsecond timestamp and the utc_date fields from the SenseDoc accelerometer table. But the timestamp field is incomplete without also knowing its reference date, which is potentially different for every device, and was not being captured in our ingest process. So for the sake of clarity and simplicity, they are being merged. Upon ingest, the microsecond and reference date information will be combined to produce a single UTC timestamp with microsecond precision, although in practice, the most precise data we currently receive is at the 10s of millisecond level.


    Window Overlap
    --------------
    Currently, we assume that if a contributor has provided multiple data files, the timespans of data they contain will not overlap, since an overlap suggests that they either were being produced simultaneously.

    In the case where a participant's files do overlap in this way, that participant's entire dataset is omitted and the problem is flagged in the ingest report for the coordinators to resolve.


    Local Time
    ----------
    We considered transforming all timestamps from UTC time to local time, to save researchers from having to do so themselves, but in the end elected to keep the timestamps as they were, as existing algorithms have already been built with an assumption of UTC time.


    Redundant Timestamps
    --------------------
    There is a known glitch in SenseDoc devices that occasionally cause a small number of samples (typically 2-4) to be recorded with the same timestamp. After analysing a number of examples, we found no clear pattern by which any one record could be construed as "preferable" to the others. It is not the case that the first or last duplicate is always of higher precision, or has null fields, etc. We contemplated taking an average of these records rather than recording just one, but the benefits of doing so seem limited, especially when contrasted with the increased processing time that would be required to ingest every file.

    To that end, we have elected to continue with the protocol implemented in the prototype, by keeping the first record with any given timestamp and ignoring any duplicated timestamps that follow.


    Column Retention
    ----------------
    After some discussion, we have determined that all the fields of the accelerometer table are required (aside from the utc_date discussed in the Redundant Dates section above) and will be ingested.

    This is not true, however, for the GPS table. Clearly the interact_id, timestamp, latitude, and longitude fields are essential. Additionally, the speed, course, and altitude are likely of potential research interest, and the sat_used and sat_in_view fields may be needed for estimating the quality of the location fix. Benoit has advised us that the pdop, hdop and vdop fields may also be useful. But nobody has spoken in defence of the fix, mode, mode1, and mode2 fields.

    Consequently, the fix, mode, mode1, and mode2 fields have been omitted from the current ingest process. If you know any reason why those should be retained after all, now would be a good time to speak up about it.


    Data Sufficiency
    ----------------
    The ingest prototype implemented a protocol whereby any file less than 10MB in size was omitted from the process on the grounds that it does not contain enough telemetry data to be of value.

    This was a reasonable cutoff for prototyping purposes, but for production, we have decided to use a time-based test. After merging the data from a participant's (potentially multiple) data files, any contribution that is less than 1 hour of total data will be omitted. (Specifically, any participant with fewer than 3600 GPS samples over the duration of the entire wave.)

    The objective is to eliminate data that is of no use to the project, but to keep everything else for later consideration.


    Column Sanity Checks
    --------------------
    For a variety of reasons, SenseDoc data fields are occasionally NULL. For crucial fields (timestamp, gps.lat, gps.lon, accel.x, accel.y, accel.z) a NULL value causes that record to be omitted from the ingest stream. But for most other fields, a NULL is converted to a default value (see next section).

    The prototype also applies a few other basic sanity checks to the records, rejecting any samples with seemingly "impossible" values. Specifically, it checks to be sure that latitude values are between -90 and 90 degrees, and longitude are between -180 and 180 degrees.

    We've added the following additional tests:

    * speed should be between 0 and 1000 km/h
    * course should be between -360 and +360 degrees
    * alt should be between -10000 and 10000 meters
    * sat_used should be between 0 and 50[^1] satellites
    * sat_in_view should be between 0 and 50 satellites

    We do not know of any appropriate sanity limits to test for in the case of: hdop, vdop and pdop, so those are not currently being filtered.

    [^1]: As of 2019, the GNSS system supports 27 active satellites at any one time and there are only 31 total satellites in orbit.]


    Column Defaults
    ---------------
    As mentioned above, the primary data columns for each table (x, y, z for accel; lat, lon for gps; and iid and timestamp for both) are required columns. Records with a NULL value for any of those fields are dropped at ingest time. 

    For all other floating point fields (speed, course, alt, pdop, hdop, vdop, sat_used) a default value of NaN is assigned whenever data is missing from the input record. Since SQL does not support the concept of NaN for integer fields, the sat_in_view column is assigned a default of -1.

    These default values allow us to ingest most input records while still making it possible for researchers to filter out incomplete records if they wish, but without having to worry about the possibility of NULL field content.


    Ingest Report
    -------------
    Upon completion of an ingest cycle, a copy of the runtime log will be sent to the coordinator for review. This report is produced by the ingest process itself and summarizes the number of participants processed, the number of records present in the incoming archive, the number of records actually ingested (there will be fewer, given the basic acceptance filtering mentioned above) and a list of specific participants whose data was omitted for reasons of minimum sufficiency or overlapping date windows.

    The data will not be considered fully ingested until the coordinator has reviewed and approved the log. 
