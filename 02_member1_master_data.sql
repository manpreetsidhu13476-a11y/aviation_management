-- ======================================================
-- 02_member1_master_data.sql
-- Member 1 - Fleet & Master Data Engineer
-- Airlines (10), Airports (20), AircraftModels (9), Aircraft (30)
-- ======================================================
USE aviation_db;

-- PART 1: AIRLINES
INSERT INTO Airlines (airline_id, airline_name, iata_code, country, founded_year) VALUES
(1, 'Air India', 'AI', 'India', 1932),
(2, 'IndiGo', '6E', 'India', 2006),
(3, 'SpiceJet', 'SG', 'India', 2005),
(4, 'Akasa Air', 'QP', 'India', 2021),
(5, 'Emirates', 'EK', 'United Arab Emirates', 1985),
(6, 'Qatar Airways', 'QR', 'Qatar', 1993),
(7, 'Singapore Airlines', 'SQ', 'Singapore', 1947),
(8, 'Lufthansa', 'LH', 'Germany', 1953),
(9, 'British Airways', 'BA', 'United Kingdom', 1974),
(10, 'Etihad Airways', 'EY', 'United Arab Emirates', 2003);

-- PART 2: AIRPORTS
INSERT INTO Airports (airport_id, airport_name, iata_code, city, country, runways) VALUES
(1, 'Indira Gandhi International Airport', 'DEL', 'Delhi', 'India', 4),
(2, 'Chhatrapati Shivaji Maharaj International Airport', 'BOM', 'Mumbai', 'India', 2),
(3, 'Kempegowda International Airport', 'BLR', 'Bengaluru', 'India', 2),
(4, 'Chennai International Airport', 'MAA', 'Chennai', 'India', 2),
(5, 'Netaji Subhas Chandra Bose International Airport', 'CCU', 'Kolkata', 'India', 2),
(6, 'Rajiv Gandhi International Airport', 'HYD', 'Hyderabad', 'India', 2),
(7, 'Cochin International Airport', 'COK', 'Kochi', 'India', 1),
(8, 'Dabolim Airport', 'GOI', 'Goa', 'India', 1),
(9, 'Sardar Vallabhbhai Patel International Airport', 'AMD', 'Ahmedabad', 'India', 1),
(10, 'Pune Airport', 'PNQ', 'Pune', 'India', 1),
(11, 'Chandigarh International Airport', 'IXC', 'Chandigarh', 'India', 1),
(12, 'Sri Guru Ram Dass Jee International Airport', 'ATQ', 'Amritsar', 'India', 1),
(13, 'Dubai International Airport', 'DXB', 'Dubai', 'United Arab Emirates', 2),
(14, 'Hamad International Airport', 'DOH', 'Doha', 'Qatar', 2),
(15, 'Singapore Changi Airport', 'SIN', 'Singapore', 'Singapore', 3),
(16, 'London Heathrow Airport', 'LHR', 'London', 'United Kingdom', 2),
(17, 'Frankfurt Airport', 'FRA', 'Frankfurt', 'Germany', 4),
(18, 'John F. Kennedy International Airport', 'JFK', 'New York', 'United States', 4),
(19, 'Suvarnabhumi Airport', 'BKK', 'Bangkok', 'Thailand', 2),
(20, 'Zayed International Airport', 'AUH', 'Abu Dhabi', 'United Arab Emirates', 2);

-- PART 3: AIRCRAFT MODELS (model 9 is intentionally unused)
INSERT INTO AircraftModels (model_id, manufacturer, model_name, seat_capacity, range_km) VALUES
(1, 'Airbus', 'A320neo', 186, 6300),
(2, 'Airbus', 'A321neo', 222, 7400),
(3, 'Airbus', 'A350-900', 325, 15000),
(4, 'Boeing', '737-800', 189, 5400),
(5, 'Boeing', '777-300ER', 396, 13650),
(6, 'Boeing', '787-9 Dreamliner', 296, 14140),
(7, 'ATR', 'ATR 72-600', 78, 1500),
(8, 'Airbus', 'A380-800', 517, 15200),
(9, 'Embraer', 'E190', 100, 4500);

-- PART 4: AIRCRAFT
INSERT INTO Aircraft (aircraft_id, registration_no, model_id, airline_id, manufactured_year, status) VALUES
(1, 'VT-ABB', 1, 1, 2011, 'Active'),
(2, 'VT-ACC', 1, 1, 2008, 'Maintenance'),
(3, 'VT-ADD', 6, 1, 2016, 'Active'),
(4, 'VT-AEE', 6, 1, 2015, 'Active'),
(5, 'VT-AFF', 5, 1, 2015, 'Active'),
(6, 'VT-IBG', 1, 2, 2009, 'Retired'),
(7, 'VT-ICH', 1, 2, 2011, 'Active'),
(8, 'VT-IDI', 1, 2, 2010, 'Active'),
(9, 'VT-IEJ', 2, 2, 2021, 'Active'),
(10, 'VT-IFK', 2, 2, 2009, 'Active'),
(11, 'VT-IGL', 7, 2, 2008, 'Retired'),
(12, 'VT-SBM', 4, 3, 2010, 'Active'),
(13, 'VT-SCN', 4, 3, 2014, 'Maintenance'),
(14, 'VT-SDO', 4, 3, 2015, 'Active'),
(15, 'VT-QBP', 4, 4, 2024, 'Active'),
(16, 'VT-QCQ', 4, 4, 2008, 'Active'),
(17, 'VT-QDR', 4, 4, 2014, 'Active'),
(18, 'A6-EBS', 5, 5, 2021, 'Active'),
(19, 'A6-ECT', 8, 5, 2015, 'Active'),
(20, 'A6-EDU', 8, 5, 2022, 'Active'),
(21, 'A7-BBV', 3, 6, 2016, 'Active'),
(22, 'A7-BCW', 3, 6, 2008, 'Active'),
(23, 'A7-BDX', 6, 6, 2013, 'Active'),
(24, '9V-SBY', 3, 7, 2021, 'Active'),
(25, '9V-SCZ', 6, 7, 2018, 'Active'),
(26, 'D-AIBA', 1, 8, 2016, 'Active'),
(27, 'D-AICB', 3, 8, 2012, 'Active'),
(28, 'G-BABC', 6, 9, 2014, 'Active'),
(29, 'G-BACD', 1, 9, 2018, 'Active'),
(30, 'A6-FBE', 6, 10, 2011, 'Active');

SELECT 'Airlines' AS tbl, COUNT(*) AS total FROM Airlines
UNION ALL SELECT 'Airports', COUNT(*) FROM Airports
UNION ALL SELECT 'AircraftModels', COUNT(*) FROM AircraftModels
UNION ALL SELECT 'Aircraft', COUNT(*) FROM Aircraft;
