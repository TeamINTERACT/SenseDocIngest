create table portal_dev.sensedoc_assignments (
    id SMALLSERIAL,
    interact_id integer not null,
    sensedoc_serial text not null,
    sensedoc_id text not null,
    city_id integer not null,
    wave_id integer not null,
    started_wearing char(10),
    stopped_wearing char(10),
    notes text,
    Primary Key(id)
);
