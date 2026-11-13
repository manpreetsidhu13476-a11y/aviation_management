-- ======================================================
-- 06_member1_fleet_queries.sql
-- Member 1 - Fleet & Master Data  (25 Queries)
-- Tables: Airlines, Airports, AircraftModels, Aircraft (+ Flights for usage)
-- ======================================================
USE aviation_db;
SET @today = '2026-11-11';

-- ---------- A. Basic retrieval (Q1-Q5) ----------

-- Q1: List all airlines, oldest first.
SELECT airline_id, airline_name, iata_code, country, founded_year
FROM Airlines
ORDER BY founded_year ASC;

-- Q2: Number of airports in each country.
SELECT country, COUNT(*) AS total_airports
FROM Airports
GROUP BY country
ORDER BY total_airports DESC, country;

-- Q3: Airports having more than 2 runways.
SELECT airport_name, iata_code, city, runways
FROM Airports
WHERE runways > 2
ORDER BY runways DESC;

-- Q4: Aircraft list with model and airline name (3-table JOIN).
SELECT AC.registration_no, AM.manufacturer, AM.model_name, AL.airline_name, AC.status
FROM Aircraft AC
JOIN AircraftModels AM ON AC.model_id = AM.model_id
JOIN Airlines AL       ON AC.airline_id = AL.airline_id
ORDER BY AL.airline_name, AC.registration_no;

-- Q5: Long-haul aircraft models (range above 10,000 km).
SELECT model_name, manufacturer, seat_capacity, range_km
FROM AircraftModels
WHERE range_km > 10000
ORDER BY range_km DESC;

-- ---------- B. Aggregation & grouping (Q6-Q12) ----------

-- Q6: Number of aircraft owned by each airline.
SELECT AL.airline_name, COUNT(AC.aircraft_id) AS total_aircraft
FROM Airlines AL
LEFT JOIN Aircraft AC ON AL.airline_id = AC.airline_id
GROUP BY AL.airline_id, AL.airline_name
ORDER BY total_aircraft DESC;

-- Q7: Total seat capacity of each airline's active fleet.
SELECT AL.airline_name, SUM(AM.seat_capacity) AS active_seat_capacity
FROM Aircraft AC
JOIN Airlines AL       ON AC.airline_id = AL.airline_id
JOIN AircraftModels AM ON AC.model_id = AM.model_id
WHERE AC.status = 'Active'
GROUP BY AL.airline_id, AL.airline_name
ORDER BY active_seat_capacity DESC;

-- Q8: Aircraft count by status.
SELECT status, COUNT(*) AS total_aircraft
FROM Aircraft
GROUP BY status;

-- Q9: Number of aircraft per manufacturer.
SELECT AM.manufacturer, COUNT(AC.aircraft_id) AS total_aircraft
FROM AircraftModels AM
JOIN Aircraft AC ON AM.model_id = AC.model_id
GROUP BY AM.manufacturer
ORDER BY total_aircraft DESC;

-- Q10: Average age (in years) of each airline's fleet.
SELECT AL.airline_name,
       ROUND(AVG(YEAR(@today) - AC.manufactured_year), 1) AS avg_fleet_age
FROM Aircraft AC
JOIN Airlines AL ON AC.airline_id = AL.airline_id
GROUP BY AL.airline_id, AL.airline_name
ORDER BY avg_fleet_age DESC;

-- Q11: Airlines operating more than one distinct aircraft model.
SELECT AL.airline_name, COUNT(DISTINCT AC.model_id) AS distinct_models
FROM Airlines AL
JOIN Aircraft AC ON AL.airline_id = AC.airline_id
GROUP BY AL.airline_id, AL.airline_name
HAVING COUNT(DISTINCT AC.model_id) > 1
ORDER BY distinct_models DESC;

-- Q12: The 5 oldest aircraft with their age.
SELECT AC.registration_no, AM.model_name, AL.airline_name,
       AC.manufactured_year, (YEAR(@today) - AC.manufactured_year) AS age_years
FROM Aircraft AC
JOIN AircraftModels AM ON AC.model_id = AM.model_id
JOIN Airlines AL       ON AC.airline_id = AL.airline_id
ORDER BY AC.manufactured_year ASC, AC.aircraft_id
LIMIT 5;

-- ---------- C. Joins with flights (Q13-Q17) ----------

-- Q13: Departures handled by each airport (busiest first).
SELECT AP.iata_code, AP.airport_name, COUNT(F.flight_id) AS departures
FROM Airports AP
LEFT JOIN Flights F ON F.origin_airport_id = AP.airport_id
GROUP BY AP.airport_id, AP.iata_code, AP.airport_name
ORDER BY departures DESC, AP.iata_code;

-- Q14: Arrivals handled by each airport.
SELECT AP.iata_code, AP.airport_name, COUNT(F.flight_id) AS arrivals
FROM Airports AP
LEFT JOIN Flights F ON F.dest_airport_id = AP.airport_id
GROUP BY AP.airport_id, AP.iata_code, AP.airport_name
ORDER BY arrivals DESC, AP.iata_code;

