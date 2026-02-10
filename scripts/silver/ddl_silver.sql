/*
===============================================================================
DDL Script: Silver Layer Table Definitions
===============================================================================
Script Purpose:
    This script initializes the table structures for the 'Silver' layer of the
    Data Warehouse. The Silver layer contains cleansed, standardized, and 
    transformed data derived from the Bronze (Raw) layer.

Scope:
    - Drops existing tables if they exist (Ensures a clean schema setup).
    - Creates tables for CRM data (Customer, Product, Sales).
    - Creates tables for ERP data (Customer, Location, Category).
    - Includes 'dwh_create_date' metadata column to track data ingestion time.

Usage:
    Execute this script to reset or initialize the Silver layer structure 
    before running any loading procedures (ELT/ETL pipelines).
===============================================================================
*/

DROP TABLE IF EXISTS silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
	cst_id int4 NULL,
	cst_key varchar(50) NULL,
	cst_firstname varchar(50) NULL,
	cst_lastname varchar(50) NULL,
	cst_marital_status varchar(50) NULL,
	cst_gndr varchar(50) NULL,
	cst_create_date date NULL,
	dwh_create_date timestamptz DEFAULT now() NULL
);

DROP TABLE IF EXISTS silver.crm_prd_info
CREATE TABLE silver.crm_prd_info (
	prd_id int4 NULL,
	cat_id varchar(50) NULL,
	prd_key varchar(50) NULL,
	prd_nm varchar(50) NULL,
	prd_cost int4 NULL,
	prd_line varchar(50) NULL,
	prd_start_dt date NULL,
	prd_end_dt date NULL,
	dwh_create_date timestamptz DEFAULT now() NULL
);

DROP TABLE IF EXISTS silver.crm_sales_details
CREATE TABLE silver.crm_sales_details (
	sls_ord_num varchar(50) NULL,
	sls_prd_key varchar(50) NULL,
	sls_cust_id int4 NULL,
	sls_order_dt date NULL,
	sls_ship_dt date NULL,
	sls_due_dt date NULL,
	sls_sales int4 NULL,
	sls_quantity int4 NULL,
	sls_price int4 NULL,
	dwh_create_date timestamptz DEFAULT now() NULL
);

DROP TABLE IF EXISTS silver.erp_cust_az12
CREATE TABLE silver.erp_cust_az12 (
	cid varchar(50) NULL,
	bdate date NULL,
	gen varchar(50) NULL,
	dwh_create_date timestamptz DEFAULT now() NULL
);

DROP TABLE IF EXISTS silver.erp_loc_a101
CREATE TABLE silver.erp_loc_a101 (
	cid varchar(50) NULL,
	cntry varchar(50) NULL,
	dwh_create_date timestamptz DEFAULT now() NULL
);

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2
CREATE TABLE silver.erp_px_cat_g1v2 (
	id varchar(50) NULL,
	cat varchar(50) NULL,
	subcat varchar(50) NULL,
	maintenance varchar(50) NULL,
	dwh_create_date timestamptz DEFAULT now() NULL
);

