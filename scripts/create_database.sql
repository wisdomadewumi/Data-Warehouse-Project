/*
===========================================================================
Create Database and Schemas
===========================================================================
Script Purpose:
	This SQL Server script is used to drop and recreate the DataWarehouse database. It ensures that an existing database with the same name is first removed, then a fresh version is created.
	Additionally, it sets up three schemas:
	- bronze (raw data)
	- silver (cleaned and transformed data)
	- gold (aggregated and business-ready data)

⚠️ WARNING 🚨:
	This script will permanently delete the existing DataWarehouse database, along with all its data and objects. Ensure you back up any important data before executing this script.
*/

USE master;
GO

-- Drop and recreate the database 'DataWarehouse'
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	DECLARE @confirm CHAR(1);
	PRINT 'WARNING: This will permanently delete the DataWarehouse database and all its data!';
	PRINT 'Enter Y to proceed or any other key to cancel:';
	
	-- Read user input
	SET @confirm = 'N'; -- Default value to prevent accidental deletion
	
	IF @confirm = 'Y'
	BEGIN
		ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		DROP DATABASE DataWarehouse;
		PRINT 'Database DataWarehouse has been dropped.';
	END

	ELSE
	BEGIN
		PRINT 'Operation canceled. The database has NOT been dropped.';
		RETURN;
	END
END
GO

-- Create the Database of Interest 'DataWarehouse'
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

PRINT 'Database and schemas have been created successfully.';
