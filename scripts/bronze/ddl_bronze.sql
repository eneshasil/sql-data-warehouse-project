/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates the tables in the 'bronze' schema.
    These tables serve as the raw data landing zone for the Data Warehouse.

    The script creates tables for the following source systems:
    1. CRM (Customer Relationship Management):
       - crm_cust_info
       - crm_prd_info
       - crm_sales_details
    2. ERP (Enterprise Resource Planning):
       - erp_cust_az12
       - erp_loc_a101
       - erp_px_cat_g1v2

    Run this script to re-define the DDL structure of 'bronze' tables.
===============================================================================
*/


-- Creating bronze layer tables
create table if not exists bronze.crm_cust_info(
cst_id INT,
cst_key VARCHAR(50),
cst_firstname VARCHAR(50),
cst_lastname VARCHAR(50),
cst_marital_status VARCHAR(50),
cst_gndr VARCHAR(50),
cst_create_date DATE
);

create table if not exists bronze.crm_prd_info(
prd_id INT,
prd_key VARCHAR(50),
prd_nm VARCHAR(50),
prd_cost INT,
prd_line VARCHAR(50),
prd_start_dt DATE,
prd_end_dt DATE
);

create table if not exists bronze.crm_sales_details(
sls_ord_num VARCHAR(50),
sls_prd_key VARCHAR(50),
sls_cust_id INT,
sls_order_dt VARCHAR(50),
sls_ship_dt VARCHAR(50),
sls_due_dt VARCHAR(50),
sls_sales INT,
sls_quantity INT,
sls_price INT
);

create table if not exists bronze.erp_cust_az12(
cid VARCHAR(50),
bdate DATE,
gen VARCHAR(50)
);

create table if not exists bronze.erp_loc_a101(
cid VARCHAR(50),
cntry VARCHAR(50)
);

create table if not exists bronze.erp_px_cat_g1v2(
id VARCHAR(50),
cat VARCHAR(50),
subcat VARCHAR(50),
maintenance VARCHAR(50)
);
