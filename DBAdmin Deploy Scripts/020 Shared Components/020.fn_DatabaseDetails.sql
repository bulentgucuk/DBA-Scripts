-- --------------------------------------------------------------------------------------------------
--  Description :   Creates the fn_DatabaseDetails function based on Version
--
--  Modification Log
--  When            Who             Description
--  10/09/2007      Simon Facer     Original Version.
--  09/27/2011      Derek Adams     Extended the maximum database size to 128 characters 
--                                  
-- --------------------------------------------------------------------------------------------------
USE [DBAdmin]
GO
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_DatabaseDetails]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping function [fn_DatabaseDetails] - SQL 2005'
                DROP FUNCTION [dbo].[fn_DatabaseDetails]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_DatabaseDetails' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Dropping function [fn_DatabaseDetails] - SQL 2000'
                DROP FUNCTION [dbo].[fn_DatabaseDetails]
            END
    END

GO
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        EXEC dbo.sp_executesql @Statement = N'
            CREATE FUNCTION [dbo].[fn_DatabaseDetails] ()
            RETURNS @retDBDetails TABLE 
                    (DBName                 VARCHAR(128),
                     StateDesc              VARCHAR(128),
                     Recovery_Model_Desc    VARCHAR(128),
                     LastFullBackupDate     DATETIME
                    )    
            -- --------------------------------------------------------------------------------------------------
            --  FUNCTION    :   [fn_DatabaseDetails]
            --  Description :   Retrieve database details, used in procedure [lp_DatabaseBackup]
            --                  SQL 2005.
            --
            --  Modification Log
            --  When            Who             Description
            --  10/09/2007      Simon Facer     Original Version.
            --  12/14/2007      Simon Facer     Added LastFullBackupDate to the returned table
            --  04/22/2008      Simon Facer     Added Logic to NULL the LastFullBackupDate if the value was
            --                                  before the DB Create Date.
            --  07/15/2008      Simon Facer     Added logic to return SnapShot as the State Description
            --  03/11/2010      David Creighton Added references to is_read_only and is_in_standby in description
            --  09/27/2011      Derek Adams     Extended the maximum database size to 128 characters 
            --                                  
            -- --------------------------------------------------------------------------------------------------

            AS

            BEGIN

                INSERT @retDBDetails
                    SELECT  d.[name],
                            CASE 
                                WHEN d.[source_database_id] IS NOT NULL THEN ''SNAPSHOT''
                                WHEN d.[is_read_only] = 1 THEN ''READ_ONLY''
                                WHEN d.[is_in_standby] = 1 THEN ''STAND_BY''
                                ELSE d.state_desc
                            END AS State_Desc,
                            d.recovery_model_desc,
                            MAX(b.backup_finish_date) AS FullBackupCompleted
                        FROM master.sys.databases d
                            LEFT OUTER JOIN [msdb].[dbo].[backupset] b
                                ON d.[name] = b.database_name
                                AND b.[type] = ''D''
                        WHERE d.[name] != ''tempdb''
                        GROUP BY d.[name],
                                 d.[source_database_id],
                                 d.[is_read_only],
                                 d.[is_in_standby],
                                 d.[state_desc],
                                 d.[recovery_model_desc]


                UPDATE @retDBDetails
                    SET LastFullBackupDate = NULL
                    WHERE DBName IN (SELECT r.DBName
                                         FROM @retDBDetails r
                                             INNER JOIN master.sys.Databases d
                                                 ON  r.DBName = d.[name]
                                                 AND r.LastFullBackupDate < d.create_date)
                RETURN
            END'
    END

