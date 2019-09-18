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
