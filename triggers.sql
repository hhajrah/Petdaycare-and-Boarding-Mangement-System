-- ============================================================
--  Pet Daycare & Boarding Management System
--  Database Triggers
--
--  Run these in phpMyAdmin:
--  1. Open phpMyAdmin → select petdaycare database
--  2. Click the SQL tab at the top
--  3. Paste each trigger one at a time and click Go
-- ============================================================

-- ============================================================
-- TRIGGER 1 — Auto-occupy kennel when pet is checked in
--
-- AFTER UPDATE ON bookings:
--   Fires automatically after any UPDATE to the bookings table
-- NEW.status = 'checked_in':
--   NEW refers to the updated row values after the UPDATE
--   Checks if the new status is 'checked_in'
-- OLD.status != 'checked_in':
--   OLD refers to the row values before the UPDATE
--   Ensures we only fire when status actually CHANGED to checked_in
--   (prevents running again if same status is set twice)
-- ============================================================

DROP TRIGGER IF EXISTS after_booking_checkin;

DELIMITER $$

CREATE TRIGGER after_booking_checkin
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    -- Only fire when status changes TO 'checked_in'
    IF NEW.status = 'checked_in' AND OLD.status != 'checked_in' THEN
        UPDATE kennels
        SET status = 'occupied'
        WHERE kennel_id = NEW.kennel_id;
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- TRIGGER 2 — Auto-free kennel when pet is checked out
--
-- AFTER UPDATE ON bookings:
--   Fires after every UPDATE on the bookings table
-- NEW.status = 'checked_out':
--   Checks if the booking was just marked as checked_out
-- OLD.status != 'checked_out':
--   Makes sure we only react when status actually changed
-- Sets kennel back to 'available' automatically
-- ============================================================

DROP TRIGGER IF EXISTS after_booking_checkout;

DELIMITER $$

CREATE TRIGGER after_booking_checkout
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    -- Only fire when status changes TO 'checked_out'
    IF NEW.status = 'checked_out' AND OLD.status != 'checked_out' THEN
        UPDATE kennels
        SET status = 'available'
        WHERE kennel_id = NEW.kennel_id;
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- VERIFY TRIGGERS WERE CREATED
-- Run this to confirm both triggers exist in your database
-- ============================================================

SHOW TRIGGERS FROM petdaycare;
