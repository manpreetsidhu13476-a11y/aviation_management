-- ======================================================
-- 07_member2_operations_queries.sql
-- Member 2 - Flight Operations  (25 Queries)
-- Tables: Flights, Crew, FlightCrew, Maintenance (+ Airlines, Airports, Aircraft)
-- ======================================================
USE aviation_db;
SET @today = '2026-11-11';

-- ---------- A. Flight schedule (Q1-Q8) ----------

-- Q1: Upcoming flights with origin and destination airport codes.
SELECT F.flight_no, AL.airline_name, OA.iata_code AS origin, DA.iata_code AS destination,
       F.departure_time, F.status
FROM Flights F
JOIN Airlines AL ON F.airline_id = AL.airline_id
JOIN Airports OA ON F.origin_airport_id = OA.airport_id
JOIN Airports DA ON F.dest_airport_id   = DA.airport_id
WHERE F.status IN ('Scheduled','Delayed')
ORDER BY F.departure_time;

-- Q2: All flights departing on 15 November 2026.
SELECT flight_no, departure_time, arrival_time, status
FROM Flights
WHERE DATE(departure_time) = '2026-11-15'
ORDER BY departure_time;

-- Q3: Flights with a delay, longest delay first.
SELECT flight_no, status, delay_minutes, departure_time
FROM Flights
WHERE delay_minutes > 0
ORDER BY delay_minutes DESC;

-- Q4: Flight count by status.
SELECT status, COUNT(*) AS total_flights
FROM Flights
GROUP BY status
ORDER BY total_flights DESC;

-- Q5: Cancelled flights with airline name and route.
SELECT F.flight_no, AL.airline_name, OA.iata_code AS origin, DA.iata_code AS destination, F.departure_time
FROM Flights F
JOIN Airlines AL ON F.airline_id = AL.airline_id
JOIN Airports OA ON F.origin_airport_id = OA.airport_id
JOIN Airports DA ON F.dest_airport_id   = DA.airport_id
WHERE F.status = 'Cancelled'
ORDER BY F.departure_time;

-- Q6: All flights departing from Delhi (DEL), with destination and fare.
SELECT F.flight_no, AL.airline_name, DA.iata_code AS destination, F.departure_time, F.base_fare
FROM Flights F
JOIN Airlines AL ON F.airline_id = AL.airline_id
JOIN Airports OA ON F.origin_airport_id = OA.airport_id
JOIN Airports DA ON F.dest_airport_id   = DA.airport_id
WHERE OA.iata_code = 'DEL'
ORDER BY F.departure_time;

-- Q7: The 5 longest scheduled flights (duration in hours).
SELECT flight_no, ROUND(TIMESTAMPDIFF(MINUTE, departure_time, arrival_time) / 60, 2) AS duration_hours
FROM Flights
ORDER BY duration_hours DESC, flight_no
LIMIT 5;

-- Q8: Flights per month.
SELECT DATE_FORMAT(departure_time, '%Y-%m') AS flight_month, COUNT(*) AS total_flights
FROM Flights
GROUP BY DATE_FORMAT(departure_time, '%Y-%m')
ORDER BY flight_month;

-- ---------- B. Delay & performance analysis (Q9-Q12) ----------

-- Q9: Average delay (minutes) per airline.
SELECT AL.airline_name, ROUND(AVG(F.delay_minutes), 2) AS avg_delay_min
FROM Flights F
JOIN Airlines AL ON F.airline_id = AL.airline_id
GROUP BY AL.airline_id, AL.airline_name
ORDER BY avg_delay_min DESC;

