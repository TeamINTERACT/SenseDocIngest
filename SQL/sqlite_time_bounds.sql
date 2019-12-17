/*
 * Running this SQL program against an SDB sqlite file
 * will display the min and max datestamps for both
 * the GPS and Accel data tables.
 */
BEGIN;
    PRAGMA temp_store = 4;
    CREATE TEMP TABLE _Vars(Name TEXT PRIMARY KEY, offset REAL, epoch TEXT);

    INSERT INTO _Vars(Name) VALUES ('acc_start');
    INSERT INTO _Vars(Name) VALUES ('acc_end');
    INSERT INTO _Vars(Name) VALUES ('gps_start');
    INSERT INTO _Vars(Name) VALUES ('gps_end');
    
    UPDATE _Vars SET offset = (SELECT min(ts)/1000000.0 FROM gps)  WHERE Name = 'gps_start';
    UPDATE _Vars SET offset = (SELECT max(ts)/1000000.0 FROM gps)  WHERE Name = 'gps_end';
    UPDATE _Vars SET offset = (SELECT min(ts)/1000000.0 FROM accel)  WHERE Name = 'acc_start';
    UPDATE _Vars SET offset = (SELECT max(ts)/1000000.0 FROM accel)  WHERE Name = 'acc_end';

    UPDATE _Vars SET epoch = (SELECT value from ancillary where key='refDate') WHERE Name = 'gps_start';
    UPDATE _Vars SET epoch = (SELECT value from ancillary where key='refDate') WHERE Name = 'gps_end';
    UPDATE _Vars SET epoch = (SELECT value from ancillary where key='refDate') WHERE Name = 'acc_start';
    UPDATE _Vars SET epoch = (SELECT value from ancillary where key='refDate') WHERE Name = 'acc_end';

    SELECT 'EPOCH: ', epoch from _Vars WHERE Name = 'gps_start';
    SELECT 'GPS 0: ', DATETIME(epoch, offset||' seconds') from _Vars WHERE Name = 'gps_start';
    SELECT 'GPS 1: ', DATETIME(epoch, offset||' seconds') from _Vars WHERE Name = 'gps_end';
    SELECT 'ACC 0: ', DATETIME(epoch, offset||' seconds') from _Vars WHERE Name = 'acc_start';
    SELECT 'ACC 1: ', DATETIME(epoch, offset||' seconds') from _Vars WHERE Name = 'acc_end';

    DROP TABLE _Vars;
END;
