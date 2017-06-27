/*HealthySQL Chapter 10 Surviving The Audit - Scripts from SQL Audit Section
  Please run them separately as needed and directed in the book */

/*Once SQL Audit is created, use this script to get current status.  
 This script was in subsection Creating an audit in SQL Server Management Studio */

SELECT * FROM sys.dm_server_audit_status
GO

/*An example of an Audit scripted out in T-SQL from SSMS */
USE [master]
GO
/****** Object:  Audit [Audit-20150408-150252]    Script Date: 4/12/2015 9:29:20 AM ******/
CREATE SERVER AUDIT [Audit-20150408-150252] -- change AuditName
TO FILE 
(	FILEPATH = N'C:\SQLAudit\' -- change path
	,MAXSIZE = 0 MB
	,MAX_ROLLOVER_FILES = 2147483647
	,RESERVE_DISK_SPACE = OFF
)
WITH
(	QUEUE_DELAY = 1000
	,ON_FAILURE = CONTINUE
	,AUDIT_GUID = '3550c2cc-9e61-417a-b045-53d226155792' -- remove parameter, system will generate GUID
)
WHERE ([database_name]='AdventureWorks2012')  -- specify your database to Audit
ALTER SERVER AUDIT [Audit-20150408-150252] WITH (STATE = OFF)/*change to "STATE=ON" to enable*/
GO

/*subsection Script Server Audit Specification - sample */
USE [master]
GO
CREATE SERVER AUDIT SPECIFICATION [DATABASE_CHANGE_AUDIT]
FOR SERVER AUDIT [Audit-20150408-150252] --should match the name of the SQLAudit created for this specification
ADD (DATABASE_CHANGE_GROUP)
WITH (STATE = OFF) /*change to STATE= ON to enable*/
GO

/*Database Audit Specification - sample script */
USE [YourDatabase_2B_Audited] -- change this to your database
GO
CREATE DATABASE AUDIT SPECIFICATION [MYDatabaseAuditSpecification] -- change this 
FOR SERVER AUDIT [Audit-20150408-150252]
ADD (SCHEMA_OBJECT_CHANGE_GROUP)
WITH (STATE = OFF)/*change to STATE=ON to enable*/
GO

/* Generating Audit Activity - create and drop database for audit */
Create Database "DetectThisDB"
Go
WAITFOR DELAY '00:00:10'
Go
Drop Database "DetectThisDB"
GO

/*generate some sample database activity. Create a table in the audited database (in my case
AdventureWorks2012) to first create a table with one column and then add another column after. */

USE [AdventureWorks2012] 
CREATE Table "AuditMe"
(col1 nvarchar(50)
)
Go
WAITFOR DELAY '00:00:10'
Go
ALTER Table "AuditMe"
ADD col2 int
GO

/*Viewing The Audit Log*/

SELECT
event_time,
succeeded,
object_id,
server_principal_name,
server_instance_name,
database_name,
schema_name,
object_name,
statement FROM
sys.fn_get_audit_file (('<Audit File Path and Name>',default,default); --put YOUR path to audit file and name
GO

