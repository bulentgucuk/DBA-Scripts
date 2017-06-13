-- Find index usage
SELECT   OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
         I.[NAME] AS [INDEX NAME], 
         USER_SEEKS, 
         USER_SCANS, 
         USER_LOOKUPS, 
         USER_UPDATES 
FROM     SYS.DM_DB_INDEX_USAGE_STATS AS S 
         INNER JOIN SYS.INDEXES AS I 
           ON I.[OBJECT_ID] = S.[OBJECT_ID] 
              AND I.INDEX_ID = S.INDEX_ID 
WHERE    OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1 
--AND		OBJECT_NAME(S.[OBJECT_ID]) = 'AccountPaymentInformation'-- CHANGE THE TABLE NAME

-- Find Recommended missing indexes
select d.*
		, s.avg_total_user_cost
		, s.avg_user_impact
		, s.last_user_seek
		,s.unique_compiles
from sys.dm_db_missing_index_group_stats s
		,sys.dm_db_missing_index_groups g
		,sys.dm_db_missing_index_details d
where s.group_handle = g.index_group_handle
and d.index_handle = g.index_handle
and	database_id = db_id()
--and	(d.object_id = 171147655 or d.object_id = 107147427)  -- CHANGE OBJECT IDS
order by D.[STATEMENT],s.avg_user_impact desc




