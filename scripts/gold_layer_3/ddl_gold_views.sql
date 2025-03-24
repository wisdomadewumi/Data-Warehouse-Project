/*
===========================================================================
DDL Script: Create Gold Views
===========================================================================
Script Purpose:
	This script creates dimension and fact views in the Gold Layer, transforming Silver Layer data into a structured, analytical format for reporting and business intelligence.

Key Higlights:
	1. Dimension Tables (dim_customers & dim_products):
	- Establish surrogate keys (customer_key, product_key) for efficient querying.
	- Integrate data from multiple Silver Layer tables, ensuring enriched, clean, and standardized attributes.
	- Handle missing values and inconsistencies, such as gender standardization and active product filtering.

	2. Fact Table (fact_sales):
	- Link sales transactions to their respective customers and products using surrogate keys for optimized joins.
	- Provide structured sales data with order, shipping, and due dates for time-based analysis.
	- Maintain data integrity by ensuring all referenced dimensions exist.
*/


/*
======================================
1. Creating Dimension: VIEW gold.dim_customers
======================================
*/

IF OBJECT_ID ('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- Creating surrogate key for View. New Primary Key
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS date_of_birth,
	ci.cst_create_date AS create_date	
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
	ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
	ON ci.cst_key = la.cid
;
GO


/*
======================================
2. Creating Dimension: VIEW gold.dim_products
======================================
*/

IF OBJECT_ID ('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Creating surrogate key for View. New Primary Key
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance AS maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
	ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL
;
GO


/*
======================================
3. Creating Fact: VIEW gold.fact_sales
======================================
*/

IF OBJECT_ID ('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
	sd.sls_ord_num AS order_number,
	dp.product_key, --Foreign Key
	dc.customer_key, --Foreign Key
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS ship_date,
	sd.sls_due_dt AS due_date,
	sd.sls_price AS price,
	sd.sls_quantity AS quantity,
	sd.sls_sales AS sales_amount
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_customers AS dc
	ON sd.sls_cust_id = dc.customer_id
LEFT JOIN gold.dim_products AS dp
	ON sd.sls_prd_key = dp.product_number
;
GO