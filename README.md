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
├── datasets/               # Raw CSV files (ERP & CRM sources)
├── scripts/                # SQL scripts for ETL processes
│   ├── init_database.sql   # DDL: Schemas and Tables creation
│   └── insert_bronze.psql  # DML: Bulk loading data into Bronze layer
├── README.md               # Project documentation
└── LICENSE                 # MIT License
```
---

## 🚀 How to Run

### Step 1: Databae Initialization

---

## License

This project is licenced under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.
