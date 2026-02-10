# Data Warehouse Catalog

This document provides a comprehensive overview of the Data Warehouse architecture, including the Bronze (Raw), Silver (Cleansed), and Gold (Curated) layers.

---

## 🏗 Architecture Overview

The data warehouse follows the **Medallion Architecture**:

| Layer | Schema | Description |
| :--- | :--- | :--- |
| **Bronze** | `bronze` | Raw data ingestion. Data is stored in its original format with no transformations. |
| **Silver** | `silver` | Cleansed and standardized data. Null handling, type casting, and deduplication are applied here. |
| **Gold** | `gold` | Business-ready data modeled in a Star Schema (Dimensions & Facts) for reporting and analytics. |

---

## 🥇 Gold Layer (Star Schema)

The Gold layer is optimized for reporting and analysis. It consists of **Dimension** tables (`dim_`) and **Fact** tables (`fact_`).

### 1. `gold.dim_customers`
**Type:** Dimension View
**Description:** A consolidated view of customers, combining personal information from CRM and demographic data from ERP systems.
**Source:** `silver.crm_cust_info`, `silver.erp_cust_az12`, `silver.erp_loc_a101`

| Column Name | Data Type | Description | Key Info |
| :--- | :--- | :--- | :--- |
| **customer_key** | `BIGINT` | Surrogate Key generated for the DWH. Unique identifier. | **[PK]** |
| **customer_id** | `INT` | Original Customer ID from the source system. | [Business Key] |
| **customer_number** | `VARCHAR` | Unique customer code (e.g., CST-123). | |
| **first_name** | `VARCHAR` | Customer's first name. | |
| **last_name** | `VARCHAR` | Customer's last name. | |
| **country** | `VARCHAR` | Country of residence (Derived from ERP Location). | |
| **marital_status** | `VARCHAR` | Marital status (Married/Single). | |
| **gender** | `VARCHAR` | Gender. **Logic:** Prioritizes CRM data; falls back to ERP if CRM is missing. | |
| **birthdate** | `DATE` | Customer's birthdate (from ERP). | |
| **create_date** | `DATE` | The date the customer record was created in the source. | |

### 2. `gold.dim_products`
**Type:** Dimension View
**Description:** Contains product catalog details including categories, subcategories, and costs. Filters only for **active products** (`end_date` is NULL).
**Source:** `silver.crm_prd_info`, `silver.erp_px_cat_g1v2`

| Column Name | Data Type | Description | Key Info |
| :--- | :--- | :--- | :--- |
| **product_key** | `BIGINT` | Surrogate Key generated for the DWH. | **[PK]** |
| **product_id** | `INT` | Original Product ID. | [Business Key] |
| **product_number** | `VARCHAR` | Unique product SKU/Code. | |
| **product_name** | `VARCHAR` | Name of the product. | |
| **category_id** | `VARCHAR` | Category ID used for joining. | |
| **category** | `VARCHAR` | Main product category (e.g., Components, Bikes). | |
| **subcategory** | `VARCHAR` | Granular product subcategory. | |
| **maintenance** | `VARCHAR` | Maintenance requirements. | |
| **cost** | `INT` | Manufacturing cost of the product. | |
| **product_line** | `VARCHAR` | Product line classification (Mountain, Road, etc.). | |
| **start_date** | `DATE` | The date the product became active. | |

### 3. `gold.fact_sales`
**Type:** Fact View
**Description:** Transactional table containing sales orders, quantities, and revenue details.
**Source:** `silver.crm_sales_details`

| Column Name | Data Type | Description | Key Info |
| :--- | :--- | :--- | :--- |
| **order_number** | `VARCHAR` | Unique order identifier. | **[PK]** |
| **product_key** | `BIGINT` | Foreign Key linking to `dim_products`. | **[FK]** |
| **customer_key** | `BIGINT` | Foreign Key linking to `dim_customers`. | **[FK]** |
| **order_date** | `DATE` | Date the order was placed. | |
| **shipping_date** | `DATE` | Date the order was shipped. | |
| **due_date** | `DATE` | Date the payment/delivery was due. | |
| **sales_amount** | `INT` | Total revenue of the sale. | |
| **quantity** | `INT` | Number of units sold. | |
| **price** | `INT` | Unit price of the product. | |

---

## 🥈 Silver Layer (Cleansed)

The Silver layer holds data that has been cleaned, standardized, and type-cast.

### CRM Source Tables
* **`silver.crm_cust_info`**:
    * *Content:* Cleaned customer data (Names trimmed, Gender/Marital Status normalized).
    * *Key Ops:* Deduplication based on `cst_id`.
* **`silver.crm_prd_info`**:
    * *Content:* Product data with `cat_id` extracted and dates cast to `DATE`.
    * *Key Ops:* Handling NULL costs, creating `prd_end_dt`.
* **`silver.crm_sales_details`**:
    * *Content:* Sales transactions with corrected date formats.
    * *Key Ops:* Data consistency checks (`Sales = Qty * Price`), invalid date handling.

### ERP Source Tables
* **`silver.erp_cust_az12`**:
    * *Content:* Extra customer details (Birthdate, Gender).
    * *Key Ops:* Prefix removal from IDs (`NAS`), future birthdate cleanup.
* **`silver.erp_loc_a101`**:
    * *Content:* Customer location data.
    * *Key Ops:* Country code standardization (e.g., 'DE' -> 'Germany').
* **`silver.erp_px_cat_g1v2`**:
    * *Content:* Product Category master data.
    * *Key Ops:* Whitespace trimming.

---

## 🥉 Bronze Layer (Raw)

Raw ingestion tables. Data is loaded here directly from source files (CSV) with `TRUNCATE` + `INSERT` logic.

* `bronze.crm_cust_info`
* `bronze.crm_prd_info`
* `bronze.crm_sales_details`
* `bronze.erp_cust_az12`
* `bronze.erp_loc_a101`
* `bronze.erp_px_cat_g1v2`