-- Q10: On-time performance (%) per airline - flights with zero delay, excluding cancelled.
SELECT AL.airline_name,
       COUNT(*) AS operated_flights,
       ROUND(100 * SUM(CASE WHEN F.delay_minutes = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS on_time_pct
FROM Flights F
JOIN Airlines AL ON F.airline_id = AL.airline_id
WHERE F.status <> 'Cancelled'
GROUP BY AL.airline_id, AL.airline_name
ORDER BY on_time_pct DESC;

-- Q11: Flights whose duration is above the average flight duration.
SELECT flight_no, TIMESTAMPDIFF(MINUTE, departure_time, arrival_time) AS duration_min
FROM Flights
WHERE TIMESTAMPDIFF(MINUTE, departure_time, arrival_time) >
      (SELECT AVG(TIMESTAMPDIFF(MINUTE, departure_time, arrival_time)) FROM Flights)
ORDER BY duration_min DESC;

-- Q12: Busiest departure date (flights per day, top 5).
SELECT DATE(departure_time) AS flight_date, COUNT(*) AS total_flights
FROM Flights
GROUP BY DATE(departure_time)
ORDER BY total_flights DESC, flight_date
LIMIT 5;

-- ---------- C. Crew management (Q13-Q19) ----------

-- Q13: Crew assigned to flight 1.
SELECT F.flight_no, C.full_name, C.role, C.experience_years
FROM FlightCrew FC
JOIN Flights F ON FC.flight_id = F.flight_id
JOIN Crew C    ON FC.crew_id = C.crew_id
WHERE F.flight_id = 1
ORDER BY FIELD(C.role, 'Pilot', 'Co-Pilot', 'Cabin Crew');

-- Q14: Crew count by role for each airline.
SELECT AL.airline_name,
       SUM(CASE WHEN C.role = 'Pilot'      THEN 1 ELSE 0 END) AS pilots,
       SUM(CASE WHEN C.role = 'Co-Pilot'   THEN 1 ELSE 0 END) AS co_pilots,
       SUM(CASE WHEN C.role = 'Cabin Crew' THEN 1 ELSE 0 END) AS cabin_crew
FROM Airlines AL
LEFT JOIN Crew C ON AL.airline_id = C.airline_id
GROUP BY AL.airline_id, AL.airline_name
ORDER BY AL.airline_name;

-- Q15: Pilots with more than 15 years of experience.
SELECT C.full_name, AL.airline_name, C.experience_years
FROM Crew C
JOIN Airlines AL ON C.airline_id = AL.airline_id
WHERE C.role = 'Pilot' AND C.experience_years > 15
ORDER BY C.experience_years DESC;

-- Q16: Crew members who have never been assigned to a flight.
SELECT C.crew_id, C.full_name, C.role, AL.airline_name
FROM Crew C
JOIN Airlines AL ON C.airline_id = AL.airline_id
LEFT JOIN FlightCrew FC ON C.crew_id = FC.crew_id
WHERE FC.flight_id IS NULL;

-- Q17: Top 5 crew members by number of flights.
SELECT C.full_name, C.role, COUNT(FC.flight_id) AS flights_assigned
FROM Crew C
JOIN FlightCrew FC ON C.crew_id = FC.crew_id
GROUP BY C.crew_id, C.full_name, C.role
ORDER BY flights_assigned DESC, C.full_name
LIMIT 5;

-- Q18: Flights that have no co-pilot assigned.
SELECT F.flight_no, F.departure_time, F.status
FROM Flights F
WHERE NOT EXISTS (SELECT 1
                  FROM FlightCrew FC
                  JOIN Crew C ON FC.crew_id = C.crew_id
                  WHERE FC.flight_id = F.flight_id AND C.role = 'Co-Pilot')
ORDER BY F.departure_time;

-- Q19: Total flying hours per crew member (top 10).
SELECT C.full_name, C.role,
       ROUND(SUM(TIMESTAMPDIFF(MINUTE, F.departure_time, F.arrival_time)) / 60, 1) AS flying_hours
FROM FlightCrew FC
JOIN Crew C    ON FC.crew_id = C.crew_id
JOIN Flights F ON FC.flight_id = F.flight_id
WHERE F.status <> 'Cancelled'
GROUP BY C.crew_id, C.full_name, C.role
ORDER BY flying_hours DESC, C.full_name
LIMIT 10;

-- ---------- D. Maintenance (Q20-Q25) ----------

-- Q20: Maintenance history with aircraft registration and airline.
SELECT M.maint_id, AC.registration_no, AL.airline_name, M.maint_date, M.maint_type, M.cost, M.status
FROM Maintenance M
JOIN Aircraft AC ON M.aircraft_id = AC.aircraft_id
JOIN Airlines AL ON AC.airline_id = AL.airline_id
ORDER BY M.maint_date DESC, M.maint_id;

-- Q21: Total maintenance cost per airline (completed work only).
SELECT AL.airline_name, SUM(M.cost) AS total_maintenance_cost
FROM Maintenance M
JOIN Aircraft AC ON M.aircraft_id = AC.aircraft_id
JOIN Airlines AL ON AC.airline_id = AL.airline_id
WHERE M.status = 'Completed'
GROUP BY AL.airline_id, AL.airline_name
ORDER BY total_maintenance_cost DESC;

-- Q22: Aircraft currently under maintenance.
SELECT AC.registration_no, AL.airline_name, M.maint_type, M.maint_date, M.cost
FROM Maintenance M
JOIN Aircraft AC ON M.aircraft_id = AC.aircraft_id
JOIN Airlines AL ON AC.airline_id = AL.airline_id
WHERE M.status = 'In Progress';

-- Q23: Maintenance type summary with count and average cost.
SELECT maint_type, COUNT(*) AS total_jobs, ROUND(AVG(cost), 2) AS avg_cost, MAX(cost) AS max_cost
FROM Maintenance
GROUP BY maint_type
ORDER BY avg_cost DESC;

-- Q24: Active aircraft with no completed maintenance in the last 180 days.
SELECT AC.registration_no, AL.airline_name,
       MAX(M.maint_date) AS last_maintenance,
       DATEDIFF(@today, MAX(M.maint_date)) AS days_since
FROM Aircraft AC
JOIN Airlines AL ON AC.airline_id = AL.airline_id
LEFT JOIN Maintenance M ON M.aircraft_id = AC.aircraft_id AND M.status = 'Completed'
WHERE AC.status = 'Active'
GROUP BY AC.aircraft_id, AC.registration_no, AL.airline_name
HAVING MAX(M.maint_date) IS NULL OR DATEDIFF(@today, MAX(M.maint_date)) > 180
ORDER BY days_since DESC;

-- Q25: Window function - each aircraft's flights in order, with the previous destination.
SELECT AC.registration_no, F.flight_no, F.departure_time,
       DA.iata_code AS destination,
       LAG(DA.iata_code) OVER (PARTITION BY F.aircraft_id ORDER BY F.departure_time) AS previous_destination,
       ROW_NUMBER()      OVER (PARTITION BY F.aircraft_id ORDER BY F.departure_time) AS flight_sequence
FROM Flights F
JOIN Aircraft AC ON F.aircraft_id = AC.aircraft_id
JOIN Airports DA ON F.dest_airport_id = DA.airport_id
WHERE F.status <> 'Cancelled'
ORDER BY AC.registration_no, F.departure_time;
