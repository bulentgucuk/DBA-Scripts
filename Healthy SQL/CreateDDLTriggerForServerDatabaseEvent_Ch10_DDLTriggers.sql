/* Healthy SQL - Chapter 10 - Surviving the Audit - Section DDL Triggers - 
    please run these separately as needed and refer to the book for proper context and run instructions */

	
/*create a DDL trigger for ALL login events on SQL Server */
CREATE Trigger on ALL Server for DDL_LOGIN_Events


/*To raise a message in response to triggering a server-level login event, run: */

Create trigger ddl_trigger_logins on ALL Server for DDL_LOGIN_Events
as Print 'You cannot create Logins in this server. This action is not permitted'
Rollback;


/*To test DDL Trigger for login events run the following */

CREATE LOGIN PleaseCreateMyLogin WITH PASSWORD = 'AintGonnaHappen';
GO

/*Create a DDL trigger to respond to database events, such a CREATE, ALTER, and DROP objects.
The syntax for this for tables is as follows:*/

CREATE Trigger test_ddl_dbtrigger on Database for CREATE_TABLE, DROP_TABLE, ALTER_TABLE
GO


/*To raise an error and prevent any attempts of creating new tables, create this trigger:*/

Create TRIGGER ddl_database_prevent_tables ON DATABASE
FOR CREATE_TABLE AS PRINT 'CREATE TABLE Issued.'
select eventdata() RAISERROR
('New tables cannot be created in this database.', 16, 1) ROLLBACK ;

/*Test the database DDL trigger just created by issuing the following tsql statement:*/
Create Table NoChance (
col1 nchar(50)
)

/*To disable the DDL triggers, you can run - Caution Be aware when running the previous script with ALL because it will in fact disable all DDL server
triggers. You can replace ALL with the actual name of the individual trigger.*/

USE Database;
GO
DISABLE Trigger ALL ON ALL SERVER;
GO

