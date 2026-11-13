-- ======================================================
-- 08_member3_booking_queries.sql
-- Member 3 - Passengers, Booking & Revenue  (25 Queries)
-- Tables: Passengers, Bookings, Payments (+ Flights, Airlines, Aircraft, AircraftModels)
-- ======================================================
USE aviation_db;
SET @today = '2026-11-11';

-- ---------- A. Passengers (Q1-Q4) ----------

-- Q1: Indian passengers, alphabetically.
SELECT passenger_id, full_name, email, phone, passport_no
FROM Passengers
WHERE nationality = 'India'
ORDER BY full_name;

-- Q2: Passenger count by nationality.
SELECT nationality, COUNT(*) AS total_passengers
FROM Passengers
GROUP BY nationality
ORDER BY total_passengers DESC, nationality;

-- Q3: Passengers with their age (as on 11-Nov-2026), oldest first - top 10.
SELECT full_name, dob, TIMESTAMPDIFF(YEAR, dob, @today) AS age
FROM Passengers
ORDER BY dob ASC
LIMIT 10;

-- Q4: Minor passengers (under 18) - need guardian handling.
SELECT passenger_id, full_name, dob, TIMESTAMPDIFF(YEAR, dob, @today) AS age
FROM Passengers
WHERE TIMESTAMPDIFF(YEAR, dob, @today) < 18
ORDER BY age;

-- ---------- B. Bookings (Q5-Q12) ----------

-- Q5: Booking details with passenger, flight and route (4-table JOIN).
SELECT B.booking_id, P.full_name, F.flight_no,
       OA.iata_code AS origin, DA.iata_code AS destination,
       B.seat_no, B.travel_class, B.fare, B.status
FROM Bookings B
JOIN Passengers P ON B.passenger_id = P.passenger_id
JOIN Flights F    ON B.flight_id = F.flight_id
JOIN Airports OA  ON F.origin_airport_id = OA.airport_id
JOIN Airports DA  ON F.dest_airport_id   = DA.airport_id
ORDER BY B.booking_id
LIMIT 20;

-- Q6: Booking count by status.
SELECT status, COUNT(*) AS total_bookings
FROM Bookings
GROUP BY status;

-- Q7: Bookings by travel class with average fare.
SELECT travel_class, COUNT(*) AS total_bookings, ROUND(AVG(fare), 2) AS avg_fare
FROM Bookings
GROUP BY travel_class
ORDER BY avg_fare DESC;

-- Q8: Number of live (non-cancelled) bookings per flight - top 10.
SELECT F.flight_no, COUNT(B.booking_id) AS live_bookings
FROM Flights F
JOIN Bookings B ON B.flight_id = F.flight_id
WHERE B.status <> 'Cancelled'
GROUP BY F.flight_id, F.flight_no
ORDER BY live_bookings DESC, F.flight_no
LIMIT 10;

-- Q9: Top 5 frequent flyers by number of confirmed / checked-in bookings.
SELECT P.full_name, P.nationality, COUNT(B.booking_id) AS trips
FROM Passengers P
JOIN Bookings B ON P.passenger_id = B.passenger_id
WHERE B.status <> 'Cancelled'
GROUP BY P.passenger_id, P.full_name, P.nationality
ORDER BY trips DESC, P.full_name
LIMIT 5;

-- Q10: Passengers who have never made a booking.
SELECT P.passenger_id, P.full_name, P.email
FROM Passengers P
LEFT JOIN Bookings B ON P.passenger_id = B.passenger_id
WHERE B.booking_id IS NULL;

-- Q11: Passengers who flew in Business or First class.
SELECT DISTINCT P.full_name, B.travel_class
FROM Passengers P
JOIN Bookings B ON P.passenger_id = B.passenger_id
WHERE B.travel_class IN ('Business','First') AND B.status <> 'Cancelled'
ORDER BY B.travel_class, P.full_name;

-- Q12: Last-minute bookings (made within 7 days of departure).
SELECT B.booking_id, P.full_name, F.flight_no,
       TIMESTAMPDIFF(DAY, B.booked_at, F.departure_time) AS days_before_departure
FROM Bookings B
JOIN Passengers P ON B.passenger_id = P.passenger_id
JOIN Flights F    ON B.flight_id = F.flight_id
WHERE TIMESTAMPDIFF(DAY, B.booked_at, F.departure_time) <= 7
ORDER BY days_before_departure, B.booking_id
LIMIT 15;

-- ---------- C. Payments & revenue (Q13-Q20) ----------

-- Q13: Payment status summary - count and total amount.
SELECT status, COUNT(*) AS total_payments, SUM(amount) AS total_amount
FROM Payments
GROUP BY status
ORDER BY total_amount DESC;

-- Q14: Payment method usage with percentage share.
SELECT method,
       COUNT(*) AS total_payments,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM Payments), 2) AS share_pct
FROM Payments
GROUP BY method
ORDER BY total_payments DESC;

-- Q15: Revenue per airline (Paid payments only).
SELECT AL.airline_name, SUM(P.amount) AS total_revenue, COUNT(P.payment_id) AS paid_tickets
FROM Payments P
JOIN Bookings B  ON P.booking_id = B.booking_id
JOIN Flights F   ON B.flight_id = F.flight_id
JOIN Airlines AL ON F.airline_id = AL.airline_id
WHERE P.status = 'Paid'
GROUP BY AL.airline_id, AL.airline_name
ORDER BY total_revenue DESC;

