/* 
================================================

Create Database and Schemas

================================================
Purpose: 
	This script creates a new database 'ScoringModel' if it doesn't exist yet.
	If the database exists, it's dropped and recreated. 
	Then the script creates 3 schemas that will be responsible for the appropriate segmentation of the project
	'bronze', 'silver' and 'gold'.
*/

USE master;

-- Drop and recreate the 'ScoringModel' database

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ScoringModel')
BEGIN
	ALTER DATABASE ScoringModel SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE ScoringModel;
END;
GO

-- Create the 'ScoringModel' database

CREATE DATABASE ScoringModel;
GO

USE ScoringModel;
GO

-- Create database Schemas

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
