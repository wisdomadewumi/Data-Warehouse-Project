/*
=============================================
	Data Quality Rechecks in Silver Table
=============================================

Script Purpose:
	This script ensures data integrity, consistency, and standardization in the Silver tables, which serve as a refined data layer for analytics and reporting. The checks validate data transformations from the Bronze layer and detect inconsistencies before moving to the Gold layer.

Objectives:
	1. Primary Key Integrity & Uniqueness:
	- Ensure no NULLs or duplicates in primary keys across all Silver tables.
	2. String Formatting & Cleanup:
	- Identify and remove unwanted spaces in categorical fields (e.g., names, marital status, gender).
	3. Data Standardization & Consistency:
	- Validate categorical values (e.g., marital status, gender, product lines, locations).
	- Ensure uniform customer and product IDs for accurate table joins.
	4. Numeric Data Validations:
	- Detect negative, NULL, or zero values in cost, sales, quantity, and price columns.
	- Verify business rules: sales = quantity * price.
	5. Date Integrity & Chronology Checks:
	- Identify out-of-range or invalid date formats.
	- Ensure logical ordering of dates (e.g., order date ≤ ship date ≤ due date).
	6. Relationship & Referential Integrity:
	- Verify that sales transactions reference valid customer and product IDs.
	- Ensure product categories align with reference tables.
*/


/*
----------------
1. silver.crm_cust_info
----------------
*/

-- 1. Check for NULLS or duplicates in Primary Key
-- Expectation: No Result
SELECT * FROM silver.crm_cust_info

SELECT
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL


-- 2. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT
	cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT
	cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT
	cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

SELECT
	cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);


-- 3. Data Standardization & Consistency
SELECT
	DISTINCT cst_marital_status
	--DISTINCT cst_gndr
FROM silver.crm_cust_info


-- Final Check
SELECT * FROM silver.crm_cust_info


/*
----------------
2. silver.crm_prd_info
----------------
*/


-- 1. Check for NULLS or duplicates in Primary Key
-- Expectation: No Result

SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL


-- 2. Breaking prd_key into cat_id and prd_key to facilitate joining other tables
SELECT
	prd_id,
	prd_key,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	--SUBSTRING(prd_key, 1, 5) AS cat_id,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM silver.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN
(SELECT DISTINCT id FROM silver.erp_px_cat_g1v2)

SELECT
	prd_id,
	prd_key,
	--REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key
FROM silver.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN
(SELECT sls_prd_key FROM silver.crm_sales_details)


-- 3. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT
	prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);


-- 4. Check for NULLs or Negative Numbers
-- Expectation: No Results
SELECT
	prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;


-- 5. Data Standardization & Consistency
SELECT
	DISTINCT prd_line
FROM silver.crm_prd_info;


-- 6. Check for Invalid Date orders (End date cannot be earlier than Start date)
SELECT
	*
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt
;

-- Final Check
SELECT * FROM silver.crm_prd_info


/*
----------------
3. silver.crm_sales_details
----------------
*/

SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details;

-- 1. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT
	sls_ord_num
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);


-- 2. Check column integrity
-- Expectation: No Results
-- sls_prd_key should be housed in newly transformed prd_info table
-- sls_cust_id should also be housed in the newly transformed cust_info table

SELECT
	sls_ord_num,
	sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

SELECT
	sls_ord_num,
	sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);


-- 3. Check for Invalid Dates
-- Dates are showing as integers, they need to be casted as DATE but we check if there are any negative or zero values (Zeros are to be converted to NULLs).

SELECT
	NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <=0
OR LEN(sls_order_dt) != 8 -- 8 because the dates have 8 digits
OR sls_order_dt > 20500101 -- Upper limit date boundary check
OR sls_order_dt < 19000101 -- Lower limit date boundary check
;

SELECT
	sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt <=0
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101
;

SELECT
	sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt <=0
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101
;


-- 4. Check for Invalid Date orders
SELECT
	*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
OR sls_order_dt > sls_due_dt
OR sls_ship_dt > sls_due_dt
;

-- 5. Check Sales, Quantity and Price
-- Business rules: sales must equal quantity * price and the negative, zero and NULL values are not allowed

SELECT
	sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0
ORDER BY sls_sales, sls_quantity, sls_price


-- Final Check
SELECT * FROM silver.crm_sales_details


/*
----------------
4. silver.erp_cust_az12
----------------
*/

SELECT
	cid,
	bdate,
	gen
FROM silver.erp_cust_az12


-- 1. Check uniformity of customer ID

SELECT
	cid AS old_cid,
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	bdate,
	gen
FROM silver.erp_cust_az12
WHERE
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)


-- 2. Identify out-of-range dates
SELECT
	bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()
;


-- 3. Data Standardization & Consistency (Low cardinality)
SELECT DISTINCT
	gen
FROM silver.erp_cust_az12
;


-- Final Check
SELECT * FROM silver.erp_cust_az12


/*
----------------
5. silver.erp_loc_a101
----------------
*/


-- 1. Check for unwanted characters in cid
SELECT
	cid,
	REPLACE(cid, '-', '') AS cid
FROM silver.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN
(SELECT cst_key FROM silver.crm_cust_info)



-- 2. Data Standardization & Consistency (Low cardinality)
SELECT DISTINCT
	cntry
FROM silver.erp_loc_a101
ORDER BY cntry
;


;-- Final Check
SELECT * FROM silver.erp_loc_a101


/*
----------------
6. silver.erp_px_cat_g1v2
----------------
*/

SELECT id FROM silver.erp_px_cat_g1v2;
SELECT cat_id FROM silver.crm_prd_info;


-- 1. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT
	cat
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat);

SELECT
	subcat
FROM silver.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat);

SELECT
	maintenance
FROM silver.erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance);


-- 2. Check Data Standardization & Consistency (Low cardinality)
SELECT DISTINCT
	cat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT
	subcat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT
	maintenance
FROM silver.erp_px_cat_g1v2;


;-- Final Check
SELECT * FROM silver.erp_px_cat_g1v2