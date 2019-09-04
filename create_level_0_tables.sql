CREATE TABLE IF NOT EXISTS level_0.accel
(
    iid bigint NOT NULL,
    ts timestamp NOT NULL,
    x INTEGER NOT NULL,
    y INTEGER NOT NULL,
    z INTEGER NOT NULL,
    PRIMARY KEY(iid,ts)
);

CREATE TABLE IF NOT EXISTS level_0.gps
(
    iid bigint NOT NULL,
    ts timestamp NOT NULL,
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
