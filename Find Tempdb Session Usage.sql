SELECT			
	sys.dm_exec_sessions.session_id AS [SESSION ID],
	DB_NAME(sys.dm_exec_sessions.database_id) AS [DATABASE Name],
	HOST_NAME AS [System Name],
	program_name AS [Program Name],
	login_name AS [USER Name],
	status,
	cpu_time AS [CPU TIME (in milisec)],
	total_scheduled_time AS [Total Scheduled TIME (in milisec)],
	total_elapsed_time AS    [Elapsed TIME (in milisec)],
	(memory_usage * 8)      AS [Memory USAGE (in KB)],
	(user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)],
	(user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)],
	(internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)],
	(internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)],
	CASE is_user_process
							WHEN 1      THEN 'user session'
							WHEN 0      THEN 'system session'
	END         AS [SESSION Type], row_count AS [ROW COUNT]

FROM sys.dm_db_session_space_usage
	INNER JOIN sys.dm_exec_sessions ON sys.dm_db_session_space_usage.session_id = sys.dm_exec_sessions.session_id
ORDER BY [SPACE Allocated FOR USER Objects (in KB)] DESC


SELECT
    [owt].[session_id],
    [owt].[exec_context_id],
    [owt].[wait_duration_ms],
    [owt].[wait_type],
    [owt].[blocking_session_id],
    [owt].[resource_description],
    CASE [owt].[wait_type]
        WHEN N'CXPACKET' THEN
            RIGHT ([owt].[resource_description],
            CHARINDEX (N'=', REVERSE ([owt].[resource_description])) - 1)
        ELSE NULL
    END AS [Node ID],
    [es].[program_name],
    [est].text,
    [er].[database_id],
    [eqp].[query_plan],
    [er].[cpu_time]
FROM sys.dm_os_waiting_tasks [owt]
INNER JOIN sys.dm_exec_sessions [es] ON
    [owt].[session_id] = [es].[session_id]
INNER JOIN sys.dm_exec_requests [er] ON
    [es].[session_id] = [er].[session_id]
OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
WHERE
    [es].[is_user_process] = 1
ORDER BY
    [owt].[session_id],
    [owt].[exec_context_id];
GO