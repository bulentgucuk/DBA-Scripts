DECLARE @object_id BIGINT,
		@RowId INT;

DECLARE @ObjectSpaceUsageReport TABLE (
	[DatabaseName] [varchar](128) NULL,
	[SchemaName] [varchar](128) NULL,
	[ObjectName] [varchar](128) NULL,
	[Index_Id] [int] NULL,
	[Partition_Number] [int] NULL,
	[Index_Type_Desc] [varchar](60) NULL,
	[Alloc_Unit_type_desc] [varchar](60) NULL,
	[Index_Depth] [tinyint] NULL,
	[Index_Level] [tinyint] NULL,
	[avg_page_space_used_in_percent] [float] NULL,
	[avg_fragmentation_in_percent] [float] NULL,
	[avg_fragment_size_in_pages] [float] NULL,
	[record_count] [bigint] NULL,
	[page_count] [bigint] NULL,
	[fragment_count] [bigint] NULL,
	[avg_record_size_in_bytes] [float] NULL,
	[min_record_size_in_bytes] [int] NULL,
	[max_record_size_in_bytes] [int] NULL
) 

DECLARE @ObjectIds TABLE (
	RowId INT IDENTITY (1,1),
	ObjectID bigint,
	ObjectName VARCHAR(128)
	)

INSERT INTO @ObjectIds (
	ObjectID,
	ObjectName
	)
SELECT	object_id,
		QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + '.' + QUOTENAME(name)
FROM	sys.tables
WHERE	is_ms_shipped = 0
AND		object_id = OBJECT_ID('dbo.RichRelevanceProductFeedLog_Test')
ORDER BY OBJECT_SCHEMA_NAME(object_id) DESC, name DESC

SELECT	@RowId =MAX(RowId)
FROM	@ObjectIds

WHILE @RowId > 0
	BEGIN
		SELECT	@object_id = ObjectID
		FROM	@ObjectIds
		WHERE	RowId = @RowId

		INSERT INTO @ObjectSpaceUsageReport
		SELECT 
			db_name(database_id) AS DatabaseName,
			OBJECT_SCHEMA_NAME(OBJECT_ID) as SchemaName,
			object_name(object_id) AS ObjectName,
			Index_Id,
			Partition_Number,
			Index_Type_Desc,
			Alloc_Unit_type_desc,
			Index_Depth,
			Index_Level,
			avg_page_space_used_in_percent,
			avg_fragmentation_in_percent,
			avg_fragment_size_in_pages,
			record_count,
			page_count,
			fragment_count,
			avg_record_size_in_bytes,
			min_record_size_in_bytes,
			max_record_size_in_bytes
		FROM	sys.dm_db_index_physical_stats(DB_ID(), @object_id, NULL, NULL, 'DETAILED')
		
		SELECT	@RowId = @RowId - 1
	END
-- Return all the data
SELECT * FROM @ObjectSpaceUsageReport 
