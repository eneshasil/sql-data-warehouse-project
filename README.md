# PostgreSQL Data Warehouse Project

This project builds a modern, scalable Data Warehouse (DWH) solution using **PostgreSQL**. It implements a **Medallion Architecture** (Bronze, Silver, Gold) to process raw data from ERP and CRM systems, transforming it into a high-quality, analytical-ready Star Schema.

---

## 🏗 Architecture & Workflow

The project follows the **ELT (Extract, Load, Transform)** pattern.

### 1. Bronze Layer (Raw)
* **Schema:** `bronze`
* **Purpose:** Raw data ingestion from CSV files.
* **Process:** Full Load (Truncate & Insert).
* **Key Features:** Fast ingestion, original data preservation.

### 2. Silver Layer (Cleansed & Standardized)
* **Schema:** `silver`
* **Purpose:** Data cleaning, normalization, and standardization.
* **Transformations:**
    * Null handling & deduplication.
    * Date normalization & type casting.
    * Domain value standardization (e.g., Country codes, Gender).
* **Architecture:** Modular Stored Procedures orchestrated by a master script with error handling and logging.

### 3. Gold Layer (Curated & Business Ready)
* **Schema:** `gold`
* **Purpose:** Reporting and BI.
* **Model:** **Star Schema** (Dimensional Modeling).
* **Components:**
    * **Dimensions:** `dim_customers`, `dim_products` (Surrogate Keys, SCD handling).
    * **Facts:** `fact_sales` (Transactional data with Foreign Keys).

---

## 📂 Project Structure

```text
sql-data-warehouse-project/
├── datasets/                   # Raw CSV files (Source Data: ERP & CRM)
├── docs/                       # Project Documentation
│   ├── data_catalog.md         # Detailed description of tables and columns
│   └── naming_conventions.md   # Naming standards for tables, columns, and procedures
├── scripts/                    # SQL Scripts for ELT
│   ├── init_database.sql       # Schema initialization
│   ├── bronze/                 # Bronze Layer Setup & Load
│   │   ├── ddl_bronze.sql      # Create Bronze tables
│   │   └── proc_load_bronze.sql# Stored Procedures for loading Bronze
│   ├── silver/                 # Silver Layer Transformation
│   │   ├── ddl_silver.sql      # Create Silver tables
│   │   ├── proc_silver_workers.sql # Transformation logic per table
│   │   └── proc_silver_load.sql    # Master Orchestrator (Logging & Error Handling)
│   └── gold/                   # Gold Layer Modeling
│       └── ddl_gold.sql        # Views for Dimensions and Facts (Star Schema)
├── tests/                      # Data Quality (DQ) & Validation
│   ├── quality_checks_silver.sql # DQ checks for Silver (Nulls, Duplicates, Logic)
│   └── quality_checks_gold.sql   # DQ checks for Gold (Referential Integrity)
├── README.md                   # Project Overview
└── LICENSE                     # MIT License
```
---

## License

This project is licenced under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.
