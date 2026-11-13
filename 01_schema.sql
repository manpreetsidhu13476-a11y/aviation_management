-- ======================================================
-- 01_schema.sql
-- Aviation Management System  |  MCA Mini Project
-- MySQL 8.0+
-- Run order: 01 -> 02 -> 03 -> 04 -> 05 -> 06/07/08
-- ======================================================
DROP DATABASE IF EXISTS aviation_db;
CREATE DATABASE aviation_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE aviation_db;

-- ---------- MEMBER 1 : FLEET & MASTER DATA ----------
CREATE TABLE Airlines (
  airline_id    INT AUTO_INCREMENT PRIMARY KEY,
  airline_name  VARCHAR(100) NOT NULL UNIQUE,
  iata_code     CHAR(2)      NOT NULL UNIQUE,
  country       VARCHAR(60)  NOT NULL,
  founded_year  INT          NOT NULL,
  CHECK (founded_year BETWEEN 1900 AND 2030)
);

CREATE TABLE Airports (
  airport_id    INT AUTO_INCREMENT PRIMARY KEY,
  airport_name  VARCHAR(120) NOT NULL,
  iata_code     CHAR(3)      NOT NULL UNIQUE,
  city          VARCHAR(60)  NOT NULL,
  country       VARCHAR(60)  NOT NULL,
  runways       INT          NOT NULL DEFAULT 1,
  CHECK (runways >= 1)
);

CREATE TABLE AircraftModels (
  model_id      INT AUTO_INCREMENT PRIMARY KEY,
  manufacturer  VARCHAR(50)  NOT NULL,
  model_name    VARCHAR(60)  NOT NULL UNIQUE,
  seat_capacity INT          NOT NULL,
  range_km      INT          NOT NULL,
  CHECK (seat_capacity > 0),
  CHECK (range_km > 0)
);

CREATE TABLE Aircraft (
  aircraft_id       INT AUTO_INCREMENT PRIMARY KEY,
  registration_no   VARCHAR(12) NOT NULL UNIQUE,
  model_id          INT NOT NULL,
  airline_id        INT NOT NULL,
  manufactured_year INT NOT NULL,
  status            ENUM('Active','Maintenance','Retired') NOT NULL DEFAULT 'Active',
  FOREIGN KEY (model_id)   REFERENCES AircraftModels(model_id),
  FOREIGN KEY (airline_id) REFERENCES Airlines(airline_id)
);

-- ---------- MEMBER 2 : OPERATIONS ----------
CREATE TABLE Crew (
  crew_id          INT AUTO_INCREMENT PRIMARY KEY,
  airline_id       INT NOT NULL,
  full_name        VARCHAR(100) NOT NULL,
  role             ENUM('Pilot','Co-Pilot','Cabin Crew') NOT NULL,
  license_no       VARCHAR(20)  NOT NULL UNIQUE,
  experience_years INT NOT NULL DEFAULT 0,
  phone            VARCHAR(15)  NOT NULL UNIQUE,
  FOREIGN KEY (airline_id) REFERENCES Airlines(airline_id)
);

CREATE TABLE Flights (
  flight_id         INT AUTO_INCREMENT PRIMARY KEY,
  flight_no         VARCHAR(8) NOT NULL UNIQUE,
  airline_id        INT NOT NULL,
  aircraft_id       INT NOT NULL,
  origin_airport_id INT NOT NULL,
  dest_airport_id   INT NOT NULL,
  departure_time    DATETIME NOT NULL,
  arrival_time      DATETIME NOT NULL,
  base_fare         DECIMAL(10,2) NOT NULL,
  delay_minutes     INT NOT NULL DEFAULT 0,
  status            ENUM('Scheduled','Delayed','Landed','Cancelled') NOT NULL DEFAULT 'Scheduled',
  FOREIGN KEY (airline_id)        REFERENCES Airlines(airline_id),
  FOREIGN KEY (aircraft_id)       REFERENCES Aircraft(aircraft_id),
  FOREIGN KEY (origin_airport_id) REFERENCES Airports(airport_id),
  FOREIGN KEY (dest_airport_id)   REFERENCES Airports(airport_id),
  CHECK (origin_airport_id <> dest_airport_id),
  CHECK (arrival_time > departure_time),
  CHECK (base_fare > 0),
  CHECK (delay_minutes >= 0)
);

