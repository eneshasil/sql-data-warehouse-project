/*
===============================================================================
Stored Procedures: Silver Layer (Worker Procedures)
===============================================================================
Script Purpose:
    Defines the transformation and loading logic for each Silver table.
    These procedures are called by the master orchestration procedure.
===============================================================================
*/

-- Procedure for table: silver.crm_cust_info
CREATE OR REPLACE PROCEDURE silver.load_crm_cust_info() as $$
BEGIN
	RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;

	RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';
	INSERT INTO silver.crm_cust_info(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date)
	SELECT
	cst_id,
	cst_key,
	TRIM(cst_firstname) as cst_firstname,
	TRIM(cst_lastname) as cst_lastname,
	CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	 	 WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	 	 ELSE 'n/a'
	END as cst_marital_status, 										-- Normalize marital status values to readable format
	CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	 	 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	 	 ELSE 'n/a'
	END as cst_gndr,												-- Normalize gender values to readable format
	cst_create_date
	FROM(
	SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	)t WHERE flag_last = 1;											-- Select the most recent record per customer
END;
$$ LANGUAGE plpgsql;

-- Procedure for table: silver.crm_prd_info
CREATE OR REPLACE PROCEDURE silver.load_crm_prd_info() as $$
BEGIN
	RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;

	RAISE NOTICE '>> Inserting Data Into: silver.crm_prd_info';
	INSERT INTO silver.crm_prd_info(
	prd_id, 			
	cat_id,			
	prd_key,			
	prd_nm,			
	prd_cost,		
	prd_line, 		
	prd_start_dt,	
	prd_end_dt	
	)
	SELECT 
	prd_id,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id, 	-- Extract category id
	SUBSTRING(prd_key, 7, LENGTH(prd_key)) as prd_key,	   	-- Extract product key
	prd_nm,
	COALESCE(prd_cost, 0) as prd_cost,
	CASE UPPER(TRIM(prd_line))
		 WHEN 'M' THEN 'Mountain'
		 WHEN 'R' THEN 'Road'
		 WHEN 'S' THEN 'Other Sales'
		 WHEN 'T' THEN 'Touring'
		 ELSE 'n/a'
	END as prd_line,	-- Map product line codes to descriptive values		
	prd_start_dt::DATE,
	LEAD(prd_start_dt::DATE) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day' as prd_end_dt -- Calcuate end date as one day before the next start date
FROM bronze.crm_prd_info; 
	
END;
$$ LANGUAGE plpgsql;

-- Procedure for table: silver.crm_sales_details
CREATE OR REPLACE PROCEDURE silver.load_crm_sales_details() as $$
BEGIN
	RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;

	RAISE NOTICE '>> Inserting Data Into: silver.crm_sales_details';	
	INSERT INTO silver.crm_sales_details (
	sls_ord_num, 
	sls_prd_key, 
	sls_cust_id, 
	sls_order_dt, 
	sls_ship_dt, 
	sls_due_dt, 
	sls_sales, 
	sls_quantity, 
	sls_price
	)
	SELECT 
	sls_ord_num,
	sls_prd_key, 
	sls_cust_id,
	CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
		 ELSE ((sls_order_dt::TEXT)::DATE)
	END as sls_order_dt,
	CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
		 ELSE ((sls_ship_dt::TEXT)::DATE)
	END as sls_ship_dt, 
	CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
		 ELSE ((sls_due_dt::TEXT)::DATE)
	END as sls_due_dt,
	CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		 	THEN sls_quantity * ABS(sls_price)
		 ELSE sls_sales
	END as sls_sales, 	-- Recalculate sales if original value is missing or incorrect
	sls_quantity, 
	CASE WHEN sls_price IS NULL OR sls_price <= 0
			THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price 
	END as sls_price	-- Derive price if original value is invalid
	FROM bronze.crm_sales_details; 
END;
$$ LANGUAGE plpgsql;

-- Procedure for table: silver.erp_cust_az12
CREATE OR REPLACE PROCEDURE silver.load_erp_cust_az12() as $$
BEGIN
	RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;

	RAISE NOTICE '>> Inserting Data Into: silver.erp_cust_az12';
	INSERT INTO silver.erp_cust_az12(cid, bdate, gen)
	SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) -- Remove 'NAS' prefix if present
		 ELSE cid
	END as cid,
	CASE WHEN bdate > now() THEN NULL
		 ELSE bdate
	END as bdate, -- Set future birthdates to NULL
	CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		 ELSE 'n/a'
	END as gen -- Normalize gender values and handle unknown cases
	FROM bronze.erp_cust_az12;
END;
$$ LANGUAGE plpgsql;

-- Procedure for table: silver.erp_loc_a101
CREATE OR REPLACE PROCEDURE silver.load_erp_loc_a101() as $$
BEGIN
	RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101;

	RAISE NOTICE '>> Inserting Data Into: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101(cid, cntry)
	SELECT
	REPLACE(cid, '-', '') as cid,
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		 ELSE TRIM(cntry)
	END as cntry -- Normalize and handle missing or blank country codes
	FROM bronze.erp_loc_a101;
END;
$$ LANGUAGE plpgsql;

-- Procedure for table: silver.erp_px_cat_g1v2
CREATE OR REPLACE PROCEDURE silver.load_erp_px_cat_g1v2() as $$
BEGIN
	RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';
	TRUNCATE TABLE silver.erp_px_cat_g1v2;

	RAISE NOTICE '>> Inserting Data Into: silver.erp_px_cat_g1v2';
	INSERT INTO silver.erp_px_cat_g1v2
	(id, cat, subcat, maintenance)
	SELECT 
	id, 
	cat, 
	subcat, 
	maintenance 
	FROM bronze.erp_px_cat_g1v2;
END;
$$ LANGUAGE plpgsql;
