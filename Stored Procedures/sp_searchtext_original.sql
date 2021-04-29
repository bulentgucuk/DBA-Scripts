-- <Migration ID="351b7531-36f7-436a-b83a-80b2e457099a" />
GO
/*
First, here's a list of sp_searchtext parameters:
•@Search_String - Text string to search for in the current database
•@Xtypes - Comma-delimited list of object types that include and exclude what objects to search in
•@Case_Sensitive - Whether the search is case sensitive or not. The default is case insensitive
•@Name - Include results that have a name that includes @Name
•@Schema - Include results that have a schema name that includes @Schema
•@Refine_Search_String - Second search string
•@Exclude_Name - Exclude results that have a name that includes @Exclude_Name
•@Exclude_Schema - Exclude results that have a schema name that includes @Exclude_Schema
•@Exclude_Search_String - Exclude results that have @Exclude_Search_String

There are no wildcards in @Search_String parameter or any other string parameters. All wildcard characters are treated as literal characters, so % and _ are just regular characters like any other one.

Xtype is a type of object, denoted by a code of char(2). MSDN has a list of all types. You don't have to memorise it all by heart. You'll remember the useful ones as you go along. Here are the most common ones:
•U = User table
•V = View
•P = Stored procedure
•FN = Scalar function
•TF = Table function
•TT = Table type

What sp_searchtext results are? Each row is one object (table, view, stored procedure, function, ...) in the database that the string was found with it. The columns are:
•schema - The schema of the object
•name - The name of the object
•type - The type of the object
•type_desc - The type's description of the object
•sp_helptext - A script that gets the full text of the object
•sp_help - A script that gets various details on the object. Very useful with user tables
•sp_columns - A script that gets the list of the object's columns
•sysobjects - A script that gets the object from sys.sysobjects table
•sp_searchtext - A script to search for the name of the object

EXAMPLES
exec [dev].[sp_searchtext] 'BusinessEntityID'      -- all objects with 'BusinessEntityID'
exec [dev].[sp_searchtext] 'BusinessEntityID',p    -- stored procedures with 'BusinessEntityID'
exec [dev].[sp_searchtext] 'BusinessEntityID','-p' -- everything except stored procedures

exec [dev].[sp_searchtext] ''   -- all objects
exec [dev].[sp_searchtext] '',u -- all user tables
exec [dev].[sp_searchtext] '',p -- all stored procedures

Mulitple Items
exec [dev].[sp_searchtext] 'BusinessEntityID','-f,-pk,-tr' -- everything except PKs, FKs, Triggers
exec [dev].[sp_searchtext] 'BusinessEntityID','u,v,p,fn,tf,tt' -- "interesting" objects

USER TABLES
exec [dev].[sp_searchtext] 'BusinessEntityID',u
exec [dev].[sp_searchtext] 'BusinessEntityID',u,@Schema='Person'

FILTER BY NAME and SCHEMA
exec [dev].[sp_searchtext] 'BusinessEntityID',@Name='Employee'
exec [dev].[sp_searchtext] 'BusinessEntityID',p,@Name='Employee'
exec [dev].[sp_searchtext] 'BusinessEntityID',p,@Name='Employee',@Schema='HumanResources'

CASE SENSITIVITY
-- all objects with 'BusinessEntityID' case insensitive
exec [dev].[sp_searchtext] 'BusinessEntityID'
exec [dev].[sp_searchtext] 'BUSINESSENTITYID'
exec [dev].[sp_searchtext] 'BUSINESSENTITYID','',0

-- all objects with 'BUSINESSENTITYID' case sensitive
exec [dev].[sp_searchtext] 'BUSINESSENTITYID','',1
exec [dev].[sp_searchtext] 'BUSINESSENTITYID',@Case_Sensitive=1

Refine & Exclude Search

Hide   Copy Code
exec [dev].[sp_searchtext] 'BusinessEntityID',p,@Refine_Search_String='Update'

exec [dev].[sp_searchtext] 'BusinessEntityID',p,
    @Exclude_Name='Update',
    @Exclude_Schema='HumanResources',
    @Exclude_Search_String='Update'



*/
CREATE OR ALTER PROCEDURE dbo.sp_searchtext
	@Search_String NVARCHAR(4000),
	@Xtypes NVARCHAR(100) = NULL,
	@Case_Sensitive BIT = 0,
	@Name NVARCHAR(4000) = NULL,
	@Schema NVARCHAR(4000) = NULL,
	@Refine_Search_String NVARCHAR(4000) = NULL,
	@Exclude_Name NVARCHAR(4000) = NULL,
	@Exclude_Schema NVARCHAR(4000) = NULL,
	@Exclude_Search_String NVARCHAR(4000) = NULL
