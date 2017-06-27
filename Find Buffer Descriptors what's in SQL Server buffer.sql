--DMV to view the buffer descriptors
SELECT	so.name,*
FROM	sys.dm_os_buffer_descriptors AS obd
	INNER JOIN sys.allocation_units AS au
		ON obd.allocation_unit_id = au.allocation_unit_id
	INNER JOIN sys.partitions AS part
		ON au.container_id = part.hobt_id
	INNER JOIN sys.objects AS so
		ON part.object_id = so.object_id
WHERE	obd.database_id = DB_ID()
AND		so.is_ms_shipped = 0

