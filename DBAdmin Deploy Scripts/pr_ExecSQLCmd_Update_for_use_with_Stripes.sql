USE [DBAdmin]
GO
drop procedure [pr_ExecSQLCmd]
go
/****** Object:  StoredProcedure [dbo].[pr_ExecSQLCmd]    Script Date: 6/17/2013 4:11:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
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


