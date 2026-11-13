-- ======================================================
-- 00_run_all.sql  -  loads the whole project in the right order
-- Usage (from the folder containing these files):
--   mysql -u root -p < 00_run_all.sql
-- or inside the mysql client:  SOURCE 00_run_all.sql;
-- ======================================================
SOURCE 01_schema.sql;
SOURCE 02_member1_master_data.sql;
SOURCE 03_member2_operations_data.sql;
SOURCE 04_member3_booking_data.sql;
SOURCE 05_views_triggers_procedures.sql;

-- Queries are run separately, member by member:
-- SOURCE 06_member1_fleet_queries.sql;
-- SOURCE 07_member2_operations_queries.sql;
-- SOURCE 08_member3_booking_queries.sql;