CREATE TABLE FlightCrew (
  flight_id INT NOT NULL,
  crew_id   INT NOT NULL,
  PRIMARY KEY (flight_id, crew_id),
  FOREIGN KEY (flight_id) REFERENCES Flights(flight_id) ON DELETE CASCADE,
  FOREIGN KEY (crew_id)   REFERENCES Crew(crew_id)      ON DELETE CASCADE
);

CREATE TABLE Maintenance (
  maint_id    INT AUTO_INCREMENT PRIMARY KEY,
  aircraft_id INT NOT NULL,
  maint_date  DATE NOT NULL,
  maint_type  ENUM('Routine','Engine','Avionics','Structural') NOT NULL,
  cost        DECIMAL(12,2) NOT NULL,
  description VARCHAR(200),
  status      ENUM('Completed','In Progress','Scheduled') NOT NULL,
  FOREIGN KEY (aircraft_id) REFERENCES Aircraft(aircraft_id) ON DELETE CASCADE,
  CHECK (cost >= 0)
);

-- ---------- MEMBER 3 : PASSENGERS, BOOKING & REVENUE ----------
CREATE TABLE Passengers (
  passenger_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name    VARCHAR(100) NOT NULL,
  email        VARCHAR(100) NOT NULL UNIQUE,
  phone        VARCHAR(15)  NOT NULL UNIQUE,
  passport_no  VARCHAR(12)  NOT NULL UNIQUE,
  nationality  VARCHAR(50)  NOT NULL,
  dob          DATE NOT NULL
);

CREATE TABLE Bookings (
  booking_id   INT AUTO_INCREMENT PRIMARY KEY,
  passenger_id INT NOT NULL,
  flight_id    INT NOT NULL,
  seat_no      VARCHAR(4) NULL,            -- NULL once a booking is cancelled
  travel_class ENUM('Economy','Business','First') NOT NULL DEFAULT 'Economy',
  fare         DECIMAL(10,2) NOT NULL,
  status       ENUM('Confirmed','Checked-In','Cancelled') NOT NULL DEFAULT 'Confirmed',
  booked_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_flight_seat (flight_id, seat_no),
  UNIQUE KEY uq_passenger_flight (passenger_id, flight_id),
  FOREIGN KEY (passenger_id) REFERENCES Passengers(passenger_id) ON DELETE CASCADE,
  FOREIGN KEY (flight_id)    REFERENCES Flights(flight_id)       ON DELETE CASCADE,
  CHECK (fare > 0)
);

CREATE TABLE Payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  booking_id INT NOT NULL,
  amount     DECIMAL(10,2) NOT NULL,
  method     ENUM('UPI','Credit Card','Debit Card','Net Banking') NOT NULL,
  status     ENUM('Paid','Pending','Refunded','Failed') NOT NULL,
  paid_at    DATETIME NULL,
  FOREIGN KEY (booking_id) REFERENCES Bookings(booking_id) ON DELETE CASCADE,
  CHECK (amount > 0)
);

-- Helpful indexes
CREATE INDEX idx_aircraft_airline  ON Aircraft(airline_id);
CREATE INDEX idx_flights_airline   ON Flights(airline_id);
CREATE INDEX idx_flights_route     ON Flights(origin_airport_id, dest_airport_id);
CREATE INDEX idx_flights_departure ON Flights(departure_time);
CREATE INDEX idx_bookings_flight   ON Bookings(flight_id);
CREATE INDEX idx_payments_booking  ON Payments(booking_id);
