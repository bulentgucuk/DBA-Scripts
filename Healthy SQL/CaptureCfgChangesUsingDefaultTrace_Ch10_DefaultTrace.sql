/* Healthy SQL - Chapter 10 - Surviving the Audit - Default Trace - 
    please run these separately as needed and refer to the book for proper context and run instructions */

/*subsection: Reviewing Default Trace Output 
  Create a quick sample table to use to keep the database intact. Execute 
  the following T-SQL against the AdventureWorks2012 database:*/

CREATE TABLE [dbo].[DropThisTableNow](
[Col1] [nchar](10) NULL,
[Col2] [nchar](10) NULL
) ON [PRIMARY]
GO
/*Verify that the table has been successfully created; check out in SSMS if it exists. Once confirmed, go
ahead and subsequently drop the table: */

USE [AdventureWorks2012]
GO
DROP TABLE [dbo].[DropThisTableNow]
GO

/*GetDeletedTableTrc Script as referenced in Ch10 p340-250 */

DECLARE @path NVARCHAR(260);
SELECT
@path = REVERSE(SUBSTRING(REVERSE([path]),
CHARINDEX(CHAR(92), REVERSE([path])), 260)) + N'log.trc'
FROM sys.traces
WHERE is_default = 1;
SELECT
LoginName,
HostName,
StartTime,
ObjectName,
TextData
FROM sys.fn_trace_gettable(@path, DEFAULT)
WHERE EventClass = 47 -- Object:Deleted
AND EventSubClass = 1 -- represents a single pass over the data
--AND DatabaseName = N'ENTER-DB_NAME' -- you can filter for a specific database
--AND ObjectName = N'ENTER-OBJ-TABLENAME' -- you can filter on a specificic object
ORDER BY StartTime DESC;

/* Ch10 - Default Trace - Creating the History Tracking Table */

Create Database AdminDB
Go
Now, let’s create the tracking table in the database just created or an existing one.
/****** Object: Table [dbo].[SQLConfig_Changes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SQLConfig_Changes](
[TextData] [varchar](500) NULL,
[HostName] [varchar](155) NULL,
[ApplicationName] [varchar](255) NULL,
[DatabaseName] [varchar](155) NULL,
[LoginName] [varchar](155) NULL,
[SPID] [int] NULL,
[StartTime] [datetime] NULL,
[EventSequence] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO

/*Default Trace - Methodology 
1. Create a temp table, matching the definition of the dbo.SQLConfig_Change table
to capture the needed data from the trace.*/
CREATE TABLE #temp_cfg (
TEXTData VARCHAR(500),
HostName VARCHAR(155),
ApplicationName VARCHAR(255),
DatabaseName VARCHAR(155),
LoginName VARCHAR(155),
SPID INT,
StartTime DATETIME,
EventSequence INT
)

/*2. Query for the physical path of the current active trace file on your SQL Server.*/
DECLARE @trc_path VARCHAR(500)
SELECT @trc_path=CONVERT(VARCHAR(500),value) FROM fn_trace_getinfo(DEFAULT)
WHERE property=2
SELECT @trc_path

/*3. Next, you will query the trace to capture the needed data for the fn_trace_
gettable function, and filter the data with the predicate TextData like
'%configure%'. The event will be inserted to your SQLConfig_Changes table only
if it has not already been captured. You also order by the StartTime descending,
so you can force the latest data to the top of the query results.*/

INSERT INTO #temp_cfg
SELECT TEXTData,HostName,ApplicationName,DatabaseName,LoginName,SPID,StartTime,EventSequence
FROM fn_trace_gettable(@trc_path,1) fn
WHERE TEXTData LIKE '%configure%'
AND SPID<>@@spid
AND fn.EventSequence NOT IN (SELECT EventSequence FROM SQLConfig_Changes)
AND TEXTData NOT LIKE '%Insert into #temp_cfg%'
ORDER BY StartTime DESC

/*4. At this point, you insert the new rows from the temp table #temp_cfg into the
dbo.SQLConfig_Changes table.*/
INSERT INTO dbo.SQLConfig_Changes
SELECT * FROM #temp_cfg

/*Invoke database mail */

