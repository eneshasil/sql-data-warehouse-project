/*
===============================================================================
Quality Checks: Silver Layer Validation
===============================================================================
Script Purpose:
    This script performs data quality checks on the Silver layer tables to ensure
    accuracy, consistency, and completeness before the data is promoted to the
    Gold layer.

Key Checks:
    1. Nulls or Duplicates in Primary Keys (Uniqueness).
    2. Unwanted Spaces in string fields.
    3. Data Standardization (e.g., Gender, Marital Status).
    4. Date Logic Errors (e.g., End Date < Start Date, Future Dates).
    5. Business Logic Consistency (e.g., Sales = Qty * Price).

Usage:
    Run these queries individually.
    Expectation: Ideally, all queries should return ZERO results (Empty Set),
    unless specified otherwise (e.g., Distinct Value checks).
===============================================================================
*/

-- =============================================================================
-- 1. Table: silver.crm_cust_info
-- =============================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT cst_id, COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for Data Standardization (Marital Status)
-- Expectation: Only 'Married', 'Single', 'n/a' should be returned
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;

-- Check for Data Standardization (Gender)
-- Expectation: Only 'Female', 'Male', 'n/a' should be returned
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;


-- =============================================================================
-- 2. Table: silver.crm_prd_info (From User Inputs)
-- =============================================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results 
SELECT prd_id, COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for Unwanted Spaces in Product Names
-- Expectation: No Results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLs or Negative Costs
-- Expectation: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Check Data Standardization (Product Line)
-- Expectation: Should match defined categories (Road, Mountain, etc.)
SELECT DISTINCT prd_line  
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders (End Date before Start Date)
-- Expectation: No Results
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- =============================================================================
-- 3. Table: silver.crm_sales_details (From User Inputs)
-- =============================================================================

-- Check for Invalid Dates (Legacy Logic Updated for DATE type)
-- Expectation: No Results with dates < 1900 or > 2050
SELECT 
    sls_due_dt, 
    sls_order_dt, 
    sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_due_dt > '2050-01-01' OR sls_due_dt < '1900-01-01'
   OR sls_order_dt > '2050-01-01' OR sls_order_dt < '1900-01-01'
   OR sls_ship_dt > '2050-01-01' OR sls_ship_dt < '1900-01-01';

-- Check for Invalid Date Orders
-- Expectation: No Results (Order Date cannot be after Shipping or Due Date)
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results
SELECT 
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


-- =============================================================================
-- 4. Table: silver.erp_cust_az12 (From User Inputs)
-- =============================================================================

-- Identify Out-of-Range Dates (Birthdates)
-- Expectation: No Results (Bdate < 1924 or Future Dates)
SELECT bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > CURRENT_DATE;

-- Check Data Standardization (Gender)
-- Expectation: Cleaned values (Female, Male, n/a)
SELECT DISTINCT gen
FROM silver.erp_cust_az12;


-- =============================================================================
-- 5. Table: silver.erp_loc_a101
-- =============================================================================

-- Check for Duplicate IDs
-- Expectation: No Results
SELECT cid, COUNT(*)
FROM silver.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1;

-- Check Data Standardization (Country)
-- Expectation: Only standardized values (United States, Germany, n/a)
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- =============================================================================
-- 6. Table: silver.erp_px_cat_g1v2
-- =============================================================================

-- Check for Duplicate IDs
-- Expectation: No Results
SELECT id, COUNT(*)
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;

-- Check for Whitespaces or formatting issues in Columns
-- Expectation: No Results
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);
