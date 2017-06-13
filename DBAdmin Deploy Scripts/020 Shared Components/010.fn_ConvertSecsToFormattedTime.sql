USE [DBAdmin]
GO
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_ConvertSecsToFormattedTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping function [fn_ConvertSecsToFormattedTime] - SQL 2005'
                DROP FUNCTION [dbo].[fn_ConvertSecsToFormattedTime]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_ConvertSecsToFormattedTime' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping function [fn_ConvertSecsToFormattedTime] - SQL 2000'
                DROP FUNCTION [dbo].[fn_ConvertSecsToFormattedTime]
            END
    END
GO



CREATE FUNCTION [dbo].[fn_ConvertSecsToFormattedTime](
            @Seconds            DECIMAL(9,4), 
            @Verbose            BIT = 1,
            @NoMilliseconds     BIT = 0)
    RETURNS VARCHAR(64)
AS
-- ********************************************************************
--  Author         Simon Facer
--  Created        09/05/2008
--
--  Purpose        Convert a numeric seconds value to a Formatted Time 
--                  (Hours / Mins / Secs)
-- ********************************************************************

BEGIN
DECLARE @Hours      INT
DECLARE @Mins       INT
DECLARE @Secs       INT
DECLARE @Remainder  INT
DECLARE @Return     VARCHAR(64)

    SELECT @Seconds = ABS(@Seconds)

    SELECT @Hours = @Seconds / 3600

    SELECT @Seconds = @Seconds - (@Hours * 3600)

    SELECT @Mins = @Seconds / 60

    SELECT @Seconds = @Seconds - (@Mins * 60)

    SELECT @Secs = CAST(@Seconds AS INT)

    SELECT @Remainder = (@Seconds - @Secs) * 10000

    IF @Verbose = 0
        BEGIN
            SELECT @Return = CASE
                                WHEN @Hours > 0 THEN CAST(@Hours AS VARCHAR(3)) + ':'
                                ELSE '0:'
                             END +
                             CASE
                                WHEN @Mins > 9 THEN CAST(@Mins AS VARCHAR(2)) + ':'
                                WHEN @Mins > 0 THEN '0' + CAST(@Mins AS VARCHAR(1)) + ':'
                                ELSE '00:'
                             END +
                             CASE
                                WHEN @Secs > 9 THEN CAST(@Secs AS VARCHAR(2))
                                WHEN @Secs > 0 THEN '0' + CAST(@Secs AS VARCHAR(1))
                                ELSE '00'
                             END +
                             CASE 
                                WHEN @NoMilliseconds = 0 THEN '.' + RIGHT(('0000' + CAST(@Remainder AS VARCHAR(4))), 4)
                                ELSE ''
                             END
        END
    ELSE
        BEGIN
            SELECT @Return = CASE
                                WHEN @Hours > 1 THEN CAST(@Hours AS VARCHAR(3)) + ' Hrs, '
                                WHEN @Hours > 0 THEN CAST(@Hours AS VARCHAR(3)) + ' Hr, '
                                ELSE ''
                             END +
                             CASE
                                WHEN @Mins > 1 THEN CAST(@Mins AS VARCHAR(2)) + ' Mins, '
                                WHEN @Mins > 0 THEN CAST(@Mins AS VARCHAR(2)) + ' Min, '
                                ELSE ''
                             END +
                             CASE
                                WHEN @Secs > 0 THEN CAST(@Secs AS VARCHAR(2))
                                ELSE '0'
                             END +
                             CASE
                                WHEN @NoMilliseconds = 0 THEN '.' + RIGHT(('0000' + CAST(@Remainder AS VARCHAR(4))), 4) 
                                ELSE ''
                             END +
                             ' Secs'
        END

    RETURN @Return

END

GO

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_ConvertSecsToFormattedTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function Created [fn_ConvertSecsToFormattedTime] - SQL 2005'
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_DatabaseDetails' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function Created [fn_ConvertSecsToFormattedTime] - SQL 2000'
            END
    END