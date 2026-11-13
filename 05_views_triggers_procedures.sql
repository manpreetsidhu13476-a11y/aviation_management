-- ======================================================
-- 05_views_triggers_procedures.sql
-- Aviation Management System | Shared (all members)
-- Run AFTER the three data files so triggers do not fire on bulk loads.
-- ======================================================
USE aviation_db;

-- ------------------------------------------------------
-- VIEWS
-- ------------------------------------------------------
DROP VIEW IF EXISTS v_flight_details;
DROP VIEW IF EXISTS v_flight_revenue;
DROP VIEW IF EXISTS v_fleet_status;

-- View 1 (Member 2): complete flight information
CREATE VIEW v_flight_details AS
SELECT
    F.flight_id,
    F.flight_no,
    AL.airline_name,
    AC.registration_no,
    AM.model_name,
    OA.iata_code AS origin,
    DA.iata_code AS destination,
    F.departure_time,
    F.arrival_time,
    TIMESTAMPDIFF(MINUTE, F.departure_time, F.arrival_time) AS duration_min,
    F.delay_minutes,
    F.status
FROM Flights F
JOIN Airlines AL       ON F.airline_id = AL.airline_id
JOIN Aircraft AC       ON F.aircraft_id = AC.aircraft_id
JOIN AircraftModels AM ON AC.model_id = AM.model_id
JOIN Airports OA       ON F.origin_airport_id = OA.airport_id
JOIN Airports DA       ON F.dest_airport_id = DA.airport_id;

-- View 2 (Member 3): revenue per flight (only 'Paid' payments)
CREATE VIEW v_flight_revenue AS
SELECT
    F.flight_id,
    F.flight_no,
    COUNT(DISTINCT B.booking_id) AS paid_bookings,
    COALESCE(SUM(P.amount), 0)   AS revenue
FROM Flights F
LEFT JOIN Bookings B ON B.flight_id = F.flight_id
LEFT JOIN Payments P ON P.booking_id = B.booking_id AND P.status = 'Paid'
GROUP BY F.flight_id, F.flight_no;

-- View 3 (Member 1): fleet summary per airline
CREATE VIEW v_fleet_status AS
SELECT
    AL.airline_id,
    AL.airline_name,
    COUNT(AC.aircraft_id)                                   AS total_aircraft,
    SUM(CASE WHEN AC.status = 'Active'      THEN 1 ELSE 0 END) AS active_aircraft,
    SUM(CASE WHEN AC.status = 'Maintenance' THEN 1 ELSE 0 END) AS in_maintenance,
    SUM(CASE WHEN AC.status = 'Retired'     THEN 1 ELSE 0 END) AS retired
FROM Airlines AL
LEFT JOIN Aircraft AC ON AC.airline_id = AL.airline_id
GROUP BY AL.airline_id, AL.airline_name;

-- ------------------------------------------------------
-- TRIGGERS
-- ------------------------------------------------------
DROP TRIGGER IF EXISTS trg_booking_before_insert;
DROP TRIGGER IF EXISTS trg_flight_after_update;
DROP TRIGGER IF EXISTS trg_maintenance_after_insert;

DELIMITER //

-- Trigger 1 (Member 3): block bookings on flights that are cancelled or already landed
CREATE TRIGGER trg_booking_before_insert
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM Flights WHERE flight_id = NEW.flight_id;
    IF v_status IN ('Cancelled', 'Landed') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Booking not allowed: flight is cancelled or already landed';
    END IF;
END //

-- Trigger 2 (Member 2): when a flight is cancelled, cancel its bookings and refund paid payments
CREATE TRIGGER trg_flight_after_update
AFTER UPDATE ON Flights
FOR EACH ROW
BEGIN
    IF NEW.status = 'Cancelled' AND OLD.status <> 'Cancelled' THEN
        UPDATE Payments
        SET status = 'Refunded'
        WHERE status = 'Paid'
          AND booking_id IN (SELECT booking_id FROM Bookings WHERE flight_id = NEW.flight_id);

        UPDATE Bookings
        SET status = 'Cancelled', seat_no = NULL
        WHERE flight_id = NEW.flight_id;
    END IF;
END //

-- Trigger 3 (Member 1): an aircraft goes to 'Maintenance' when work starts on it
CREATE TRIGGER trg_maintenance_after_insert
AFTER INSERT ON Maintenance
FOR EACH ROW
BEGIN
    IF NEW.status = 'In Progress' THEN
        UPDATE Aircraft SET status = 'Maintenance' WHERE aircraft_id = NEW.aircraft_id;
    END IF;
END //

DELIMITER ;

-- ------------------------------------------------------
-- STORED PROCEDURES
-- ------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_book_ticket;
DROP PROCEDURE IF EXISTS sp_flight_manifest;

DELIMITER //

-- Procedure 1 (Member 3): book a seat and create a pending payment
CREATE PROCEDURE sp_book_ticket(
    IN  p_passenger_id INT,
    IN  p_flight_id    INT,
    IN  p_seat_no      VARCHAR(4),
    IN  p_class        VARCHAR(10),
    OUT p_booking_id   INT
)
BEGIN
    DECLARE v_base DECIMAL(10,2) DEFAULT NULL;
    DECLARE v_fare DECIMAL(10,2);
    DECLARE v_mult DECIMAL(3,2);

    SELECT base_fare INTO v_base FROM Flights WHERE flight_id = p_flight_id;
    IF v_base IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Flight not found';
    END IF;

    SET v_mult = CASE p_class WHEN 'Business' THEN 2.50 WHEN 'First' THEN 4.00 ELSE 1.00 END;
    SET v_fare = ROUND(v_base * v_mult, 2);

    INSERT INTO Bookings (passenger_id, flight_id, seat_no, travel_class, fare, status)
    VALUES (p_passenger_id, p_flight_id, p_seat_no, p_class, v_fare, 'Confirmed');

    SET p_booking_id = LAST_INSERT_ID();

    INSERT INTO Payments (booking_id, amount, method, status)
    VALUES (p_booking_id, v_fare, 'UPI', 'Pending');
END //

-- Procedure 2 (Member 2): passenger manifest of a flight
CREATE PROCEDURE sp_flight_manifest(IN p_flight_id INT)
BEGIN
    SELECT
        B.seat_no,
        P.full_name,
        P.passport_no,
        B.travel_class,
        B.status
    FROM Bookings B
    JOIN Passengers P ON B.passenger_id = P.passenger_id
    WHERE B.flight_id = p_flight_id
      AND B.status <> 'Cancelled'
    ORDER BY B.seat_no;
END //

DELIMITER ;

-- Demo calls
-- SELECT * FROM v_flight_details LIMIT 5;
-- CALL sp_flight_manifest(30);
-- CALL sp_book_ticket(10, 55, '12C', 'Economy', @new_booking);  SELECT @new_booking;
