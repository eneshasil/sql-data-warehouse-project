/*
===============================================================================
DDL Script: Gold Layer Views
===============================================================================
Script Purpose:
    This script creates the Gold layer views for the Data Warehouse.
    The Gold layer represents the dimensional model (Star Schema) designed 
    for reporting and analytical requirements.

    It performs the following transformations:
    1. Integration: Joins data from Silver layer tables (CRM & ERP).
    2. Surrogate Keys: Generates unique keys (ROW_NUMBER) for Dimensions.
    3. Filtering: Handles Slowly Changing Dimensions (SCD) by selecting 
       only current records (e.g., active products).
    4. Star Schema: Establishes relationships between Facts and Dimensions.

List of Views:
    1. gold.dim_customers: Consolidated customer dimension.
    2. gold.dim_products: Product dimension linked with categories.
    3. gold.fact_sales: Transactional fact table with foreign keys.

Usage:
    This script can be queried directly.
===============================================================================
*/

CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	la.cntry as country,
	ci.cst_marital_status as marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender info
		 ELSE COALESCE(ca.gen, 'n/a')
	END as gender,
	ca.bdate as birthdate,
	ci.cst_create_date as create_date 
FROM silver.crm_cust_info as ci
LEFT JOIN silver.erp_cust_az12 as ca 
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 as la
ON ci.cst_key = la.cid;

CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key ) as product_key,
	pn.prd_id as product_id, 
	pn.prd_key as product_number,
	pn.prd_nm as product_name,
	pn.cat_id as category_id,  
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance,
	pn.prd_cost as cost, 
	pn.prd_line as product_line, 
	pn.prd_start_dt as start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 as pc
ON pn.cat_id = pc.id 
WHERE pn.prd_end_dt IS NULL;

CREATE VIEW gold.fact_sales as
SELECT 
sd.sls_ord_num as order_number, 
pr.product_key,
cu.customer_key,
sd.sls_order_dt as order_date, 
sd.sls_ship_dt as shipping_date, 
sd.sls_due_dt as due_date, 
sd.sls_sales as sales_amount, 
sd.sls_quantity as quantity, 
sd.sls_price as price
FROM silver.crm_sales_details as sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number 
LEFT JOIN gold.dim_customers as cu
ON sd.sls_cust_id = cu.customer_id;



