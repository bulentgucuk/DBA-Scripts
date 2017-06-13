USE [DBAdmin]
GO
IF dbo.fn_SQLVersion() = 8
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_FormatDateTime_100_WithSeconds' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping Function [dbo].[fn_FormatDateTime_100_WithSeconds] (SQL 2000)'
                DROP FUNCTION [dbo].[fn_FormatDateTime_100_WithSeconds]
            END
    END
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_FormatDateTime_100_WithSeconds]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping Function [dbo].[fn_FormatDateTime_100_WithSeconds] (SQL 2005)'
                DROP FUNCTION [dbo].[fn_FormatDateTime_100_WithSeconds]
            END
    END
GO
CREATE FUNCTION [dbo].[fn_FormatDateTime_100_WithSeconds](
            @DateToFormat       DATETIME)
    RETURNS VARCHAR(32)
AS
-- ********************************************************************
--  Author         Simon Facer
--  Created        09/05/2008
--
--  Purpose        Format a DATETIME Value, as per format 100, but
--                 with seconds.
-- ********************************************************************

BEGIN

DECLARE @Return         VARCHAR(32)

    SELECT @Return = CONVERT (VARCHAR(32), @DateToFormat, 101) + ' ' + LTRIM(LEFT(RIGHT(CONVERT (VARCHAR(32), @DateToFormat, 109), 14), 8)) + RIGHT(CONVERT (VARCHAR(32), @DateToFormat, 109), 2) 

    RETURN @Return

END
GO

IF dbo.fn_SQLVersion() = 8
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_FormatDateTime_100_WithSeconds' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function [dbo].[fn_FormatDateTime_100_WithSeconds] Created (SQL 2000)'
            END
    END
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_Gene[fn_FormatDateTime_100_WithSeconds]rateNumbers]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function [dbo].[fn_FormatDateTime_100_WithSeconds] Created (SQL 2005)'
            END
    END
GO