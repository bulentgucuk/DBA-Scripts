use master
go
exec sp_WhoIsActive
	@output_column_list = '[dd hh:mm:ss.mss],[session_id], [sql_text], [login_name], [wait_info], [blocking_session_id], [host_name], [database_name], [program_name], [start_time], [login_time], [collection_time]'
	

	
exec sp_WhoIsActive @get_outer_command = 1,
@output_column_list  = '[dd%],[session_id],[blocking%],[sql_text],[sql_command],[login_name],[wait_info],[host_name],[database_name],[program_name],[tran_log%],[cpu%],[temp%],[block%],[reads%],[writes%],[context%],[physical%],[start%]'

