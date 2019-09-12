CREATE TABLE IF NOT EXISTS level_0.sd_accel
(
    iid bigint NOT NULL,   -- interact_id
    ts timestamp with time zone NOT NULL, -- participant's UTC time, to millisec 
    x double precision NOT NULL,
    y double precision NOT NULL,
    z double precision NOT NULL,
    PRIMARY KEY(iid,ts)
);
COMMENT ON TABLE level_0.sd_accel IS 'Contains all the valid accelerometer records extracted from the SenseDoc devices. Granularity = 20ms';

CREATE TABLE IF NOT EXISTS level_0.sd_gps
(
    iid bigint NOT NULL,  -- interact_id
    ts timestamp with time zone NOT NULL, -- participant's UTC time, to millisec
    lat double precision NOT NULL,
    lon double precision NOT NULL,
    speed real DEFAULT 'NaN',
    course real DEFAULT 'NaN',
    -- mode char(1) DEFAULT '',
    -- fix char(1) DEFAULT '',
    alt real DEFAULT 'NaN',
    -- mode1 char(1) DEFAULT '',
    -- mode2 real DEFAULT 'NaN',
    sat_used real DEFAULT 'NaN',
    pdop real DEFAULT 'NaN',
    hdop real DEFAULT 'NaN',
    vdop real DEFAULT 'NaN',
    sat_in_view integer DEFAULT -1, 
    PRIMARY KEY(iid,ts)
);
COMMENT ON TABLE level_0.sd_gps IS 'Contains all the valid GPS records extracted from the SenseDoc devices. Granularity = 1s';
