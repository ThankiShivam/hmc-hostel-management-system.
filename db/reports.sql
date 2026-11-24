-- Reporting queries adapted to the executable schema. Numbers are stable within this file.
BEGIN READ ONLY;
SET LOCAL search_path TO hmc, pg_catalog;

-- 01. Active residents with assigned rooms
SELECT s.student_id, s.name, s.branch, s.year, r.room_no, w.wing_name
FROM student s
JOIN rooms r ON (s.resident_wing, s.resident_room) = (r.wing_id, r.room_no)
JOIN wing w ON w.wing_id = r.wing_id
WHERE s.status = 'Active'
ORDER BY w.wing_name, r.room_no, s.student_id;

-- 02. Rooms open for allocation and their vacant beds
SELECT wing_name, room_no, capacity, occupied_beds, vacant_beds
FROM room_occupancy
WHERE availability AND vacant_beds > 0
ORDER BY vacant_beds DESC, wing_id, room_no;

-- 03. Active students with a recorded support request
SELECT s.student_id, s.name, s.health_details, s.resident_room, w.wing_name
FROM student s LEFT JOIN wing w ON w.wing_id = s.resident_wing
WHERE s.status = 'Active' AND NULLIF(trim(s.health_details), '') IS NOT NULL
ORDER BY s.student_id;

-- 04. Active students by branch and year
SELECT branch, year, count(*) AS students
FROM student WHERE status = 'Active'
GROUP BY branch, year ORDER BY branch, year;

-- 05. Active hostel committee members
SELECT s.student_id, s.name, s.branch, s.year, w.wing_name
FROM student s LEFT JOIN wing w ON w.wing_id = s.resident_wing
WHERE s.hmc_flag AND s.status = 'Active' ORDER BY w.wing_name, s.student_id;

-- 06. Room and bed capacity per wing, including empty wings
SELECT w.wing_name, w.type, w.floors, count(r.room_no) AS rooms,
       coalesce(sum(r.capacity), 0) AS beds
FROM wing w LEFT JOIN rooms r USING (wing_id)
GROUP BY w.wing_id ORDER BY w.wing_name;

-- 07. Staff and their manager
SELECT s.staff_id, s.name, s.role, s.salary, a.name AS manager
FROM staff s LEFT JOIN admin a ON a.admin_id = s.managed_by
ORDER BY s.role, s.staff_id;

-- 08. Wardens and their assigned wings
SELECT s.staff_id, s.name, w.wing_name, w.type
FROM warden wd JOIN staff s USING (staff_id)
LEFT JOIN wing w ON w.wing_id = wd.assigned_wing ORDER BY s.staff_id;

-- 09. Cleaning staff, shifts and work areas
SELECT s.staff_id, s.name, cs.working_area, s.working_hours, s.working_days
FROM cleaning_staff cs JOIN staff s USING (staff_id) ORDER BY s.staff_id;

-- 10. Payroll by staff role
SELECT role, count(*) AS staff_count, sum(salary) AS total_salary,
       round(avg(salary), 2) AS average_salary
FROM staff GROUP BY role ORDER BY total_salary DESC NULLS LAST, role;

-- 11. Staff who have neither assigned nor resolved a complaint
SELECT s.staff_id, s.name, s.role FROM staff s
WHERE NOT EXISTS (SELECT 1 FROM complaint c
                  WHERE c.assigned_by = s.staff_id OR c.solved_by = s.staff_id)
ORDER BY s.role, s.staff_id;

-- 12. Staff with above-average salary
SELECT staff_id, name, role, salary FROM staff
WHERE salary > (SELECT avg(salary) FROM staff)
ORDER BY salary DESC, staff_id;

-- 13. Open complaints with the reporting student and staff member who assigned the work
SELECT c.comp_id, c.type, c.description, c.reporting_date,
       s.name AS resident, st.name AS assigning_staff
FROM complaint c JOIN student s USING (student_id)
LEFT JOIN staff st ON st.staff_id = c.assigned_by
WHERE c.status = 'Open' ORDER BY c.reporting_date, c.comp_id;

-- 14. Average resolution time and age of outstanding complaints, in days
SELECT type, count(resolved_on) AS resolved,
       round(avg(resolved_on - reporting_date) FILTER (WHERE resolved_on IS NOT NULL), 1) AS avg_resolution_days,
       round(avg(CURRENT_DATE - reporting_date) FILTER (WHERE resolved_on IS NULL), 1) AS avg_pending_days
FROM complaint GROUP BY type ORDER BY type;

-- 15. Resolved complaints per maintenance staff member, including zero
SELECT st.staff_id, st.name, st.role, count(c.comp_id) AS resolved
FROM staff st LEFT JOIN complaint c ON c.solved_by = st.staff_id AND c.resolved_on IS NOT NULL
WHERE st.role IN ('Plumber', 'Carpenter', 'Electrician')
GROUP BY st.staff_id ORDER BY resolved DESC, st.staff_id;

