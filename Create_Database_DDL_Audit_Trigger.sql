IF SERVERPROPERTY('EngineEdition') <> 5
/***
https://docs.microsoft.com/en-us/sql/t-sql/functions/version-transact-sql-configuration-functions?view=sql-server-2017
To programmatically determine the engine edition, use SELECT SERVERPROPERTY('EngineEdition').
This query will return '5' for single databases/elastic pools and '8' for managed instances in Azure SQL Database.
***/
	BEGIN
		DECLARE @tsql NVARCHAR(4000);
		SET @tsql = '
			CREATE OR ALTER TRIGGER [Database_DDL_Audit] ON DATABASE
			FOR DDL_DATABASE_LEVEL_EVENTS
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
					  @EventType  = @EventDataXml.value(''(/EVENT_INSTANCE/EventType)[1]'', ''SYSNAME'')
					, @SchemaName = @EventDataXml.value(''(/EVENT_INSTANCE/SchemaName)[1]'', ''SYSNAME'')
					, @ObjectName = @EventDataXml.value(''(/EVENT_INSTANCE/ObjectName)[1]'', ''SYSNAME'');
    
				INSERT INTO [DBA].dbo.[AuditLog] (
					[CreateDate],[LoginName], [ComputerName],[ProgramName],[DBName],[SQLEvent], [SchemaName], [ObjectName], [SQLCmd], [XmlEvent]
				)
				SELECT
					GETDATE(),
					SUSER_NAME(), 
					HOST_NAME(), 
					PROGRAM_NAME(),
					ISNULL(@EventDataXml.value(''(/EVENT_INSTANCE/DatabaseName)[1]'', ''SYSNAME''), DB_NAME()),
					@EventType, 
					@SchemaName, 
					@ObjectName, 
					@EventDataXml.value(''(/EVENT_INSTANCE/TSQLCommand)[1]'', ''NVARCHAR(MAX)''), 
					@EventDataXml
				 ;
			END;';
		EXEC sp_executesql @stmt = @tsql;
	END
GO