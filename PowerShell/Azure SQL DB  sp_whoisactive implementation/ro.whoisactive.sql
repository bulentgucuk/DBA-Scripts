SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [ro].[WhoIsActive]
AS
SELECT [RowId]
      ,[dd hh:mm:ss.mss]
      ,[session_id]
      ,[sql_text]
      ,[login_name]
      ,[wait_info]
      ,[tran_log_writes]
      ,[CPU]
      ,[tempdb_allocations]
      ,[tempdb_current]
      ,[blocking_session_id]
      ,[reads]
      ,[writes]
      ,[physical_reads]
      ,[query_plan]
      ,[used_memory]
      ,[status]
      ,[tran_start_time]
      ,[open_tran_count]
      ,[percent_complete]
      ,[host_name]
      ,[database_name]
      ,[program_name]
      ,[start_time]
      ,[login_time]
      ,[request_id]
      ,[collection_time]
FROM [dbo].[WhoIsActive] WITH (NOLOCK);
GO