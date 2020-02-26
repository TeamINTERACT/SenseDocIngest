create table portal_dev.sensedoc_assignments (
    id SMALLSERIAL,
    interact_id integer not null,
    sensedoc_serial integer not null,
    city_id integer not null,
    wave_id integer not null,
    started_wearing char(10),
    stopped_wearing char(10),
    Primary Key(id)
);
COMMENT on COLUMN portal_dev.sensedoc_assignments.id IS
           'Simple row number index.';
COMMENT on COLUMN portal_dev.sensedoc_assignments.interact_id IS
           'Unique identifier of project participant.';
COMMENT on COLUMN portal_dev.sensedoc_assignments.sensedoc_serial IS
           'Unique identifier of a device assigned to participant.';
COMMENT on COLUMN portal_dev.sensedoc_assignments.city_id IS
           'The study city in which the user is enrolled.';
COMMENT on COLUMN portal_dev.sensedoc_assignments.wave_id IS
           'The data collection wave for which this assignment was made';
COMMENT on COLUMN portal_dev.sensedoc_assignments.started_wearing IS
           'The date this user received this device, with the understanding that good data will not begin until the following day.';
COMMENT on COLUMN portal_dev.sensedoc_assignments.stopped_wearing IS
           'The last date on which the user wore this device, which we assume extends until 3:00 the following morning.';
