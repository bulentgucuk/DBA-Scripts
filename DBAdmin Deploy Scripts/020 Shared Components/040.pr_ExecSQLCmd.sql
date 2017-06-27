USE [DBAdmin]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_ExecSQLCmd]') AND type in (N'P', N'PC'))
    BEGIN
    PRINT 'Dropping procedure [pr_ExecSQLCmd] - SQL 2008'
    DROP PROCEDURE [dbo].[pr_ExecSQLCmd]
    END
GO

/****** Object:  StoredProcedure [dbo].[pr_ExecSQLCmd]    Script Date: 09/23/2012 10:40:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[pr_ExecSQLCmd]
    @SQLCmd         VARCHAR(max), --NVARCHAR(2048),
    @Source         VARCHAR(64),
    @rc             INT = NULL OUTPUT
AS

    IF @Source != 'pr_DatabaseBackup'
        BEGIN
            PRINT 'Invalid Source Routine - Code execution not allowed'
            SELECT @rc = -1
            RETURN
        END

    SELECT @rc = 0

    BEGIN TRY
        EXEC (@SQLCmd)
    END TRY
    BEGIN CATCH
        SELECT @rc = ERROR_NUMBER()
    END CATCH

RETURN
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_DatabaseBackup]') AND type in (N'P', N'PC'))
    BEGIN
    PRINT 'Procedure Created [pr_DatabaseBackup] - SQL 2008'
    END
GO
