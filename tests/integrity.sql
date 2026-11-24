\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path TO hmc, pg_catalog;
DO $$
BEGIN
    IF (SELECT count(*) FROM room_occupancy) <> 5 OR
       (SELECT occupied_beds FROM room_occupancy WHERE wing_id = 1 AND room_no = 101) IS DISTINCT FROM 2 OR
       (SELECT occupied_beds FROM room_occupancy WHERE wing_id = 2 AND room_no = 101) IS DISTINCT FROM 1 THEN
        RAISE EXCEPTION 'Same-numbered rooms or inactive students were counted incorrectly';
    END IF;
    IF (SELECT count(*) FROM room_occupancy WHERE availability AND vacant_beds > 0) <> 3 THEN
        RAISE EXCEPTION 'Full or administratively closed rooms appeared in available inventory';
    END IF;
    IF (SELECT sum(amount) FROM student_payment) IS DISTINCT FROM 6800 OR
       (SELECT sum(amount) FROM visitor_payment) IS DISTINCT FROM 450 THEN
        RAISE EXCEPTION 'Unexpected demo payment totals';
    END IF;
    IF (SELECT avg(resolved_on - reporting_date) FROM complaint) IS DISTINCT FROM 2 THEN
        RAISE EXCEPTION 'Unexpected mean resolution time';
    END IF;
    BEGIN
        UPDATE student SET resident_wing = NULL WHERE student_id = 101;
        RAISE EXCEPTION 'Half a room key was accepted';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO visitor_payment (transaction_id, visitor_id, amount) VALUES (1001, 1, 1);
        RAISE EXCEPTION 'A student transaction also accepted a visitor payment';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        UPDATE visitor_payment SET transaction_id = 1001 WHERE transaction_id = 1003;
        RAISE EXCEPTION 'A payment update crossed payer types';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO attendance VALUES (101, DATE '2025-04-07', 'Absent');
        RAISE EXCEPTION 'Duplicate attendance was accepted';
    EXCEPTION WHEN unique_violation THEN NULL;
    END;
    BEGIN
        UPDATE complaint SET resolved_on = reporting_date - 1 WHERE comp_id = 2;
        RAISE EXCEPTION 'Resolution predates the complaint';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
END;
$$;
ROLLBACK;
