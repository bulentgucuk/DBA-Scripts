USE [DBAdmin]
GO

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CHECKDB_Schedule]') AND type in (N'U'))
            BEGIN
                PRINT 'Dropping table [CHECKDB_Schedule] - SQL 2005'
                DROP TABLE [dbo].[CHECKDB_Schedule]
            END
    END
IF dbo.fn_SQLVersion() < 9
    BEGIN
        PRINT 'DBAdmin CheckDB processing is not written for SQL 2000. Use the Standard Maintenance Plan processing.'
        PRINT '*** Processing of this script is being aborted ***'
        RAISERROR ('DBAdmin CheckDB processing is not written for SQL 2000', 20, 1) WITH LOG
    END

GO

CREATE TABLE [dbo].[CHECKDB_Schedule](
    [ScheduleID] [int] NOT NULL,
    [Schedule_Day] [int] NOT NULL,
    [DatabaseName] [sysname] NOT NULL,
    [TableName] [sysname] NOT NULL ) ON [PRIMARY]

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CHECKDB_Schedule]') AND type in (N'U'))
    BEGIN
        PRINT 'Table [CHECKDB_Schedule] created - SQL 2005'
    END
