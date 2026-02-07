 /*
 
=====================================================
Database Initialization (Drop & Re-create)
=====================================================

Script Purpose:
	This script handles the structural reset of the 'datawarehouse' database.
	It connects to the main system database (postgres) to perform the following:
	
	1. Revokes public connections to the existing 'datawarehouse'.
	2. Terminates all active sessions to ensure a clean drop.
	3. Drops the 'datawarehouse' database if it exists.
	4. Creates a new, empty 'datawarehouse' database.

IMPORTANT:
	Schema creation (bronze, silver, gold) is NOT performed in this script.
	Those operations are handled in a separate child SQL script which must be 
	executed after establishing a connection to the newly created 'datawarehouse'.

WARNING:
	Running this script will permanently delete the entire 'datawarehouse' database 
	and all its data. Ensure backups are taken before proceeding.
	
 */


REVOKE CONNECT ON DATABASE datawarehouse FROM public;

-- Preventing external connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'datawarehouse' and pid <> pg_backend_pid();

-- Drop 'datawarehouse' database if it exists
DROP database IF EXISTS datawarehouse;

-- Creating 'datawarehouse' database
CREATE database datawarehouse
