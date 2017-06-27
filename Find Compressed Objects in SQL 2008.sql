-- Find Compressed objects in SQL 2008
SELECT	st.name,
		st.object_id,
		sp.partition_id,
		sp.partition_number,
		sp.data_compression,
		sp.data_compression_desc
FROM sys.partitions SP
	INNER JOIN sys.tables ST
		ON st.object_id = sp.object_id
WHERE data_compression <> 0