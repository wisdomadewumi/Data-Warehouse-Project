# Data Catalog: Gold Layer

## Overview
The Gold Layer represents the final stage of data transformation, aggregating cleansed and structured data from the Silver Layer to provide a high-quality, analytical-ready dataset. This layer supports business intelligence, reporting, and advanced analytics by offering well-defined dimension and fact tables that enhance data consistency, integrity, and performance.

---

### 1. **Dimension: gold.dim_customers**
- **Purpose:** Consolidates customer-related data from multiple source systems (CRM, ERP, and Location datasets). It provides a single customer reference, ensuring accurate customer profiling, segmentation, and analytics.
- **Columns:**

| Column Name      | Data Type     | Description                                                                                   |
|------------------|---------------|-----------------------------------------------------------------------------------------------|
| customer_key     | INT           | Surrogate primary key for the customer dimension.               |
| customer_id      | INT           | Unique numerical identifier assigned to each customer.                                        |
| customer_number  | NVARCHAR(50)  | Alphanumeric identifier representing the customer, used for tracking and referencing.         |
| first_name       | NVARCHAR(50)  | First name of the customer, as recorded in the system.                                         |
| last_name        | NVARCHAR(50)  | Last name or family name of the customer.                                                     |
| country          | NVARCHAR(50)  | The country of residence for the customer (e.g., 'Australia').                               |
| marital_status   | NVARCHAR(50)  | The marital status of the customer (e.g., 'Married', 'Single').                              |
| gender           | NVARCHAR(50)  | The gender of the customer (e.g., 'Male', 'Female', 'n/a').                                  |
| birthdate        | DATE          | The date of birth of the customer, formatted as YYYY-MM-DD (e.g., 1971-10-06).               |
| create_date      | DATE          | The date when the customer account was created in the system.|

---

### 2. **Dimension: gold.dim_products**
- **Purpose:** provides a unified product catalog, integrating product information from CRM and ERP systems. It ensures that only active products are available for analysis and reporting.
- **Columns:**

| Column Name         | Data Type     | Description                                                                                   |
|---------------------|---------------|-----------------------------------------------------------------------------------------------|
| product_key         | INT           | Surrogate key uniquely identifying each product record in the product dimension table.         |
| product_id          | INT           | A unique identifier assigned to the product for internal tracking and referencing.            |
| product_number      | NVARCHAR(50)  | A structured alphanumeric code representing the product, often used for categorization or inventory. |
| product_name        | NVARCHAR(50)  | Descriptive name of the product, including key details such as type, color, and size.         |
| category_id         | NVARCHAR(50)  | A unique identifier for the product's category, linking to its high-level classification.     |
| category            | NVARCHAR(50)  | The broader classification of the product (e.g., Bikes, Components) to group related items.  |
| subcategory         | NVARCHAR(50)  | A more detailed classification of the product within the category, such as product type.      |
| maintenance_required| NVARCHAR(50)  | Indicates whether the product requires maintenance (e.g., 'Yes', 'No').                       |
| cost                | INT           | The cost or base price of the product, measured in monetary units.                            |
| product_line        | NVARCHAR(50)  | The specific product line or series to which the product belongs (e.g., Road, Mountain).      |
| start_date          | DATE          | The date when the product became available for sale or use, stored in|

---

### 3. **Fact: gold.fact_sales**
- **Purpose:** Provides sales transaction data, linking customers, products, and sales activities. It is used for sales performance tracking, revenue analysis, and forecasting.
- **Columns:**

| Column Name     | Data Type     | Description                                                                                   |
|-----------------|---------------|-----------------------------------------------------------------------------------------------|
| order_number    | NVARCHAR(50)  | A unique alphanumeric identifier for each sales order (e.g., 'SO54496').                      |
| product_key     | INT           | Surrogate key linking the order to the product dimension table.                               |
| customer_key    | INT           | Surrogate key linking the order to the customer dimension table.                              |
| order_date      | DATE          | The date when the order was placed.                                                           |
| shipping_date   | DATE          | The date when the order was shipped to the customer.                                          |
| due_date        | DATE          | The date when the order payment was due.                                                      |
| price           | INT           | The price per unit of the product for the line item, in whole currency units (e.g., 25).   |
| quantity        | INT           | The number of units of the product ordered for the line item (e.g., 1).                       |
| sales_amount    | INT           | The total revenue generated from the sale for the line item, in whole currency units (e.g., 25).      |


## Conclusion

The Gold Layer ensures that all customer, product, and sales data is accurate, structured, and ready for analysis. These views allow efficient data querying, reporting, and dashboard creation while maintaining referential integrity and consistency.