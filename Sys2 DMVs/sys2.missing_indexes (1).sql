------------------------------------------------------------------------
-- Script:			sys2.missing_indexes.sql
-- Version:			6
-- Release Date:	2011-09-06
-- Author:			Davide Mauri (SolidQ Italy)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.missing_indexes			
-- Notes:			Display all the detected missing indexes in ALL tables and ALL databases
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.missing_indexes', 'V') IS NOT NULL)
	DROP VIEW sys2.missing_indexes
GO

CREATE VIEW sys2.missing_indexes
AS
WITH cte AS
(
SELECT
    d.database_id,
    d.[object_id],
    d.index_handle,
	database_name = db_name(d.database_id),
    d.statement as fully_qualified_object,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
	gs.user_seeks, 
	gs.avg_user_impact,
	gs.last_user_seek,
	gs.last_user_scan,
	total_columns_to_index = (select count(*) from sys.dm_db_missing_index_columns(d.index_handle)),
	command = 'CREATE INDEX IX_' + 
			CAST(ABS(CHECKSUM(isnull(equality_columns, '') + isnull(inequality_columns, '') + isnull(included_columns, ''))) as varchar(100)) + 
			' ON ' + 
			d.statement + 
			' (' + isnull(equality_columns, '') + 
			case when (equality_columns + inequality_columns) is null then '' else ',' end + 
			isnull(inequality_columns, '')  + ')' + 
			isnull(' INCLUDE (' + included_columns + ')', '')
FROM
    sys.dm_db_missing_index_groups g 
LEFT OUTER JOIN 
    sys.dm_db_missing_index_group_stats gs on gs.group_handle = g.index_group_handle 
LEFT OUTER JOIN
    sys.dm_db_missing_index_details d on g.index_handle = d.index_handle
)
SELECT
	*
FROM
	cte