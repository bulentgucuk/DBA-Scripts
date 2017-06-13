USE [DBAdmin]
GO
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_CheckDB_ScheduleDay]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping function [fn_CheckDB_ScheduleDay] - SQL 2005'
                DROP FUNCTION [dbo].[fn_CheckDB_ScheduleDay]
            END
    END

IF dbo.fn_SQLVersion() < 9
    BEGIN
        PRINT 'DBAdmin CheckDB processing is not written for SQL 2000. Use the Standard Maintenance Plan processing.'
        PRINT '*** Processing of this script is being aborted ***'
        RAISERROR ('DBAdmin CheckDB processing is not written for SQL 2000', 20, 1) WITH LOG
    END

GO
-- ***********************************************************************************
-- Author:      Simon Facer
-- Create date: 12/24/2009
-- Description: Determine the current ScheduleDay for the passed Schedule.
--
--  Modification History
--  When        Who             Description
--  12/24/2009  S Facer         Original Version
-- ***********************************************************************************
CREATE FUNCTION [dbo].[fn_CheckDB_ScheduleDay]
 (
    @ScheduleID     INT,
    @CurrentDate    DATETIME
 )
    RETURNS INT

AS

BEGIN

    -- *******************************************************************************
    -- Declare local variables for use in the Function
    DECLARE @retScheduleDay             INT

    DECLARE @CycleStartsOnDayOfWeek     INT
    DECLARE @CycleStartsOnDayOfMonth    INT
    DECLARE @MonthNum                   INT
    DECLARE @Year                       INT
    DECLARE @FirstDayOfMonth            INT
    DECLARE @LastDayOfMonth             INT
    DECLARE @CycleStartDay              INT
    DECLARE @CycleStartDate             DATETIME
    DECLARE @DayOfWeek                  INT
    -- *******************************************************************************

    -- *******************************************************************************
    -- Retrieve the cycle start data for the Schedule, if it doesnt exist return -1 to
    -- the calling routine
    SELECT  @CycleStartsOnDayOfWeek = COALESCE(CycleStartsOnDayOfWeek, -1),
            @CycleStartsOnDayOfMonth = COALESCE(CycleStartsOnDayOfMonth, -1)
        FROM CHECKDB_Parms
        WHERE ScheduleID = @ScheduleID

    IF @@ROWCOUNT = 0 
        BEGIN
            SELECT @retScheduleDay = -1
            RETURN @retScheduleDay
        END
    -- *******************************************************************************

    -- *******************************************************************************
    -- If this is a weekly cycle, check for the day of the week (1 = Sunday)
    IF @CycleStartsOnDayOfWeek > 0 AND
       @CycleStartsOnDayOfMonth = -1
        BEGIN
            SELECT @DayOfWeek = (@@DATEFIRST + DATEPART(dw, @CurrentDate)) % 7
            
            SELECT @retScheduleDay = @DayOfWeek - @CycleStartsOnDayOfWeek
            IF @retScheduleDay < 0
                BEGIN
                    SELECT @retScheduleDay = @retScheduleDay + 7
                END
        END
    -- *******************************************************************************

    -- *******************************************************************************
    -- If this is a monthly cycle, check for the day of the month
    IF @CycleStartsOnDayOfWeek = -1 AND
       @CycleStartsOnDayOfMonth > 0
        BEGIN

            -- If the @CycleStartsOnDayOfMonth > Last day of the month, 
            --  set @CycleStartsOnDayOfMonth = Last day of the month
            SELECT  @MonthNum = DATEPART(MONTH, @CurrentDate) + 1,
                    @Year = DATEPART(YEAR, @CurrentDate)
            IF @MonthNum > 12
                BEGIN
                    SELECT @MonthNum = @MonthNum - 12,
                           @Year = @Year + 1
                END
            
            --SELECT DATEADD(DAY, -1, (CAST((CAST(@MonthNum AS VARCHAR(2)) + '/01/' + CAST(@Year AS VARCHAR(4))) AS DATETIME)))
            SELECT @LastDayOfMonth = DATEPART(DD, (DATEADD(DAY, -1, (CAST((CAST(@MonthNum AS VARCHAR(2)) + '/01/' + CAST(@Year AS VARCHAR(4))) AS DATETIME)))))

            IF @CycleStartsOnDayOfMonth > @LastDayOfMonth
                BEGIN
                    SELECT @CycleStartsOnDayOfMonth = @LastDayOfMonth
                END

            -- Return the days past the current Monthly Start Day
            SELECT @CycleStartDate = CAST((CAST(DATEPART(MONTH, @CurrentDate) AS VARCHAR(2)) + '/' + CAST(@CycleStartsOnDayOfMonth AS VARCHAR(2)) + '/' + CAST(DATEPART(YEAR, @CurrentDate) AS VARCHAR(4))) AS DATETIME)
            IF @CycleStartDate > @CurrentDate
                BEGIN
                    SELECT @CycleStartDate = DATEADD(MONTH, -1, @CycleStartDate)
                END

            SELECT @retScheduleDay = DATEDIFF(DAY, @CycleStartDate, @CurrentDate)
        END 
    -- *******************************************************************************
        
    -- *******************************************************************************
    -- If this is a Week-In-Month cycle (e.g. 2nd Saturday of the Month)
    -- Identify the Cycle Start Date, then treat the same as a Month Cycle
    IF @CycleStartsOnDayOfWeek > 0 AND
       @CycleStartsOnDayOfMonth > 0
        BEGIN

            -- Identify the day number of the first day of the month, this code factors OUT any non-standard
            -- setting for DATEFIRST (standard is Sunday = 1, DATEFIRST = 7))
            SELECT @FirstDayOfMonth = (@@DATEFIRST + DATEPART(dw, CAST(DATEPART(MONTH, @CurrentDate) AS VARCHAR(2)) + '/01/' + CAST(DATEPART(YEAR, @CurrentDate) AS VARCHAR(4)))) % 7

            -- Identify the x-day of y-week for the current month
            IF @FirstDayOfMonth <= @CycleStartsOnDayOfWeek
                BEGIN
                    SELECT @CycleStartDay = (@CycleStartsOnDayOfWeek - @FirstDayOfMonth) + ((@CycleStartsOnDayOfMonth - 1) * 7) + 1
                END
            ELSE
                BEGIN
                    SELECT @CycleStartDay = (@CycleStartsOnDayOfWeek - @FirstDayOfMonth) + (@CycleStartsOnDayOfMonth * 7) + 1
                END
            SELECT @CycleStartDate = CAST(DATEPART(MONTH, @CurrentDate) AS VARCHAR(2)) + '/' + CAST(@CycleStartDay AS VARCHAR(2)) + '/' + CAST(DATEPART(YEAR, @CurrentDate) AS VARCHAR(4))

            -- If the x-day of y-week for the current month is after the Current Date, repeat for the previous month
            IF @CycleStartDay > DATEPART(DAY, @CurrentDate)
                BEGIN
                    SELECT @FirstDayOfMonth = (@@DATEFIRST + DATEPART(dw, CAST(DATEPART(MONTH, DATEADD(MONTH, -1, @CurrentDate)) AS VARCHAR(2)) + '/01/' + CAST(DATEPART(YEAR, DATEADD(MONTH, -1, @CurrentDate)) AS VARCHAR(4)))) % 7

                    IF @FirstDayOfMonth <= @CycleStartsOnDayOfWeek
                        BEGIN
                            SELECT @CycleStartDay = (@CycleStartsOnDayOfWeek - @FirstDayOfMonth) + ((@CycleStartsOnDayOfMonth - 1) * 7) + 1
                        END
                    ELSE
                        BEGIN
                            SELECT @CycleStartDay = (@CycleStartsOnDayOfWeek - @FirstDayOfMonth) + (@CycleStartsOnDayOfMonth * 7) + 1
                        END
                    SELECT @CycleStartDate = CAST(DATEPART(MONTH, DATEADD(MONTH, -1, @CurrentDate)) AS VARCHAR(2)) + '/' + CAST(@CycleStartDay AS VARCHAR(2)) + '/' + CAST(DATEPART(YEAR, DATEADD(MONTH, -1, @CurrentDate)) AS VARCHAR(4))
                END

            SELECT @retScheduleDay = DATEDIFF(DAY, @CycleStartDate, @CurrentDate)
        END 
    -- *******************************************************************************
        

    RETURN @retScheduleDay

END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_CheckDB_ScheduleDay]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    BEGIN
        PRINT 'Function Created [fn_CheckDB_ScheduleDay] - SQL 2005'
    END

GO