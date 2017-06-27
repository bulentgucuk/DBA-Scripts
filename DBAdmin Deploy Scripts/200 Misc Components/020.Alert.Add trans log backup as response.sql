/*
8/29/2001 - SRB
Add a response to the tran log full alert to run the tran log backup job automatically.
**NOTE.  This does not factor in litespeed enabled jobs...yet.
*/


Declare @jobid uniqueidentifier
set @jobid = N'00000000-0000-0000-0000-000000000000'

use msdb;
SELECT @jobid = [job_id]
FROM [msdb].[dbo].[sysjobs]
where [name] = 'DBAdmin: User DB - STD Transaction Log Backups'

EXEC msdb.dbo.sp_update_alert @name=N'DBAdmin: Transaction Log Full', 
        @message_id=9002, 
        @severity=0, 
        @enabled=1, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=@jobid
GO
