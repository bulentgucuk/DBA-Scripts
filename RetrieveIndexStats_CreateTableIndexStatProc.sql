if exists (select 1 from sysobjects where id=object_id(N'[dbo].[init_indexstats]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	drop proc dbo.init_indexstats
go
CREATE proc dbo.init_indexstats
as

set nocount on
if not exists (select 1 from dbo.sysobjects where id=object_id(N'[dbo].[indexstats]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	create table dbo.indexstats (
	  	database_id smallint NOT NULL
		,object_id int NOT NULL
		,index_id int NOT NULL
		,partition_number int NOT NULL
		,leaf_insert_count bigint NOT NULL
		,leaf_delete_count bigint NOT NULL
		,leaf_update_count bigint NOT NULL
		,leaf_ghost_count bigint NOT NULL
		,nonleaf_insert_count bigint NOT NULL
		,nonleaf_delete_count bigint NOT NULL
		,nonleaf_update_count bigint NOT NULL
		,leaf_allocation_count bigint NOT NULL
		,nonleaf_allocation_count bigint NOT NULL
		,leaf_page_merge_count bigint NOT NULL
		,nonleaf_page_merge_count bigint NOT NULL
		,range_scan_count bigint NOT NULL
		,singleton_lookup_count bigint NOT NULL
		,forwarded_fetch_count bigint NOT NULL
		,lob_fetch_in_pages bigint NOT NULL
		,lob_fetch_in_bytes bigint NOT NULL
		,lob_orphan_create_count bigint NOT NULL
		,lob_orphan_insert_count bigint NOT NULL
		,row_overflow_fetch_in_pages bigint NOT NULL
		,row_overflow_fetch_in_bytes bigint NOT NULL
		,column_value_push_off_row_count bigint NOT NULL
		,column_value_pull_in_row_count bigint NOT NULL
		,row_lock_count bigint NOT NULL
		,row_lock_wait_count bigint NOT NULL
		,row_lock_wait_in_ms bigint NOT NULL
		,page_lock_count bigint NOT NULL
		,page_lock_wait_count bigint NOT NULL
		,page_lock_wait_in_ms bigint NOT NULL
		,index_lock_promotion_attempt_count bigint NOT NULL
		,index_lock_promotion_count bigint NOT NULL
		,page_latch_wait_count bigint NOT NULL
		,page_latch_wait_in_ms bigint NOT NULL
		,page_io_latch_wait_count bigint NOT NULL
		,page_io_latch_wait_in_ms bigint NOT NULL
		,now datetime default getdate())
else 	truncate table dbo.indexstats
go
exec dbo.init_indexstats
