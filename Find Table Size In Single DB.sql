-- Find Table Size and RowCount and Published tables
DECLARE	 @top INT
	, @include_system_tables BIT;

SELECT	@include_system_tables = 0;

BEGIN

	SELECT	[TableName]
		, IsPublished
		, (SELECT rows FROM sysindexes s WHERE s.indid < 2 AND s.id = OBJECT_ID(a.[TableName])) AS [RowCount]
		, [TotalSpaceUsed(MB)]

--INTO tempdb.dbo.LmsTableSize
	FROM
		(
		SELECT	QUOTENAME(SCHEMA_NAME(so.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id)) AS [TableName]
				, o.is_published AS IsPublished
				, CONVERT(numeric(15,2),(((CONVERT(numeric(15,2),SUM(i.reserved)) * (SELECT low FROM master.dbo.spt_values (NOLOCK) WHERE number = 1 AND type = 'E')) / 1024.)/1024.)) AS [TotalSpaceUsed(MB)]
		FROM	sys.sysindexes AS i WITH (NOLOCK)
			INNER JOIN sys.sysobjects AS so WITH (NOLOCK)
				ON i.id = so.id
				AND	((@include_system_tables = 1 AND so.type IN ('U', 'S')) OR so.type = 'U')
				AND ((@include_system_tables = 1)OR (OBJECTPROPERTY(i.id, 'IsMSShipped') = 0))
			INNER JOIN sys.objects AS o WITH (NOLOCK)
				ON	so.id = o.object_id
		WHERE	i.indid IN (0, 1, 255)
		--AND		i.rows = 0
		--AND		i.reserved = 0.00 
		GROUP BY	QUOTENAME(SCHEMA_NAME(so.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id)), o.is_published
	
		) AS a
	ORDER BY
		 -- [RowCount],
		  [TableName]--,
		 --[TotalSpaceUsed(MB)] DESC
END
