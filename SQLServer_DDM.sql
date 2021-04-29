--https://docs.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking?view=sql-server-2017
--Dynamic Data Masking quick demo script
USE DBA;
GO

IF OBJECT_ID('dbo.Membership') IS NOT NULL
	DROP TABLE dbo.Membership;

CREATE TABLE dbo.Membership  
	  (MemberID int IDENTITY CONSTRAINT PK_dbo_Membership_MemberID PRIMARY KEY CLUSTERED,  
	   FirstName varchar(50) MASKED WITH (FUNCTION = 'partial(1,"XXXXXXX",0)') NULL,  
	   LastName varchar(50) NOT NULL,  
	   Phone varchar(12) MASKED WITH (FUNCTION = 'default()') NULL,  
	   Email varchar(100) MASKED WITH (FUNCTION = 'email()') NULL);

GO 

INSERT dbo.Membership (FirstName, LastName, Phone, Email)
VALUES
	('Roberto', 'Tamburello', '555.123.4567', 'RTamburello@contoso.com'),  
	('Janice', 'Galvin', '555.123.4568', 'JGalvin@contoso.com.co'),  
	('Zheng', 'Mu', '555.123.4569', 'ZMu@contoso.net');  
GO

SELECT * FROM dbo.Membership;

GO

--Create test user for read
IF DATABASE_PRINCIPAL_ID('DDM_TestUser') IS NULL
	CREATE USER DDM_TestUser WITHOUT LOGIN;
GO

--Grant DDM_TestUser Select permission
GRANT SELECT ON Membership TO DDM_TestUser;

--Grantint DDM_TestUser db_datareader role permission does NOT allow UNMASK
ALTER ROLE db_datareader ADD MEMBER DDM_TestUser;

--CREATE TEST USER
IF DATABASE_PRINCIPAL_ID('DDM_db_owner') IS NULL
	CREATE USER DDM_db_owner WITHOUT LOGIN;
GO

-- Grant DDM_db_owner db_owner role permission
ALTER ROLE db_owner ADD MEMBER DDM_db_owner;
GO


EXECUTE AS USER = 'DDM_TestUser';
SELECT * FROM Membership;  
REVERT;  


EXECUTE AS USER = 'DDM_db_owner';
SELECT * FROM Membership;  
REVERT; 

GO

--Adding a Mask on an Existing Column
ALTER TABLE dbo.Membership
	ALTER COLUMN LastName ADD MASKED WITH (FUNCTION = 'partial(2,"XXX",0)');

EXECUTE AS USER = 'DDM_TestUser';
SELECT * FROM Membership;  
REVERT;  


EXECUTE AS USER = 'DDM_db_owner';
SELECT * FROM Membership;  
REVERT; 

GO

--Editing a Mask on an Existing Column
ALTER TABLE dbo.Membership
	ALTER COLUMN LastName varchar(100) MASKED WITH (FUNCTION = 'default()');

EXECUTE AS USER = 'DDM_TestUser';
SELECT * FROM Membership;  
REVERT;  


EXECUTE AS USER = 'DDM_db_owner';
SELECT * FROM Membership;  
REVERT; 

GO


--Granting Permissions to View Unmasked Data
GRANT UNMASK TO DDM_TestUser;
GO

EXECUTE AS USER = 'DDM_TestUser';  
SELECT * FROM Membership;  
REVERT;   
  
-- Removing the UNMASK permission  
REVOKE UNMASK TO DDM_TestUser;
GO

EXECUTE AS USER = 'DDM_TestUser';  
SELECT * FROM Membership;  
REVERT;   



--Dropping a Dynamic Data Mask
ALTER TABLE dbo.Membership
	ALTER COLUMN LastName DROP MASKED;
GO

EXECUTE AS USER = 'DDM_TestUser';  
SELECT * FROM Membership;  
REVERT;



-- Cleanup
-- Users
IF DATABASE_PRINCIPAL_ID('DDM_TestUser') IS NOT NULL
	DROP USER DDM_TestUser;
GO
IF DATABASE_PRINCIPAL_ID('DDM_db_owner') IS NOT NULL
	DROP USER DDM_db_owner;
GO

--Table
IF OBJECT_ID('dbo.Membership') IS NOT NULL
	DROP TABLE dbo.Membership;
GO
