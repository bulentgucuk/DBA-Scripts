-- NEED TO CREAT INDEXSTATS TABLE BEFORE EXECUTING IT.
if exists (select 1 from dbo.sysobjects where id=object_id(N'[dbo].[insert_indexstats]')and OBJECTPROPERTY(id,'IsProcedure')=1)
	drop proc insert_indexstats
go
create proc insert_indexstats (@dbid smallint=NULL,@objid int=NULL,@indid int=NULL,@partitionid int=NULL)
as
declare @now datetime
select @now = getdate()
insert into indexstats (database_id
		,object_id
		,index_id
		,partition_number
		,leaf_insert_count
		,leaf_delete_count
		,leaf_update_count
		,leaf_ghost_count
		,nonleaf_insert_count
		,nonleaf_delete_count
		,nonleaf_update_count
		,leaf_allocation_count 
		,nonleaf_allocation_count
		,leaf_page_merge_count 
		,nonleaf_page_merge_count
		,range_scan_count
		,singleton_lookup_count
		,forwarded_fetch_count
		,lob_fetch_in_pages
		,lob_fetch_in_bytes
		,lob_orphan_create_count
		,lob_orphan_insert_count
		,row_overflow_fetch_in_pages
		,row_overflow_fetch_in_bytes
		,column_value_push_off_row_count
		,column_value_pull_in_row_count
		,row_lock_count
		,row_lock_wait_count
		,row_lock_wait_in_ms
		,page_lock_count
		,page_lock_wait_count
		,page_lock_wait_in_ms
		,index_lock_promotion_attempt_count
		,index_lock_promotion_count
		,page_latch_wait_count
		,page_latch_wait_in_ms
		,page_io_latch_wait_count
		,page_io_latch_wait_in_ms,
		now)
select	database_id
			,object_id
			,index_id
			,partition_number
			,leaf_insert_count
			,leaf_delete_count
			,leaf_update_count
			,leaf_ghost_count
			,nonleaf_insert_count
			,nonleaf_delete_count
			,nonleaf_update_count
			,leaf_allocation_count
			,nonleaf_allocation_count
			,leaf_page_merge_count
			,nonleaf_page_merge_count
			,range_scan_count
			,singleton_lookup_count
			,forwarded_fetch_count
			,lob_fetch_in_pages
			,lob_fetch_in_bytes
			,lob_orphan_create_count
			,lob_orphan_insert_count
			,row_overflow_fetch_in_pages
			,row_overflow_fetch_in_bytes
			,column_value_push_off_row_count
			,column_value_pull_in_row_count
			,row_lock_count
			,row_lock_wait_count
			,row_lock_wait_in_ms
			,page_lock_count
			,page_lock_wait_count
			,page_lock_wait_in_ms
			,index_lock_promotion_attempt_count
			,index_lock_promotion_count
			,page_latch_wait_count
			,page_latch_wait_in_ms
			,page_io_latch_wait_count
			,page_io_latch_wait_in_ms
			,@now 
from sys.dm_db_index_operational_stats(@dbid,@objid,@indid,@partitionid)
go
exec dbo.insert_indexstats NULL,NULL,NULL,NULL
--exec dbo.insert_indexstats 7,NULL,NULL,NULL
--select * from sys.dm_db_index_operational_stats(NULL,NULL,NULL,NULL)
