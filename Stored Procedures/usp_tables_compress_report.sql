
CREATE PROCEDURE dbo.usp_tables_compress_report 
	(@compress_method char(4))

AS
SET NOCOUNT ON
BEGIN
	DECLARE @schema_name sysname,
			@table_name sysname
	CREATE TABLE #compress_report_tb (
		ObjName sysname,
		schemaName sysname,
		indx_ID int,
		partit_number int,
		size_with_current_compression_setting bigint,
		size_with_requested_compression_setting bigint,
		sample_size_with_current_compression_setting bigint,
		sample_size_with_requested_compression_setting bigint
		)
	DECLARE	c_sch_tb_crs cursor for
		SELECT	TABLE_SCHEMA,TABLE_NAME
		FROM	INFORMATION_SCHEMA.TABLES
		WHERE	TABLE_TYPE LIKE 'BASE%'
		AND		TABLE_CATALOG = upper(db_name())
	OPEN	c_sch_tb_crs
	FETCH NEXT FROM c_sch_tb_crs INTO @schema_name, @table_name
	WHILE	@@Fetch_Status = 0
		BEGIN
			INSERT INTO #compress_report_tb
			EXEC sp_estimate_data_compression_savings
				@schema_name = @schema_name,
				@object_name = @table_name,
				@index_id = NULL,
				@partition_number = NULL,
				@data_compression = @compress_method
			FETCH NEXT FROM c_sch_tb_crs INTO @schema_name, @table_name
		END

	CLOSE c_sch_tb_crs 
	DEALLOCATE c_sch_tb_crs

	SELECT	schemaName AS [schema_name]
		  , ObjName AS [table_name]
		  , avg(size_with_current_compression_setting) as avg_size_with_current_compression_setting
		  , avg(size_with_requested_compression_setting) as avg_size_with_requested_compression_setting
		  , avg(size_with_current_compression_setting - size_with_requested_compression_setting) AS avg_size_saving
	FROM #compress_report_tb
	GROUP BY schemaName,ObjName
	ORDER BY schemaName ASC, avg_size_saving DESC 
	DROP TABLE #compress_report_tb
END
SET NOCOUNT OFF
GO