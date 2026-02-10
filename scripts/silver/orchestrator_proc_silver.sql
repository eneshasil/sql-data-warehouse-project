/*
===============================================================================
Stored Procedure: Load Silver Layer (Orchestrator)
===============================================================================
Script Purpose:
    This master stored procedure orchestrates the loading of the Silver layer.
    It utilizes the 'bronze.load_log' and 'bronze.load_log_detail' tables
    to provide comprehensive logging, timing, and error handling.

    Features:
    - Logs overall batch status and duration.
    - Logs individual table operation status and duration.
    - Implements Try/Catch (Exception Handling) to manage failures gracefully.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
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
    v_proc_name text;
	v_tables text[] := ARRAY[
        'silver.crm_cust_info',
        'silver.crm_prd_info',
        'silver.crm_sales_details',
        'silver.erp_cust_az12',
        'silver.erp_loc_a101',
        'silver.erp_px_cat_g1v2'
    ];

BEGIN
	v_total_start_time := clock_timestamp();

	INSERT INTO bronze.load_log(status, notes)
	VALUES ('IN_PROGRESS', 'Silver Layer Loading Started')
	RETURNING id INTO v_load_log_id;
	
	RAISE NOTICE '>> Load Log ID: % - Starting Silver Layer Load...', v_load_log_id;
	
	FOREACH v_table_name IN ARRAY v_tables
	LOOP	
		BEGIN
			
			v_proc_name := REPLACE(v_table_name, 'silver.', 'silver.load_');
			v_start_time := clock_timestamp();
			
			INSERT INTO bronze.load_log_detail(
				load_log_id, table_name, operation, start_time, status
				) VALUES(
				  	v_load_log_id, v_table_name, 'INSERT', v_start_time, 'IN_PROGRESS');
			
			RAISE NOTICE 'Executing: %', v_proc_name;
			
			EXECUTE format('CALL %s()', v_proc_name);
			
			v_end_time := clock_timestamp();
			
			UPDATE bronze.load_log_detail
			SET
				end_time = v_end_time,
				duration_seconds = EXTRACT(EPOCH FROM(v_end_time - v_start_time)),
				status = 'SUCCESS'
			WHERE load_log_id = v_load_log_id
				AND table_name = v_table_name
				AND operation = 'INSERT'
				AND status = 'IN_PROGRESS';
			
			RAISE NOTICE '>> % loaded successfully in % seconds', v_table_name, ROUND(EXTRACT(EPOCH FROM(v_end_time - v_start_time))::numeric, 2);
		
		EXCEPTION
			WHEN OTHERS THEN
				GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
		
			UPDATE bronze.load_log_detail 
			SET
				end_time = clock_timestamp(),
				duration_seconds = EXTRACT(EPOCH FROM(clock_timestamp() - v_start_time)),
				status = 'FAILED',
				error_message = v_error_msg
            WHERE load_log_id = v_load_log_id
                AND table_name = v_table_name
                AND operation = 'INSERT'
                AND status = 'IN_PROGRESS';
			
			RAISE WARNING '!! Error loading table %: %', v_table_name, v_error_msg;
			
			UPDATE bronze.load_log
            SET
                status = 'FAILED',
                notes = format('Failed at table: %s. Error: %s', v_table_name, v_error_msg),
                total_duration_seconds = EXTRACT(EPOCH FROM(clock_timestamp() - v_total_start_time))
            WHERE id = v_load_log_id;
			
			RAISE EXCEPTION 'Silver Layer Load failed at table %', v_table_name;
			
		END;		
	END LOOP;
	
	v_total_duration := EXTRACT(EPOCH FROM(clock_timestamp() - v_total_start_time));
	
	UPDATE bronze.load_log
    SET 
        status = 'SUCCESS',
        notes = format('Successfully loaded %s Silver tables', array_length(v_tables, 1)),
        total_duration_seconds = v_total_duration
    WHERE id = v_load_log_id;

    RAISE NOTICE '>> Silver Layer loaded successfully in % seconds', ROUND(v_total_duration, 2);
    RAISE NOTICE '===============================================';
    
EXCEPTION
    WHEN OTHERS THEN
        -- En dış katmanda beklenmedik bir hata olursa
        GET STACKED DIAGNOSTICS v_error_msg = MESSAGE_TEXT;
        RAISE WARNING 'Critical error in silver.load_silver: %', v_error_msg;
        RAISE;
	
END $$;

CALL silver.load_silver();
