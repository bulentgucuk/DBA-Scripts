USE [master]
GO

DROP TRIGGER IF EXISTS [Server_DDL_Audit] ON ALL SERVER
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM master.sys.server_triggers WHERE parent_class_desc = 'SERVER' AND name = N'Server_DDL_Audit')
	BEGIN
		EXECUTE dbo.sp_executesql N'CREATE TRIGGER [Server_DDL_Audit] ON ALL SERVER FOR DDL_SERVER_LEVEL_EVENTS AS BEGIN SELECT 1 END'
	END
GO
ALTER TRIGGER [Server_DDL_Audit] ON ALL SERVER
FOR DDL_SERVER_LEVEL_EVENTS
AS 
BEGIN
	SET NOCOUNT ON;
    DECLARE @EventDataXml   XML;
    DECLARE @SchemaName     SYSNAME;
    DECLARE @ObjectName     SYSNAME;
    DECLARE @EventType      SYSNAME;
 
    -- getting back event data
    SET @EventDataXml = EVENTDATA();
    
    SELECT
		  @EventType  = @EventDataXml.value('(/EVENT_INSTANCE/EventType)[1]', 'SYSNAME')
		, @SchemaName = @EventDataXml.value('(/EVENT_INSTANCE/SchemaName)[1]', 'SYSNAME')
		, @ObjectName = @EventDataXml.value('(/EVENT_INSTANCE/ObjectName)[1]', 'SYSNAME');
    
    INSERT [DBA].dbo.[AuditLog] (
        [CreateDate],[LoginName], [ComputerName],[ProgramName],[DBName],[SQLEvent], [SchemaName], [ObjectName], [SQLCmd], [XmlEvent]
    )
    SELECT
        GETDATE(),
        SUSER_NAME(), 
        HOST_NAME(), 
        PROGRAM_NAME(),
        ISNULL(@EventDataXml.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'SYSNAME'), DB_NAME()),
        @EventType, 
        @SchemaName, 
        @ObjectName, 
        @EventDataXml.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'), 
        @EventDataXml
     ;
END;

GO

ENABLE TRIGGER [Server_DDL_Audit] ON ALL SERVER;
GO
