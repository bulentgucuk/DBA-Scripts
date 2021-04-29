USE [msdb]
GO

/****** Object:  Operator [CI DBA Alerts]    Script Date: 3/8/2019 6:10:45 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'SSB - IT & Engineering - DevOps')
EXEC msdb.dbo.sp_add_operator @name=N'SSB - IT & Engineering - DevOps', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'devops@ssbinfo.com', 
		@category_name=N'[Uncategorized]'
GO

USE [msdb]
GO
EXEC master.dbo.sp_MSsetalertinfo @failsafeoperator=N'SSB - IT & Engineering - DevOps'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1
GO


/****** Object:  Operator [CI DBA Alerts]    Script Date: 3/8/2019 6:10:45 PM ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'CI DBA Alerts')
EXEC msdb.dbo.sp_delete_operator @name=N'CI DBA Alerts'
GO