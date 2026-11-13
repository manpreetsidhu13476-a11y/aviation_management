# Aviation Management System (MySQL 8.0+) - MCA Mini Project

A relational database for airline operations: fleet, airports, flights, crew rostering,
aircraft maintenance, passenger bookings and revenue.

## Team split (25 queries per member = 75 total)

| Member | Module | Tables | Data file | Query file |
|---|---|---|---|---|
| 1 | Fleet & Master Data | Airlines, Airports, AircraftModels, Aircraft | `02_member1_master_data.sql` | `06_member1_fleet_queries.sql` |
| 2 | Flight Operations | Crew, Flights, FlightCrew, Maintenance | `03_member2_operations_data.sql` | `07_member2_operations_queries.sql` |
| 3 | Passengers & Revenue | Passengers, Bookings, Payments | `04_member3_booking_data.sql` | `08_member3_booking_queries.sql` |

Shared: `01_schema.sql` (all 11 tables) and `05_views_triggers_procedures.sql`
(3 views, 3 triggers, 2 stored procedures). `00_run_all.sql` loads everything in order.

## Run order
1. `01_schema.sql`  (drops and recreates `aviation_db`)
2. `02`, `03`, `04` data files (in this order, because of foreign keys)
3. `05_views_triggers_procedures.sql` (after data, so triggers do not fire during loading)
4. `06`, `07`, `08` query files in any order (Member 3 Q16 uses the view from file 05)

## Sample data
10 airlines, 20 airports, 9 aircraft models, 30 aircraft, 50 crew, 60 flights (24 landed, 25 scheduled,
6 delayed, 5 cancelled), 225 crew roster rows, 49 maintenance records, 80 passengers (6 minors),
250 bookings, 250 payments. "Today" in the data is 11-Nov-2026 (`@today` in the query files).

Deliberate data cases used by queries: one unused aircraft model (E190), two airports with no flights,
three crew members never rostered, three upcoming flights without a co-pilot, two aircraft under maintenance,
six passengers with no booking.

## Relationships
```
Airlines 1--* Aircraft *--1 AircraftModels
Airlines 1--* Crew            Airlines 1--* Flights
Aircraft 1--* Flights         Airports 1--* Flights (origin and destination)
Flights *--* Crew  (via FlightCrew)      Aircraft 1--* Maintenance
Passengers 1--* Bookings *--1 Flights    Bookings 1--1 Payments
```

## Concepts covered
JOINs (up to 5 tables, self-role joins on Airports), GROUP BY / HAVING, subqueries, NOT EXISTS,
LEFT JOIN anti-joins, CASE pivots, CTEs, window functions (RANK, ROW_NUMBER, LAG, running SUM),
views, triggers (SIGNAL, cascading refund), stored procedures (IN/OUT parameters),
CHECK / UNIQUE / FOREIGN KEY constraints.

## Demo commands
```sql
CALL sp_flight_manifest(30);
CALL sp_book_ticket(40, 55, '12C', 'Economy', @new_id); SELECT @new_id;
UPDATE Flights SET status = 'Cancelled' WHERE flight_id = 55;   -- trigger cancels bookings and refunds
INSERT INTO Bookings (passenger_id, flight_id, seat_no, travel_class, fare)
VALUES (1, 1, '20A', 'Economy', 5000);                          -- fails: flight already landed
```
(Use a flight whose status is Scheduled or Delayed for the booking/cancel demos; check with
`SELECT flight_id, status FROM Flights;`.)
