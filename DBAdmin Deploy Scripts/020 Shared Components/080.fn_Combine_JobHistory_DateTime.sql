USE DBAdmin
GO
IF dbo.fn_SQLVersion() = 8
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_Combine_JobHistory_DateTime' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping Function [dbo].[fn_Combine_JobHistory_DateTime] (SQL 2000)'
                DROP FUNCTION [dbo].[fn_Combine_JobHistory_DateTime]
            END
    END
IF dbo.fn_SQLVersion() > 8
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_Combine_JobHistory_DateTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping Function [dbo].[fn_Combine_JobHistory_DateTime] (SQL 2005)'
                DROP FUNCTION [dbo].[fn_Combine_JobHistory_DateTime]
            END
    END
GO

CREATE FUNCTION dbo.fn_Combine_JobHistory_DateTime(
            @Run_Date       INT,
            @Run_Time       INT)
    RETURNS DATETIME
AS
-- ********************************************************************
--  Author         Simon Facer
--  Created        09/05/2008
--
--  Purpose        Convert the msdb..sysjobhistory run_date and run_time
--                 into a DATETIME value.
-- ********************************************************************

BEGIN

DECLARE @Return         DATETIME
DECLARE @RunDateVC      VARCHAR(16)
DECLARE @RunTimeVC      VARCHAR(16)
DECLARE @Date           VARCHAR(16)
DECLARE @Time           VARCHAR(16)

    SELECT @RunDateVC = CAST(@Run_Date AS VARCHAR(8)),
           @RunTimeVC = RIGHT(('000000' + CAST(@Run_Time AS VARCHAR(6))), 6)

    SELECT @Date = SUBSTRING(@RunDateVC, 5, 2) + '/' + SUBSTRING(@RunDateVC, 7, 2) + '/' + SUBSTRING(@RunDateVC, 1, 4)
    SELECT @Time = SUBSTRING(@RunTimeVC, 1, 2) + ':' + SUBSTRING(@RunTimeVC, 3, 2) + ':' + SUBSTRING(@RunTimeVC, 5, 2)

    SELECT @Return = CAST((@Date + ' ' + @Time) AS DATETIME)

    RETURN @Return

END
GO

IF dbo.fn_SQLVersion() = 8
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_Combine_JobHistory_DateTime' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function [dbo].[fn_Combine_JobHistory_DateTime] Created (SQL 2000)'
            END
    END
IF dbo.fn_SQLVersion() > 8
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_Combine_JobHistory_DateTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function [dbo].[fn_Combine_JobHistory_DateTime] Created (SQL 2005)'
            END
    END