ELSE
    BEGIN
        EXEC dbo.sp_executesql @Statement = N'
            CREATE FUNCTION [dbo].[fn_DatabaseDetails] ()
            RETURNS @retDBDetails TABLE 
                    (DBName                 VARCHAR(128),
                     StateDesc              VARCHAR(128),
                     Recovery_Model_Desc    VARCHAR(128),
                     LastFullBackupDate     DATETIME
                    )    
            -- --------------------------------------------------------------------------------------------------
            --  FUNCTION    :   [fn_DatabaseDetails]
            --  Description :   Retrieve database details, used in procedure [lp_DatabaseBackup]
            --                  SQL 2000.
            --
            --  Modification Log
            --  When            Who             Description
            --  10/09/2007      Simon Facer     Original Version.
            --  12/14/2007      Simon Facer     Added LastFullBackupDate to the returned table
            --  04/22/2008      Simon Facer     Added Logic to NULL the LastFullBackupDate if the value was
            --                                  before the DB Create Date.
            --  06/17/2008      David Creighton Changed the references to the sysdatabases.status column to use
            --                                  the DATABASEPROPERTY() function.  This was needed to catch dbs
            --                                  in a standby state.
            --  03/15/2010      Simon Facer     Added COALESCE to the DatabaseProprty calls for SQL 2000, found a
            --                                  situation where NULL was being retuned.
            --  09/27/2011      Derek Adams     Extended the maximum database size to 128 characters 
            --                                  
            -- --------------------------------------------------------------------------------------------------

            AS

            BEGIN

                INSERT @retDBDetails
                    SELECT  d.[name], 
                            CASE
                                WHEN (
                                    COALESCE(DATABASEPROPERTY(d.[name], ''IsInStandby''), 0) +
                                    COALESCE(DATABASEPROPERTY(d.[name], ''IsDetached''), 0) +
                                    COALESCE(DATABASEPROPERTY(d.[name], ''IsEmergencyMode''), 0) +
                                    COALESCE(DATABASEPROPERTY(d.[name], ''IsInLoad''), 0) +
                                    COALESCE(DATABASEPROPERTY(d.[name], ''IsInRecovery''), 0) +
                                    COALESCE(DATABASEPROPERTY(d.[name], ''IsNotRecovered''), 0) +
                                    COALESCE(DATABASEPROPERTY(d.[name], ''IsOffline''), 0) +
                                    COALESCE(DATABASEPROPERTY(d.[name], ''IsShutdown''), 0) +
                                    COALESCE(DATABASEPROPERTY(d.[name], ''IsSuspect''), 0)
                                ) > 0
                                   THEN ''Offline''
                                ELSE ''Online''
                            END,
                            CAST((DATABASEPROPERTYEX (d.[name], ''Recovery'') ) AS VARCHAR(60)),
                            MAX(b.backup_finish_date) AS FullBackupCompleted
                        FROM master.dbo.sysdatabases d
                            LEFT OUTER JOIN [msdb].[dbo].[backupset] b
                                ON d.[name] = b.database_name
                                AND b.[type] = ''D''
                        WHERE d.[name] != ''tempdb''
                        GROUP BY d.[name],
                                 CASE
                                     WHEN (
                                        COALESCE(DATABASEPROPERTY(d.[name], ''IsInStandby''), 0) +
                                        COALESCE(DATABASEPROPERTY(d.[name], ''IsDetached''), 0) +
                                        COALESCE(DATABASEPROPERTY(d.[name], ''IsEmergencyMode''), 0) +
                                        COALESCE(DATABASEPROPERTY(d.[name], ''IsInLoad''), 0) +
                                        COALESCE(DATABASEPROPERTY(d.[name], ''IsInRecovery''), 0) +
                                        COALESCE(DATABASEPROPERTY(d.[name], ''IsNotRecovered''), 0) +
                                        COALESCE(DATABASEPROPERTY(d.[name], ''IsOffline''), 0) +
                                        COALESCE(DATABASEPROPERTY(d.[name], ''IsShutdown''), 0) +
                                        COALESCE(DATABASEPROPERTY(d.[name], ''IsSuspect''), 0)
                                      ) > 0
                                         THEN ''Offline''
                                     ELSE ''Online''
                                 END,
                                 CAST((DATABASEPROPERTYEX (d.[name], ''Recovery'') ) AS VARCHAR(60))

                UPDATE @retDBDetails
                    SET LastFullBackupDate = NULL
                    WHERE DBName IN (SELECT r.DBName
                                         FROM @retDBDetails r
                                             INNER JOIN master..sysdatabases d
                                                 ON  r.DBName = d.[name]
                                                 AND r.LastFullBackupDate < d.crdate)

                RETURN
            END'
    END
GO

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_DatabaseDetails]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function Created [fn_DatabaseDetails] - SQL 2005'
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'fn_DatabaseDetails' AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
            BEGIN
                PRINT 'Function Created [fn_DatabaseDetails] - SQL 2000'
            END
    END

GO