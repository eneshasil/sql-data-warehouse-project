/*
===============================================================================
Stored Procedure: Prepare Bronze Layer (Truncate & Log)
===============================================================================
Script Purpose:
    This script sets up the logging infrastructure and defines the stored procedure
    responsible for preparing the 'bronze' layer for data ingestion.

    It performs the following tasks:
    1. Creates Logging Tables (if they do not exist):
       - bronze.load_log: Tracks the overall status and duration of the load batch.
       - bronze.load_log_detail: Tracks the status, duration, and row counts for 
         individual table operations.

    2. Creates Stored Procedure 'bronze.prepare_load':
       - Iterates through a predefined list of Bronze tables (CRM & ERP sources).
       - Truncates each table to ensure they are empty before loading new raw data.
       - Implements granular logging: Records start/end times and status for every table.
       - Error Handling: Captures exceptions, logs the failure, and stops the process 
         to prevent partial data loads.

    3. Creates Monitoring Views:
       - bronze.v_load_summary: Provides a high-level report of load executions.
       - bronze.v_load_detail_summary: Provides a detailed breakdown of logs per table.

Usage:
    1. Deploy Logic:
       Run this script once to create the tables and stored procedure in the database.
       Example: psql -U user -d datawarehouse -f scripts/bronze/proc_load_bronze.sql

    2. Execute Load:
       To run the full load process (Truncate + CSV Load), execute the 
       orchestration script: 'scripts/bronze/load_bronze.sql'.
       
       (Manual Execution for testing: CALL bronze.prepare_load();)
===============================================================================
*/


CREATE TABLE IF NOT EXISTS bronze.load_log (
	id bigserial PRIMARY KEY,
	run_at timestamptz NOT NULL DEFAULT now(),
	status text NOT NULL,
	notes text,
	total_duration_seconds NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS bronze.load_log_detail(
	id bigserial PRIMARY KEY,
	load_log_id bigint REFERENCES bronze.load_log(id),
	table_name text NOT NULL,
	operation text NOT NULL, -- 'TRUNCATE', 'LOAD' etc.
	start_time timestamptz NOT NULL,
	end_time timestamptz,
	duration_seconds numeric(10,2),
	row_count bigint,
	status text NOT NULL, -- 'SUCCESS', 'FAILED', 'IN_PROGRESS'
	error_message text,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE PROCEDURE bronze.prepare_load()
LANGUAGE plpgsql
AS $$
DECLARE 
	v_error_msg text;
	v_load_log_id bigint;
	v_start_time timestamptz;
	v_end_time timestamptz;
	v_total_start_time timestamptz;
	v_total_duration numeric(10,2);
	v_table_name text;
	v_tables text[] := ARRAY[
	'bronze.crm_cust_info',
	'bronze.crm_prd_info',
	'bronze.crm_sales_details',
	'bronze.erp_cust_az12',
	'bronze.erp_loc_a101',
	'bronze.erp_px_cat_g1v2'
	];

BEGIN
	-- Total time start
	v_total_start_time := clock_timestamp();

	-- Main log record
	INSERT INTO bronze.load_log(status, notes) 
	VALUES ('IN_PROGRESS', 'Starting table truncation process')
	RETURNING id INTO v_load_log_id;

	RAISE NOTICE 'Load Log ID: % - Startig truncation process', v_load_log_id;

	-- Seperate truncate and logging process for each table
	FOREACH v_table_name IN ARRAY v_tables
	LOOP
		BEGIN
			v_start_time := clock_timestamp();
			
			-- Log details start
			INSERT INTO bronze.load_log_detail(
				load_log_id, table_name, operation, start_time, status
			) VALUES(
				v_load_log_id, v_table_name, 'TRUNCATE', v_start_time, 'IN_PROGRESS'
			);

			-- TRUNCATE process
			EXECUTE format('TRUNCATE TABLE %s', v_table_name);
	
			v_end_time := clock_timestamp();
	
			-- Log details - SUCCESS
			UPDATE bronze.load_log_detail
			SET
				end_time = v_end_time,
				duration_seconds = EXTRACT(EPOCH FROM(v_end_time - v_start_time)),
				status = 'SUCCESS'
			WHERE load_log_id = v_load_log_id
				AND table_name = v_table_name
				AND operation = 'TRUNCATE'
				AND status = 'IN_PROGRESS';
	
			RAISE NOTICE 'Table % truncated in % seconds', v_table_name, ROUND(EXTRACT(EPOCH FROM(v_end_time - v_start_time))::numeric, 2);

		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;

			-- Log details - ERROR
			UPDATE bronze.load_log_detail
			SET
				end_time = clock_timestamp(),
				duration_seconds = EXTRACT(EPOCH FROM(clock_timestamp() - v_start_time)),
				status = 'FAILED',
				error_message = v_error_msg
			WHERE load_log_id = v_load_log_id
				AND table_name = v_table_name
				AND operation = 'TRUNCATE'
				AND status = 'IN_PROGRESS';
				
			RAISE WARNING 'Error truncating table % %', v_table_name, v_error_msg;

			-- Update main log and cancel the process
			UPDATE bronze.load_log
			SET
				status = 'FAILED',
				notes = format('Failed at table: %s. Error %s', v_table_name, v_error_msg),
				total_duration_seconds = EXTRACT(EPOCH FROM(clock_timestamp() - v_total_start_time))
			WHERE id = v_load_log_id;

			RAISE EXCEPTION 'Truncation process failed at table %: %', v_table_name, v_error_msg;		
		END;
	END LOOP;

	-- Calculating total time
	v_total_duration := EXTRACT(EPOCH FROM(clock_timestamp() - v_total_start_time));

	-- Main log - SUCCESS
	UPDATE bronze.load_log
	SET	
		status = 'SUCCESS',
		notes = format('Successfully truncated %s tables', array_length(v_tables, 1)),
		total_duration_seconds = v_total_duration
	WHERE id = v_load_log_id;

	RAISE NOTICE 'All tables truncated successfully in % seconds', ROUND(v_total_duration, 2);
	RAISE NOTICE '===============================================';

EXCEPTION
	WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
		RAISE WARNING 'Critical error in prepare_load:: %', v_error_msg;
		RAISE EXCEPTION 'The process has been cancelled: %', v_error_msg;
	
END $$;

-- A view for logging report
CREATE OR REPLACE VIEW bronze.v_load_summary AS
SELECT
	ll.id as load_id,
	ll.run_at,
	ll.status as overall_status,
	ll.total_duration_seconds,
	COUNT(lld.id) as total_operations,
	COUNT(CASE WHEN lld.status = 'SUCCESS' THEN 1 END) as successfull_operations,
	COUNT(CASE WHEN lld.status = 'FAILED' THEN 1 END) as failed_operations,
    ll.notes
FROM bronze.load_log as ll
LEFT JOIN bronze.load_log_detail lld ON ll.id = lld.load_log_id
GROUP BY ll.id, ll.run_at, ll.status, ll.total_duration_seconds, ll.notes
ORDER BY ll.run_at DESC;

-- A view for detailed report
CREATE OR REPLACE VIEW bronze.v_load_detail_summary AS
SELECT 
    lld.load_log_id,
    ll.run_at,
    lld.table_name,
    lld.operation,
    lld.status,
    lld.duration_seconds,
    lld.error_message,
    lld.start_time,
    lld.end_time
FROM bronze.load_log_detail lld
JOIN bronze.load_log as ll ON lld.load_log_id = ll.id
ORDER BY lld.load_log_id DESC, lld.start_time;

