-- Error 823: Read Write Request Failure
DECLARE @Error823AlertName SYSNAME = N'I/O Alert - Error 823: Read or Write request failure';

EXEC msdb.dbo.sp_add_alert @name = @Error823AlertName,
              @message_id=823,
              @Severity=0,
              @enabled=1,
              @delay_between_responses=900,
              @include_event_description_in=1,
              @category_name=N'[Uncategorized]',
              @job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name = @Error823AlertName,
@operator_name=@OperatorName, @notification_method = 1;
GO
-- Error 824: Read Write Request Failure
DECLARE @Error824AlertName SYSNAME = N'I/O Alert - Error 824: Logical Consistency I/O Error';

EXEC msdb.dbo.sp_add_alert @name = @Error824AlertName,
              @message_id=824,
              @Severity=0,
              @enabled=1,
              @delay_between_responses=900,
              @include_event_description_in=1,
              @category_name=N'[Uncategorized]',
              @job_id=N'00000000-0000-0000-0000-000000000000';

EXEC msdb.dbo.sp_add_notification @alert_name = @Error824AlertName,
@operator_name=@OperatorName, @notification_method = 1;
GO
