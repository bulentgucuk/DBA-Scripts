USE [DBAdmin]
GO
IF dbo.fn_SQLVersion() = 8
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_GenerateNumbers' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping Function [dbo].[fn_GenerateNumbers] (SQL 2000)'
                DROP FUNCTION [dbo].[fn_GenerateNumbers]
            END
    END
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GenerateNumbers]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping Function [dbo].[fn_GenerateNumbers] (SQL 2005)'
                DROP FUNCTION [dbo].[fn_GenerateNumbers]
            END
    END
GO

DECLARE @Version        INT
SELECT @Version = dbo.fn_SQLVersion()

/****** Drop the object ******/
IF @Version = 8
    BEGIN
        EXEC dbo.sp_executesql @Statement = N'
                -- ***********************************************************************************
                -- Author:      Simon Facer
                -- Create date: 07/07/2008
                -- Description: Generate a list of consecutive numbers.
                --              SQL 2000 - CTE''s are not available in 2000, this code does the same
                --              thing as the CTE in the 2005 version.
                --
                --  Modification History
                --  When        Who             Description
                --  12/31/2008  S Facer         Original Version
                -- ***********************************************************************************
                CREATE FUNCTION [dbo].[fn_GenerateNumbers]
                 (
                    @Start BIGINT,
                    @End BIGINT
                 )
                    RETURNS @ret TABLE(Number BIGINT)

                    AS

                    BEGIN

                        DECLARE @LoopIDX                INT
                        DECLARE @t TABLE   (IDCol       BIGINT       IDENTITY(1,1),
                                            OtherCol    BIT)
                        DECLARE @t2 TABLE  (IDCol       BIGINT,
                                            OtherCol    BIT)

                        -- Seed the @t table with the first 10 rows
                        INSERT @t (OtherCol)
                            SELECT 1 UNION ALL
                            SELECT 1 UNION ALL 
                            SELECT 1 UNION ALL
                            SELECT 1 UNION ALL
                            SELECT 1 UNION ALL
                            SELECT 1 UNION ALL
                            SELECT 1 UNION ALL
                            SELECT 1 UNION ALL
                            SELECT 1 UNION ALL
                            SELECT 1  
                            
                        -- Each iteration through the outer loop adds another ^10 to the rows in @t
                        WHILE (SELECT MAX(IDCol)
                                   FROM @t) < @End
                            BEGIN

                                DELETE @t2
                                INSERT @t2
                                    SELECT *
                                        FROM @t
                                
                                SELECT @LoopIDX = 0

                                WHILE @LoopIDX < 9
                                    BEGIN
                                        INSERT @t (OtherCol)
                                            SELECT OtherCol
                                                FROM @t2

                                        SELECT @LoopIDX = @LoopIDX + 1
                                    END
                            END

                        INSERT INTO @ret(Number)
                            SELECT IDCol FROM @t WHERE IDCol BETWEEN @Start AND @End

                    RETURN

                    END'
    END
ELSE
    BEGIN
        EXEC dbo.sp_executesql @Statement = N'
                -- ***********************************************************************************
                -- Author:      Simon Facer
                -- Create date: 07/07/2008
                -- Description: Generate a list of consecutive numbers, using a Common Table Expression.
                --              SQL 2005 +
                --
                --  Modification History
                --  When        Who             Description
                --  07/07/2008  S Facer         Original Version
                -- ***********************************************************************************
                CREATE FUNCTION [dbo].[fn_GenerateNumbers]
                 (
                    @Start BIGINT,
                    @End BIGINT
                 )
                    RETURNS @ret TABLE(Number BIGINT)

                    AS

                    BEGIN
                        WITH
                            L0 AS (SELECT 1 AS C UNION ALL SELECT 1), --2 rows
                            L1 AS (SELECT 1 AS C FROM L0 AS A, L0 AS B),--4 rows
                            L2 AS (SELECT 1 AS C FROM L1 AS A, L1 AS B),--16 rows
                            L3 AS (SELECT 1 AS C FROM L2 AS A, L2 AS B),--256 rows
                            L4 AS (SELECT 1 AS C FROM L3 AS A, L3 AS B),--65536 rows
                            L5 AS (SELECT 1 AS C FROM L4 AS A, L4 AS B),--4294967296 rows
                            num AS (SELECT ROW_NUMBER() OVER(ORDER BY C) AS N FROM L5)

                        INSERT INTO @ret(Number)
                            SELECT N FROM NUM WHERE N BETWEEN @Start AND @End

                    RETURN

                    END'
    END
GO
IF dbo.fn_SQLVersion() = 8
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_GenerateNumbers' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function [dbo].[fn_GenerateNumbers] Created (SQL 2000)'
            END
    END
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GenerateNumbers]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function [dbo].[fn_GenerateNumbers] Created (SQL 2005)'
            END
    END
GO