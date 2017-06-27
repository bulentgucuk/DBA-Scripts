-- This step will be executed when the hour is between 6 amd and 22 pm
IF	(SELECT	DATEPART(HH, GETDATE())) >= 6
	AND
	(SELECT	DATEPART(HH, GETDATE())) <= 22
	BEGIN
		USE NetQuote
		-- Declare table variable to store table names
		DECLARE	@Stats TABLE (
			RowId INT IDENTITY (1,1),
			TableName VARCHAR (255)
			)
		-- Declare other variables to store values
		DECLARE	@top int,
				@include_system_tables 	bit,
				@RowId INT,
				@Str NVARCHAR (500)
		-- Don't include system tables for the operation
		SELECT	@include_system_tables = 0

		-- Insert user tables with more than 1000 rows into the table variable
		SET NOCOUNT ON
		INSERT INTO @Stats (TableName)
		SELECT	[Table Name]
		FROM	(
			SELECT	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id)) AS [Table Name],
					CONVERT(numeric(15,2),(((CONVERT(numeric(15,2),SUM(i.reserved)) * (SELECT low FROM master.dbo.spt_values (NOLOCK) WHERE number = 1 AND type = 'E')) / 1024.)/1024.)) AS [Total space used (MB)]
			FROM	sysindexes i (NOLOCK)
				INNER JOIN 	sysobjects o (NOLOCK) 
					ON	i.id = o.id AND 
				((@include_system_tables = 1 AND o.type IN ('U', 'S')) OR o.type = 'U') AND 
				((@include_system_tables = 1)OR (OBJECTPROPERTY(i.id, 'IsMSShipped') = 0))
			WHERE	indid IN (0, 1, 255)
			AND		ROWS > 1000
			GROUP BY	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id))
			) AS A

		-- Get the maxid from table variable and go into the while loop to run update stats
		SELECT	@RowId = MAX(RowId) FROM @Stats
		WHILE	@RowId > 0
			BEGIN
				SELECT	@Str = ''
				SELECT	@Str = 'Update Statistics ' + TableName + ' WITH SAMPLE 10 PERCENT'
				FROM	@Stats
				WHERE	RowId = @RowId
				PRINT	@STR
				EXEC	SP_EXECUTESQL @Stmt = @str
				SELECT	@RowId = @RowId - 1
			END
	END
