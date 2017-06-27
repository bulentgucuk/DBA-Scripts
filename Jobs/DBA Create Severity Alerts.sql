-- ADD Severity ALERTS 16 - 25 FOR ALERTING EVERY 60 SECONDS TO TroppusDBATeam OPERATOR 
 USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 016',
 @message_id=0,
 @severity=16,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 016',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO
 
  USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 017',
 @message_id=0,
 @severity=17,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 017',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO
 
  USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 018',
 @message_id=0,
 @severity=18,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 018',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO
 
  USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 019',
 @message_id=0,
 @severity=19,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 019',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO
 
  USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 020',
 @message_id=0,
 @severity=20,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 020',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO
 
  USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 021',
 @message_id=0,
 @severity=21,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 021',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO
 
  USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 022',
 @message_id=0,
 @severity=22,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 022',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO
 
  USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 023',
 @message_id=0,
 @severity=23,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 023',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO
 
  USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 024',
 @message_id=0,
 @severity=24,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 024',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO
 
  USE [msdb]
 GO
 EXEC msdb.dbo.sp_add_alert @name=N'Severity 025',
 @message_id=0,
 @severity=25,
 @enabled=1,
 @delay_between_responses=60,
 @include_event_description_in=1,
 @job_id=N'00000000-0000-0000-0000-000000000000'
 GO
 EXEC msdb.dbo.sp_add_notification 
	@alert_name=N'Severity 025',
	@operator_name=N'TroppusDBATeam',
	@notification_method = 1
 GO