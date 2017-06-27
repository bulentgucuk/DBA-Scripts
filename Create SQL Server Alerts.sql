USE [msdb]
GO

DECLARE @Enabled                TINYINT
DECLARE @NotificationMethod     TINYINT
DECLARE @NotificationMessage    NVARCHAR(512)
DECLARE @WMINamespace           NVARCHAR(512)
DECLARE @Operator               NVARCHAR(128);

SELECT @Enabled = 1

SELECT @Operator =  N'CI DBA Alerts'

SELECT @NotificationMethod = 1  -- Email
--SELECT @NotificationMethod = 2  -- Pager


/****** Object:  Alert [DBAdmin: (017) Insufficient Resources Error]    Script Date: 08/23/2008 22:22:37 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: (017) Insufficient Resources Error', 
        @message_id=0, 
        @severity=17, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: (017) Insufficient Resources Error', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: (018) Nonfatal Internal Software Error]    Script Date: 08/23/2008 22:22:37 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: (018) Nonfatal Internal Software Error', 
        @message_id=0, 
        @severity=18, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: (018) Nonfatal Internal Software Error', @operator_name = @Operator, @notification_method=@NotificationMethod


/****** Object:  Alert [DBAdmin: (019) Fatal Error in Resource]    Script Date: 08/23/2008 22:22:37 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: (019) Fatal Error in Resource', 
        @message_id=0, 
        @severity=19, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: (019) Fatal Error in Resource', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: (020) Fatal Error In Current Process]    Script Date: 08/23/2008 22:22:37 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: (020) Fatal Error In Current Process', 
        @message_id=0, 
        @severity=20, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: (020) Fatal Error In Current Process', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: (021) Fatal Error In Database Processes]    Script Date: 08/23/2008 22:22:37 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: (021) Fatal Error In Database Processes', 
        @message_id=0, 
        @severity=21, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: (021) Fatal Error In Database Processes', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: (022) Fatal Error: Table Integrity Suspect]    Script Date: 08/23/2008 22:22:38 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: (022) Fatal Error: Table Integrity Suspect', 
        @message_id=0, 
        @severity=22, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: (022) Fatal Error: Table Integrity Suspect', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: (023) Fatal Database Integrity Error]    Script Date: 08/23/2008 22:22:38 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: (023) Fatal Database Integrity Error', 
        @message_id=0, 
        @severity=23, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: (023) Fatal Database Integrity Error', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: (024) Fatal Hardware Error]    Script Date: 08/23/2008 22:22:38 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: (024) Fatal Hardware Error', 
        @message_id=0, 
        @severity=24, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: (024) Fatal Hardware Error', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: (025) Fatal Error]    Script Date: 08/23/2008 22:22:38 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: (025) Fatal Error', 
        @message_id=0, 
        @severity=25, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: (025) Fatal Error', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: SQL Server Shutdown Request]    Script Date: 08/23/2008 22:22:38 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: SQL Server Shutdown Request', 
        @message_id=6006, 
        @severity=0, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: SQL Server Shutdown Request', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: SQL Server Startup]    Script Date: 10/19/2010 07:33:39 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: SQL Server Startup', 
        @message_id=0, 
        @severity=1, 
        @enabled=1, 
        @delay_between_responses=60, 
        @include_event_description_in=0, 
        @event_description_keyword=N'DBAdmin: SQL Has Started', 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: SQL Server Startup', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: System Shutdown Request]    Script Date: 08/23/2008 22:22:39 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: System Shutdown Request', 
        @message_id=17147, 
        @severity=0, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: System Shutdown Request', @operator_name = @Operator, @notification_method=@NotificationMethod

/****** Object:  Alert [DBAdmin: Transaction Log Full]    Script Date: 08/23/2008 22:22:39 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: Transaction Log Full', 
        @message_id=9002, 
        @severity=0, 
        @enabled=@Enabled, 
        @delay_between_responses=300, 
        @include_event_description_in=2, 
        @category_name=N'[Uncategorized]', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DBAdmin: Transaction Log Full', @operator_name = @Operator, @notification_method=@NotificationMethod

IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'DB Mirroring: Mirror failover')
    EXEC msdb.dbo.sp_delete_alert @name=N'DB Mirroring: Mirror failover'

SET @NotificationMessage= @@SERVERNAME + N' has had a mirrored database failover'
SET @WMINamespace = N'\\.\root\Microsoft\SqlServer\ServerEvents\' + CAST( ServerProperty('InstanceName') AS nvarchar)

/****** Object:  Alert [DB Mirroring: Mirror failover]    Script Date: 07/12/2011 09:55:57 ******/
EXEC msdb.dbo.sp_add_alert @name=N'DB Mirroring: Mirror failover', 
        @message_id=0, 
        @severity=0, 
        @enabled=1, 
        @delay_between_responses=10, 
        @include_event_description_in=3, 
        @notification_message=@NotificationMessage, 
        @category_name=N'[Uncategorized]', 
        @wmi_namespace=@WMINamespace, 
        @wmi_query=N'SELECT * FROM DATABASE_MIRRORING_STATE_CHANGE WHERE State = 7 OR State = 8', 
        @job_id=N'00000000-0000-0000-0000-000000000000'

EXEC sp_add_notification @alert_name=N'DB Mirroring: Mirror failover', @operator_name = @Operator, @notification_method=@NotificationMethod

EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: Error Number 823', 
@message_id=823, 
@severity=0, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
 
EXEC msdb.dbo.sp_add_notification @alert_name=N'DBAdmin: Error Number 823', 
@operator_name=@Operator, @notification_method = 1; 
 
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: Error Number 824', 
@message_id=824, 
@severity=0, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
 
EXEC msdb.dbo.sp_add_notification @alert_name=N'DBAdmin: Error Number 824', 
@operator_name=@Operator, @notification_method = 1; 
 
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: Error Number 825', 
@message_id=825, 
@severity=0, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
 
EXEC msdb.dbo.sp_add_notification @alert_name=N'DBAdmin: Error Number 825', 
@operator_name=@Operator, @notification_method = 1; 
 
EXEC msdb.dbo.sp_add_alert @name=N'DBAdmin: Error Number 833', 
@message_id=833, 
@severity=0, 
@enabled=1, 
@delay_between_responses=60, 
@include_event_description_in=1; 
 
EXEC msdb.dbo.sp_add_notification @alert_name=N'DBAdmin: Error Number 833', 
@operator_name=@Operator, @notification_method = 1; 

