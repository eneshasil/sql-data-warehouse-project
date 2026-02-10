# Naming Conventions

This document outlines the naming standards and conventions used throughout the Data Warehouse project. Adhering to these rules ensures consistency, readability, and maintainability across the Bronze, Silver, and Gold layers.

---

## 1. General Rules

* **Case:** All database objects (schemas, tables, columns, procedures) must use **lowercase**.
* **Separator:** Use **snake_case** (underscores `_`) to separate words.
* **Language:** English.
* **Characters:** Only alphanumeric characters (`a-z`, `0-9`) and underscores (`_`). No spaces or special characters.

---

## 2. Layer & Schema Structure

The project follows the Medallion Architecture with specific schemas for each layer:

| Layer | Schema Name | Purpose |
| :--- | :--- | :--- |
| **Bronze** | `bronze` | Raw ingestion layer. Maintains original source structure. |
| **Silver** | `silver` | Cleansed and standardized layer. Enriched data. |
| **Gold** | `gold` | Curated business layer (Star Schema). |

---

## 3. Table Naming Conventions

### Bronze & Silver Layers
Tables in these layers reflect the source system and the entity.

* **Pattern:** `[source_system]_[entity]_[details]`
* **Examples:**
    * `crm_cust_info` (Source: CRM, Entity: Customer Info)
    * `erp_loc_a101` (Source: ERP, Entity: Location, Code: A101)
    * `crm_sales_details`

### Gold Layer
Tables in the Gold layer follow Dimensional Modeling (Star Schema) standards.

* **Dimensions:** `dim_[entity_name]` (Plural)
    * Example: `dim_customers`, `dim_products`
* **Facts:** `fact_[process_name]` (Plural)
    * Example: `fact_sales`

---

## 4. Column Naming Conventions

### Bronze & Silver Layers (Technical Names)
Columns often use abbreviated prefixes to indicate the source table or entity.

* **Pattern:** `[abbreviation]_[attribute]`
* **Examples:**
    * **Customer Table (`cst_`):** `cst_id`, `cst_firstname`, `cst_key`
    * **Product Table (`prd_`):** `prd_id`, `prd_cost`, `prd_start_dt`
    * **Sales Table (`sls_`):** `sls_ord_num`, `sls_quantity`
* **Exception:** Some ERP columns retain their original source codes (e.g., `cid`, `bdate`, `gen`) if widely understood or required for lineage.

### Gold Layer (Business Names)
Columns in the Gold layer must be user-friendly, descriptive, and readable for BI tools. No cryptic abbreviations.

* **Surrogate Keys:** `[entity]_key` (e.g., `customer_key`, `product_key`)
* **Business Keys:** `[entity]_id` or `[entity]_number` (e.g., `customer_id`, `order_number`)
* **Dates:** `[event]_date` (e.g., `order_date`, `shipping_date`, `create_date`)
* **Attributes:** Full English words (e.g., `marital_status` instead of `cst_marital_status`).

---

## 5. Stored Procedures & Scripts

Procedures are named based on the layer they populate and the target table.

* **Pattern:** `[layer].load_[target_table_name]`
* **Examples:**
    * `silver.load_crm_cust_info`
    * `silver.load_crm_sales_details`
    * `silver.load_silver` (Orchestration procedure)

---

## 6. Views

Views used for monitoring or intermediate logic use a specific prefix to distinguish them from physical tables.

* **Pattern:** `v_[view_purpose]`
* **Examples:**
    * `bronze.v_load_summary`
    * `bronze.v_load_detail_summary`

---

## 7. Standard Abbreviations

| Abbreviation | Full Term | Usage Context |
| :--- | :--- | :--- |
| `cst` | Customer | CRM Customer tables |
| `prd` | Product | CRM Product tables |
| `sls` | Sales | CRM Sales tables |
| `ord` | Order | Order numbers/dates |
| `dt` | Date | Bronze/Silver columns (`start_dt`) |
| `nm` | Name | Bronze/Silver columns (`prd_nm`) |
| `dim` | Dimension | Gold tables |
| `fact` | Fact | Gold tables |
| `dwh` | Data Warehouse | Metadata columns (`dwh_create_date`) |
