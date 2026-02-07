/*
===============================================================================
Bronze Layer Data Loading Script
===============================================================================
Script Purpose:
    This script orchestrates the loading of the Bronze layer.
    1. Checks for the required BASE_PATH variable.
    2. Calls the stored procedure to truncate tables and log the start.
    3. Executes the bulk load of CSV files using \copy.
    4. Displays summary and detailed execution reports.

Usage:
    psql -h <host> -U <user> -d <dbname> -v BASE_PATH='/absolute/path/to/project' -f load_bronze.sql

Example:
    psql -U postgres -d datawarehouse -v BASE_PATH='/Users/eneshasil/Desktop/Repositories/sql-data-warehouse-project' -f scripts/bronze/load_bronze.sql
===============================================================================
*/

-- 1. Configuration & Safety Check
-- \set BASE_PATH '/Users/eneshasil/Desktop/Repositories/sql-data-warehouse-project' -- Uncomment for manual testing

-- 2. Prepare the environment (Truncate tables, log start)
CALL bronze.prepare_load();

-- 3. Bulk Load CSV Files
RAISE NOTICE 'Starting CSV Bulk Load from % ...', :'BASE_PATH';

\copy bronze.crm_cust_info FROM :'BASE_PATH'/'datasets/source_crm/cust_info.csv' WITH (FORMAT csv, HEADER, DELIMITER ',');
\copy bronze.crm_prd_info FROM :'BASE_PATH'/'datasets/source_crm/prd_info.csv' WITH (FORMAT csv, HEADER, DELIMITER ',');
\copy bronze.crm_sales_details FROM :'BASE_PATH'/'datasets/source_crm/sales_details.csv' WITH (FORMAT csv, HEADER, DELIMITER ',');

\copy bronze.erp_cust_az12 FROM :'BASE_PATH'/'datasets/source_erp/CUST_AZ12.csv' WITH (FORMAT csv, HEADER, DELIMITER ',');
\copy bronze.erp_loc_a101 FROM :'BASE_PATH'/'datasets/source_erp/LOC_A101.csv' WITH (FORMAT csv, HEADER, DELIMITER ',');
\copy bronze.erp_px_cat_g1v2 FROM :'BASE_PATH'/'datasets/source_erp/PX_CAT_G1V2.csv' WITH (FORMAT csv, HEADER, DELIMITER ',');

-- 4. Summary Report
SELECT * FROM bronze.v_load_summary;

-- 5. Detailed Report(Latest Run)
SELECT * FROM bronze.v_load_detail_summary 
WHERE load_log_id = (SELECT MAX(id) FROM bronze.load_log);

-- 6. Quality Check: Durations & Status
SELECT 
    table_name,
    duration_seconds,
    status,
    CASE 
        WHEN error_message IS NOT NULL THEN error_message 
        ELSE 'OK' 
    END as result
FROM bronze.load_log_detail
WHERE load_log_id = (SELECT MAX(id) FROM bronze.load_log)
ORDER BY start_time;
