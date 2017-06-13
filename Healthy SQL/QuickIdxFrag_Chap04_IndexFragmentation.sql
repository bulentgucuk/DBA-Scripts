SELECT * INTO dbo.INDEX_FRAG_STATS FROM sys.dm_db_index_physical_stats (5, NULL, NULL, NULL , 'LIMITED')

SELECT t.database_id, s.name, s.type,t.object_id, t.index_type_desc, t.avg_fragmentation_in_percent, t.page_count

FROM dbo.INDEX_FRAG_STATS t inner join sysobjects s on t.[OBJECT_ID] = s.id

order by t.avg_fragmentation_in_percent desc

Drop Table dbo.INDEX_FRAG_STATS 