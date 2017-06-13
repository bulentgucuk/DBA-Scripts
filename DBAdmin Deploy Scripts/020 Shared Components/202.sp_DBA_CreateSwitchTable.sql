USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DBA_CreateSwitchTable]') AND type in (N'P', N'PC'))
	EXEC( 'CREATE PROCEDURE [dbo].[sp_DBA_CreateSwitchTable] AS' )
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE dbo.sp_DBA_CreateSwitchTable
		  @DBName SYSNAME
		, @PSName SYSNAME
		, @table_name SYSNAME
		, @Debug BIT = 1
		, @DryRun BIT = 1
AS
BEGIN
/******

EXEC dbo.sp_DBA_CreateSwitchTable
		@DBName = 'SystemLogging2',
	    @PSName = 'PS_CustomerActionLog',
	    @table_name = 'dbo.CustomerActionLog',
	    @Debug = 1,
	    @DryRun = 1;

*******/

	SET NOCOUNT ON;

	DECLARE	@Switch SYSNAME,
			@SwitchTableName SYSNAME,
			@FGName SYSNAME,
			@Compression SYSNAME,
			@object_name SYSNAME,
			@object_id INT,
			@SQL NVARCHAR(MAX);

	SET	@Switch =  '_Switch';

	-- Based on partitioned table find the object id and concat _switch for switch table creation
	SELECT 
		  @object_name = QUOTENAME(s.name) + '.' + QUOTENAME(o.name)  --'[' + s.name + '].[' + o.name + ']'
		, @SwitchTableName = QUOTENAME(s.name) + '.' + QUOTENAME(o.name + @Switch)
		, @object_id = o.[object_id]
	FROM sys.objects o WITH (NOWAIT)
		INNER JOIN sys.schemas s WITH (NOWAIT) ON o.[schema_id] = s.[schema_id]
	WHERE s.name + '.' + o.name = @table_name
		AND o.[type] = 'U'
		AND o.is_ms_shipped = 0

	
	IF OBJECT_ID('tempdb..#IndCols') IS NOT NULL
		DROP TABLE #IndCols


	SELECT DISTINCT OBJECT_NAME(ic.object_id) AS Tablename
			, idx.name AS IndName
			, ic.[object_id] 
			, ic.index_id
			, ic.is_descending_key
			, ic.is_included_column
			, c.name
			, ic.key_ordinal
			, ic.partition_ordinal
			, p.data_compression_desc
			, fg.name AS FileGroupName
			, idx.has_filter
			, idx.filter_definition
			, p.partition_number
	INTO	#IndCols
	FROM sys.index_columns ic WITH (NOWAIT)
		INNER JOIN sys.columns c WITH (NOWAIT) ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
		INNER JOIN sys.indexes AS idx WITH (NOWAIT) ON ic.object_id = idx.object_id AND ic.index_id = idx.index_id
		INNER JOIN sys.partitions AS p ON p.object_id= c.object_id AND p.index_id=idx.index_id
		LEFT OUTER JOIN sys.destination_data_spaces AS dds ON dds.partition_scheme_id = idx.data_space_id and dds.destination_id = p.partition_number
		LEFT OUTER JOIN sys.partition_schemes AS ps ON ps.data_space_id = idx.data_space_id
		LEFT OUTER JOIN sys.partition_range_values AS prv ON prv.boundary_id = p.partition_number and prv.function_id = ps.function_id
		LEFT OUTER JOIN sys.filegroups AS fg ON fg.data_space_id = dds.data_space_id or fg.data_space_id = idx.data_space_id
		LEFT OUTER JOIN sys.partition_functions AS pf ON  pf.function_id = prv.function_id

	WHERE ic.[object_id] = @object_id 
	and partition_number = 2
	order by FileGroupName


	SELECT	@SQL = N'IF OBJECT_ID('+ '''' + @SwitchTableName + '''' + ') IS NOT NULL' + CHAR(13)
		+ 'BEGIN' + CHAR(13)
		+ 'DROP TABLE ' + '' + @SwitchTableName + '' + ';' + CHAR(13)
		+ 'END' + CHAR(13)


	SELECT @SQL = @SQL + N'CREATE TABLE ' + @SwitchTableName + CHAR(13) + '(' + CHAR(13) + STUFF((
		SELECT CHAR(9) + ', [' + c.name + '] ' + 
			CASE WHEN c.is_computed = 1
				THEN 'AS ' + cc.[definition] 
				ELSE UPPER(tp.name) + 
					CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary')
						   THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(5)) END + ')'
						 WHEN tp.name IN ('nvarchar', 'nchar')
						   THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length / 2 AS VARCHAR(5)) END + ')'
						 WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset') 
						   THEN '(' + CAST(c.scale AS VARCHAR(5)) + ')'
						 WHEN tp.name = 'decimal' 
						   THEN '(' + CAST(c.[precision] AS VARCHAR(5)) + ',' + CAST(c.scale AS VARCHAR(5)) + ')'
						ELSE ''
					END +
					CASE WHEN c.collation_name IS NOT NULL THEN ' COLLATE ' + c.collation_name ELSE '' END +
					CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END +
					CASE WHEN dc.[definition] IS NOT NULL THEN ' DEFAULT' + dc.[definition] ELSE '' END + 
					CASE WHEN ic.is_identity = 1 THEN ' IDENTITY(' + CAST(ISNULL(ic.seed_value, '0') AS CHAR(1)) + ',' + CAST(ISNULL(ic.increment_value, '1') AS CHAR(1)) + ')' ELSE '' END 
			END
		
			+ CHAR(13)
		FROM sys.columns c WITH (NOWAIT)
		JOIN sys.types tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
		LEFT JOIN sys.computed_columns cc WITH (NOWAIT) ON c.[object_id] = cc.[object_id] AND c.column_id = cc.column_id
		LEFT JOIN sys.default_constraints dc WITH (NOWAIT) ON c.default_object_id != 0 AND c.[object_id] = dc.parent_object_id AND c.column_id = dc.parent_column_id
		LEFT JOIN sys.identity_columns ic WITH (NOWAIT) ON c.is_identity = 1 AND c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
		WHERE c.[object_id] = @object_id
		ORDER BY c.column_id
		FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' ')
		+ ISNULL((SELECT DISTINCT CHAR(9) + ', CONSTRAINT [' + k.name + @Switch + '] PRIMARY KEY (' + 
						(SELECT STUFF((
							 SELECT ', [' + c.name + '] ' + CASE WHEN ic.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
							 FROM sys.index_columns ic WITH (NOWAIT)
							 JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
							 WHERE ic.is_included_column = 0
							 AND ic.[object_id] = k.parent_object_id 
							 AND ic.index_id = k.unique_index_id
							 ORDER BY ic.key_ordinal
							 FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''))
				+ ')'
				+ CHAR(13)
				
				FROM sys.key_constraints k WITH (NOWAIT)
					INNER JOIN #IndCols AS i ON i.object_id = k.parent_object_id AND i.IndName = k.name
				WHERE k.parent_object_id = @object_id 
				AND k.[type] = 'PK'), '') --+ ')'
				+ CHAR(13) 
				+ 'WITH(DATA_COMPRESSION = ' + (SELECT	DISTINCT i.data_compression_desc
												FROM	sys.key_constraints AS k
													INNER JOIN #IndCols AS i ON i.object_id = k.parent_object_id AND i.IndName = k.name
												WHERE	k.[type] = 'PK') + ')'
				


	SET @FGName = (SELECT Min(QUOTENAME(i.FileGroupName))
	FROM sys.key_constraints AS k
		INNER JOIN #IndCols AS i ON i.object_id = k.parent_object_id AND i.IndName = k.name
	WHERE parent_object_id =  @object_id 
	and i.partition_number = 2
	)

	SET @SQL = @SQL + CHAR(13) + ') ON ' + @FGName +  ';'

	IF @Debug = 1
		BEGIN
			PRINT '---------------------- SWITCH TABLE CREATE SCRIPT -----------------------'
			PRINT 'Create switch table command  : ';
			PRINT @SQL;
			PRINT '---------------------- SWITCH TABLE CREATE SCRIPT -----------------------'
			PRINT ''
		END

	IF @DryRun = 0
		BEGIN
			EXEC sys.sp_executesql @stmt = @SQL;
		END


	SELECT @SQL = ''
		SELECT @SQL = ''
	SELECT @SQL = ISNULL(((SELECT DISTINCT
			 CHAR(13) + 'CREATE' + CASE WHEN i.is_unique = 1 THEN ' UNIQUE' ELSE '' END 
					+ ' NONCLUSTERED INDEX [' + i.name +  @Switch +'] ON ' + @SwitchTableName + ' (' +
					STUFF((
					SELECT ', [' + c.name + ']' + CASE WHEN c.is_descending_key = 1 THEN ' DESC' ELSE ' ASC' END
					
					FROM	#IndCols c
					WHERE	c.is_included_column = 0
					AND		c.index_id = i.index_id
					AND		c.key_ordinal <> 0
					and c.partition_number = 2
					ORDER BY	c.FileGroupName, c.key_ordinal
					FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')'  
					+ ISNULL(CHAR(13) + 'INCLUDE (' + 
						STUFF((
						SELECT ', [' + c.name + ']'
						FROM #IndCols c
						WHERE c.is_included_column = 1
							AND c.index_id = i.index_id
							and c.partition_number = 2
						FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ')', '') + CHAR(13)
							+ ISNULL('WHERE ' + c.filter_definition , '')
							+ 'WITH (DATA_COMPRESSION = ' + c.data_compression_desc COLLATE SQL_Latin1_General_CP1_CI_AS +')' + CHAR(13)
							+ 'ON ' +  QUOTENAME(c.FileGroupName) + ';'
			FROM sys.indexes i WITH (NOWAIT)
				INNER JOIN #IndCols AS c ON i.object_id = c.object_id AND i.index_id = c.Index_id and c.partition_number = 2
			WHERE i.[object_id] = @object_id
				AND i.is_primary_key = 0
				AND i.[type] = 2
			FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)')
		), '')
		--PRINT @SQL;


	IF @Debug = 1
		BEGIN
			PRINT '---------------------- SWITCH TABLE INDEX CREATE SCRIPT -----------------------'
			PRINT 'Create switch index command  : ';
			PRINT @SQL;
			PRINT '---------------------- SWITCH TABLE INDEX CREATE SCRIPT -----------------------'
			PRINT ''
		END

	IF @DryRun = 0
		BEGIN
			EXEC sys.sp_executesql @stmt = @SQL;
			
		END

	Print 'EXEC dbo.sp_DBA_SwitchPartition
		@DBName = '+@DBName+',
	    @PSName = '+@PSName+',
	    @object_id = '+cast(@object_id as varchar)+',
	    @table_name = '+@object_name+',
	    @SwitchTableName = '+@SwitchTableName+',
	    @Debug = '+cast(@Debug as varchar)+',
	    @DryRun = '+cast(@DryRun as varchar)+';'

	-- Execute switchpartition stored procedure
	EXEC dbo.sp_DBA_SwitchPartition
		@DBName = @DBName,
	    @PSName = @PSName,
	    @object_id = @object_id,
	    @table_name = @object_name,--@table_name,
	    @SwitchTableName = @SwitchTableName,
	    @Debug = @Debug,
	    @DryRun = @DryRun;
	

END
GO
