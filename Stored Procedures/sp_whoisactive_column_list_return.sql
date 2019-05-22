use master
go
exec sp_WhoIsActive @get_outer_command = 1,
@output_column_list  = '[dd%],[session_id],[blocking%],[sql_text],[sql_command],[login_name],[wait_info],[host_name],[database_name],[program_name],[tran_log%],[cpu%],[temp%],[block%],[reads%],[writes%],[context%],[physical%],[start%]'
