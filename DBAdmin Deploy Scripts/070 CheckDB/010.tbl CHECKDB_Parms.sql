USE [DBAdmin]
GO

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CHECKDB_Parms]') AND type in (N'U'))
            BEGIN
                PRINT 'Dropping table [CHECKDB_Parms] - SQL 2005'
                DROP TABLE [dbo].[CHECKDB_Parms]
            END
    END
IF dbo.fn_SQLVersion() < 9
    BEGIN
        PRINT 'DBAdmin CheckDB processing is not written for SQL 2000. Use the Standard Maintenance Plan processing.'
        PRINT '*** Processing of this script is being aborted ***'
        RAISERROR ('DBAdmin CheckDB processing is not written for SQL 2000', 20, 1) WITH LOG
    END

GO

CREATE TABLE [dbo].[CHECKDB_Parms](
    [ScheduleID] [int] IDENTITY(1,1) NOT NULL,
    [DBGroup] [varchar](16) NULL,
    [IncludeDBs] [varchar](2048) NULL,
    [ExcludeDBs] [varchar](2048) NULL,
    [SplitOverDays] [tinyint] NULL,
    [CycleStartsOnDayOfWeek] [tinyint] NULL,
    [CycleStartsOnDayOfMonth] [tinyint] NULL,
 CONSTRAINT [PK_CHECKDB_Parms] PRIMARY KEY CLUSTERED 
(
    [ScheduleID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[CHECKDB_Parms]  WITH CHECK ADD  CONSTRAINT [CK_CHECKDB_Parms_DBGroup] CHECK  (([DBGroup]='All' OR [DBGroup]='System' OR [DBGroup]='User'))
GO
ALTER TABLE [dbo].[CHECKDB_Parms] CHECK CONSTRAINT [CK_CHECKDB_Parms_DBGroup]
GO
ALTER TABLE [dbo].[CHECKDB_Parms]  WITH CHECK ADD  CONSTRAINT [CK_CHECKDB_Parms_DBGroup_or_IncludeDBs] CHECK  (([DBGroup] IS NOT NULL OR [IncludeDBs] IS NOT NULL))
GO
ALTER TABLE [dbo].[CHECKDB_Parms] CHECK CONSTRAINT [CK_CHECKDB_Parms_DBGroup_or_IncludeDBs]
GO

CREATE TRIGGER [dbo].[tiu_CHECKDB_Parms]
   ON  [dbo].[CHECKDB_Parms]
   AFTER INSERT, UPDATE
AS 
BEGIN

    SET NOCOUNT ON;

    UPDATE dbo.CHECKDB_Parms
        SET SplitOverDays = 1
        WHERE ScheduleID IN (SELECT ScheduleID 
                                 FROM inserted
                                 WHERE SplitOverDays IS NULL or 
                                       SplitOverDays < 1)
    UPDATE dbo.CHECKDB_Parms
        SET SplitOverDays = 14
        WHERE ScheduleID IN (SELECT ScheduleID 
                                 FROM inserted
                                 WHERE SplitOverDays > 14)

    -- CycleStartsOnDayOfWeek: 1 = Sunday.
    UPDATE dbo.CHECKDB_Parms
        SET CycleStartsOnDayOfWeek = 1
        WHERE ScheduleID IN (SELECT ScheduleID 
                                 FROM inserted
                                 WHERE CycleStartsOnDayOfWeek < 1)
    UPDATE dbo.CHECKDB_Parms
        SET CycleStartsOnDayOfWeek = 7
        WHERE ScheduleID IN (SELECT ScheduleID 
                                 FROM inserted
                                 WHERE CycleStartsOnDayOfWeek > 7)

-- If BOTH CycleStartsOnDayOfWeek and CycleStartsOnDayOfMonth are specified, this becomes 
--  the CycleStartsOnDayOfWeek of the CycleStartsOnDayOfMonth Week, so
--      CycleStartsOnDayOfWeek = 1 / CycleStartsOnDayOfMonth = 2 is the Sunday of the Second Week of the Month
DECLARE @DayOfWeek_DayOfMonth TABLE (
            ScheduleID              INT,
            CycleStartsOnDayOfWeek  TINYINT,
            CycleStartsOnDayOfMonth TINYINT)

    INSERT @DayOfWeek_DayOfMonth
        SELECT  ScheduleID,
                CycleStartsOnDayOfWeek,
                CycleStartsOnDayOfMonth
            FROM inserted
                WHERE   (CycleStartsOnDayOfWeek IS NOT NULL)
                 AND    (CycleStartsOnDayOfMonth IS NOT NULL AND
                          (CycleStartsOnDayOfMonth < 1 OR CycleStartsOnDayOfMonth > 4))

    UPDATE dbo.CHECKDB_Parms
        SET CycleStartsOnDayOfMonth = 1
        WHERE ScheduleID IN (SELECT ScheduleID 
                                 FROM @DayOfWeek_DayOfMonth
                                 WHERE CycleStartsOnDayOfMonth < 1)
    UPDATE dbo.CHECKDB_Parms
        SET CycleStartsOnDayOfMonth = 4
        WHERE ScheduleID IN (SELECT ScheduleID 
                                 FROM @DayOfWeek_DayOfMonth
                                 WHERE CycleStartsOnDayOfMonth > 4)

END
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CHECKDB_Parms]') AND type in (N'U'))
    BEGIN
        PRINT 'Table [CHECKDB_Parms] created - SQL 2005'
    END

GO

INSERT [dbo].[CHECKDB_Parms](
            [DBGroup],
            [SplitOverDays],
            [CycleStartsOnDayOfWeek])
    SELECT 'System', 
           1,
           1
      UNION
    SELECT 'User', 
           1,
           7

GO

IF EXISTS (SELECT * FROM [DBAdmin].[dbo].[CHECKDB_Parms])
    BEGIN
        PRINT 'Table [CHECKDB_Parms] seeded with System and User schedules.'
    END
