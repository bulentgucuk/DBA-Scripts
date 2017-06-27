USE [msdb]

DECLARE @Enabled            TINYINT
DECLARE @NotificationMethod TINYINT
DECLARE @WMI_NameSpace      NVARCHAR(256)
DECLARE @Operator           NVARCHAR(128);

SELECT @Operator = ParmValue
FROM [DBAdmin].[dbo].[DBAdmin_InstallParms]
WHERE ParmName = 'JobPageOperator';

SELECT @Enabled = CAST(ParmValue AS TINYINT)
    FROM [DBAdmin].[dbo].[DBAdmin_InstallParms]
    WHERE ParmName = 'AlertsEnabled'    
    
IF EXISTS (SELECT * 
               FROM [DBAdmin].[dbo].[DBAdmin_InstallParms]
               WHERE ParmName = 'IsProduction'
                AND  ParmValue = '1')
    SELECT @NotificationMethod = 2  -- Pager
ELSE
    SELECT @NotificationMethod = 1  -- Email


IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBAdmin Alerts' AND category_class=2)
    BEGIN
        EXEC sp_add_category @class=N'ALERT', @type=N'NONE', @name=N'DBAdmin Alerts'
    END


/****** Object:  Alert [DB Mirroring: Oldest Unsent Transaction Warning]    Script Date: 06/14/2010 14:21:28 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: DB Mirroring: Oldest Unsent Transaction Warning', 
        @message_id=32040, 
        @severity=0, 
        @enabled=0, 
        @delay_between_responses=600, 
        @include_event_description_in=3, 
        @notification_message=N'The oldest unsent transaction for a database on this server has exceeded the age specified in the Mirroring Monitor Threshold.', 
        @category_name=N'DBAdmin Alerts', 
        @job_id=N'00000000-0000-0000-0000-000000000000'
EXEC sp_add_notification @alert_name=N'DBAdmin: DB Mirroring: Oldest Unsent Transaction Warning', @operator_name = @Operator, @notification_method=@NotificationMethod


/****** Object:  Alert [DB Mirroring: Synchronous Mirroring Latency Warning]    Script Date: 06/14/2010 14:21:48 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: DB Mirroring: Synchronous Mirroring Latency Warning', 
        @message_id=32044, 
        @severity=0, 
        @enabled=0, 
        @delay_between_responses=600, 
        @include_event_description_in=3, 
        @notification_message=N'The Mirroring Latency for a database on this server has exceeded the value specified in the Mirroring Monitor Threshold.', 
        @category_name=N'DBAdmin Alerts', 
        @job_id=N'00000000-0000-0000-0000-000000000000'
EXEC sp_add_notification @alert_name=N'DBAdmin: DB Mirroring: Synchronous Mirroring Latency Warning', @operator_name = @Operator, @notification_method=@NotificationMethod


/****** Object:  Alert [DB Mirroring: Unrecovered Log Warning]    Script Date: 06/14/2010 14:22:04 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: DB Mirroring: Unrecovered Log Warning', 
        @message_id=32043, 
        @severity=0, 
        @enabled=0, 
        @delay_between_responses=600, 
        @include_event_description_in=3, 
        @notification_message=N'The Un-Recovered log for a database on the Mirror has exceeded the value specified in the Mirroring Monitor Threshold.', 
        @category_name=N'DBAdmin Alerts', 
        @job_id=N'00000000-0000-0000-0000-000000000000'
EXEC sp_add_notification @alert_name=N'DBAdmin: DB Mirroring: Unrecovered Log Warning', @operator_name = @Operator, @notification_method=@NotificationMethod


/****** Object:  Alert [DB Mirroring: Unsent Log Warning]    Script Date: 06/14/2010 14:22:11 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: DB Mirroring: Unsent Log Warning', 
        @message_id=32042, 
        @severity=0, 
        @enabled=0, 
        @delay_between_responses=600, 
        @include_event_description_in=3, 
        @notification_message=N'The Un-Sent log for a database on the Mirror has exceeded the value specified in the Mirroring Monitor Threshold.', 
        @category_name=N'DBAdmin Alerts', 
        @job_id=N'00000000-0000-0000-0000-000000000000'
EXEC sp_add_notification @alert_name=N'DBAdmin: DB Mirroring: Unsent Log Warning', @operator_name = @Operator, @notification_method=@NotificationMethod


