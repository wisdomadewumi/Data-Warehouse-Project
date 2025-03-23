/*
======================================
	Cleaning & Loading Silver Tables
======================================
*/


/*
----------------
1. bronze.crm_cust_info to silver.crm_cust_info
----------------
*/

PRINT '>> Truncating Table: silver.crm_cust_info';
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Inserting Data Into: silver.crm_cust_info';
INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
)

SELECT
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE
		WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
		WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		ELSE 'n/a'
	END AS cst_marital_status,
	CASE
		WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		ELSE 'n/a'
	END AS cst_gndr,
	cst_create_date
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
) t -- This subquery ranks customer list
WHERE flag_last = 1 -- Allows us to have unique customer IDs
;


/*
In summary,
	- Unwanted trailing spaces were removed from cst_firstname & cst_lastname using TRIM()
	- Data was normalized i.e. coded values were mapped to meaningful, user-friendly descriptions on cst_marital_status & cst_gndr
	- Missing values were handled as NULLS and blanks were converted to a default value e.g: cst_marital_status & cst_gndr
	- Duplicate values were removed by the subquery flag_last column
*/



/*
----------------
2. bronze.crm_prd_info to silver.crm_prd_info
----------------
*/

PRINT '>> Truncating Table: silver.crm_prd_info';
TRUNCATE TABLE silver.crm_prd_info;
PRINT '>> Inserting Data Into: silver.crm_prd_info';
INSERT INTO silver.crm_prd_info (
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)

SELECT
	prd_id,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
	prd_nm,
	ISNULL(prd_cost, 0) AS prd_cost,
	CASE UPPER(TRIM(prd_line))
		WHEN 'M' THEN 'Mountain'
		WHEN 'R' THEN 'Road'
		WHEN 'S' THEN 'Other Sales'
		WHEN 'T' THEN 'Touring'
		ELSE 'n/a'
	END AS prd_line,
	CAST(prd_start_dt AS DATE) AS prd_start_dt,
	CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info
;



/*
In summary,
	- Derived columns (cat_id & prd_key) were created by transforming the existing prd_key column
	- Product line codes were mapped to meaningful, user-friendly descriptions for prd_line
	- Missing values were handled as NULLS were converted to 0 using ISNULL() on prd_cost and a default value on prd_line
	- prd_start_dt and prd_end_dt datatype were casted from DATETIME to DATE
	- Data enrichment (add new relevant data to enhance the dataset for analysis) was performed on prd_end_dt to provide a more logical value for the price date change on a specific product category
*/


/*
----------------
3. bronze.crm_sales_details to silver.crm_sales_details
----------------
*/

PRINT '>> Truncating Table: silver.crm_sales_details';
TRUNCATE TABLE silver.crm_sales_details;
PRINT '>> Inserting Data Into: silver.crm_sales_details';
INSERT INTO silver.crm_sales_details (
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)

SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE
		WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_order_dt,
	CASE
		WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,
	CASE
		WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,
	CASE
		WHEN sls_sales <=0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,
	sls_quantity,
	CASE
		WHEN sls_price <= 0 OR sls_price IS NULL THEN sls_sales / NULLIF(sls_quantity, 0)
		ELSE sls_price
	END AS sls_price
FROM bronze.crm_sales_details
;



/*
In summary,
	- Invalid values for dates were handled by converting to NULL on sls_order_dt, sls_ship_dt and sls_due_dt
	- sls_order_dt, sls_ship_dt and sls_due_dt datatype were casted from INT to VARCHAR to DATE
	- Missing, invalid and incorrect values were managed by Deriving columns (sls_sales & sls_price) from already existing columns (sls_sales, sls_quantity & sls_price)
*/


/*
----------------
4. bronze.erp_cust_az12 to silver.erp_cust_az12
----------------
*/

PRINT '>> Truncating Table: silver.erp_cust_az12';
TRUNCATE TABLE silver.erp_cust_az12;
PRINT '>> Inserting Data Into: silver.erp_cust_az12';
INSERT INTO silver.erp_cust_az12 (
	cid,
	bdate,
	gen
)

SELECT
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	CASE
		WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS bdate,
	CASE
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12
;



/*
In summary,
	- Invalid values for customer id and birthdates were handled by removing NAS prefix on cid and converting birthdate above GETDATE(). Note: my current date - 22/03/2025 23:00 GMT+1
	- Gender codes were mapped to meaningful, user-friendly descriptions for gen while its missing values were managed (converted to a default value)
*/


/*
----------------
5. bronze.erp_loc_a101 to silver.erp_loc_a101
----------------
*/

PRINT '>> Truncating Table: silver.erp_loc_a101';
TRUNCATE TABLE silver.erp_loc_a101;
PRINT '>> Inserting Data Into: silver.erp_loc_a101';
INSERT INTO silver.erp_loc_a101 (
	cid,
	cntry
)

SELECT
	REPLACE(cid, '-', '') AS cid,
	CASE
		WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		ELSE TRIM(cntry)
	END AS cntry
FROM bronze.erp_loc_a101
;



/*
In summary,
	- Invalid values for customer id and birthdates were handled by removing hypen on cid
	- Country codes were mapped to meaningful, user-friendly descriptions for cntry while the missing values were managed (converted to a default value)
	- Unwanted spaces have also been removed
*/


/*
----------------
6. bronze.erp_px_cat_g1v2 to silver.erp_px_cat_g1v2
----------------
*/

PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
TRUNCATE TABLE silver.erp_px_cat_g1v2;
PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
INSERT INTO silver.erp_px_cat_g1v2 (
	id,
	cat,
	subcat,
	maintenance
)

SELECT
	id,
	TRIM(cat) AS cat,
	TRIM(subcat) AS subcat,
	TRIM(maintenance) AS maintenance
FROM bronze.erp_px_cat_g1v2
;



/*
No big changes in this block as everything checks out
*/