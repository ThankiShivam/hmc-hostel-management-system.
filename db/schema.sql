-- Run inside a transaction. db/install.sql loads this file and the demo records together.
CREATE SCHEMA hmc;
SET LOCAL search_path TO hmc, pg_catalog;

CREATE TABLE admin (
    admin_id integer PRIMARY KEY,
    name varchar(100) NOT NULL,
    email varchar(150) NOT NULL UNIQUE
);

CREATE TABLE wing (
    wing_id integer PRIMARY KEY,
    wing_name varchar(50) NOT NULL UNIQUE,
    type varchar(50),
    floors integer CHECK (floors > 0)
);

CREATE TABLE staff (
    staff_id integer PRIMARY KEY,
    name varchar(100) NOT NULL,
    contact_no varchar(15) NOT NULL,
    working_hours varchar(30),
    working_days varchar(20),
    salary numeric(10, 2) CHECK (salary >= 0),
    role varchar(50) NOT NULL,
    managed_by integer REFERENCES admin
);

CREATE TABLE cleaning_staff (
    staff_id integer PRIMARY KEY REFERENCES staff ON DELETE CASCADE,
    working_area varchar(100)
);
CREATE TABLE plumber (staff_id integer PRIMARY KEY REFERENCES staff ON DELETE CASCADE);
CREATE TABLE carpenter (staff_id integer PRIMARY KEY REFERENCES staff ON DELETE CASCADE);
CREATE TABLE electrician (staff_id integer PRIMARY KEY REFERENCES staff ON DELETE CASCADE);
CREATE TABLE warden (
    staff_id integer PRIMARY KEY REFERENCES staff ON DELETE CASCADE,
    assigned_wing integer REFERENCES wing
);

CREATE TABLE rooms (
    wing_id integer REFERENCES wing,
    room_no integer,
    capacity integer NOT NULL CHECK (capacity > 0),
    availability boolean NOT NULL DEFAULT true,
    PRIMARY KEY (wing_id, room_no)
);
COMMENT ON COLUMN rooms.availability IS 'Administrative flag: the room is open for allocation.';

CREATE TABLE student (
    student_id bigint PRIMARY KEY,
    name varchar(100) NOT NULL,
    dob date,
    contact varchar(15),
    email varchar(150) UNIQUE,
    branch varchar(100),
    emergency_contact varchar(15),
    father_contact varchar(15),
    father_name varchar(100),
    year integer CHECK (year > 0),
    health_details text,
    status varchar(30) NOT NULL DEFAULT 'Active',
    program varchar(100),
    resident_wing integer,
    resident_room integer,
    hmc_flag boolean NOT NULL DEFAULT false,
    gender varchar(10),
    FOREIGN KEY (resident_wing, resident_room) REFERENCES rooms (wing_id, room_no) MATCH FULL
);

CREATE TABLE visitor (
    visitor_id integer PRIMARY KEY,
    name varchar(100) NOT NULL,
    contact_no varchar(15),
    aadhar_no varchar(12) UNIQUE,
    stay_duration integer CHECK (stay_duration >= 0),
    check_in date,
    check_out date,
    request_status varchar(30) NOT NULL DEFAULT 'Pending',
    approved_by integer REFERENCES admin,
    allocated_wing integer,
    allocated_room integer,
    FOREIGN KEY (allocated_wing, allocated_room) REFERENCES rooms (wing_id, room_no) MATCH FULL,
    CHECK (check_out IS NULL OR (check_in IS NOT NULL AND check_out >= check_in))
);

CREATE TABLE suggestions (
    suggestion_id integer PRIMARY KEY,
    description text NOT NULL,
    visitor_id integer NOT NULL REFERENCES visitor
);

-- The shared transaction row chooses the payer type. Both child keys must match it.
CREATE TABLE payment (
    transaction_id bigint PRIMARY KEY,
    method varchar(50) NOT NULL,
    date date NOT NULL,
    payer_type text NOT NULL CHECK (payer_type IN ('student', 'visitor')),
    UNIQUE (transaction_id, payer_type)
);
CREATE TABLE student_payment (
    transaction_id bigint PRIMARY KEY,
    student_id bigint NOT NULL REFERENCES student,
    amount numeric(10, 2) NOT NULL CHECK (amount > 0),
    payer_type text GENERATED ALWAYS AS ('student'::text) STORED,
    FOREIGN KEY (transaction_id, payer_type) REFERENCES payment (transaction_id, payer_type) ON DELETE CASCADE
);
CREATE TABLE visitor_payment (
    transaction_id bigint PRIMARY KEY,
    visitor_id integer NOT NULL REFERENCES visitor,
    amount numeric(10, 2) NOT NULL CHECK (amount > 0),
    payer_type text GENERATED ALWAYS AS ('visitor'::text) STORED,
    FOREIGN KEY (transaction_id, payer_type) REFERENCES payment (transaction_id, payer_type) ON DELETE CASCADE
);

CREATE TABLE complaint (
    comp_id integer PRIMARY KEY,
    type varchar(50),
    status varchar(30) NOT NULL DEFAULT 'Open'
        CHECK (status IN ('Open', 'In Progress', 'Resolved', 'Closed')),
    description text,
    reporting_date date NOT NULL,
    assigned_by integer REFERENCES staff,
    student_id bigint NOT NULL REFERENCES student,
    solved_by integer REFERENCES staff,
    resolved_on date,
    CHECK (resolved_on >= reporting_date),
    CHECK ((status IN ('Resolved', 'Closed')) = (resolved_on IS NOT NULL))
);

CREATE TABLE parcel (
    parcel_id integer PRIMARY KEY,
    arrival_date date NOT NULL,
    timestamp timestamp DEFAULT CURRENT_TIMESTAMP,
    status varchar(30) NOT NULL DEFAULT 'Pending',
    received_date date,
    student_id bigint NOT NULL REFERENCES student,
    handover_by integer REFERENCES staff,
    CHECK (received_date >= arrival_date)
);

CREATE TABLE overnight_leave (
    leave_id integer PRIMARY KEY,
    request_date date NOT NULL,
    from_date date NOT NULL,
    to_date date NOT NULL,
    return_timestamp timestamp,
    status varchar(30) NOT NULL DEFAULT 'Pending',
    student_id bigint NOT NULL REFERENCES student,
    approved_by integer REFERENCES staff,
    CHECK (to_date >= from_date)
);

CREATE TABLE attendance (
    student_id bigint REFERENCES student,
    date date,
    status varchar(20) NOT NULL DEFAULT 'Present' CHECK (status IN ('Present', 'Absent', 'On Leave')),
    PRIMARY KEY (student_id, date)
);

CREATE INDEX student_active_room ON student (resident_wing, resident_room) WHERE status = 'Active';

CREATE VIEW room_occupancy AS
SELECT r.wing_id, w.wing_name, r.room_no, r.capacity, r.availability,
       count(s.student_id)::integer AS occupied_beds,
       r.capacity - count(s.student_id)::integer AS vacant_beds
FROM rooms r
JOIN wing w ON w.wing_id = r.wing_id
LEFT JOIN student s ON (s.resident_wing, s.resident_room) = (r.wing_id, r.room_no)
                   AND s.status = 'Active'
GROUP BY r.wing_id, w.wing_name, r.room_no, r.capacity, r.availability;