-- Q16: Top 5 flights by revenue (uses view v_flight_revenue from file 05).
SELECT flight_no, paid_bookings, revenue
FROM v_flight_revenue
ORDER BY revenue DESC, flight_no
LIMIT 5;

-- Q17: Revenue by travel class (Paid only).
SELECT B.travel_class, SUM(P.amount) AS revenue
FROM Bookings B
JOIN Payments P ON B.booking_id = P.booking_id
WHERE P.status = 'Paid'
GROUP BY B.travel_class
ORDER BY revenue DESC;

-- Q18: Pending payments with passenger contact details (follow-up list).
SELECT P.full_name, P.phone, P.email, F.flight_no, PAY.amount
FROM Payments PAY
JOIN Bookings B   ON PAY.booking_id = B.booking_id
JOIN Passengers P ON B.passenger_id = P.passenger_id
JOIN Flights F    ON B.flight_id = F.flight_id
WHERE PAY.status = 'Pending'
ORDER BY PAY.amount DESC;

-- Q19: Cancelled bookings and what happened to the money.
SELECT B.booking_id, P.full_name, F.flight_no, F.status AS flight_status,
       PAY.amount, PAY.status AS payment_status
FROM Bookings B
JOIN Passengers P ON B.passenger_id = P.passenger_id
JOIN Flights F    ON B.flight_id = F.flight_id
JOIN Payments PAY ON PAY.booking_id = B.booking_id
WHERE B.status = 'Cancelled'
ORDER BY PAY.status, B.booking_id
LIMIT 20;

-- Q20: Total refunded amount per airline.
SELECT AL.airline_name, COUNT(PAY.payment_id) AS refunds, SUM(PAY.amount) AS refunded_amount
FROM Payments PAY
JOIN Bookings B  ON PAY.booking_id = B.booking_id
JOIN Flights F   ON B.flight_id = F.flight_id
JOIN Airlines AL ON F.airline_id = AL.airline_id
WHERE PAY.status = 'Refunded'
GROUP BY AL.airline_id, AL.airline_name
ORDER BY refunded_amount DESC;

-- ---------- D. Advanced analytics (Q21-Q25) ----------

-- Q21: Seat occupancy % of the 10 fullest flights (live bookings / aircraft capacity).
SELECT F.flight_no, AM.seat_capacity,
       COUNT(B.booking_id) AS booked_seats,
       ROUND(100 * COUNT(B.booking_id) / AM.seat_capacity, 2) AS occupancy_pct
FROM Flights F
JOIN Aircraft AC       ON F.aircraft_id = AC.aircraft_id
JOIN AircraftModels AM ON AC.model_id = AM.model_id
JOIN Bookings B        ON B.flight_id = F.flight_id AND B.status <> 'Cancelled'
GROUP BY F.flight_id, F.flight_no, AM.seat_capacity
ORDER BY occupancy_pct DESC, F.flight_no
LIMIT 10;

-- Q22: Passengers who travelled with more than one airline.
SELECT P.full_name, COUNT(DISTINCT F.airline_id) AS airlines_used
FROM Passengers P
JOIN Bookings B ON P.passenger_id = B.passenger_id
JOIN Flights F  ON B.flight_id = F.flight_id
WHERE B.status <> 'Cancelled'
GROUP BY P.passenger_id, P.full_name
HAVING COUNT(DISTINCT F.airline_id) > 1
ORDER BY airlines_used DESC, P.full_name;

-- Q23: Rank passengers by spend within their nationality (window function).
SELECT nationality, full_name, total_spent,
       RANK() OVER (PARTITION BY nationality ORDER BY total_spent DESC) AS spend_rank
FROM (
    SELECT P.passenger_id, P.nationality, P.full_name, SUM(PAY.amount) AS total_spent
    FROM Passengers P
    JOIN Bookings B   ON P.passenger_id = B.passenger_id
    JOIN Payments PAY ON PAY.booking_id = B.booking_id AND PAY.status = 'Paid'
    GROUP BY P.passenger_id, P.nationality, P.full_name
) S
ORDER BY nationality, spend_rank, full_name;

-- Q24: Running total of daily revenue (Paid payments).
SELECT pay_date, daily_revenue,
       SUM(daily_revenue) OVER (ORDER BY pay_date) AS running_total
FROM (
    SELECT DATE(paid_at) AS pay_date, SUM(amount) AS daily_revenue
    FROM Payments
    WHERE status = 'Paid'
    GROUP BY DATE(paid_at)
) D
ORDER BY pay_date
LIMIT 20;

-- Q25: CTE - high-value customers whose total spend exceeds the average customer spend.
WITH spend AS (
    SELECT P.passenger_id, P.full_name, SUM(PAY.amount) AS total_spent
    FROM Passengers P
    JOIN Bookings B   ON P.passenger_id = B.passenger_id
    JOIN Payments PAY ON PAY.booking_id = B.booking_id AND PAY.status = 'Paid'
    GROUP BY P.passenger_id, P.full_name
)
SELECT full_name, total_spent
FROM spend
WHERE total_spent > (SELECT AVG(total_spent) FROM spend)
ORDER BY total_spent DESC;
