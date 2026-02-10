/*
===============================================================================
Quality Checks: Gold Layer Validation
===============================================================================
Script Purpose:
    This script performs data quality checks on the Gold layer views (Star Schema).
    It validates the integrity of the Dimensional Model used for reporting.

Key Checks:
    1. Referential Integrity: Ensures every fact record links to valid dimensions.
       (Orphaned records check).
    2. Surrogate Key Uniqueness: Verifies that dimension keys are unique.
    3. Data Consistency: Validates consolidated attributes (e.g., Gender, Category).
    4. Completeness: Checks for NULL values in critical reporting columns.

Usage:
    Run these queries individually.
    Expectation: Ideally, all queries should return ZERO results (Empty Set),
    unless specified otherwise (e.g., Distinct Value checks).
===============================================================================
*/

-- =============================================================================
-- 1. Dimension: gold.dim_customers
-- =============================================================================

-- Check for Duplicate Surrogate Keys
-- Expectation: No Results
SELECT customer_key, COUNT(*)
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check for Duplicate Business Keys (Customer IDs)
-- Expectation: No Results
SELECT customer_id, COUNT(*)
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Data Standardization Check (Gender)
-- Expectation: Should only return 'Female', 'Male', 'n/a'
SELECT DISTINCT gender 
FROM gold.dim_customers;


-- =============================================================================
-- 2. Dimension: gold.dim_products
-- =============================================================================

-- Check for Duplicate Surrogate Keys
-- Expectation: No Results
SELECT product_key, COUNT(*)
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Check for Duplicate Business Keys (Product Number)
-- Expectation: No Results
SELECT product_number, COUNT(*)
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;

-- Data Standardization Check (Categories)
-- Expectation: Check if categories look correct and consistent
SELECT DISTINCT category, subcategory
FROM gold.dim_products
ORDER BY 1, 2;


-- =============================================================================
-- 3. Fact: gold.fact_sales
-- =============================================================================

-- Check for Referential Integrity (Orphaned Facts)
-- Importance: Critical!
-- Description: Finds sales records where the Customer or Product Key is NULL.
-- This happens if a sale refers to a customer/product that doesn't exist in dimensions.
-- Expectation: No Results
SELECT *
FROM gold.fact_sales f
WHERE f.customer_key IS NULL 
   OR f.product_key IS NULL;

-- Check for Data Validity (Zero or Negative Sales)
-- Expectation: No Results (Unless returns/refunds are handled as negative)
SELECT *
FROM gold.fact_sales
WHERE sales_amount <= 0 
   OR quantity <= 0 
   OR price <= 0;

-- Check for Date Consistency
-- Expectation: Order Date should not be in the future
SELECT *
FROM gold.fact_sales
WHERE order_date > CURRENT_DATE;

-- Data Consistency: Verify Total Sales Calculation
-- Expectation: No Results
SELECT 
    sales_amount, quantity, price
FROM gold.fact_sales
WHERE sales_amount != (quantity * price);