-- Q15: Airports that have no departing or arriving flights.
SELECT AP.iata_code, AP.airport_name, AP.city
FROM Airports AP
WHERE NOT EXISTS (SELECT 1 FROM Flights F
                  WHERE F.origin_airport_id = AP.airport_id
                     OR F.dest_airport_id   = AP.airport_id);

-- Q16: Top 5 most operated routes (origin -> destination).
SELECT OA.iata_code AS origin, DA.iata_code AS destination, COUNT(*) AS total_flights
FROM Flights F
JOIN Airports OA ON F.origin_airport_id = OA.airport_id
JOIN Airports DA ON F.dest_airport_id   = DA.airport_id
GROUP BY OA.iata_code, DA.iata_code
ORDER BY total_flights DESC, origin, destination
LIMIT 5;

-- Q17: Flights operated by each aircraft - top 10 (utilisation).
SELECT AC.registration_no, AL.airline_name, COUNT(F.flight_id) AS flights_operated
FROM Aircraft AC
JOIN Airlines AL ON AC.airline_id = AL.airline_id
LEFT JOIN Flights F ON F.aircraft_id = AC.aircraft_id
GROUP BY AC.aircraft_id, AC.registration_no, AL.airline_name
ORDER BY flights_operated DESC, AC.registration_no
LIMIT 10;

-- ---------- D. Subqueries & NOT EXISTS (Q18-Q21) ----------

-- Q18: Aircraft models that no airline currently uses.
SELECT AM.model_id, AM.manufacturer, AM.model_name
FROM AircraftModels AM
LEFT JOIN Aircraft AC ON AM.model_id = AC.model_id
WHERE AC.aircraft_id IS NULL;

-- Q19: Airline with the largest fleet.
SELECT AL.airline_name, COUNT(*) AS total_aircraft
FROM Airlines AL
JOIN Aircraft AC ON AL.airline_id = AC.airline_id
GROUP BY AL.airline_id, AL.airline_name
ORDER BY total_aircraft DESC
LIMIT 1;

-- Q20: Airlines that have no retired aircraft.
SELECT AL.airline_name
FROM Airlines AL
WHERE NOT EXISTS (SELECT 1 FROM Aircraft AC
                  WHERE AC.airline_id = AL.airline_id
                    AND AC.status = 'Retired');

-- Q21: Aircraft older than the average age of the whole fleet.
SELECT AC.registration_no, AL.airline_name, AC.manufactured_year
FROM Aircraft AC
JOIN Airlines AL ON AC.airline_id = AL.airline_id
WHERE AC.manufactured_year < (SELECT AVG(manufactured_year) FROM Aircraft)
ORDER BY AC.manufactured_year;

-- ---------- E. Advanced SQL (Q22-Q25) ----------

-- Q22: Rank airlines by fleet size using a window function.
SELECT airline_name, total_aircraft,
       RANK() OVER (ORDER BY total_aircraft DESC) AS fleet_rank
FROM (
    SELECT AL.airline_name, COUNT(AC.aircraft_id) AS total_aircraft
    FROM Airlines AL
    LEFT JOIN Aircraft AC ON AL.airline_id = AC.airline_id
    GROUP BY AL.airline_id, AL.airline_name
) T
ORDER BY fleet_rank, airline_name;

-- Q23: Each airline's share (%) of the total world fleet in this database.
SELECT AL.airline_name,
       COUNT(AC.aircraft_id) AS total_aircraft,
       ROUND(100 * COUNT(AC.aircraft_id) / SUM(COUNT(AC.aircraft_id)) OVER (), 2) AS fleet_share_pct
FROM Airlines AL
LEFT JOIN Aircraft AC ON AL.airline_id = AC.airline_id
GROUP BY AL.airline_id, AL.airline_name
ORDER BY fleet_share_pct DESC, AL.airline_name;

-- Q24: CTE - airlines whose average aircraft capacity is above the overall average.
WITH airline_cap AS (
    SELECT AL.airline_id, AL.airline_name, AVG(AM.seat_capacity) AS avg_capacity
    FROM Airlines AL
    JOIN Aircraft AC       ON AL.airline_id = AC.airline_id
    JOIN AircraftModels AM ON AC.model_id = AM.model_id
    GROUP BY AL.airline_id, AL.airline_name
)
SELECT airline_name, ROUND(avg_capacity, 1) AS avg_seat_capacity
FROM airline_cap
WHERE avg_capacity > (SELECT AVG(avg_capacity) FROM airline_cap)
ORDER BY avg_capacity DESC;

-- Q25: Fleet composition - manufacturer-wise count per airline (pivot using CASE).
SELECT AL.airline_name,
       SUM(CASE WHEN AM.manufacturer = 'Airbus'  THEN 1 ELSE 0 END) AS airbus,
       SUM(CASE WHEN AM.manufacturer = 'Boeing'  THEN 1 ELSE 0 END) AS boeing,
       SUM(CASE WHEN AM.manufacturer NOT IN ('Airbus','Boeing') THEN 1 ELSE 0 END) AS others
FROM Airlines AL
JOIN Aircraft AC       ON AL.airline_id = AC.airline_id
JOIN AircraftModels AM ON AC.model_id = AM.model_id
GROUP BY AL.airline_id, AL.airline_name
ORDER BY AL.airline_name;
