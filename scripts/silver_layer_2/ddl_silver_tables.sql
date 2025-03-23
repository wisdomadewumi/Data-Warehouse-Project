/*
===========================================================================
Data Structure Definition for CRM and ERP Data in Silver Schema
===========================================================================
Script Purpose:
	This script is a Data Definition Language (DDL) script that ensures the proper structure of tables for Customer Relationship Management (CRM) and Enterprise Resource Planning (ERP) data within the silver schema. It ensures tables are dropped before creation in case they already exist and creates six objects within the silver schema to store data for CRM and ERP. These data will later be transformed by subsequent scripts.
*/



/*
1. silver.crm_cust_info
	Stores customer details such as ID, name, marital status, gender, and creation date.
*/

IF OBJECT_ID ('silver.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
	cst_id				INT,
	cst_key				NVARCHAR(50),
	cst_firstname		NVARCHAR(50),
	cst_lastname		NVARCHAR(50),
	cst_marital_status	NVARCHAR(50),
	cst_gndr			NVARCHAR(50),
	cst_create_date		DATE,
	dwh_create_date		DATETIME2 DEFAULT GETDATE()
);
GO


/*
2. silver.crm_sales_details
	Tracks sales transactions, including order number, customer ID, product key, order dates, shipping details, and pricing information.
*/

IF OBJECT_ID ('silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
	sls_ord_num		NVARCHAR(50),
	sls_prd_key		NVARCHAR(50),
	sls_cust_id		INT,
	sls_order_dt	DATE,
	sls_ship_dt		DATE,
	sls_due_dt		DATE,
	sls_sales		INT,
	sls_quantity	INT,
	sls_price		INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*
3. silver.crm_prd_info
	Contains product details like ID, name, cost, product line, and validity dates.
*/

IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
	prd_id			INT,
	cat_id			NVARCHAR(50),
	prd_key			NVARCHAR(50),
	prd_nm			NVARCHAR(50),
	prd_cost		INT,
	prd_line		NVARCHAR(50),
	prd_start_dt	DATE,
	prd_end_dt		DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*
4. silver.erp_cust_az12
	Stores ERP customer demographic information such as customer ID, birth date, and gender.
*/

IF OBJECT_ID ('silver.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 (
	cid		NVARCHAR(50),
	bdate	DATE,
	gen		NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*
5. silver.erp_loc_a101
	Holds customer location data, mapping customer IDs to countries.
*/

IF OBJECT_ID ('silver.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 (
	cid		NVARCHAR(50),
	cntry	NVARCHAR(255),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*
6. silver.erp_px_cat_g1v2
	Contains product categorization data, including ID, category, subcategory, and maintenance status.
*/

IF OBJECT_ID ('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE silver.erp_px_cat_g1v2;
CREATE TABLE silver.erp_px_cat_g1v2 (
	id			NVARCHAR(50),
	cat			NVARCHAR(50),
	subcat		NVARCHAR(50),
	maintenance	NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