IF @@ROWCOUNT > 0
--select @@ROWCOUNT
BEGIN
DECLARE c CURSOR FOR
SELECT LTRIM(REPLACE(SUBSTRING(TEXTdata,31,250), '. Run the RECONFIGURE statement to
install.', ''))
FROM #temp_cfg
OPEN c
FETCH NEXT FROM c INTO @textdata
WHILE (@@FETCH_STATUS <> -1)
BEGIN
--FETCH c INTO @textdata
SELECT @message = @textdata + 'on server ' + @@servername + CHAR(13)
EXEC msdb.dbo.sp_send_dbmail --@profile_name='ProfileName - otherwise will use default profile'
@recipients='SQLAdmin@SomeSQLCompany.com',
@subject='SQL Server Configuration Change Alert',
@body=@message
FETCH NEXT FROM c INTO @textdata
END
CLOSE c
DEALLOCATE c
END
DROP TABLE #temp_cfg

/*Ch10 Default Trace - section: Creating the Stored Procedure */

SET NOCOUNT ON
GO
CREATE PROCEDURE dbo.usp_Capture_SQL_Config_Changes @SendEmailTo VARCHAR(255) AS

CREATE TABLE #temp_cfg (
TEXTData VARCHAR(500),
HostName VARCHAR(155),
ApplicationName VARCHAR(255),
DatabaseName VARCHAR(155),
LoginName VARCHAR(155),
SPID INT,
StartTime DATETIME,
EventSequence INT
)
DECLARE @trc_path VARCHAR(500),
@message VARCHAR(MAX),
@message1 VARCHAR(MAX),
@textdata VARCHAR(1000)
SELECT @trc_path=CONVERT(VARCHAR(500),value) FROM fn_trace_getinfo(DEFAULT)
WHERE property=2
INSERT INTO #temp_cfg
SELECT TEXTData,HostName,ApplicationName,DatabaseName,LoginName,SPID,StartTime,EventSequence
FROM fn_trace_gettable(@trc_path,1) fn
WHERE TEXTData LIKE '%configure%'
AND fn.EventSequence NOT IN (SELECT EventSequence FROM SQLConfig_Changes)
AND TEXTData NOT LIKE '%Insert into #temp_cfg%'
ORDER BY StartTime DESC
INSERT INTO dbo.SQLConfig_Changes
SELECT * FROM #temp_cfg
/*select TextData,HostName,ApplicationName,DatabaseName,LoginName,SPID,StartTime,EventSequence
from fn_trace_gettable(@trc_path,1) fn
where TextData like '%configure%'
and SPID<>@@spid
and fn.EventSequence not in (select EventSequence from SQLConfig_Changes)
order by StartTime desc*/
--select * from SQLConfig_Changes
IF @@ROWCOUNT > 0
--select @@ROWCOUNT
BEGIN
DECLARE c CURSOR FOR
SELECT LTRIM(REPLACE(SUBSTRING(TEXTdata,31,250), '. Run the RECONFIGURE statement to install.', ''))
FROM #temp_cfg
OPEN c
FETCH NEXT FROM c INTO @textdata
WHILE (@@FETCH_STATUS <> -1)
BEGIN
--FETCH c INTO @textdata
SELECT @message = @textdata + 'on server ' + @@servername + CHAR(13)
EXEC msdb.dbo.sp_send_dbmail --@profile_name='ProfileName - otherwise will use default profile',
@recipients=@SendEmailTo,
@subject='SQL Server Configuration Change Alert',
@body=@message
FETCH NEXT FROM c INTO @textdata
END
CLOSE c
DEALLOCATE c
END
DROP TABLE #temp_cfg
GO

/*Testing the Process to capture configuration changes - turn on Ad Hoc Distributed Queries */

sp_configure 'show advanced options',1
GO
RECONFIGURE WITH override
GO
sp_configure 'Ad Hoc Distributed Queries',1
GO
RECONFIGURE WITH override
GO

/* Execute Stored Procedure */

exec dbo.usp_Capture_SQL_Config_Changes 'SQLDBA@SomeSQLCompany.com' --change email address

/*query the SQLConfig_Changes table to return configuration change history. */

SELECT *
FROM dbo.SQLConfig_Changes
ORDER BY StartTime DESC
