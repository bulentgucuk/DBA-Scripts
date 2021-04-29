CREATE PROC sp_who4
AS
BEGIN
	IF OBJECT_ID('tempdb..#res') IS NOT NULL 
	BEGIN 
		DROP TABLE #res;
	END;

	WITH XMLNAMESPACES(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
	BlkSessions
	AS (
		SELECT	blk_sei.spid AS session_id, NULLIF(blk_sei.blocked, 0) AS blocked_by, NULL AS group_num
		FROM	sys.sysprocesses blk_sei
		WHERE	blk_sei.blocked <> 0 
		UNION ALL
		SELECT	blk_blk.session_id, NULL AS blocked_by, ROW_NUMBER() OVER(ORDER BY blk_blk.session_id)  AS group_num
		FROM (
			SELECT	blk_sei.spid AS session_id
			FROM	sys.sysprocesses blk_sei
			WHERE	EXISTS(SELECT * FROM sys.dm_os_waiting_tasks dmowt WHERE dmowt.blocking_session_id = blk_sei.spid) -- blk_sei.blocked = 0
			AND		NOT EXISTS(SELECT * FROM sys.dm_os_waiting_tasks dmowt WHERE dmowt.session_id = blk_sei.spid) -- blk_sei.blocked = 0
			UNION ALL
			SELECT	blk_se.spid AS session_id
			FROM	(
				-- I'm not sure if bellow session_id s are returned by sys.sysprocesses.spid or not. If not then this query will return these values to allow the generation of hierarchyid values
				SELECT -2 UNION ALL
				SELECT -3 UNION ALL
				SELECT -4
			) AS blk_se(spid) -- Abnormal session_id. See https://docs.microsoft.com/en-us/sql/relational-databases/system-compatibility-views/sys-sysprocesses-transact-sql
			WHERE	EXISTS(SELECT * FROM sys.sysprocesses blk_sei WHERE	blk_sei.blocked = blk_se.spid)
			AND		NOT EXISTS(SELECT * FROM sys.sysprocesses blk_sei WHERE	blk_sei.spid = blk_se.spid)
		) blk_blk
	), BlkSessionsRecursion
	AS (
		SELECT	blk_ses.group_num, CONVERT(HIERARCHYID, '/' + LTRIM(blk_ses.session_id) + '/') AS hid, blk_ses.session_id, blk_ses.blocked_by
		FROM	BlkSessions blk_ses
		WHERE	blk_ses.blocked_by IS NULL 
		UNION ALL
		SELECT	blk_hd.group_num, CONVERT(HIERARCHYID, blk_hd.hid.ToString() + LTRIM(blk_ses.session_id) + '/') AS hid, blk_ses.session_id, blk_ses.blocked_by
		FROM	BlkSessionsRecursion blk_hd 
		JOIN	BlkSessions blk_ses ON blk_ses.blocked_by = blk_hd.session_id
	), BlkHierarchy
	AS (
		SELECT	blk_hid.group_num, blk_hid.hid, blk_hid.hid.ToString() AS blocking_connections, blk_hid.session_id
		FROM	BlkSessionsRecursion blk_hid
	)
	SELECT	blk_hi.group_num, blk_hi.blocking_connections, QUOTENAME(blk.connection_db) AS connection_db, blk_sql.obct, blk_sql.sql_statement, blk.[status], blk.transaction_count, blk.wait_type, blk_lok.resource_type, blk.cpu, blk.wait_duration, blk.reads, blk.writes, qp.query_plan, qp.[indexes], blk.[sql_handle], CASE WHEN blk_hi.blocking_connections IS NULL THEN 0 ELSE 1 END AS is_blocked, blk.resource_description wait_description, blk.hst_name, blk.program_name, blk.[name], blk_hi.hid, CONVERT(INT, NULL) dbid, CONVERT(BIGINT, NULL) associatedObjectId, CONVERT(NVARCHAR(550), NULL) wait_obct  
	INTO #res
	FROM (
		SELECT	blk_sei.spid AS session_id, blk_sei.hostname AS hst_name, blk_sei.program_name, blk_sei.loginame AS [name], blk_sei.[status], blk_sei.open_tran AS transaction_count,  blk_wt.wait_type, blk_wt.resource_description, blk_wt.resource_address, CONVERT(DECIMAL(38, 4), blk_wt.wait_duration_ms*.1/1000) AS wait_duration, CONVERT(DECIMAL(38, 4), blk_co.cpu_time*.1/1000) AS cpu, blk_co.logical_reads AS reads, blk_co.writes AS writes, DB_NAME(blk_sei.dbid) AS [connection_db], blk_sei.sql_handle AS [sql_handle], blk_sei.stmt_start AS sql_statement_start, blk_sei.stmt_end AS sql_statement_end
		FROM	sys.sysprocesses blk_sei
		OUTER APPLY sys.dm_exec_sql_text(blk_sei.sql_handle) AS blk_txt
		JOIN	sys.dm_exec_sessions blk_co ON blk_co.session_id = blk_sei.spid	
		JOIN	sys.dm_os_waiting_tasks blk_wt ON blk_wt.session_id = blk_co.session_id
		WHERE	blk_sei.blocked <> 0
		UNION ALL
		SELECT	blk_sei.spid AS session_id, blk_sei.hostname AS hst_name, blk_sei.program_name, blk_sei.loginame AS [name], blk_sei.[status], blk_sei.open_tran AS transaction_count, blk_wt.wait_type, blk_wt.resource_description, blk_wt.resource_address, CONVERT(DECIMAL(38, 4), blk_wt.wait_duration_ms*.1/1000) AS wait_duration, CONVERT(DECIMAL(38, 4), blk_co.cpu_time*.1/1000) AS cpu, blk_co.logical_reads AS reads, blk_co.writes AS writes, DB_NAME(blk_sei.dbid) AS [connection_db], blk_sei.sql_handle AS [sql_handle], blk_sei.stmt_start AS sql_statement_start, blk_sei.stmt_end AS sql_statement_end
		FROM	sys.sysprocesses blk_sei
		OUTER APPLY sys.dm_exec_sql_text(blk_sei.sql_handle) AS blk_txt
		JOIN	sys.dm_exec_sessions blk_co ON blk_co.session_id = blk_sei.spid
		LEFT JOIN sys.dm_os_waiting_tasks blk_wt ON blk_wt.session_id = blk_co.session_id
		WHERE	blk_sei.blocked = 0
		AND		EXISTS(SELECT * FROM sys.sysprocesses blk_wt WHERE blk_wt.blocked = blk_sei.spid)
		UNION ALL
		SELECT	blk_se.spid AS session_id, blk_se.[desc] AS hst_name, NULL AS program_name, NULL AS [name], NULL AS [status], NULL AS transaction_count,  NULL AS wait_type, NULL AS resource_description, NULL AS resource_address, NULL AS wait_duration, NULL AS cpu, NULL AS reads, NULL AS writes, NULL AS [connection_db], NULL AS [sql_handle], NULL AS sql_statement_start, NULL AS sql_statement_end
		FROM	(
			-- I'm not sure if bellow session_id s are returned by sys.sysprocesses.spid or not. If not then this query will return these values to allow the generation of hierarchyid values
			SELECT -2, 'The blocking resource is owned by an orphaned distributed transaction.' UNION ALL
			SELECT -3, 'The blocking resource is owned by a deferred recovery transaction.' UNION ALL
			SELECT -4, 'Session ID of the blocking latch owner could not be determined due to internal latch state transitions.'
		) AS blk_se(spid, [desc]) -- Abnormal session_id. See https://docs.microsoft.com/en-us/sql/relational-databases/system-compatibility-views/sys-sysprocesses-transact-sql?view=sql-server-200019
		WHERE	EXISTS(SELECT * FROM sys.sysprocesses blk_sei WHERE	blk_sei.blocked = blk_se.spid)
		AND		NOT EXISTS(SELECT * FROM sys.sysprocesses blk_sei WHERE	blk_sei.spid = blk_se.spid)
		UNION ALL
		SELECT	blk_sei.spid AS session_id, blk_sei.hostname AS hst_name, blk_sei.program_name, blk_sei.loginame AS [name], blk_sei.[status], blk_sei.open_tran AS transaction_count, blk_wt.wait_type, blk_wt.resource_description, blk_wt.resource_address, CONVERT(DECIMAL(38, 4), blk_wt.wait_duration_ms*.1/1000) AS wait_duration, CONVERT(DECIMAL(38, 4), blk_co.cpu_time*.1/1000) AS cpu, blk_co.logical_reads AS reads, blk_co.writes AS writes, DB_NAME(blk_sei.dbid) AS [connection_db], blk_sei.sql_handle AS [sql_handle], blk_sei.stmt_start AS sql_statement_start, blk_sei.stmt_end AS sql_statement_end
		FROM	sys.sysprocesses blk_sei
		OUTER APPLY sys.dm_exec_sql_text(blk_sei.sql_handle) AS blk_txt
		JOIN	sys.dm_exec_sessions blk_co ON blk_co.session_id = blk_sei.spid
		LEFT JOIN sys.dm_os_waiting_tasks blk_wt ON blk_wt.session_id = blk_co.session_id AND /*CXCONSUMER,CXPACKET*/blk_co.session_id <> blk_wt.blocking_session_id 
		WHERE	blk_sei.spid <> @@SPID -- By default, current session will be excluded
		AND		blk_sei.ecid = 0
		AND		EXISTS(
			SELECT	*
			FROM	sys.dm_exec_requests der 
			WHERE	der.session_id = blk_sei.spid
			AND		der.status IN (N'suspended', N'running', N'runnable')
			AND		NOT EXISTS(SELECT * FROM sys.dm_os_waiting_tasks dowt WHERE /*CXCONSUMER,CXPACKET*/dowt.session_id <> dowt.blocking_session_id AND dowt.session_id = der.session_id)
			AND		NOT EXISTS(SELECT * FROM sys.dm_os_waiting_tasks dowt WHERE /*CXCONSUMER,CXPACKET*/dowt.session_id <> dowt.blocking_session_id AND dowt.blocking_session_id = der.session_id)
		)
	) blk
	LEFT JOIN sys.dm_tran_locks blk_lok ON blk_lok.lock_owner_address = blk.resource_address
	LEFT JOIN BlkHierarchy blk_hi ON blk_hi.session_id = blk.session_id
	OUTER APPLY (
		SELECT
			obct = QUOTENAME(DB_NAME(blk_sqltxt.dbid)) + '.' + QUOTENAME(OBJECT_SCHEMA_NAME(blk_sqltxt.objectid, blk_sqltxt.dbid)) + '.' + QUOTENAME(OBJECT_NAME(blk_sqltxt.objectid, blk_sqltxt.dbid)), 
			sql_statement = (SELECT SUBSTRING(blk_sqltxt.[text], /*1*/ blk_sqlffs2.sql_start, /*2000*/ blk_sqlffs2.sql_len) AS '*' FOR XML PATH(''), TYPE) -- Instead of sql_start and sql_len used to return current sql statement we are returning text of sql batch
		FROM (
			SELECT	blk_sqlffs.sql_start, sql_len = ISNULL(NULLIF(NULLIF(blk.sql_statement_end, 0), -1), 4000) / 2 - blk_sqlffs.sql_start
			FROM	(SELECT sql_start= ISNULL(NULLIF(NULLIF(blk.sql_statement_start, 0), -1), 0) / 2 + 1) blk_sqlffs
		) blk_sqlffs2
		OUTER APPLY sys.dm_exec_sql_text(blk.sql_handle) blk_sqltxt
	) blk_sql
	OUTER APPLY (
		SELECT	TOP(1) pl.query_plan, pl.query_plan.query('//MissingIndexes') AS [indexes]
		FROM	sys.dm_exec_requests rq OUTER APPLY sys.dm_exec_query_plan(rq.plan_handle) pl
		WHERE	blk.session_id = rq.session_id
		ORDER BY rq.request_id
	) qp
	ORDER BY is_blocked DESC, blk_hi.group_num, blk_hi.hid
	OPTION(KEEPFIXED PLAN, MAXDOP 1);

	IF OBJECT_ID('tempdb..#obct_locks') IS NOT NULL 
	BEGIN 
		DROP TABLE #obct_locks;
	END;

	CREATE TABLE #obct_locks (
		id INT IDENTITY PRIMARY KEY,
		hid HIERARCHYID NOT NULL,
		wait_description NVARCHAR(550) NOT NULL,
		dbid INT NOT NULL,
		associatedObjectId BIGINT NOT NULL,
		wait_obct NVARCHAR(550) NULL
	)
	INSERT #obct_locks
	(
	    hid,
	    wait_description,
	    dbid,
	    associatedObjectId
	)
	SELECT	blk.hid, blk.wait_description,
		dbid = CASE 
			WHEN blk.wait_description LIKE '%[ ]dbid=[0-9]%'
			THEN (
				SELECT	TOP(1) CASE WHEN s.col LIKE '[0-9]%[ ]%' THEN TRY_CONVERT(INT,  LEFT(s.col, PATINDEX('%[ ]%', s.col))) END
				FROM	(SELECT SUBSTRING(blk.wait_description, PATINDEX('%[ ]dbid=[0-9]%', blk.wait_description)+6, 5) ) s(col)
			)
		END,
		associatedObjectId = CASE 
			WHEN blk.wait_description LIKE '%[ ]associatedObjectId=[0-9]%'
			THEN SUBSTRING(blk.wait_description, PATINDEX('%[ ]associatedObjectId=[0-9]%', blk.wait_description)+19+1, 4000) 
		END
	FROM #res blk
	WHERE blk.wait_description IS NOT NULL
	OPTION(KEEPFIXED PLAN, MAXDOP 1)

	DECLARE @SqlStatement NVARCHAR(MAX) = ''
	SELECT	@SqlStatement = @SqlStatement  + 'UNION SELECT hid = ' + CONVERT(VARCHAR(200), CONVERT(VARBINARY(8000), CONVERT(HIERARCHYID, cto.hid)), 1) + ', obct_name = (SELECT QUOTENAME(DB_NAME(' + LTRIM(cto.dbid) + ')) + ''.'' + QUOTENAME(OBJECT_SCHEMA_NAME(pos.object_id)) + ''.'' + QUOTENAME(OBJECT_NAME(pos.object_id)) FROM ' + QUOTENAME(DB_NAME(cto.dbid)) + '.sys.partitions pos WHERE pos.partition_id = ' + LTRIM(cto.associatedObjectId) + ')'
	FROM	#obct_locks cto
	
	SELECT @SqlStatement = SUBSTRING(@SqlStatement, 6, 8000000)

	SELECT	@SqlStatement = '
		UPDATE	lo
		SET		lo.wait_obct = obct.obct_name
		FROM	#res lo JOIN (
		' + @SqlStatement + '
		) obct ON lo.hid = obct.hid'

	EXEC(@SqlStatement) 

	SELECT	s.group_num, s.blocking_connections, s.connection_db, s.obct, s.sql_statement, s.[status], s.transaction_count, s.wait_type, s.wait_obct, s.wait_duration, s.cpu, s.reads, s.writes, s.[indexes], s.query_plan, s.program_name, s.hst_name, s.[name], s.hid
	FROM	#res s
	ORDER BY is_blocked DESC, group_num, hid
END
GO