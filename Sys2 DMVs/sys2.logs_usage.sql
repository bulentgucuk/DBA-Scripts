------------------------------------------------------------------------
-- Script:			sys2.logs_usage
-- Version:			1
-- Release Date:	2010-03-03
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			Thomas Kejser (MS SQL CAT Team)
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.logs_usage		
-- Notes:			Display Transaction Log usage data
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.logs_usage', 'V') IS NOT NULL)
	DROP VIEW sys2.logs_usage
GO

CREATE VIEW sys2.logs_usage
AS
WITH cte as
(
SELECT 
	name, 
	db.log_reuse_wait_desc, 
	size_mb = ls.cntr_value / 1024.,
	used_mb = lu.cntr_value / 1024.,
	used_percent = CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT),
	log_status = CASE 
		WHEN CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT) > .75
			THEN CASE 
					/* tempdb special monitoring */ 
					WHEN db.name = 'tempdb' AND log_reuse_wait_desc NOT IN ('CHECKPOINT', 'NOTHING') THEN 'WARNING'  					
					WHEN db.name <> 'tempdb' THEN 'WARNING' 
					ELSE 'OK' 
				END 
		ELSE 'OK' 
	END 	
FROM 
	sys.databases db 
JOIN 
	sys.dm_os_performance_counters lu ON db.name = lu.instance_name 
JOIN 
	sys.dm_os_performance_counters ls ON db.name = ls.instance_name 
WHERE 
	lu.counter_name LIKE 'Log File(s) Used Size (KB)%' 
AND 
	ls.counter_name LIKE 'Log File(s) Size (KB)%' 
)
select
	*
from
	cte
