# PostgreSQL Data Warehouse Project

This project aims to build a modern Data Warehouse (DWH) solution using **PostgreSQL**. It collects raw data from various heterogeneous sources (ERP and CRM), transforms it through a Medallion Architecture (Bronze, Silver, Gold layers), and optimizes it for Business Intelligence (BI) reporting and advanced analytics.

---

## 🏗 Architecture & Requirements

### The Data Warehouse
The project follows the **ELT (Extract, Load, Transform)** pattern to consolidate sales data, ensuring data quality and analytical readiness.

#### Specifications
- **Data Sources**: Integration of CSV exports from two distinct source systems (ERP and CRM).
- **Architecture**:
    - **Bronze Layer**: Raw data ingestion (Full Load / Truncate & Load).
    - **Silver Layer**: Data cleansing, standardization, and normalization (*Planned*).
    - **Gold Layer**: Business-ready dimensional models (Star Schema) (*Planned*).
- **Data Quality**: Automated logging and error handling during the loading process.
- **Documentation**: Comprehensive documentation for stakeholders and analytics teams.

### BI & Analytics
SQL-based analytics are developed to deliver insights into:
- **Customer Behavior**
- **Product Performance**
- **Sales Trends**

These insights empower stakeholders with key business metrics for strategic decision-making.

---

## 📂 Project Structure

```text
sql-data-warehouse-project/
├── datasets/                              # Raw CSV files (ERP & CRM sources)
├── scripts/                               # SQL scripts for ETL processes
│   ├── 01_init_database.sql               # Database Initialization (Drop & Re-create)
|   ├── 02_init_database.sql               # Schema Initialization
|   └── bronze/                            # Bronze Layer (Medallion Architecture)
│       ├── ddl_bronze.sql                 # DDL Script: Create Bronze Tables
│       ├── load_bronze.sql                # Bronze Layer Data Loading Script
│       └── proc_load_bronze_setup.sql     # DML: Bulk loading data into Bronze layer
|   └── silver/                            # Silver Layer
│       ├── ddl_silver.sql                 # DDL Script: Create Silver Tables
│       ├── worker_proc_silver.sql         # Defines the transformation and loading logic for each Silver table
│       └── orchestrator_proc_silver.sql   # This master stored procedure orchestrates the loading of the Silver layer.
├── tests/                                 # SQL scripts for Data Quality and validation checks.
|   └── quality_checks_silver.sql          # Performs data quality checks on the Silver layer.
├── README.md                              # Project documentation
└── LICENSE                                # MIT License
```
---

## License

This project is licenced under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.
