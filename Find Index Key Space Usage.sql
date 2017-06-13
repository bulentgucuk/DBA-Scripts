/*============================================================================
  File:     KeySpaceSavingsSingleResultSet.sql

  Summary:  Potential cluster key space savings

  SQL Server Versions: 2005 onwards
------------------------------------------------------------------------------
  Written by Paul S. Randal, SQLskills.com

  (c) 2012, SQLskills.com. All rights reserved.

  For more scripts and sample code, check out
    http://www.SQLskills.com

  You may alter this code for your own *non-commercial* purposes. You may
  republish altered code as long as you include this copyright and give due
  credit, but you must obtain prior permission before blogging this code.
 
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

IF EXISTS (SELECT * FROM msdb.sys.objects WHERE [name] = 'SQLskillsIKSpace')
    DROP TABLE msdb.dbo.SQLskillsIKSpace;
GO
CREATE TABLE msdb.dbo.SQLskillsIKSpace (
    DatabaseID SMALLINT,
	SchemaName SYSNAME,
	ObjectName SYSNAME,
    ObjectID INT,
    IndexCount SMALLINT DEFAULT (0),
    TableRows BIGINT DEFAULT (0),
    KeyCount SMALLINT DEFAULT (0),
    KeyWidth SMALLINT DEFAULT (0));
GO

EXEC sp_MSforeachdb
    N'IF EXISTS (SELECT 1 FROM (SELECT DISTINCT [name]
    FROM sys.databases WHERE [state_desc] = ''ONLINE''
        AND [database_id] > 4
        AND [name] != ''pubs''
        AND [name] != ''Northwind''
        AND [name] != ''distribution''
        AND [name] NOT LIKE ''ReportServer%''
        AND [name] NOT LIKE ''Adventure%'') AS names WHERE [name] = ''?'')
BEGIN
USE [?]

INSERT INTO msdb.dbo.SQLskillsIKSpace
(DatabaseID, SchemaName, ObjectName, ObjectID)
SELECT DB_ID (''?''), SCHEMA_NAME (o.[schema_id]), OBJECT_NAME (o.[object_id]), o.[object_id]
FROM sys.objects o
WHERE o.[type_desc] IN (''USER_TABLE'', ''VIEW'')
    AND o.[is_ms_shipped] = 0
    AND EXISTS (
        SELECT *
        FROM sys.indexes
        WHERE [index_id] = 1
            AND [object_id] = o.[object_id]);

UPDATE msdb.dbo.SQLskillsIKSpace
SET [TableRows] = (
    SELECT SUM ([rows])
    FROM sys.partitions p
    WHERE p.[object_id] = [ObjectID]
    AND p.[index_id] = 1)
WHERE [DatabaseID] = DB_ID (''?'');
 
UPDATE msdb.dbo.SQLskillsIKSpace
SET [IndexCount] = (
    SELECT COUNT (*)
    FROM sys.indexes i
    WHERE i.[object_id] = [ObjectID]
    AND i.[is_hypothetical] = 0
    AND i.[is_disabled] = 0
    AND i.[index_id] != 1)
WHERE [DatabaseID] = DB_ID (''?'');

UPDATE msdb.dbo.SQLskillsIKSpace
SET [KeyCount] = (
    SELECT COUNT (*)
    FROM sys.index_columns ic
    WHERE ic.[object_id] = [ObjectID]
    AND ic.[index_id] = 1)
WHERE [DatabaseID] = DB_ID (''?'');

UPDATE msdb.dbo.SQLskillsIKSpace
SET [KeyWidth] = (
    SELECT SUM (c.[max_length])
    FROM sys.columns c
    JOIN sys.index_columns ic
    ON c.[object_id] = ic.[object_id]
    AND c.[object_id] = [ObjectID]
    AND ic.[column_id] = c.[column_id]
    AND ic.[index_id] = 1)
WHERE [DatabaseID] = DB_ID (''?'');

DELETE msdb.dbo.SQLskillsIKSpace
WHERE
    ([KeyCount] = 1 AND [KeyWidth] < 9)
    OR [IndexCount] = 0 OR [TableRows] = 0;

END';
GO

SELECT
 DB_NAME ([DatabaseID]) AS [Database],
 [SchemaName] AS [Schema],
 [ObjectName] AS [Table],
    [IndexCount] AS [NCIndexes],
    [KeyCount] AS [ClusterKeys],
    [KeyWidth],
    [TableRows],
    [IndexCount] * [TableRows] * [KeyWidth] AS [KeySpaceInBytes],
    ([IndexCount] * [TableRows] * ([KeyWidth] - 8)) AS [PotentialSavings]
FROM msdb.dbo.SQLskillsIKSpace
ORDER BY [PotentialSavings] DESC;

DROP TABLE msdb.dbo.SQLskillsIKSpace;
GO 