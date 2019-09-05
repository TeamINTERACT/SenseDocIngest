CREATE TABLE IF NOT EXISTS level_0.sd_accel
(
    iid bigint NOT NULL,   -- interact_id
    ts timestamp NOT NULL, -- participant's local time
    x double precision NOT NULL,
    y double precision NOT NULL,
    z double precision NOT NULL,
    PRIMARY KEY(iid,ts)
);

CREATE TABLE IF NOT EXISTS level_0.sd_gps
(
    iid bigint NOT NULL,  -- interact_id
    ts timestamp NOT NULL, -- participant's local time
    lat double precision NOT NULL,
    lon double precision NOT NULL,
    speed real NOT NULL,
    course real NOT NULL,
    mode char(1) DEFAULT '',
    fix char(1) DEFAULT '',
    alt real NOT NULL,
    mode1 char(1) DEFAULT '',
    mode2 real NOT NULL,
    sat_used real NOT NULL,
    pdop real NOT NULL,
    hdop real NOT NULL,
    vdop real NOT NULL,
    sat_in_view integer DEFAULT -1 
);
