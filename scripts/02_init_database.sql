/*
										(Child Script)
=====================================================
Schema Initialization
=====================================================

Script Purpose:
	This script sets up the logical architecture within the 'datawarehouse' database.
	It creates the three main layers (schemas) for the ETL process:
	
	1. 'bronze': Raw data layer.
	2. 'silver': Cleansed and conformed data layer.
	3. 'gold':   Curated business-level data layer.

PREREQUISITE:
	This script must be executed while connected specifically to the 
	'datawarehouse' database (created by the Admin script).

*/

-- Creating schemas
create schema if not exists bronze;
create schema if not exists silver;
create schema if not exists gold;
