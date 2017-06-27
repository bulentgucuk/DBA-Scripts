-- Author: I. Stirk.

-- Do not lock anything, and do not get held up by any locks.
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- What SQL statements are currently using the transaction logs?
SELECT tst.session_id
  , es.original_login_name
  , DB_NAME(tdt.database_id) AS DatabaseName
  , DATEDIFF(SECOND, tat.transaction_begin_time, GETDATE()) AS [TransDuration(s)]
  , tdt.database_transaction_log_record_count AS SpaceUsed
  , CASE tat.transaction_state
      WHEN 0 THEN 'The transaction has not been completely initialized yet'
      WHEN 1 THEN 'The transaction has been initialized but has not started'
      WHEN 2 THEN 'The transaction is active'
      WHEN 3 THEN 'The transaction has ended'
      WHEN 4 THEN 'The commit process has been initiated on the distributed tran'
      WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution'
      WHEN 6 THEN 'The transaction has been committed'
      WHEN 7 THEN 'The transaction is being rolled back'
      WHEN 8 THEN 'The transaction has been rolled back'
      ELSE 'Unknown'
  END AS TransactionState
  , SUBSTRING(TXT.text, ( er.statement_start_offset / 2 ) + 1,
       ( ( CASE WHEN er.statement_end_offset = -1
                     THEN LEN(CONVERT(NVARCHAR(MAX), TXT.text)) * 2
                     ELSE er.statement_end_offset
              END - er.statement_start_offset ) / 2 ) + 1) AS CurrentQuery
  , TXT.text AS ParentQuery
  , es.host_name
  , CASE tat.transaction_type
      WHEN 1 THEN 'Read/Write Transaction'
      WHEN 2 THEN 'Read-Only Transaction'
      WHEN 3 THEN 'System Transaction'
              WHEN 4 THEN 'Distributed Transaction'
              ELSE 'Unknown'
  END AS TransactionType
  , tat.transaction_begin_time AS StartTime
FROM sys.dm_tran_session_transactions AS tst
       INNER JOIN sys.dm_tran_active_transactions AS tat
              ON tst.transaction_id = tat.transaction_id
       INNER JOIN sys.dm_tran_database_transactions AS tdt
              ON tst.transaction_id = tdt.transaction_id
       INNER JOIN sys.dm_exec_sessions es
              ON tst.session_id = es.session_id
       INNER JOIN sys.dm_exec_requests er
              ON tst.session_id = er.session_id
       CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) TXT
--ORDER BY tdt.database_transaction_log_record_count DESC -- log space size.
ORDER BY [TransDuration(s)] DESC -- transaction duration.