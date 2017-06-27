/* Healthy SQL - Chapter 10 - Surviving the Audit - Change Data Capture - 
    please run these separately as needed and refer to the book for proper context and run instructions */

Use AdminDB -- use this db, as created in previous section to follow book
GO
exec sys.sp_cdc_enable_db
Go

/*Confirm which databases have CDC enabled by running the following:*/

select name, is_cdc_enabled from sys.databases

/*To enable CDC on each table, use this:*/

exec sys.sp_cdc_enable_table [TABLENAME]

/*For this demo, you will enable CDC on the SQLConfig_Changes table by executing the following
statement:*/
EXEC sys.sp_cdc_enable_table
@source_schema = N'dbo',
@source_name = N'SQLConfig_Changes',
@role_name = NULL
GO

/* To confirm which tables have CDC enabled and see that the SQLConfig_Changes table is now CDC
enabled, run the following: */
select name, is_tracked_by_cdc from sys.tables

/*make a change to SQLConfig_Changes table by inserting a configuration change.*/

sp_configure xp_cmdshell, 1
go
reconfigure with override
go

/*Query the associated CDC table, in this example, [cdc].[dbo_SQLConfig_Changes_CT].*/

select __$operation,TextData,HostName,
ApplicationName,DatabaseName, LoginName,
SPID, StartTime, EventSequence
from [cdc].[dbo_SQLConfig_Changes_CT]

/*To turn off Change Data Capture on a table, use this:*/

exec sys.sp_cdc_disable_table
@source_schema = N'dbo',
@source_name = N'SQLConfig_Changes', -- sample table name
@role_name = NULL
GO

/* Disable CDC on the database. */
exec sys.sp_cdc_disable_db
go