AS 
BEGIN
	SET NOCOUNT ON;
	
	-- reserved chars
	if @Search_String is not null
		set @Search_String = replace(replace(replace(@Search_String, '[', '[[]'), '%', '[%]'), '_', '[_]')
	
	if @Name is not null
		set @Name = replace(replace(replace(@Name, '[', '[[]'), '%', '[%]'), '_', '[_]')
	
	if @Refine_Search_String is not null
		set @Refine_Search_String = replace(replace(replace(@Refine_Search_String, '[', '[[]'), '%', '[%]'), '_', '[_]')
	
	if @Schema is not null
		set @Schema = replace(replace(replace(@Schema, '[', '[[]'), '%', '[%]'), '_', '[_]')
	
	if @Exclude_Name is not null
		set @Exclude_Name = replace(replace(replace(@Exclude_Name, '[', '[[]'), '%', '[%]'), '_', '[_]')
	
	if @Exclude_Search_String is not null
		set @Exclude_Search_String = replace(replace(replace(@Exclude_Search_String, '[', '[[]'), '%', '[%]'), '_', '[_]')
	
	if @Exclude_Schema is not null
		set @Exclude_Schema = replace(replace(replace(@Exclude_Schema, '[', '[[]'), '%', '[%]'), '_', '[_]')
	

	-- xtypes
	declare @Include_Types table (xtype char(2))
	declare @Exclude_Types table (xtype char(2))

	if @Xtypes is not null and @Xtypes <> ''
	begin
		declare @xtype nvarchar(10)
		declare @From_Index int = 1
		declare @To_Index int = charindex(',', @Xtypes)
		IF @To_Index <> 0
		begin
			while @To_Index <> 0
			begin
				set @xtype = ltrim(rtrim(substring(@Xtypes, @From_Index, @To_Index - @From_Index)))
				if left(@xtype,1) = '-' and len(@xtype) between 2 and 3
					insert into @Exclude_Types values(upper(right(@xtype,len(@xtype)-1)))
				ELSE IF LEN(@xtype) BETWEEN 1 AND 2
					INSERT INTO @Include_Types VALUES(UPPER(@xtype))

				set @From_Index = @To_Index + 1
				set @To_Index = charindex(',', @Xtypes, @From_Index)
				
				IF @To_Index = 0
				BEGIN
					set @xtype = ltrim(rtrim(substring(@Xtypes, @From_Index, len(@Xtypes))))
					IF LEFT(@xtype,1) = '-' AND LEN(@xtype) BETWEEN 2 AND 3
						insert into @Exclude_Types values(upper(right(@xtype,len(@xtype)-1)))
					ELSE IF LEN(@xtype) BETWEEN 1 AND 2
						INSERT INTO @Include_Types VALUES(UPPER(@xtype))
				END
			END
		END
		ELSE
		BEGIN
			set @xtype = ltrim(rtrim(@Xtypes))
			IF LEFT(@xtype,1) = '-' AND LEN(@xtype) BETWEEN 2 AND 3
				insert into @Exclude_Types values(upper(right(@xtype,len(@xtype)-1)))
			ELSE IF LEN(@xtype) BETWEEN 1 AND 2
				INSERT INTO @Include_Types VALUES(UPPER(@xtype))
		END
	END
	
	declare @IsIncludeTypes	int = (case when exists(select top 1 xtype from @Include_Types) then 1 else 0 end)
	declare @IsExcludeTypes	int = (case when exists(select top 1 xtype from @Exclude_Types) then 1 else 0 end)


	-- objects
	declare @objects table (
		id int, 
		xtype char(2),
		name sysname,
		[schema] sysname
	)
	
	if @Case_Sensitive is null or @Case_Sensitive = 0
	begin

		-- sysobjects
		insert into @objects
		select so.id, so.xtype, so.name, ss.name
		from sys.sysobjects so with (nolock)
		inner join sys.schemas ss with (nolock) on so.[uid] = ss.[schema_id]
		left outer join sys.syscomments sc with (nolock) on so.id = sc.id
		where (so.xtype <> 'TT')
		and (so.name like '%' + @Search_String + '%' or sc.[text] like '%' + @Search_String + '%')
		and (@IsIncludeTypes = 0 or so.xtype in (select xtype from @Include_Types))
		and (@IsExcludeTypes = 0 or so.xtype not in (select xtype from @Exclude_Types))
		and (@Name is null or @Name = '' or so.name like '%' + @Name + '%')
		and (@Exclude_Name is null or @Exclude_Name = '' or so.name not like '%' + @Exclude_Name + '%')
		and (@Refine_Search_String is null or @Refine_Search_String = '' or (so.name like '%' + @Refine_Search_String + '%' or sc.[text] like '%' + @Refine_Search_String + '%'))
		and (@Exclude_Search_String is null or @Exclude_Search_String = '' or (so.name not like '%' + @Exclude_Search_String + '%' and sc.[text] not like '%' + @Exclude_Search_String + '%'))
		and (@Schema is null or @Schema = '' or ss.name like '%' + @Schema + '%')
		and (@Exclude_Schema is null or @Exclude_Schema = '' or ss.name not like '%' + @Exclude_Schema + '%')

		-- sysobjects Table type
		insert into @objects
		select so.id, so.xtype, stt.name, ss.name
		from sys.sysobjects so with (nolock)
		inner join sys.table_types stt with (nolock) on so.id = stt.type_table_object_id
		inner join sys.schemas ss with (nolock) on stt.[schema_id] = ss.[schema_id]
		left outer join sys.syscomments sc with (nolock) on so.id = sc.id
		where (so.xtype = 'TT')
		and (stt.name like '%' + @Search_String + '%' or sc.[text] like '%' + @Search_String + '%')
		and (@IsIncludeTypes = 0 or so.xtype in (select xtype from @Include_Types))
		and (@IsExcludeTypes = 0 or so.xtype not in (select xtype from @Exclude_Types))
		and (@Name is null or @Name = '' or stt.name like '%' + @Name + '%')
		and (@Exclude_Name is null or @Exclude_Name = '' or stt.name not like '%' + @Exclude_Name + '%')
		and (@Refine_Search_String is null or @Refine_Search_String = '' or (stt.name like '%' + @Refine_Search_String + '%' or sc.[text] like '%' + @Refine_Search_String + '%'))
		and (@Exclude_Search_String is null or @Exclude_Search_String = '' or (stt.name not like '%' + @Exclude_Search_String + '%' and sc.[text] not like '%' + @Exclude_Search_String + '%'))
		and (@Schema is null or @Schema = '' or ss.name like '%' + @Schema + '%')
		and (@Exclude_Schema is null or @Exclude_Schema = '' or ss.name not like '%' + @Exclude_Schema + '%')

		-- column objects
		insert into @objects
		select so.id, so.xtype, so.name, ss.name
		from sys.columns c with (nolock)
		inner join sys.sysobjects so with (nolock) on c.[object_id] = so.id
		inner join sys.schemas ss with (nolock) on so.[uid] = ss.[schema_id]
		where (so.xtype <> 'TT')
		and (c.name like '%' + @Search_String + '%')
		and (@IsIncludeTypes = 0 or so.xtype in (select xtype from @Include_Types))
		and (@IsExcludeTypes = 0 or so.xtype not in (select xtype from @Exclude_Types))
		and (@Name is null or @Name = '' or so.name like '%' + @Name + '%')
		and (@Exclude_Name is null or @Exclude_Name = '' or so.name not like '%' + @Exclude_Name + '%')
		and (@Refine_Search_String is null or @Refine_Search_String = '' or c.name like '%' + @Refine_Search_String + '%')
		and (@Exclude_Search_String is null or @Exclude_Search_String = '' or c.name not like '%' + @Exclude_Search_String + '%')
		and (@Schema is null or @Schema = '' or ss.name like '%' + @Schema + '%')
		and (@Exclude_Schema is null or @Exclude_Schema = '' or ss.name not like '%' + @Exclude_Schema + '%')
		
		-- column objects Table type
		INSERT INTO @objects
		SELECT so.id, so.xtype, stt.name, ss.name
		FROM sys.sysobjects so WITH (NOLOCK)
		INNER JOIN sys.table_types stt WITH (NOLOCK) ON so.id = stt.type_table_object_id
		INNER JOIN sys.schemas ss WITH (NOLOCK) ON stt.[schema_id] = ss.[schema_id]
		INNER JOIN sys.columns c WITH (NOLOCK) ON c.[object_id] = stt.type_table_object_id
		WHERE (so.xtype = 'TT')
		AND (c.name LIKE '%' + @Search_String + '%')
		AND (@IsIncludeTypes = 0 OR so.xtype IN (SELECT xtype FROM @Include_Types))
		AND (@IsExcludeTypes = 0 OR so.xtype NOT IN (SELECT xtype FROM @Exclude_Types))
		AND (@Name IS NULL OR @Name = '' OR stt.name LIKE '%' + @Name + '%')
		AND (@Exclude_Name IS NULL OR @Exclude_Name = '' OR stt.name NOT LIKE '%' + @Exclude_Name + '%')
		AND (@Refine_Search_String IS NULL OR @Refine_Search_String = '' OR c.name LIKE '%' + @Refine_Search_String + '%')
		AND (@Exclude_Search_String IS NULL OR @Exclude_Search_String = '' OR c.name NOT LIKE '%' + @Exclude_Search_String + '%')
		AND (@Schema IS NULL OR @Schema = '' OR ss.name LIKE '%' + @Schema + '%')
		AND (@Exclude_Schema IS NULL OR @Exclude_Schema = '' OR ss.name NOT LIKE '%' + @Exclude_Schema + '%')

	END
	ELSE IF @Case_Sensitive = 1
	BEGIN

		-- sysobjects
		insert into @objects
		select so.id, so.xtype, so.name, ss.name
		from sys.sysobjects so with (nolock)
		inner join sys.schemas ss with (nolock) on so.[uid] = ss.[schema_id]
		left outer join sys.syscomments sc with (nolock) on so.id = sc.id
		where (so.xtype <> 'TT')
		and (so.name collate Latin1_General_BIN like '%' + @Search_String + '%' collate Latin1_General_BIN or sc.[text] collate Latin1_General_BIN like '%' + @Search_String + '%' collate Latin1_General_BIN)
		and (@IsIncludeTypes = 0 or so.xtype in (select xtype from @Include_Types))
		and (@IsExcludeTypes = 0 or so.xtype not in (select xtype from @Exclude_Types))
		and (@Name is null or @Name = '' or so.name collate Latin1_General_BIN like '%' + @Name + '%' collate Latin1_General_BIN)
		and (@Exclude_Name is null or @Exclude_Name = '' or so.name collate Latin1_General_BIN not like '%' + @Exclude_Name + '%' collate Latin1_General_BIN)
		and (@Refine_Search_String is null or @Refine_Search_String = '' or (so.name collate Latin1_General_BIN like '%' + @Refine_Search_String + '%' collate Latin1_General_BIN or sc.[text] collate Latin1_General_BIN like '%' + @Refine_Search_String + '%' collate Latin1_General_BIN))
		and (@Exclude_Search_String is null or @Exclude_Search_String = '' or (so.name collate Latin1_General_BIN not like '%' + @Exclude_Search_String + '%' collate Latin1_General_BIN and sc.[text] collate Latin1_General_BIN not like '%' + @Exclude_Search_String + '%' collate Latin1_General_BIN))
		and (@Schema is null or @Schema = '' or ss.name collate Latin1_General_BIN like '%' + @Schema + '%' collate Latin1_General_BIN)
		and (@Exclude_Schema is null or @Exclude_Schema = '' or ss.name collate Latin1_General_BIN not like '%' + @Exclude_Schema + '%' collate Latin1_General_BIN)

		-- sysobjects Table type
		insert into @objects
		select so.id, so.xtype, stt.name, ss.name
		from sys.sysobjects so with (nolock)
		inner join sys.table_types stt with (nolock) on so.id = stt.type_table_object_id
		inner join sys.schemas ss with (nolock) on stt.[schema_id] = ss.[schema_id]
		left outer join sys.syscomments sc with (nolock) on so.id = sc.id
		where (so.xtype = 'TT')
		and (stt.name collate Latin1_General_BIN like '%' + @Search_String + '%' collate Latin1_General_BIN or sc.[text] collate Latin1_General_BIN like '%' + @Search_String + '%' collate Latin1_General_BIN)
		and (@IsIncludeTypes = 0 or so.xtype in (select xtype from @Include_Types))
		and (@IsExcludeTypes = 0 or so.xtype not in (select xtype from @Exclude_Types))
		and (@Name is null or @Name = '' or stt.name collate Latin1_General_BIN like '%' + @Name + '%' collate Latin1_General_BIN)
		and (@Exclude_Name is null or @Exclude_Name = '' or stt.name collate Latin1_General_BIN not like '%' + @Exclude_Name + '%' collate Latin1_General_BIN)
		and (@Refine_Search_String is null or @Refine_Search_String = '' or (stt.name collate Latin1_General_BIN like '%' + @Refine_Search_String + '%' collate Latin1_General_BIN or sc.[text] collate Latin1_General_BIN like '%' + @Refine_Search_String + '%' collate Latin1_General_BIN))
		and (@Exclude_Search_String is null or @Exclude_Search_String = '' or (stt.name collate Latin1_General_BIN not like '%' + @Exclude_Search_String + '%' collate Latin1_General_BIN and sc.[text] collate Latin1_General_BIN not like '%' + @Exclude_Search_String + '%' collate Latin1_General_BIN))
		and (@Schema is null or @Schema = '' or ss.name collate Latin1_General_BIN like '%' + @Schema + '%' collate Latin1_General_BIN)
		and (@Exclude_Schema is null or @Exclude_Schema = '' or ss.name collate Latin1_General_BIN not like '%' + @Exclude_Schema + '%' collate Latin1_General_BIN)

		-- column objects
		insert into @objects
		select so.id, so.xtype, so.name, ss.name
		from sys.columns c with (nolock)
		inner join sys.sysobjects so with (nolock) on c.[object_id] = so.id
		inner join sys.schemas ss with (nolock) on so.[uid] = ss.[schema_id]
		where (so.xtype <> 'TT')
		and (c.name collate Latin1_General_BIN like '%' + @Search_String + '%' collate Latin1_General_BIN)
		and (@IsIncludeTypes = 0 or so.xtype in (select xtype from @Include_Types))
		and (@IsExcludeTypes = 0 or so.xtype not in (select xtype from @Exclude_Types))
		and (@Name is null or @Name = '' or so.name collate Latin1_General_BIN like '%' + @Name + '%' collate Latin1_General_BIN)
		and (@Exclude_Name is null or @Exclude_Name = '' or so.name collate Latin1_General_BIN not like '%' + @Exclude_Name + '%' collate Latin1_General_BIN)
		and (@Refine_Search_String is null or @Refine_Search_String = '' or c.name collate Latin1_General_BIN like '%' + @Refine_Search_String + '%' collate Latin1_General_BIN)
		and (@Exclude_Search_String is null or @Exclude_Search_String = '' or c.name collate Latin1_General_BIN not like '%' + @Exclude_Search_String + '%' collate Latin1_General_BIN)
		and (@Schema is null or @Schema = '' or ss.name collate Latin1_General_BIN like '%' + @Schema + '%' collate Latin1_General_BIN)
		and (@Exclude_Schema is null or @Exclude_Schema = '' or ss.name collate Latin1_General_BIN not like '%' + @Exclude_Schema + '%' collate Latin1_General_BIN)
		
		-- column objects Table type
		INSERT INTO @objects
		SELECT so.id, so.xtype, stt.name, ss.name
		FROM sys.sysobjects so WITH (NOLOCK)
		INNER JOIN sys.table_types stt WITH (NOLOCK) ON so.id = stt.type_table_object_id
		INNER JOIN sys.schemas ss WITH (NOLOCK) ON stt.[schema_id] = ss.[schema_id]
		INNER JOIN sys.columns c WITH (NOLOCK) ON c.[object_id] = stt.type_table_object_id
		WHERE (so.xtype = 'TT')
		AND (c.name COLLATE Latin1_General_BIN LIKE '%' + @Search_String + '%' COLLATE Latin1_General_BIN)
		AND (@IsIncludeTypes = 0 OR so.xtype IN (SELECT xtype FROM @Include_Types))
		AND (@IsExcludeTypes = 0 OR so.xtype NOT IN (SELECT xtype FROM @Exclude_Types))
		AND (@Name IS NULL OR @Name = '' OR stt.name COLLATE Latin1_General_BIN LIKE '%' + @Name + '%' COLLATE Latin1_General_BIN)
		AND (@Exclude_Name IS NULL OR @Exclude_Name = '' OR stt.name COLLATE Latin1_General_BIN NOT LIKE '%' + @Exclude_Name + '%' COLLATE Latin1_General_BIN)
		AND (@Refine_Search_String IS NULL OR @Refine_Search_String = '' OR c.name COLLATE Latin1_General_BIN LIKE '%' + @Refine_Search_String + '%' COLLATE Latin1_General_BIN)
		AND (@Exclude_Search_String IS NULL OR @Exclude_Search_String = '' OR c.name COLLATE Latin1_General_BIN NOT LIKE '%' + @Exclude_Search_String + '%' COLLATE Latin1_General_BIN)
		AND (@Schema IS NULL OR @Schema = '' OR ss.name COLLATE Latin1_General_BIN LIKE '%' + @Schema + '%' COLLATE Latin1_General_BIN)
		AND (@Exclude_Schema IS NULL OR @Exclude_Schema = '' OR ss.name COLLATE Latin1_General_BIN NOT LIKE '%' + @Exclude_Schema + '%' COLLATE Latin1_General_BIN)

	END


	SELECT DISTINCT
		[schema],
		name,
		[type] = LTRIM(RTRIM(xtype)),

		-- http://msdn.microsoft.com/en-us/library/ms177596.aspx
		type_desc = (CASE 
			WHEN xtype = 'AF' THEN 'Aggregate function (CLR)'
			WHEN xtype = 'C'  THEN 'CHECK constraint'
			WHEN xtype = 'D'  THEN 'Default or DEFAULT constraint'
			WHEN xtype = 'F'  THEN 'FOREIGN KEY constraint'
			WHEN xtype = 'FN' THEN 'Scalar function'
			WHEN xtype = 'FS' THEN 'Assembly (CLR) scalar-function'
			WHEN xtype = 'FT' THEN 'Assembly (CLR) table-valued function'
			WHEN xtype = 'IF' THEN 'In-lined table-function'
			WHEN xtype = 'IT' THEN 'Internal table'
			WHEN xtype = 'L'  THEN 'Log'
			WHEN xtype = 'P'  THEN 'Stored procedure'
			WHEN xtype = 'PC' THEN 'Assembly (CLR) stored-procedure'
			WHEN xtype = 'PK' THEN 'PRIMARY KEY constraint (type is K)'
			WHEN xtype = 'RF' THEN 'Replication filter stored procedure'
			WHEN xtype = 'S'  THEN 'System table'
			WHEN xtype = 'SN' THEN 'Synonym'
			WHEN xtype = 'SQ' THEN 'Service queue'
			WHEN xtype = 'TA' THEN 'Assembly (CLR) DML trigger'
			WHEN xtype = 'TF' THEN 'Table function'
			WHEN xtype = 'TR' THEN 'SQL DML Trigger'
			WHEN xtype = 'TT' THEN 'Table type'
			WHEN xtype = 'U'  THEN 'User table'
			WHEN xtype = 'UQ' THEN 'UNIQUE constraint (type is K)'
			WHEN xtype = 'V'  THEN 'View'
			WHEN xtype = 'X'  THEN 'Extended stored procedure'
			ELSE '' END
		),

		[sp_helptext] = (CASE WHEN xtype NOT IN ('AF','F','FS','PK','TT','U','UQ') THEN ('exec sp_helptext ''' + [schema] + '.' + name + '''') ELSE '' END),

		[sp_help] = (CASE WHEN xtype NOT IN ('TT') THEN ('exec sp_help ''' + [schema] + '.' + name + '''') ELSE '' END),
		
		[sp_columns] = (CASE 
			WHEN xtype IN ('S','SN','TF','U','V') THEN 'exec sp_columns ' + name 
			WHEN xtype IN ('TT') THEN 
				'select *' + ' ' +
				'from sys.columns with (nolock)' + ' ' +
				'where [object_id] = ' + CAST(id AS VARCHAR) + ' ' +
				'order by column_id'
			WHEN xtype IN ('PK','UQ') THEN 
				'select Table_Name = schema_name(kc.[schema_id]) + ''.'' + object_name(kc.parent_object_id), Column_Name = col_name(ic.[object_id], ic.column_id), Sort_Order = (case when ic.is_descending_key = 1 then ''DESC'' else ''ASC'' end)' + ' ' +
				'from sys.key_constraints kc with (nolock)' + ' ' +
				'inner join sys.index_columns ic with (nolock) on kc.parent_object_id = ic.[object_id] and kc.unique_index_id = ic.index_id' + ' ' +
				'where kc.[object_id] = ' + CAST(id AS VARCHAR) + ' ' +
				'order by ic.key_ordinal'
			WHEN xtype IN ('F') THEN 
				'select Foreign_Key = schema_name(f.[schema_id]) + ''.'' + f.name,' + ' ' +
				'Foreign_Table = schema_name(sop.[uid]) + ''.'' + object_name(f.parent_object_id),' + ' ' +
				'Foreign_Column = col_name(fc.parent_object_id, fc.parent_column_id),' + ' ' +
				'Primary_Table = schema_name(sof.[uid]) + ''.'' + object_name(f.referenced_object_id),' + ' ' +
				'Primary_Column = col_name(fc.referenced_object_id, fc.referenced_column_id)' + ' ' +
				'from sys.foreign_keys f with (nolock)' + ' ' +
				'inner join sys.foreign_key_columns fc with (nolock)' + ' ' +
				'on f.[object_id] = fc.constraint_object_id' + ' ' +
				'and f.[object_id] = ' + CAST(id AS VARCHAR) + ' ' +
				'inner join sys.sysobjects sop with (nolock) on sop.id = f.parent_object_id' + ' ' +
				'inner join sys.sysobjects sof with (nolock) on sof.id = f.referenced_object_id'
			WHEN xtype IN ('D') THEN 
				'select Table_Name = schema_name([schema_id]) + ''.'' + object_name(parent_object_id), Column_Name = col_name(parent_object_id, parent_column_id)' + ' ' +
				'from sys.default_constraints with (nolock)' + ' ' +
				'where [object_id] = ' +  + CAST(id AS VARCHAR)
			ELSE '' END),

		[sysobjects] = 'select * from sys.sysobjects with (nolock) where id = ' + CAST(id AS VARCHAR),

		[sp_searchtext] = 'exec [dev].[sp_searchtext] ''' + name + ''''

	FROM @objects
	ORDER BY type_desc, [schema], name

END
	

GO


