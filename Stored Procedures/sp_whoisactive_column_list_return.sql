use master
go
exec sp_WhoIsActive
	@output_column_list = '[dd hh:mm:ss.mss],[session_id], [sql_text], [login_name], [wait_info], [blocking_session_id], [host_name], [database_name], [program_name], [start_time], [login_time], [collection_time]'
	
