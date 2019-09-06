CREATE TABLE IF NOT EXISTS level_0.sd_accel
(
    iid bigint NOT NULL,   -- interact_id
    ts timestamp NOT NULL, -- participant's local time, to microsec 
    x double precision NOT NULL,
    y double precision NOT NULL,
    z double precision NOT NULL,
    PRIMARY KEY(iid,ts)
);
COMMENT ON TABLE level_0.sd_accel IS 'Contains all the valid accelerometer records extracted from the SenseDoc devices. Granularity = 20ms';

CREATE TABLE IF NOT EXISTS level_0.sd_gps
(
    iid bigint NOT NULL,  -- interact_id
    ts timestamp NOT NULL, -- participant's local time, to microsec
    lat double precision NOT NULL,
    lon double precision NOT NULL,
    speed real,
    course real,
    mode char(1) DEFAULT '',
    fix char(1) DEFAULT '',
    alt real,
    mode1 char(1) DEFAULT '',
    mode2 real,
    sat_used real,
    pdop real,
    hdop real,
    vdop real,
    sat_in_view integer DEFAULT -1, 
    PRIMARY KEY(iid,ts)
);
COMMENT ON TABLE level_0.sd_gps IS 'Contains all the valid GPS records extracted from the SenseDoc devices. Granularity = 1s';
