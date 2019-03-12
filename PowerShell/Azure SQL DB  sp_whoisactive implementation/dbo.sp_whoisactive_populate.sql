SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.sp_whoisactive_populate
AS
BEGIN
IF OBJECT_ID ('dbo.WhoIsActive_Temp') IS NOT NULL
	BEGIN
		DROP TABLE dbo.WhoIsActive_Temp;
	END

DECLARE
    @destination_table VARCHAR(4000) ,
    @msg NVARCHAR(1000) ;
SET @destination_table = 'WhoIsActive_Temp';

DECLARE @schema VARCHAR(4000) ;
EXEC dbo.Sp_WhoIsActive
@get_transaction_info = 1,
@get_plans = 1,
@return_schema = 1,
@schema = @schema OUTPUT ;

SET @schema = REPLACE(@schema, '<table_name>', @destination_table) ;

PRINT @schema
EXEC(@schema) ;


    DECLARE @numberOfRuns INT ;
    SET @numberOfRuns = 1 ;
    WHILE @numberOfRuns > 0
        BEGIN;
            EXEC dbo.sp_WhoIsActive @get_transaction_info = 1, @get_plans = 1,
                @destination_table = @destination_table ;
            SET @numberOfRuns = @numberOfRuns - 1 ;
            IF @numberOfRuns > 0
                BEGIN
                    SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + ': ' +
                     'Logged info. Waiting...'
                    RAISERROR(@msg,0,0) WITH nowait ;
                    WAITFOR DELAY '00:00:05'
                END
            ELSE
                BEGIN
                    SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + ': ' + 'Done.'
                    RAISERROR(@msg,0,0) WITH nowait ;
                END
        END ;

INSERT INTO [dbo].[WhoIsActive]
           ([dd hh:mm:ss.mss]
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
		   )
SELECT
            [dd hh:mm:ss.mss]
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
FROM	[dbo].[WhoIsActive_Temp];
DROP TABLE [dbo].[WhoIsActive_Temp];
END
GO