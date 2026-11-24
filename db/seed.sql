-- Fictional reporting fixture. The original personal and identity fields stay empty.
SET LOCAL search_path TO hmc, pg_catalog;

INSERT INTO admin (admin_id, name, email) VALUES
    (1, 'Demo Administrator', 'admin@example.invalid'),
    (2, 'Duty Administrator', 'duty@example.invalid');

INSERT INTO wing (wing_id, wing_name, type, floors) VALUES
    (1, 'North', 'Residential', 2), (2, 'South', 'Residential', 2),
    (3, 'Annex', 'Planned', 1);
INSERT INTO rooms (wing_id, room_no, capacity, availability) VALUES
    (1, 101, 2, true), (1, 102, 2, true), (1, 103, 2, false),
    (2, 101, 3, true), (2, 102, 1, true);

INSERT INTO staff (staff_id, name, contact_no, working_hours, working_days, salary, role, managed_by) VALUES
    (1, 'North Warden', 'EXT-101', '08:00-16:00', 'Mon-Fri', 35000, 'Warden', 1),
    (2, 'South Warden', 'EXT-102', '14:00-22:00', 'Mon-Fri', 35500, 'Warden', 1),
    (3, 'Cleaning Lead', 'EXT-103', '08:00-16:00', 'Mon-Sat', 21000, 'Cleaning', 2),
    (4, 'Plumbing Lead', 'EXT-104', '09:00-17:00', 'Mon-Fri', 27000, 'Plumber', 2),
    (5, 'Carpentry Lead', 'EXT-105', '09:00-17:00', 'Mon-Fri', 26500, 'Carpenter', 2),
    (6, 'Electrical Lead', 'EXT-106', '09:00-17:00', 'Mon-Fri', 28000, 'Electrician', 2);
INSERT INTO warden VALUES (1, 1), (2, 2);
INSERT INTO cleaning_staff VALUES (3, 'North common areas');
INSERT INTO plumber VALUES (4);
INSERT INTO carpenter VALUES (5);
INSERT INTO electrician VALUES (6);

INSERT INTO student (student_id, name, email, branch, year, program, status, resident_wing, resident_room, hmc_flag, health_details) VALUES
    (101, 'Demo Resident A', 'resident-a@example.invalid', 'ICT', 2, 'BTech', 'Active', 1, 101, true, NULL),
    (102, 'Demo Resident B', 'resident-b@example.invalid', 'ICT', 2, 'BTech', 'Active', 1, 101, false, NULL),
    (103, 'Demo Resident C', 'resident-c@example.invalid', 'MnC', 1, 'BTech', 'Active', 2, 101, false, 'Fictional accessibility request'),
    (104, 'Demo Resident D', 'resident-d@example.invalid', 'ICT', 3, 'BTech', 'Inactive', 2, 101, false, NULL),
    (105, 'Demo Resident E', 'resident-e@example.invalid', 'ICT', 1, 'BTech', 'Active', NULL, NULL, false, NULL);

INSERT INTO visitor (visitor_id, name, stay_duration, check_in, check_out, request_status, approved_by, allocated_wing, allocated_room) VALUES
    (1, 'Demo Guest A', 2, DATE '2025-04-07', DATE '2025-04-09', 'Approved', 1, 2, 102),
    (2, 'Demo Guest B', NULL, NULL, NULL, 'Pending', NULL, NULL, NULL);
INSERT INTO suggestions (suggestion_id, description, visitor_id) VALUES
    (1, 'Add a wing map near reception.', 1);

INSERT INTO payment (transaction_id, method, date, payer_type) VALUES
    (1001, 'Online', DATE '2025-04-01', 'student'),
    (1002, 'Card', DATE '2025-04-02', 'student'),
    (1003, 'Online', DATE '2025-04-07', 'visitor'),
    (1004, 'Online', DATE '2025-05-01', 'student');
INSERT INTO student_payment (transaction_id, student_id, amount) VALUES
    (1001, 101, 2500), (1002, 103, 1800), (1004, 101, 2500);
INSERT INTO visitor_payment (transaction_id, visitor_id, amount) VALUES (1003, 1, 450);

INSERT INTO complaint (comp_id, type, status, description, reporting_date, assigned_by, student_id, solved_by, resolved_on) VALUES
    (1, 'Plumbing', 'Open', 'Tap leaks in the north washroom.', DATE '2025-02-21', 1, 101, NULL, NULL),
    (2, 'Electrical', 'Resolved', 'Light flickers in the south corridor.', DATE '2025-02-24', 2, 103, 6, DATE '2025-02-26'),
    (3, 'Carpentry', 'In Progress', 'Desk drawer needs repair.', DATE '2025-04-08', 1, 102, NULL, NULL);

INSERT INTO parcel (parcel_id, arrival_date, timestamp, status, received_date, student_id, handover_by) VALUES
    (1, DATE '2025-04-08', TIMESTAMP '2025-04-08 14:30:00', 'Pending', NULL, 103, NULL),
    (2, DATE '2025-04-07', TIMESTAMP '2025-04-07 09:00:00', 'Received', DATE '2025-04-08', 101, 1);
INSERT INTO overnight_leave (leave_id, request_date, from_date, to_date, status, student_id, approved_by) VALUES
    (1, DATE '2025-04-01', DATE '2025-04-11', DATE '2025-04-13', 'Approved', 101, 1),
    (2, DATE '2025-04-06', DATE '2025-04-12', DATE '2025-04-13', 'Pending', 103, NULL);
INSERT INTO attendance (student_id, date, status) VALUES
    (101, DATE '2025-04-07', 'Present'), (101, DATE '2025-04-08', 'Present'),
    (101, DATE '2025-04-09', 'Absent'), (102, DATE '2025-04-07', 'Present'),
    (103, DATE '2025-04-09', 'Absent');
