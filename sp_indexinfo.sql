--http://www.karaszi.com/SQLServer/util_sp_indexinfo.asp

USE master 
GO 
IF OBJECT_ID('sp_indexinfo') IS NOT NULL DROP PROC sp_indexinfo 
GO 
CREATE PROCEDURE sp_indexinfo 
 @tblPat SYSNAME = '%' 
,@missing_ix tinyint = 0 
AS 
--Written by Tibor Karaszi 2008-07-07 
--Last modified 2014-05-19  
WITH key_columns AS 
( 
SELECT 
 c.OBJECT_ID 
,c.name AS column_name 
,ic.key_ordinal 
,ic.is_included_column 
,ic.index_id 
,ic.is_descending_key 
FROM sys.columns AS c 
INNER JOIN sys.index_columns AS ic ON c.OBJECT_ID = ic.OBJECT_ID AND ic.column_id = c.column_id 
) 
, physical_info AS 
( 
SELECT p.OBJECT_ID, p.index_id, ds.name AS location, SUM(CASE WHEN a.type_desc = 'IN_ROW_DATA' THEN p.rows ELSE 0 END) AS rows, SUM(a.total_pages) AS pages 
FROM sys.partitions AS p 
INNER JOIN sys.allocation_units AS a ON p.hobt_id = a.container_id 
INNER JOIN sys.data_spaces AS ds ON a.data_space_id = ds.data_space_id 
GROUP BY OBJECT_ID, index_id, ds.name 
) 
SELECT 
OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS sch_name 
,OBJECT_NAME(i.OBJECT_ID) AS tbl_name 
,i.name AS ix_name 
,CASE i.TYPE 
  WHEN 0 THEN 'heap' 
  WHEN 1 THEN 'cl' 
  WHEN 2 THEN 'nc' 
  WHEN 3 THEN 'xml' 
  WHEN 6 THEN 'col-store' 
  ELSE CAST(i.TYPE AS VARCHAR(2)) 
END 
AS type 
,i.is_unique AS uq
,CASE 
  WHEN is_primary_key = 0 AND is_unique_constraint = 0 THEN 'no' 
  WHEN is_primary_key = 1 AND is_unique_constraint = 0 THEN 'PK' 
  WHEN is_primary_key = 0 AND is_unique_constraint = 1 THEN 'UQ' 
END 
AS cnstr 
,STUFF((SELECT CAST(', ' + kc.column_name + CASE kc.is_descending_key 
                                             WHEN 0 THEN ''  
                                             ELSE ' DESC'  
                                             END 
               AS VARCHAR(MAX)) 
AS [text()]  
FROM key_columns AS kc 
WHERE i.OBJECT_ID = kc.OBJECT_ID AND i.index_id = kc.index_id AND kc.is_included_column = 0 
ORDER BY key_ordinal  
FOR XML PATH('')  
), 1, 2, '') AS key_cols 
,STUFF((SELECT CAST(', ' + column_name AS VARCHAR(MAX)) AS [text()] 
  FROM key_columns AS kc 
  WHERE i.OBJECT_ID = kc.OBJECT_ID AND i.index_id = kc.index_id AND kc.is_included_column = 1 
  ORDER BY key_ordinal 
  FOR XML PATH('') 
), 1, 2, '') AS incl_cols 
,p.rows
,p.pages 
,CAST((p.pages * 8.00) / 1024 AS DECIMAL(9,2)) AS MB 
,s.user_seeks AS seeks
,s.user_scans AS scans
,s.user_lookups AS lookups
,s.user_updates AS updates
,CASE WHEN i.is_disabled = 1 THEN '[DISABLED]' ELSE p.location END AS location   
,i.filter_definition AS filter --requires 2008
,INDEXPROPERTY(i.object_id, i.name, 'IsDisabled') AS disabled   
,INDEXPROPERTY(i.object_id, i.name, 'IndexDepth') AS depth   
,INDEXPROPERTY(i.object_id, i.name, 'IndexFillFactor ') AS fill_factor   
,INDEXPROPERTY(i.object_id, i.name, 'IsPageLockDisallowed') AS page_lock_disallowed  
,INDEXPROPERTY(i.object_id, i.name, 'IsRowLockDisallowed') AS row_lock_disallowed   
FROM sys.indexes AS i 
LEFT OUTER JOIN physical_info AS p 
  ON i.OBJECT_ID = p.OBJECT_ID AND i.index_id = p.index_id 
LEFT OUTER JOIN sys.dm_db_index_usage_stats AS s 
  ON s.OBJECT_ID = i.OBJECT_ID AND s.index_id = i.index_id AND s.database_id = DB_ID() 
WHERE OBJECTPROPERTY(i.OBJECT_ID, 'IsMsShipped') = 0 
AND OBJECTPROPERTY(i.OBJECT_ID, 'IsTableFunction') = 0 
AND OBJECT_NAME(i.OBJECT_ID) LIKE @tblPat 
ORDER BY tbl_name, ix_name  

DECLARE @crlf char(2)
SET @crlf = CHAR(13) + CHAR(10)

IF @missing_ix = 1 
BEGIN 
SELECT 
 OBJECT_SCHEMA_NAME(d.OBJECT_ID) AS schema_name   
,OBJECT_NAME(d.OBJECT_ID) AS table_name   
,'CREATE INDEX '
+ CAST(
OBJECT_SCHEMA_NAME(d.OBJECT_ID)
+ '__' + OBJECT_NAME(d.OBJECT_ID) 
+ '__' + REPLACE(REPLACE(COALESCE(REPLACE(d.equality_columns, ', ', '__'), ''), '[', ''), ']', '')
+ '__' + REPLACE(REPLACE(COALESCE(REPLACE(d.inequality_columns, ', ', '__'), ''), '[', ''), ']', '')
+ '__' + REPLACE(REPLACE(COALESCE(REPLACE(d.included_columns, ', ', '__'), ''), '[', ''), ']', '')
AS sysname)
+ @crlf + 'ON ' + OBJECT_SCHEMA_NAME(d.OBJECT_ID) + '.' + OBJECT_NAME(d.OBJECT_ID) + ' '
+ '(' + COALESCE(d.equality_columns + COALESCE(', ' + d.inequality_columns, ''), d.inequality_columns) + ')'+ @crlf
+ COALESCE('INCLUDE(' + d.included_columns + ')', '') 
AS ddl 
,s.user_seeks 
,s.user_scans 
,s.avg_user_impact 
FROM sys.dm_db_missing_index_details AS d 
INNER JOIN  sys.dm_db_missing_index_groups AS g 
  ON d.index_handle = g.index_handle 
INNER JOIN sys.dm_db_missing_index_group_stats AS  s 
  ON g.index_group_handle = s.group_handle 
WHERE OBJECT_NAME(d.OBJECT_ID) LIKE @tblPat 
AND d.database_id = DB_ID() 
ORDER BY avg_user_impact DESC 
END 
GO  
EXEC sp_MS_Marksystemobject sp_indexinfo