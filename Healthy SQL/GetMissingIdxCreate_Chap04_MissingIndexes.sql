-- GetMissingIdxCreate script - Missing indexes with CREATE statement

SELECT MID.[statement] AS ObjectName

,MID.equality_columns AS EqualityColumns

,MID.inequality_columns AS InequalityColms

,MID.included_columns AS IncludedColumns

,MIGS.user_seeks

,MIGS.last_user_seek AS LastUserSeek

,MIGS.avg_total_user_cost

,MIGS.avg_user_impact

,N'CREATE NONCLUSTERED INDEX <Add Index Name here> ' +

N'ON ' + MID.[statement] +

N' (' + MID.equality_columns

+ ISNULL(', ' + MID.inequality_columns, N'') +

N') ' + ISNULL(N'INCLUDE (' + MID.included_columns + N');', ';')

AS CreateStatement

FROM sys.dm_db_missing_index_group_stats AS MIGS

INNER JOIN sys.dm_db_missing_index_groups AS MIG

ON MIGS.group_handle = MIG.index_group_handle

INNER JOIN sys.dm_db_missing_index_details AS MID

ON MIG.index_handle = MID.index_handle

WHERE database_id = DB_ID()

AND MIGS.last_user_seek >= DATEDIFF(month, GetDate(), -1)

ORDER BY MIGS.avg_user_impact DESC; 