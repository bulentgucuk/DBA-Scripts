USE [DBAdmin]
GO
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[lp_SetCMDShell]') AND type = N'P')
            BEGIN
                PRINT 'Dropping procedure [lp_SetCMDShell] - SQL 2005'
                DROP PROCEDURE [dbo].[lp_SetCMDShell]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'lp_SetCMDShell' AND type = N'P')
            BEGIN
                PRINT 'Dropping procedure [lp_SetCMDShell] - SQL 2000'
                DROP PROCEDURE [dbo].[lp_SetCMDShell]
            END
    END

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_SetCMDShell]') AND type = N'P')
            BEGIN
                PRINT 'Dropping procedure [pr_SetCMDShell] - SQL 2005'
                DROP PROCEDURE [dbo].[pr_SetCMDShell]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'pr_SetCMDShell' AND type = N'P')
            BEGIN
                PRINT 'Dropping procedure [pr_SetCMDShell] - SQL 2000'
                DROP PROCEDURE [dbo].[pr_SetCMDShell]
            END
    END

GO
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        EXEC dbo.sp_executesql @Statement = N'
            CREATE PROCEDURE [dbo].[pr_SetCMDShell]
                @setval bit,
                @curval bit = NULL OUTPUT
            AS

            DECLARE
                @adv_options bit,
                @xp_cmdshell bit

            IF (IS_SRVROLEMEMBER(''sysadmin'') = 0)
            BEGIN
                RAISERROR (''Only system administrators may run this procedure'', 16, 1)
                RETURN 1
            END

            SELECT @adv_options = CAST(value_in_use AS bit)
            FROM master.sys.configurations
            WHERE name = ''show advanced options''

            SELECT @xp_cmdshell = CAST(value_in_use AS bit)
            FROM master.sys.configurations
            WHERE name = ''xp_cmdshell''

            SET @curval = @xp_cmdshell

            IF (@xp_cmdshell != @setval)
            BEGIN

                IF (@adv_options = 0)
                BEGIN
                    EXEC sp_configure ''show advanced options'', 1
                    RECONFIGURE
                END

                EXEC sp_configure ''xp_cmdshell'', @setval
                RECONFIGURE

                IF (@adv_options = 0)
                BEGIN
                    EXEC sp_configure ''show advanced options'', 0
                    RECONFIGURE
                END

            END

            RETURN'
    END

ELSE
    BEGIN
        EXEC dbo.sp_executesql @Statement = N'
            CREATE PROCEDURE [dbo].[pr_SetCMDShell]
                @setval bit,
                @curval bit = NULL OUTPUT
            AS
            
            IF (IS_SRVROLEMEMBER(''sysadmin'') = 0)
            BEGIN
                RAISERROR (''Only system administrators may run this procedure'', 16, 1)
                RETURN 1
            END

            SET @curval = 1
            
            RETURN'
    END
GO

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_SetCMDShell]') AND type = N'P')
            BEGIN
                PRINT 'Procedure Created [pr_SetCMDShell] - SQL 2005'
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'pr_SetCMDShell' AND type = N'P')
            BEGIN
                PRINT 'Procedure Created [pr_SetCMDShell] - SQL 2000'
            END
    END

GO
