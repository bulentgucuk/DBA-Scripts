USE msdb ; 
GO 
EXEC dbo.sp_add_notification 
@alert_name = N'Alert Tester', 
@operator_name = N'MyNewOperator', 
@notification_method = 1 ; 
GO 
USE [msdb] 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 017', 
@message_id=0, 
@severity=17, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 017', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 018', 
@message_id=0, 
@severity=18, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 018', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 019', 
@message_id=0, 
@severity=19, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 019', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 020', 
@message_id=0, 
@severity=20, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 020', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 021', 
@message_id=0, 
@severity=21, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 021', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 022', 
@message_id=0, 
@severity=22, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 022', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 023', 
@message_id=0, 
@severity=23, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 023', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 024', 
@message_id=0, 
@severity=24, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 024', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 025', 
@message_id=0, 
@severity=25, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 025', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 823', 
@message_id=823, 
@severity=0, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 823', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 824', 
@message_id=824, 
@severity=0, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 824', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
EXEC msdb.dbo.sp_add_alert @name=N'Error Number 825', 
@message_id=825, 
@severity=0, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 825', 
@operator_name=N'MyNewOperator', @notification_method = 1; 
GO 
    EXEC msdb.dbo.sp_add_alert @name=N'Error Number 833', 
@message_id=833, 
@severity=0, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
GO 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Error Number 833', 
@operator_name=N'MyNewOperator', @notification_method = 1; 