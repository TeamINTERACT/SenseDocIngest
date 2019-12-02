Files in this directory will be run by sensedoc_ingest to clean up newly ingested data from SDB before the table is absorbed into the main data tables.

These are run once per user, but there are lots of users and each one has a lot of records, so each script should do what it can to abort early if it is not applicable to the data.

Known Global Tests Needed
    - missing required values (nulls ts, iid, x,y,z,lat,lon)
        drop record
        - currently being dropped during sqlite export

    - illegal required values (@lat<90, @lon<180...)
        drop record
        - currently being dropped during sqlite export

    - illegal optional values (nulls or impossibles for sat, alt, etc)
        replace with -9999
        - currently being transformed during sqlite export

    - out-of-window timestamps
        Example: see details in yokadi notes for item 118
        ts not within study boundaries
        ts not within individual user wear times
        drop record
        if iid and date window not in known exception list
            report violation to operator

        User 101002187 (VicW1) has illegal values from 2012, which
        Benoit has verified can be ignored, as they were caused by a low battery condition and do not contain real data.

        An ingest is only clean if it produces no violation warnings

Known Isolated Issues