-- 16. Complaints reported in February 2025
SELECT c.comp_id, c.type, c.status, c.description, s.name AS resident
FROM complaint c JOIN student s USING (student_id)
WHERE c.reporting_date >= DATE '2025-02-01' AND c.reporting_date < DATE '2025-03-01'
ORDER BY c.reporting_date, c.comp_id;

-- 17. Approved visitors, allocated rooms and approving administrators
SELECT v.visitor_id, v.name, w.wing_name, r.room_no, v.check_in, v.check_out, a.name AS approver
FROM visitor v
LEFT JOIN rooms r ON (v.allocated_wing, v.allocated_room) = (r.wing_id, r.room_no)
LEFT JOIN wing w ON w.wing_id = r.wing_id
LEFT JOIN admin a ON a.admin_id = v.approved_by
WHERE v.request_status = 'Approved' ORDER BY v.check_in, v.visitor_id;

-- 18. Approved visitors currently staying; the checkout date is exclusive
SELECT visitor_id, name, allocated_wing, allocated_room, check_in, check_out
FROM visitor WHERE request_status = 'Approved' AND check_in <= CURRENT_DATE
AND (check_out IS NULL OR check_out > CURRENT_DATE)
ORDER BY visitor_id;

-- 19. Visitor suggestions
SELECT sg.suggestion_id, v.name AS visitor, sg.description
FROM suggestions sg JOIN visitor v USING (visitor_id) ORDER BY sg.suggestion_id;

-- 20. Visitor requests handled and approved per administrator
SELECT a.admin_id, a.name, count(v.visitor_id) AS handled_requests,
       count(v.visitor_id) FILTER (WHERE v.request_status = 'Approved') AS approved_requests
FROM admin a LEFT JOIN visitor v ON v.approved_by = a.admin_id
GROUP BY a.admin_id ORDER BY handled_requests DESC, a.admin_id;

-- 21. Visitors and payment details, including visitors with no payment yet
SELECT v.visitor_id, v.name, vp.transaction_id, p.method, vp.amount, p.date
FROM visitor v LEFT JOIN visitor_payment vp USING (visitor_id)
LEFT JOIN payment p ON p.transaction_id = vp.transaction_id
ORDER BY v.visitor_id, p.date, p.transaction_id;

-- 22. Monthly fee collections from students
SELECT date_trunc('month', p.date)::date AS month, count(*) AS payments, sum(sp.amount) AS collected
FROM student_payment sp JOIN payment p USING (transaction_id)
GROUP BY 1 ORDER BY 1;

-- 23. Students with no recorded payment
SELECT s.student_id, s.name, s.branch, s.year
FROM student s WHERE NOT EXISTS (SELECT 1 FROM student_payment sp WHERE sp.student_id = s.student_id)
ORDER BY s.name, s.student_id;

-- 24. Parcels awaiting collection and the resident's assigned room
SELECT p.parcel_id, p.arrival_date, s.name AS resident, w.wing_name, s.resident_room
FROM parcel p JOIN student s USING (student_id)
LEFT JOIN wing w ON w.wing_id = s.resident_wing
WHERE p.status = 'Pending' ORDER BY p.arrival_date, p.parcel_id;

-- 25. Approved overnight leave requests with the approving staff member
SELECT ol.leave_id, s.name AS resident, ol.from_date, ol.to_date, ol.return_timestamp, st.name AS approver
FROM overnight_leave ol JOIN student s USING (student_id)
LEFT JOIN staff st ON st.staff_id = ol.approved_by
WHERE ol.status = 'Approved' ORDER BY ol.from_date, ol.leave_id;

-- 26. Pending leave requests
SELECT ol.leave_id, s.name AS resident, ol.request_date, ol.from_date, ol.to_date, w.wing_name
FROM overnight_leave ol JOIN student s USING (student_id)
LEFT JOIN wing w ON w.wing_id = s.resident_wing
WHERE ol.status = 'Pending' ORDER BY ol.request_date, ol.leave_id;

-- 27. Students marked absent on 9 April 2025
SELECT s.student_id, s.name, s.resident_room, w.wing_name
FROM attendance a JOIN student s USING (student_id)
LEFT JOIN wing w ON w.wing_id = s.resident_wing
WHERE a.date = DATE '2025-04-09' AND a.status = 'Absent' ORDER BY w.wing_name, s.student_id;

-- 28. Collections by payer type
SELECT 'student' AS payer_type, coalesce(sum(amount), 0) AS collected FROM student_payment
UNION ALL SELECT 'visitor', coalesce(sum(amount), 0) FROM visitor_payment ORDER BY payer_type;

-- 29. Attendance percentage per student for 7–11 April 2025; NULL means no observations
SELECT s.student_id, s.name, count(a.date) AS tracked_days,
       count(a.date) FILTER (WHERE a.status = 'Present') AS days_present,
       round(100.0 * count(a.date) FILTER (WHERE a.status = 'Present') / nullif(count(a.date), 0), 2) AS attendance_pct
FROM student s LEFT JOIN attendance a ON a.student_id = s.student_id
    AND a.date BETWEEN DATE '2025-04-07' AND DATE '2025-04-11'
GROUP BY s.student_id ORDER BY attendance_pct NULLS LAST, s.student_id;

COMMIT;
