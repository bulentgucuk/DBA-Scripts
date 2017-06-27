USE [msdb]
GO

/****** Object:  Operator [DBA Group]    Script Date: 09/20/2011 10:12:36 ******/
EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
		@enabled=1, 
		@weekday_pager_start_time=0, 
		@weekday_pager_end_time=235959, 
		@saturday_pager_start_time=0, 
		@saturday_pager_end_time=235959, 
		@sunday_pager_start_time=0, 
		@sunday_pager_end_time=235959, 
		@pager_days=127, 
		@email_address=N'bulentgucuk@gmail.com', 
		@category_name=N'[Uncategorized]'
GO


