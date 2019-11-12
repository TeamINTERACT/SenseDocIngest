The Problem
===========
In the process of ingesting raw data files, we inevitably come across issues within the data that require some kind of intervention. For example, in the case of participant #101002187 from Wave 1 Victoria, we discovered that some of the records were coded with timestamps in 2012. Upon investigation, it turns out that those were spurious records caused by a low battery condition, and we can safely ignore them. But these could just as easily have been legimate data records that had erroneous dates for some other reason. Consequently, for any given data hygiene test we might apply, we cannot treat all failures the same way. Each one will need to be investigated, and an appropriate decision made about how to handle that case. Some we can safely drop, as we are doing in the example case above, but others will be retained, after some appropriate correction is applied.

So the question becomes: *How do we track all of these decisions so that we can rerun the ingest process in the future without constantly tripping over the same known problems?*

Possible Solutions
==================
On one hand, these decisions could be coded into the ingest script explicitly, but that will lead to bloat of the core ingest code, and limit its applicability to other cities and other studies in the future.

Another choice would be to actually repair the SDB files in question, correcting the error conditions in the archived data so that they do not recur in future ingests. But this is problematic for several reasons. First, it assumes that the SDB files will never need to be rebuilt from the raw SD data. And second, it doesn't leave an explicit trail of the changes that were made, which compromises the transparency of our data handling.

Recommended Solution
====================
The best way to handle this, I think, is to create a set of "remedy" scripts that will become part of a slightly expanded ingest process.

Our current system uses a sort of "implicit" cleaning algorithm. Each SDB file is loaded into a temporary ingest table, and during that load, rows with illegal values (like a NULL timestamp or a latitude > 90) are dropped. Once the entire SDB file has been ingested into this temporary table, and only if the ingest completed successfully, the data is then moved into the live table and the process continues with the next SDB file.

Under the proposed changes, instead of dropping such rows implicitly, those tests would become explicit remedy scripts, to be processed along with all the specific case scenarios like the one for user 101002187. After loading an SDB file into the temporary DB table, all the known remedies will then be considered, and if appropriate, applied.

Once all the remedies have been run, whatever data is left in the table is known to have passed all our hygiene tests, so it can then be safely accepted into the main table. If any problems are found with the data later, it means we've discovered a new issue, so a new remedy script can be created and the ingest can be run again.

This solution allows us to find data problems before they taint downstream research, solve them quickly, document them thoroughly, and never have to touch them again. (Probably. :-)

Estimate
========
These changes are not particularly complicated and I don't anticipate them taking much time. It should take about a day to implement and then maybe a second day for testing and validation. But I want 

