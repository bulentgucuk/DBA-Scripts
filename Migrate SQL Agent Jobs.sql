/*****
dbatools powershell module installedto SSBETL02 and following command used windows auth for source and copied the jobs from
SSBETL02 to VM-DB-DEV-01 using sql credential for target server and disabled the jobs in the target server

below statement executed in SSBETL02 to migrate the jobs to VM-DB-DEV-01
Get-DbaAGentJob -SqlInstance SSBETL02 -ExcludeDisabledJobs | WHERE-OBJECT NAME -Like "crm prod*" | ForEach-Object {Copy-DbaAgentJob -Source $_.SqlInstance -Job $_.Name -Destination VM-DB-DEV-01.SSBINFO.COM -DestinationSqlCredential ssb_bgucuk -DisableOnDestination}

below is executed in vm-db-dev-01 to move the jobs to vm-etl-dev-01 and vm-etl-prod-01

Get-DbaAGentJob -SqlInstance VM-DB-DEV-01 | WHERE-OBJECT NAME -Like "crm prod*" | ForEach-Object {Copy-DbaAgentJob -Source $_.SqlInstance -Job $_.Name -Destination VM-ETL-DEV-01.SSBINFO.COM -DisableOnDestination}

Get-DbaAGentJob -SqlInstance VM-DB-DEV-01 | WHERE-OBJECT NAME -Like "crm prod*" | ForEach-Object {Copy-DbaAgentJob -Source $_.SqlInstance -Job $_.Name -Destination VM-ETL-PROD-01.SSBINFO.COM -DisableOnDestination}


*****/


/***
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_id=N'8feb9db8-5b96-470e-af55-bb6cacc85e2f', 
		--@owner_login_name=N'sa'
		@owner_login_name=N'SSBCLOUD\dhorstman'
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_id=N'552eef39-328f-4f8e-9b62-e42959d35935', 
		@notify_level_page=2, 
		--@notify_email_operator_name=N'SQL Agent Monitoring'
		@notify_email_operator_name=N'Tommy and SSIS Mon'
GO
EXEC msdb.dbo.sp_attach_schedule @job_id=N'552eef39-328f-4f8e-9b62-e42959d35935',@schedule_id=526
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_id=N'85f22ded-653f-47d0-ada6-35f9dd45cef7', 
		--@owner_login_name=N'sa'
		@owner_login_name=N'SSBCLOUD\dhorstman'
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_id=N'90c4bd3a-5b39-49bc-9bc5-fe6a8ac1069c', 
		@notify_level_page=2, 
		--@notify_email_operator_name=N'SQL Agent Monitoring'
		@notify_email_operator_name=N'Tommy and SSIS Mon'
GO
******/

