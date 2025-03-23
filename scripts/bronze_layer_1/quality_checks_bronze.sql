/*
=============================================
	Data Quality Checks in Bronze Tables
=============================================
*/


/*
----------------
1. bronze.crm_cust_info
----------------
*/

SELECT * FROM bronze.crm_cust_info

-- 1. Check for NULLS or duplicates in Primary Key
-- Expectation: No Result

SELECT
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL


-- 2. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT
	cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT
	cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT
	cst_marital_status
FROM bronze.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

SELECT
	cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);


-- 3. Data Standardization & Consistency
SELECT
	DISTINCT cst_marital_status
	--DISTINCT cst_gndr
FROM bronze.crm_cust_info


/*
----------------
2. bronze.crm_prd_info
----------------
*/

SELECT
	prd_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
FROM bronze.crm_prd_info


-- 1. Check for NULLS or duplicates in Primary Key
-- Expectation: No Result

SELECT
	prd_id,
	COUNT(*)
FROM bronze.crm_prd_info
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
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN
(SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2)

SELECT
	prd_id,
	prd_key,
	--REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN
(SELECT sls_prd_key FROM bronze.crm_sales_details)


-- 3. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT
	prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);


-- 4. Check for NULLs or Negative Numbers
-- Expectation: No Results
SELECT
	prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;


-- 5. Data Standardization & Consistency (Low cardinality)
SELECT
	DISTINCT prd_line
FROM bronze.crm_prd_info;


-- 6. Check for Invalid Date orders (End date cannot be earlier than Start date)
-- Since some end dates do not meet the criteria above, we use the LEAD() function to create a new column for End date where an old price terminates on the eve of the date of a newer price
SELECT
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt2
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509', 'AC-HE-HL-U509-R')
--WHERE prd_end_dt < prd_start_dt
;


/*
----------------
3. bronze.crm_sales_details
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
FROM bronze.crm_sales_details;

-- 1. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT
	sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);


-- 2. Check column integrity
-- Expectation: No Results
-- sls_prd_key should be housed in newly transformed prd_info table
-- sls_cust_id should also be housed in the newly transformed cust_info table

SELECT
	sls_ord_num,
	sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

SELECT
	sls_ord_num,
	sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);


-- 3. Check for Invalid Dates
-- Dates are showing as integers, they need to be casted as DATE but we check if there are any negative or zero values (Zeros are to be converted to NULLs).

SELECT
	NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <=0
OR LEN(sls_order_dt) != 8 -- 8 because the dates have 8 digits
OR sls_order_dt > 20500101 -- Upper limit date boundary check
OR sls_order_dt < 19000101 -- Lower limit date boundary check
;

SELECT
	sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <=0
OR LEN(sls_ship_dt) != 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101
;

SELECT
	sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <=0
OR LEN(sls_due_dt) != 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101
;


-- 4. Check for Invalid Date orders
SELECT
	*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
OR sls_order_dt > sls_due_dt
OR sls_ship_dt > sls_due_dt
;

-- 5. Check Sales, Quantity and Price
-- Business rules: sales must equal quantity * price and the negative, zero and NULL values are not allowed
-- Best practice: Discuss about next steps to handle bad data at this level with the experts

SELECT
	sls_sales AS old_sls_sales,
	CASE
		WHEN sls_sales <=0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
		--WHEN sls_price = 0 OR sls_price IS NULL THEN sls_sales / sls_quantity * sls_quantity
		ELSE sls_sales
	END AS sls_sales,
	sls_quantity,
	sls_price AS old_sls_price,
	CASE
		WHEN sls_price <= 0 OR sls_price IS NULL THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0
ORDER BY sls_sales, sls_quantity, sls_price

-- Rules
-- If sales is negative, zero or NULL, derive it using quantity and price
-- If price is zero or null, calculate it using sales and quantity
-- If price is negative, convert it to a positive value


/*
----------------
4. bronze.erp_cust_az12
----------------
*/

SELECT
	cid,
	bdate,
	gen
FROM bronze.erp_cust_az12


-- 1. Check uniformity of customer ID
-- cid column has two variants for customer identification: 'NASAW%' and 'AW%'. We can transform it via a CASE WHEN statement.

SELECT
	cid AS old_cid,
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	bdate,
	gen
FROM bronze.erp_cust_az12
WHERE
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)


-- 2. Identify out-of-range dates
SELECT
	bdate AS old_bdate,
	CASE
		WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS bdate
FROM bronze.erp_cust_az12
-- WHERE bdate < '1924-01-01' OR bdate > GETDATE()
;


-- 3. Data Standardization & Consistency (Low cardinality)
SELECT DISTINCT
	gen AS old_gen,
	CASE
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12
;


/*
----------------
5. bronze.erp_loc_a101
----------------
*/

SELECT * FROM bronze.erp_loc_a101;
SELECT cst_key FROM silver.crm_cust_info;


-- 1. Check for unwanted characters in cid
SELECT
	cid,
	REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN
(SELECT cst_key FROM silver.crm_cust_info)



-- 2. Data Standardization & Consistency (Low cardinality)
SELECT DISTINCT
	cntry AS old_cntry,
	CASE
		WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		ELSE TRIM(cntry)
	END AS cntry
FROM bronze.erp_loc_a101
ORDER BY cntry
;


/*
----------------
6. bronze.erp_px_cat_g1v2
----------------
*/

SELECT id FROM bronze.erp_px_cat_g1v2;
SELECT cat_id FROM silver.crm_prd_info;


-- 1. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT
	cat
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat);

SELECT
	subcat
FROM bronze.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat);

SELECT
	maintenance
FROM bronze.erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance);


-- 2. Check Data Standardization & Consistency (Low cardinality)
SELECT DISTINCT
	cat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT
	subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT
	maintenance
FROM bronze.erp_px_cat_g1v2;