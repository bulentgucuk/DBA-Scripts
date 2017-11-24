USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dba_SpaceUsed]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[dba_SpaceUsed]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[dba_SpaceUsed] 

    @SourceDB varchar ( 128 ) = null -- Optional database name
         -- If omitted, the current database is reported.
  , @SortBy char(1) = 'S' -- N for name, S for Size
           -- T for table name

/* Returns a table with the space used in all tables of the
*  database.  It's reported with the schema information unlike
*  the system procedure sp_spaceuse.
*
*  sp_spaceused is used to perform the calculations to ensure
*  that the numbers match what SQL Server would report.
*
*  Compatible with sQL Server 2000 and 2005
*
* Example:
exec dbo.dba_SpaceUsed null, 'N'
*
* c Copyright 2007 Andrew Novick http://www.NovickSoftware.com
* This software is provided as is without warrentee of any kind.
* You may use this procedure in any of your SQL Server databases
* including databases that you sell, so long as they contain 
* other unrelated database objects. You may not publish this 
* procedure either in print or electronically.
******************************************************************/
AS

SET NOCOUNT ON

DECLARE @sql nvarchar (4000)

IF @SourceDB IS NULL BEGIN
	SET @SourceDB = DB_NAME () -- The current DB 
END

--------------------------------------------------------
-- Create and fill a list of the tables in the database.

CREATE TABLE #Tables (	[schema] sysname
                      , TabName sysname )
		
SELECT @sql = 'insert #tables ([schema], [TabName]) 
                  select TABLE_SCHEMA, TABLE_NAME 
		          from ['+ @SourceDB +'].INFORMATION_SCHEMA.TABLES
			          where TABLE_TYPE = ''BASE TABLE'''
EXEC (@sql)


---------------------------------------------------------------
-- #TabSpaceTxt Holds the results of sp_spaceused. 
-- It Doesn't have Schema Info!
CREATE TABLE #TabSpaceTxt (
                         TabName sysname
	                   , [Rows] varchar (11)
	                   , Reserved varchar (18)
					   , Data varchar (18)
	                   , Index_Size varchar ( 18 )
	                   , Unused varchar ( 18 )
                       )
					
---------------------------------------------------------------
-- The result table, with numeric results and Schema name.
CREATE TABLE #TabSpace ( [Schema] sysname
                       , TabName sysname
	                   , [Rows] bigint
	                   , ReservedMB numeric(18,3)
					   , DataMB numeric(18,3)
	                   , Index_SizeMB numeric(18,3)
	                   , UnusedMB numeric(18,3)
                       )

DECLARE @Tab sysname -- table name
      , @Sch sysname -- owner,schema

DECLARE TableCursor CURSOR FOR
    SELECT [SCHEMA], TabNAME 
         FROM #tables

OPEN TableCursor;
FETCH TableCursor into @Sch, @Tab;

WHILE @@FETCH_STATUS = 0 BEGIN

	SELECT @sql = 'exec [' + @SourceDB 
	   + ']..sp_executesql N''insert #TabSpaceTxt exec sp_spaceused '
	   + '''''[' + @Sch + '].[' + @Tab + ']' + '''''''';

	Delete from #TabSpaceTxt; -- Stores 1 result at a time
	EXEC (@sql);

    INSERT INTO #TabSpace
	SELECT @Sch
	     , [TabName]
         , convert(bigint, rows)
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(reserved, len(reserved)-3)) / 1024.0) 
                ReservedMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(data, len(data)-3)) / 1024.0) DataMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(index_size, len(index_size)-3)) / 1024.0) 
                 Index_SizeMB
	     , convert(numeric(18,3), convert(numeric(18,3), 
		        left(unused, len([Unused])-3)) / 1024.0) 
                [UnusedMB]
        FROM #TabSpaceTxt;

	FETCH TableCursor into @Sch, @Tab;
END;

CLOSE TableCursor;
DEALLOCATE TableCursor;

-----------------------------------------------------
-- Caller specifies sort, Default is size
IF @SortBy = 'N' -- Use Schema then Table Name
	SELECT * FROM #TabSpace
	   ORDER BY [Schema] asc, [TabName] asc
ELSE IF @SortBy = 'T'  -- Table name, then schema
	SELECT * FROM #TabSpace
	   ORDER BY [TabName] asc, [Schema] asc
ELSE  -- S, NULL, or whatever get's the default
	SELECT * FROM #TabSpace
	   ORDER BY ReservedMB desc
;

DROP TABLE #Tables
DROP TABLE #TabSpaceTxt
DROP TABLE #TabSpace



GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
