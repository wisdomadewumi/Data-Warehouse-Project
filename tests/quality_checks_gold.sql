/*
=============================================
	Data Quality Checks in Gold Layer
=============================================

Script Purpose:
	This script performs data validation on the Gold Layer (gold schema) to ensure data integrity, consistency, and accuracy before analytical use.

Highlights:
	1. Validating gold.dim_customers
	- Detecting Duplicate Records: Ensures that the JOIN logic between CRM, ERP, and location data does not introduce duplicates in cst_id.
	- Resolving Data Integration Issues (Gender Conflict): Compares cst_gndr (CRM) and gen (ERP) to standardize gender values, ensuring CRM is the master source.
	- Final Validation: Confirms that gold.dim_customers reflects the correct transformations after cleaning.

	2. Validating gold.dim_products
	- Filtering Out Historical Data: Removes inactive products (prd_end_dt IS NULL) to maintain an up-to-date product list.
	- Ensuring Unique Product Keys: Detects potential duplicate product entries to maintain a clean, single version of each product.
	- Final Validation: Ensures that gold.dim_products meets the expected structure and content.
	
	3. Validating gold.fact_sales
	- Identifying Duplicate Orders: Detects cases where the same order_number appears more than once, preventing overcounting in sales reports.
	- Foreign Key Integrity Check: Ensures that every fact record has a valid customer_key and product_key, preventing orphaned records.
	- Final Validation: Ensures that gold.fact_sales is correctly linked with dimension tables.
*/



/*
======================================
1. Transforming gold.dim_customers
======================================
*/

--1. After joining tables, check if any duplicates were introduced by the JOIN logic

SELECT cst_id, COUNT(*)
FROM (
SELECT
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON		  ci.cst_key = la.cid
) t
GROUP BY cst_id
HAVING COUNT(*) > 1


-- 2. Data Integration Issue from 2 different gender columns?
-- The distinct pairs show the possible combinations but we have data that isn't matching. Nevertheless, the crm_cust_info table is correct when in doubt. Now we have to add the missing values from the gender column on erp_cust_az12

SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is master for gender info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS new_gen
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
ON		  ci.cst_key = la.cid
ORDER BY ci.cst_gndr


-- Final Check
SELECT * FROM gold.dim_customers



/*
======================================
2. Transforming gold.dim_products
======================================
*/

-- 1. Removing historization data from products

SELECT
	pn.prd_id AS product_key,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS sub_category,
	pn.prd_key AS product_id,
	pn.prd_nm AS product_name,
	pn.prd_line AS product_line,
	pn.prd_cost AS product_cost,
	pn.prd_start_dt AS product_start_date,
	pn.prd_end_dt AS product_end_date,
	pc.maintenance AS maintenance
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL -- This is to filter out record history of old product fields


--2. Check if product key is unique i.e. has no duplicates

SELECT product_key, COUNT(*)
FROM (
	SELECT
		pn.prd_id AS product_key,
		pn.prd_key AS product_id,
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
) t
GROUP BY product_key
HAVING COUNT(*) > 1


-- Final Check
SELECT * FROM gold.dim_products


/*
======================================
3. Transforming gold.fact_sales
======================================
*/

SELECT order_number, COUNT(*)
FROM (
SELECT
	sd.sls_ord_num AS order_number,
	dp.product_key AS product_key,
	dc.customer_key AS customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS ship_date,
	sd.sls_due_dt AS due_date,
	sd.sls_price AS price,
	sd.sls_quantity AS quantity,
	sd.sls_sales AS sales
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_customers AS dc
ON sd.sls_cust_id = dc.customer_id
LEFT JOIN gold.dim_products AS dp
ON sd.sls_prd_key = dp.product_number
) t
GROUP BY order_number
HAVING COUNT(*) > 1



-- Foreign Key Integrity Check
-- We're checking if all dimension tables can successfully join to the fact table

SELECT *
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products AS p
ON p.product_key = f.product_key
WHERE c.customer_key IS NULL
OR p.product_key IS NULL


-- Final Check
SELECT * FROM gold.fact_sales