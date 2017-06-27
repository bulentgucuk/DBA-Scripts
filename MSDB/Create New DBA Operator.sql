USE [msdb]
GO

/****** Object:  Operator [BizOpDBA]    Script Date: 10/15/2012 08:45:25 ******/
EXEC msdb.dbo.sp_add_operator @name=N'BizOpDBA', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'bgucuk@servicesource.com', 
		@category_name=N'[Uncategorized]'
GO


