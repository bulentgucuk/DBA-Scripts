USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_ReorgRebuildIndexes]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[usp_ReorgRebuildIndexes]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[usp_ReorgRebuildIndexes] 
	 @databasename 			nvarchar(256) = N''	-- If you only want to rebuild/reorganize a particular database
	,@FragCheck				FLOAT=10			-- Only indexes with an avg fragmentation in percent > @FragCheck are inluded,	    
	,@DensityCheck			FLOAT=75			-- OR tables with an avg page space used in percent < @DensityCheck are included
	,@RebuildThreshold		FLOAT=30			-- Rebuild indexes if avg fragmentation in percent reaches this threshold, which should not be higher than 30
	,@online				BIT=0				-- If 1, REBUILD WITH ONLINE = ON (Enterpise or Developer) or REORGANIZE, else REORGANIZE IF @currentfrag < @RebuildThreshold ELSE REBUILD (IF no users)
	,@runrebuild			BIT=1				-- If 1, REBUILD/REORGANIZE is executed, else code script is generated only 
	,@DBMirrorPerf 			BIT=1				-- If 1, REBUILD/REORGANIZE database in mirror with high performance mode. This parameter will be ignored if the database is not set up in mirroring.
    ,@ChangeDBRecovery		BIT=1               -- If Online = 1, Change DB Recovery is default to 0 - if Online = 0 then use flag to determine if Recovery mode should be changed
	,@SendEmail				BIT=1				-- 1 to Send Email Per Database or 0 for no email
	,@SendSummaryOnly		BIT=0				-- 1 to Send Summary only via Email - SendEmail needs to be 1
	,@MaxDaysofLog			INT=14				-- Number of days for which to keep job log data - Default is 14 days
    ,@MaxErrors				INT=10				-- Max Number of errors after which job fails - Default is 10
						
AS
BEGIN
	/*
	NOTE (see BOL): The defragmentation process is always fully logged, 
	regardless of the database recovery model setting (see ALTER DATABASE). 
	@databasename is database to defrag indexes for.
	@maxruntime is total allowed runtime in seconds for this job, which is checked after each db and each index has been processed.

	-- Example how to rebuild ALL database
	EXEC master.dbo.usp_ReorgRebuildIndexes 
		@databasename ='',
		@FragCheck = 10.0,
		@DensityCheck = 75.0,
		@RebuildThreshold = 30.0,
		@online = 1,
		@runrebuild = 1,
		@DBMirrorPerf = 1,
		@ChangeDBRecovery = 1,
		@SendEmail = 1,
		@SendSummaryOnly = 0,
		@MaxDaysofLog = 14,
		@MaxErrors = 10

	The SP only runs on SQL 2005. 
	This SP rebuild and/or reorganizes all indexexs in the specified database or all databases.
	You can run this SP while users are using the database, if you specify @online = 1.
	If ONLINE, REBUILD WITH (ONLINE = ON, FILLFACTOR = 90) will be run if possible, else REORGANIZE. 
	These online options does not hold locks long term and thus will 
	not block running queries or updates. A relatively unfragmented index can be defragmented 
	faster than a new index can be built because the time to defragment is related to the amount 
	of fragmentation. A very fragmented index might take considerably longer to defragment than 
	to rebuild.  In addition, the defragmentation is always fully logged, regardless of the 
	database recovery model setting (see ALTER DATABASE). The defragmentation of a very 
	fragmented index can generate more log than even a fully logged index creation. 
	The defragmentation, however, is performed as a series of short transactions and thus does 
	not require a large log if log backups are taken frequently or if the recovery model setting
	is SIMPLE.
	*/

	SET NOCOUNT ON;

	DECLARE 
	 @DBMode 					varchar(50)
	,@StatusMsg 				nvarchar(max)
	,@ErrorMsg 					nvarchar(255)
	,@ifexists					INT
	,@startmain					datetime
	,@starteddate				datetime
	,@endeddate					datetime
	,@totalsecondspassed		int
	,@myedition					varchar(50)
	,@NewLine					CHAR (1)
	,@Retry						INT
	,@Outparm					INT
	,@schemaname				sysname
	,@objectname				sysname
	,@indexname					sysname
	,@tableid					int
	,@indexid					int
	,@currentfrag				float
	,@currentdensity			float
	,@postfrag					float
	,@postdensity				float	
	,@partitionnum				varchar(10)
	,@partitioncount			bigint
	,@indextype					varchar(18)
	,@command					nvarchar(4000)
	,@myrebuildoption			nvarchar(500)
	,@myreorganizeoption	    nvarchar(500)
	,@lob_count					int
	,@sqllob_count				nvarchar(500)
	,@parmlob_count				nvarchar(50)
	,@mydisabledindex			bit
	,@parmmydisabledindex	    nvarchar(50)
	,@sqlmydisabledindex	    nvarchar(500)
	,@pagelocksnotallowedcount	int
	,@parmmyallowpagelocks	    nvarchar(50)
	,@sqlmyallowpagelocks	    nvarchar(500)
	,@rowlocksnotallowedcount	int
	,@parmmyallowrowlocks	    nvarchar(50)
	,@sqlmyallowrowlocks	    nvarchar(500)
	,@myindexishypotetical	    bit
	,@parmmyindexishypotetical  nvarchar(50)
	,@sqlmyindexishypotetical   nvarchar(500)
	,@countprocessed			int
	,@onofflinemess				varchar(50)
	,@myservicename				varchar(100)
	,@rc						int
	,@mycode					nvarchar(max)
	,@activeconnectionsindb	    smallint
	,@onlineedition				bit
	,@RecoveryMode 				varchar(128)
	,@RecoveryModeOld 			varchar(128)
	,@altdbbefore				nvarchar(200)
	,@altdbafter				nvarchar(200)
	,@dbStatusMsg 				varchar(1024)
	,@dbmirrorold	    	    tinyint
	,@dbmirrorwitness			nvarchar(128)
	,@altdbmirrorbefore			nvarchar(200)
	,@altdbmirrorafter			nvarchar(200)
	,@myfromname 				nvarchar(500)
	,@mytoname 					nvarchar(4000)
	,@myrecipients				VARCHAR(100)
	,@mycurrentaddres 			VARCHAR(1024)
	,@alladdresses 				NVARCHAR(1024)
	,@mailaddress 				varchar (200)
	,@mylogmessage				nvarchar(255)
	,@activelastminutes			int 
	,@sqlstring					nvarchar (512)
	,@mydbid					smallint
	,@sqlparm					nvarchar(100)
	,@numproc					int
	,@ToDeleteDateTime			DATETIME
	,@err						int
	,@Status					NVARCHAR (50)
	,@SubjectLocal				NVARCHAR (1024) 
	,@MailBody					NVARCHAR (MAX)
	,@JobRunStartDateTime		DATETIME
	,@JobRunEndDateTime			DATETIME
	,@JobIndexCount				SMALLINT
	,@JobStatus					NVARCHAR (50)
	,@MainStartDateTime			DATETIME
		
	SET		@Retry = 0
	SET		@StatusMsg = ''
	SET		@NewLine = CHAR(13)
	SET		@MainStartDateTime = GETDATE()
	
	IF		@Online = 1 SET @ChangeDBRecovery = 0

	WHILE (@retry >= 0 AND @retry <= @MaxErrors)
	BEGIN
			--Create table to keep log if it does exist OR delete old data based on max date provided by user
			IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ReorgRebuildIndexesJobLog]') AND type in (N'U'))
			BEGIN;
				CREATE TABLE [dbo].[ReorgRebuildIndexesJobLog](
					[DatabaseName] [sysname] NOT NULL,
					[JobRunStartDateTime] [datetime] NULL,
					[JobRunEndDateTime] [datetime] NULL,
					[JobIndexCount] [smallint] NULL,										
					[JobStatus] [nvarchar](50) NULL,									
					[JobLog] [nvarchar](max) NULL
				) ON [PRIMARY]
			END;
			ELSE
			BEGIN;
				SET		@ToDeleteDateTime = DATEDIFF(dd, @MaxDaysofLog, GetDate())
				DELETE 
				FROM	[ReorgRebuildIndexesJobLog]
				WHERE	JobRunStartDateTime <= @ToDeleteDateTime
			END;

			-- Check the values of fragmentation, density and rebuild threshold parameters

			BEGIN;
				IF @FragCheck < 10 
				BEGIN;
					SET @ErrorMsg = N'Fragmentation checker should not be lower than 10'
					GOTO FAILONDB
   				END;
				ELSE
				IF @FragCheck >= @RebuildThreshold
				BEGIN;	
					SET @ErrorMsg = N'Fragmentation checker should not higher or equal to rebuild threshold'
					GOTO FAILONDB
				END;
				IF @DensityCheck > 75
				BEGIN;
					SET @ErrorMsg = N'Density checker should not higher than 75'
					GOTO FAILONDB
   				END;		
			END;

			BEGIN;
				--Close Cursor if left open by previous attempt to run procedure
				IF Cursor_Status('GLOBAL', 'Main_Cursor') >= 0
				BEGIN
					CLOSE Main_Cursor
					DEALLOCATE Main_Cursor
				END

				BEGIN
					IF @databasename <> '' OR LEN(@DatabaseName) > 0-- Rebuild/reo
rganize one database
					BEGIN;
						SELECT @ifexists = COUNT(name) FROM sys.sysdatabases where name = @databasename
						IF @ifexists = 0
						BEGIN;
							SET @ErrorMsg = 'Database ' + @databasename + ' does not exist!'
							GOTO FAILONDB							
						END;
						ELSE
						DECLARE  Main_Cursor  CURSOR FOR 
						SELECT name FROM sys.sysdatabases where name = @databasename
					END;
					ELSE	
					BEGIN;	 
						-- Rebuild/reorganize all databases
						DECLARE  Main_Cursor  CURSOR FOR 
						SELECT	name 
						FROM	sys.sysdatabases 
						WHERE	name not in('tempdb','master','model','msdb')
						Order BY name ASC
					END;
				END
			END;

			OPEN Main_Cursor
			FETCH NEXT FROM Main_Cursor INTO @databasename
			WHILE @@FETCH_STATUS=0
			BEGIN;
				--Check Database Accessibility
				SELECT @DBMode = 'OK'
				IF (DATABASEPROPERTYEX(@databasename, 'Status') = N'ONLINE' 
					AND DATABASEPROPERTYEX(@databasename, 'Updateability') = N'READ_WRITE'
					AND DATABASEPROPERTYEX(@databasename, 'UserAccess') = N'MULTI_USER')
					SELECT @DBMode = 'OK'
				ELSE
					SELECT @DBMode = 'NOT AVAILABLE'
				
				IF @DBMode <> 'OK'
				BEGIN;								
					SET @ErrorMsg = N'Unable to rebuild/reorganize indexes on ' + @databasename + N' on SQL Server ' + @@servername + CHAR(13) 
						+ N'The database is '  + @DBMode + N'!' + CHAR(13) 
						+ N'No rebuild/reorganize can be done on this database (not ONLINE, not READ_WRITE or not MULTI_USER).'
					GOTO FAILONDB
				END;
				ELSE
				BEGIN;			
					BEGIN;
						SELECT @starteddate = getdate()
						SET @StatusMsg = @StatusMsg + @NewLine + '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'	
						SET @StatusMsg = @StatusMsg + @NewLine + '-- START OF INDEX DEFRAG FOR DATABASE ' + @databasename + ' AT ' + CONVERT (VARCHAR(20), getdate(), 120)
					END;

					-- If database is mirrored, the recovery model must be 'FULL'.
					-- If database is not mirrored, alter recovery model from FULL (full recovery model) to SIMPLE.
					-- This is done BEFORE reindexing in order to minimize growth of the transaction log.
					-- Check database recovery model and change it to SIMPLE if FULL.

					SELECT	@dbmirrorold = ''

					SELECT	@dbmirrorold = mirroring_safety_level, @dbmirrorwitness = mirroring_witness_name 
					FROM	sys.database_mirroring A INNER JOIN sys.databases B 
							ON A.database_id = B.database_id 
					WHERE	B.name = @databasename
							AND A.mirroring_state=4 
							AND A.mirroring_role=1 

					SELECT	@RecoveryMode = cast(DATABASEPROPERTYEX(@databasename, 'Recovery') as varchar(20))
					SELECT	@RecoveryModeOld = @RecoveryMode

					IF @dbmirrorold = ''
					BEGIN;
						IF @RecoveryMode <> 'SIMPLE'
						BEGIN;
							SELECT @altdbbefore = N'ALTER DATABASE [' + @databasename + N'] SET RECOVERY SIMPLE; '
							IF @runrebuild = 1
							BEGIN; 
								IF @ChangeDBRecovery = 1
								BEGIN;
									EXEC(@altdbbefore)
									SELECT @dbStatusMsg = '-- Recovery model for database ' + @databasename + ' was changed to SIMPLE from '  + @RecoveryModeOld + ' recovery mode.'
									SET @StatusMsg = @StatusMsg + @NewLine + @dbStatusMsg
								END;
							END;
							ELSE SELECT @altdbbefore = N''
						END;
					END;
					ELSE -- Database in morror that requires FULL recovery model
					BEGIN;
						IF @RecoveryMode <> 'FULL'
						BEGIN;
							SELECT @altdbbefore = N'ALTER DATABASE [' + @databasename + N'] SET RECOVERY FULL; '
							IF @runrebuild = 1
							BEGIN; 
								EXEC(@altdbbefore)
								SELECT @dbStatusMsg = '-- Recovery model for database ' + @databasename + ' was changed to FULL from '  + @RecoveryModeOld + ' recovery mode.'
								SET @StatusMsg = @StatusMsg + @NewLine + @dbStatusMsg
							END;
						 END;
						ELSE SELECT @altdbbefore = N''
					END;

					IF @DBMirrorPerf = 1 and @dbmirrorold > 1   
					BEGIN;
						IF @dbmirrorold = 2   -- DB mirroring in high protection mode	
						BEGIN;
							SELECT @altdbmirrorbefore = N'ALTER DATABASE [' + @databasename + N'] SET PARTNER SAFETY OFF; '
							IF @runrebuild = 1
							BEGIN; 
								EXEC(@altdbmirrorbefore)
								SELECT @dbStatusMsg = '-- Mirror safety level for database ' + @databasename + ' was changed to High Performance.' 
								SET @StatusMsg = @StatusMsg + @NewLine + @dbStatusMsg
							END;
						END;

						IF @dbmirrorold = 3  -- DB mirroring in high availability mode	
						BEGIN;
							SELECT @altdbmirrorbefore = N'ALTER DATABASE [' + @databasename + N'] SET PARTNER SAFETY OFF WITNESS OFF; '
							IF @runrebuild = 1
							BEGIN; 
								EXEC(@altdbmirrorbefore)
								SELECT @dbStatusMsg = '-- Mirror safety level for database ' + @databasename + ' was changed to High Performance.' 
								SET @StatusMsg = @StatusMsg + @NewLine + @dbStatusMsg
							END;
						END;					 
					END;

					-- Check if there has been any activity (reads and/or writes) in this database for the last 15 minutes.
					/*
					Get number of currently active connections.
					0 means no active connections in selected database!
					*/
					SELECT @mydbid = DB_ID(@databasename)
					SET @sqlparm = N'@pnumproc INT output'
					SET @activelastminutes = 15
					SET @numproc = 0

					-- Do an active conenctions count on server for this database
					SELECT @sqlstring = N'select @pnumproc = count(session_id) 
					from sys.dm_exec_connections as ec with (nolock) inner join
					sys.sysprocesses as sp with (nolock) on ec.session_id = sp.spid
					where ec.session_id <> ' + cast(@@SPID as varchar(10)) +
					N' and DATEDIFF(minute, ec.last_read, GETDATE()) < ' + cast(@activelastminutes as varchar(10)) +
					N' and DATEDIFF(minute, ec.last_write, GETDATE()) < ' + cast(@activelastminutes as varchar(10)) +
					N' and sp.dbid = ' + cast(@mydbid as varchar(10))

					EXECUTE sp_executesql @sqlstring, @sqlparm, @pnumproc = @numproc output

					SELECT @dbStatusMsg = N'-- No of processes with connections active for the last ' + cast(@activelastminutes as nvarchar(10)) +
					 N' minutes in DB ' + @databasename + N' is ' + CAST(@numproc AS NVARCHAR(10))
					SET @StatusMsg = @StatusMsg + @NewLine + @dbStatusMsg

					-- Check SQL Edition in order to set possible rebuild options
					SELECT @myedition = CONVERT(VARCHAR(50), SERVERPROPERTY('Edition'))
					IF (@myedition LIKE 'Developer Edition%' OR @myedition LIKE 'Enterprise Edition%') 
					SET @onlineedition = 1 ELSE SET @onlineedition = 0

					-- Get service name of current SQL Server - used for getting performance counter.
					SELECT @myservicename = 'MSSQL$' + @@SERVICENAME + ':Databases'

					-- Print On- or offline message
					IF  @online = 1 SET @onofflinemess = 'ONLINE (users allowed)'
					ELSE SET @onofflinemess = 'OFFLINE (no users allowed)'
					-- Notify if code is generated only or executed.
					IF @runrebuild = 0 SET @StatusMsg = @StatusMsg + @NewLine + '-- Execute the following code ' + @onofflinemess + ' to rebuild and/or reorganize indexes in database ' 
								+ @databasename + ' for better performance!'
					ELSE SET @StatusMsg = @StatusMsg + @NewLine +  '-- Rebuild and/or reorganization ' + @onofflinemess + ' of indexes in database ' + @databasename + ' will now be executed!'

					SET @lob_count = 0
					SET @mydisabledindex = 0
					SET @pagelocksnotallowedcount = 0
					SET @myindexishypotetical = 0
					SET @countprocessed = 0
					SET @outparm = 0
					SET @rc = 0
					SET @currentfrag = 0.0
					SET @mycode = N''

					IF object_id('tempdb..#work_to_do') is not null 
					DROP TABLE		#work_to_do

					CREATE TABLE	#work_to_do  (
						 IndexID		int not null
						,IndexName		varchar(255) null
						,TableName		varchar(255) null
						,TableID		int not null
						,SchemaName		varchar(255) null
						,IndexType		varchar(18) not null

						,PartitionNumber	varchar(18) not null
						,PartitionCount		int null
						,CurrentDensity		float not null
						,CurrentFragmentation	float not null
						);

					INSERT INTO #work_to_do(
						IndexID, TableID, IndexType, PartitionNumber, CurrentDensity, CurrentFragmentation
						)
						SELECT
							fi.index_id 
							,fi.object_id 
							,fi.index_type_desc AS IndexType
							,cast(fi.partition_number as varchar(10)) AS PartitionNumber
							,fi.avg_page_space_used_in_percent AS CurrentDensity
							,fi.avg_fragmentation_in_percent AS CurrentFragmentation
						FROM sys.dm_db_index_physical_stats(db_id(@databasename), NULL, NULL, NULL, 'SAMPLED') AS fi 
						WHERE	(fi.avg_fragmentation_in_percent > @FragCheck 
						OR	fi.avg_page_space_used_in_percent < @DensityCheck)
						AND	page_count> 8
						AND	fi.index_id > 0

					-- Assign the index names, schema names, table names and partition counts.
					EXEC ('UPDATE #work_to_do SET TableName = t.name, SchemaName = s.name, IndexName = i.Name 
						,PartitionCount = (SELECT COUNT(*) pcount
						FROM [' 
						+ @databasename + '].sys.Partitions p
						where  p.Object_id = w.TableID 
						AND p.index_id = w.Indexid)
						FROM [' 
						+ @databasename + '].sys.tables t INNER JOIN ['
						+ @databasename + '].sys.schemas s ON t.schema_id = s.schema_id 
						INNER JOIN #work_to_do w ON t.object_id = w.tableid INNER JOIN ['
						+ @databasename + '].sys.indexes i ON w.tableid = i.object_id and w.indexid = i.index_id');

					-- Declare the cursor for the list of tables, indexes and partitions to be processed.
					-- If the index is a clustered index, rebuild all of the nonclustered indexes for the table.
					-- If we are rebuilding the clustered indexes for a table, we can exclude the nonclustered and specify ALL instead on the table.

					IF Cursor_Status('LOCAL', 'Local_Rebuildindex_Cursor') >= 0
					BEGIN
						CLOSE Local_Rebuildindex_Cursor
						DEALLOCATE Local_Rebuildindex_Cursor
					END

					DECLARE Local_Rebuildindex_Cursor CURSOR LOCAL FOR 
						SELECT 
						 IndexID
						,TableID	
						,CASE WHEN IndexType = 'Clustered Index' THEN 'ALL' ELSE '[' + IndexName + ']' END AS IndexName
						,TableName
						,SchemaName
						,IndexType
						,PartitionNumber
						,PartitionCount
						,CurrentDensity
						,CurrentFragmentation
						FROM	#work_to_do i 
						WHERE	NOT EXISTS(
								SELECT	1 
								FROM	#work_to_do iw 
								WHERE	iw.TableName = i.TableName 
								AND	iw.IndexType = 'CLUSTERED INDEX' 
								AND	i.IndexType = 'NONCLUSTERED INDEX')
						ORDER BY TableName, IndexID;

					-- Open the cursor.
					OPEN Local_Rebuildindex_Cursor;

					-- Loop through the tables, indexes and partitions.
					FETCH NEXT
					   FROM Local_Rebuildindex_Cursor
					   INTO @indexid, @tableid, @indexname, @objectname, @schemaname, @indextype, @partitionnum, @partitioncount, @currentdensity, @currentfrag;

					WHILE @@FETCH_STATUS = 0
					BEGIN;

						SET @StatusMsg = @StatusMsg + @NewLine

  					    -- SET INDEX OPTIONS FOR CURRENT INDEX DEPENDING ON IF REBUILD ON LINE IS POSSIBLE OR NOT.
						-- Only Developer and Enterprise allows REBUILD WITH (ONLINE = ON).
						-- SET REBUILD AND REORGANIZE OPTION:
						-- ======================================================================================
						IF @online = 1
						BEGIN;
						-- If online is required for Std Ed, reorganize is the only option
							IF @onlineedition = 1
							BEGIN;
								SET @myrebuildoption = N' REBUILD WITH (ONLINE = ON, FILLFACTOR = 90, MAXDOP = 0) '
								-- Changed ONLINE to always mean REBUILD WITH ONLINE, if needed, except for LOBs.
								-- LOBS are REORGANIZED, if ONLINE is specified.
								-- SET @myrebuildoption = N' REORGANIZE '
								SET @myreorganizeoption = N' REORGANIZE '
								SELECT @err = @@error IF @err <> 0 GOTO FAILONINDEX
							END;
							ELSE
							BEGIN; 
								SET @myrebuildoption =   N' REORGANIZE '
								SET @myreorganizeoption = N' REORGANIZE '
								SELECT @err = @@error IF @err <> 0 GOTO FAILONINDEX
							END;
						END;
						ELSE
						BEGIN;
							-- Even if offline is specified, this code checks if there has been active connections for the last 15 minutes
							-- and if this is the case and code execution is specified, the options used will be adapted to what is possible.
							IF @activeconnectionsindb > 0
							BEGIN;
								IF (@onlineedition = 0 AND @runrebuild = 1) 
								SET @myrebuildoption =   N' REORGANIZE '
								IF (@onlineedition = 0 AND @runrebuild = 1)
								SET @myreorganizeoption = N' REORGANIZE '
								IF (@onlineedition = 0 AND @runrebuild = 0) 
								SET @myrebuildoption = N' REBUILD WITH (FILLFACTOR = 90) '
								IF (@onlineedition = 0 AND @runrebuild = 0) 
								SET @myreorganizeoption = N' REORGANIZE '

								IF (@onlineedition = 1 AND @runrebuild = 1) 
								SET @myrebuildoption = N' REBUILD WITH (ONLINE = ON, FILLFACTOR = 90, MAXDOP = 0) '
								IF (@onlineedition = 1 AND @runrebuild = 1) 
								SET @myreorganizeoption = N' REORGANIZE '
								IF (@onlineedition = 1 AND @runrebuild = 0) 
								SET @myrebuildoption = N' REBUILD WITH (FILLFACTOR = 90, MAXDOP = 0) '
								IF (@onlineedition = 1 AND @runrebuild = 0) 
								SET @myreorganizeoption = N' REORGANIZE '

								SELECT @err = @@error IF @err <> 0 GOTO FAILONINDEX
							END;
							ELSE
							BEGIN; 
								SET @myrebuildoption =  N' REBUILD WITH (FILLFACTOR = 90, MAXDOP = 0) '
								SET @myreorganizeoption = N' REORGANIZE '

								SELECT @err = @@error IF @err <> 0 GOTO FAILONINDEX
							END;
						END;

						-- Check if index is DISABLED, then do not process it, print message.
						SET @parmmydisabledindex = N'@pmydisabledindex bit output'
						SET @sqlmydisabledindex = N'SELECT @pmydisabledindex = is_disabled '
						+ N' FROM [' + @databasename + '].sys.indexes '
						+ N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
						+ N' AND index_id = ' + cast(@indexid as varchar(50))
						EXECUTE sp_executesql @sqlmydisabledindex, @parmmydisabledindex, @pmydisabledindex = @mydisabledindex output

						SELECT @err = @@error IF @err <> 0 GOTO FAILONINDEX
						-- Check if ANY table index exists that does not allow ROW LOCKS, 
						-- including only those not hypothetical and not disabled,
						-- Do not process ANY INDEX FOR THIS TABLE IF ROW LOCKS IS NOT ALLOWED.
						-- Print message and proceed to next.
						-- This SP requires that you always allow row-level locking!
						-- MS: "By default, SQL Server makes a choice of page-level, row-level, or table-level locking. 
						-- When cleared, the index does not use row-level locking. By default, this check box is selected. 
						-- This option is only available for SQL Server 2005 indexes. 
						-- This option will reduce the chance of temporarily blocking other users, but it can slow down index maintenance actions."
						-- It is usually better to let SQL Server manage the locking behavior.
						SET @parmmyallowrowlocks = N'@xrowlocksnotallowedcount int output'
						SET @sqlmyallowrowlocks = N'SELECT @xrowlocksnotallowedcount = COUNT(allow_row_locks) '
						+ N' FROM [' + @databasename + '].sys.indexes '
						+ N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
						+ N' AND allow_row_locks = 0 '
						+ N' AND is_hypothetical = 0 '
						+ N' AND is_disabled = 0 '
						EXECUTE sp_executesql @sqlmyallowrowlocks, @parmmyallowrowlocks, @xrowlocksnotallowedcount = @rowlocksnotallowedcount output
						IF @rowlocksnotallowedcount > 0 SET @StatusMsg = @StatusMsg + @NewLine +  N'-- NOTE: Row locks not allowed on object_id = ' + cast(@tableid as varchar(50)) + N', table ' + @objectname + N', index ' + @indexname

						-- Check if ANY table index exists that do
es not allow PAGE LOCKS, 
						-- including only those not hypothetical and not disabled.
						-- Do not process ANY INDEX FOR THIS TABLE IF PAGE LOCKS IS NOT ALLOWED.
						-- Print message and proceed to next.
						-- This SP requires that you always allow page-level locking!
						-- MS: "By default, SQL Server makes a choice of page-level, row-level, or table-level locking. 
						-- By default, SQL Server makes a choice of page-level, row-level, or table-level locking. 
						-- When cleared, the index does not use page-level locking. By default, this check box is selected. 
						-- This option is only available for SQL Server 2005 indexes. 
						-- This option will reduce the chance of temporarily blocking other users, but it can slow down index maintenance actions."
						-- It is usually better to let SQL Server manage the locking behavior.
						SET @parmmyallowpagelocks = N'@xpagelocksnotallowedcount int output'
						SET @sqlmyallowpagelocks = N'SELECT @xpagelocksnotallowedcount = COUNT(allow_page_locks) '
						+ N' FROM [' + @databasename + '].sys.indexes '
						+ N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
						+ N' AND allow_page_locks = 0 '
						+ N' AND is_hypothetical = 0 '
						+ N' AND is_disabled = 0 '
						EXECUTE sp_executesql @sqlmyallowpagelocks, @parmmyallowpagelocks, @xpagelocksnotallowedcount = @pagelocksnotallowedcount output
						IF @pagelocksnotallowedcount > 0 SET @StatusMsg = @StatusMsg + @NewLine +  N'-- NOTE: Page locks not allowed on object_id = ' + cast(@tableid as varchar(50)) + N', table ' + @objectname + N', index ' + @indexname

						-- Check if index is hypotetical, then do not process it
						SET @parmmyindexishypotetical = N'@pmyindexishypotetical bit output'
						SET @sqlmyindexishypotetical = N'SELECT @pmyindexishypotetical = is_hypothetical '
						+ N' FROM [' + @databasename + '].sys.indexes '
						+ N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
						+ N' AND index_id = ' + cast(@indexid as varchar(50))
						EXECUTE sp_executesql @sqlmyindexishypotetical, @parmmyindexishypotetical, @pmyindexishypotetical = @myindexishypotetical output

						SELECT @err = @@error IF @err <> 0 GOTO FAILONINDEX					 
						-- Check if this table contains LOB_DATA; if so, always do a REORGANIZE; REBUILD WITH (ONLINE = ON) is not allowed
						SET @parmlob_count = N'@plob_count INT output'

						SET @sqllob_count = N'SELECT @plob_count = lob_data_space_id '
						+ N' FROM [' + @databasename + '].sys.tables '
						+ N' WHERE object_id = ' + cast(@tableid as varchar(50)) 
						
						EXECUTE sp_executesql @sqllob_count, @parmlob_count, @plob_count = @lob_count output

						SELECT @err = @@error IF @err <> 0 GOTO FAILONINDEX
						-- ALWAYS SET TO REORGANIZE option for LOBs, if ONLINE IS REQUIRED - they can not be rebuilt online.
						-- LOB Online:
						IF (@lob_count > 0 AND @online = 1)
						SET @myrebuildoption = N' REORGANIZE '
						-- LOB Offline specified, but active users
						IF (@lob_count > 0 AND @online = 0 AND @runrebuild = 1 AND @activeconnectionsindb > 0) 
						SET @myrebuildoption = N' REORGANIZE '
						-- SQL Enterprise Edition,LOB Offline specified and no active users
						IF (@lob_count > 0 AND @online = 0 AND @runrebuild = 1 AND @activeconnectionsindb = 0 AND @onlineedition = 1) 
						SET @myrebuildoption = N' REBUILD WITH (FILLFACTOR = 90, MAXDOP = 0) '
						-- SQL Standard Edition,LOB Offline specified and no active users
						IF (@lob_count > 0 AND @online = 0 AND @runrebuild = 1 AND @activeconnectionsindb = 0 AND @onlineedition = 0) 
						SET @myrebuildoption = N' REBUILD WITH (FILLFACTOR = 90) '

						-- If index is disabled (1) OR pagelocks is not allowed (0) OR index is hypotetical (1), then do not process!
						IF (@mydisabledindex = 1 OR @rowlocksnotallowedcount > 0 OR @pagelocksnotallowedcount > 0 OR @myindexishypotetical = 1)
						 -- Send a message for indexes not processed! 
						BEGIN;
						SET @StatusMsg = @StatusMsg + @NewLine +  '-- Index ' + @indexname + ' for table ' + @schemaname + '.' + @objectname + ' is disabled or hypotetical or has index row/page locking disabled!'
						SET @StatusMsg = @StatusMsg + @NewLine +  N'Skipped index for table ' + @schemaname + '.' + @objectname + N', index ' + @indexname
							+ N' partition ' + cast(@partitionnum as varchar(10)) + N', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
							+ N', avg page space used in percent ' + cast(@currentdensity as varchar(50)) + N'.' 
							+ N' Index ' + @indexname + N' is disabled or hypotetical or has index row/page locking disabled!'
						GOTO NEXTINDEX
						END;
						ELSE
						BEGIN;
						-- If the index is more heavily fragmented, issue a REBUILD, if ONLINE is required and possible.  
						-- Otherwise, REORGANIZE.
						IF @currentfrag < @RebuildThreshold
						BEGIN;
							SELECT @command = N'ALTER INDEX ' + @indexname + N' ON [' + @databasename + N'].[' + @schemaname + N'].[' + @objectname + N']' + @myreorganizeoption;
							IF @partitioncount > 1 SELECT @command = @command + N' PARTITION = ' + @partitionnum  + ';';
							ELSE SET @command = @command  + ';'
							IF @runrebuild = 1 exec @rc = sp_executesql @command
							IF @runrebuild = 0 SET @mycode = @mycode + N' ' + @command
							IF @rc <> 0
							BEGIN;
								SELECT @outparm = 4
								SET @StatusMsg = @StatusMsg + @NewLine +  'Stopped index rebuild/reorganize for database ' + @databasename + ' on SQL Server ' + @@SERVERNAME +  CHAR(13) 
								+ ', exit on error when executing command ' + @command + ' !'
								GOTO CODEEXIT
							END;
							ELSE SELECT @outparm = 0
						END;

						IF @currentfrag >= @RebuildThreshold
						BEGIN;
							SELECT @command = N'ALTER INDEX ' + @indexname + N' ON [' + @databasename + N'].[' + @schemaname + N'].[' + @objectname + N']' + @myrebuildoption;
							IF @partitioncount > 1 SELECT @command = @command + N' PARTITION = ' + @partitionnum;
							ELSE SET @command = @command  + ';'
							IF @runrebuild = 1 exec @rc = sp_executesql @command
							IF @runrebuild = 0 SET @mycode =  @mycode + N' ' + @command
							IF @rc <> 0
							BEGIN;
								SELECT @outparm = 4
								SET @StatusMsg = @StatusMsg + @NewLine +  'Stopped index rebuild/reorganize for database ' + @databasename + ' on SQL Server ' + @@SERVERNAME +  CHAR(13) 
								+ ', exit on error when executing command ' + @command + ' !'
								GOTO CODEEXIT
							END;
							ELSE SELECT @outparm = 0
						END;
	
						IF @lob_count > 0
						BEGIN;
							SELECT @err = @@error IF @err <> 0 GOTO FAILONINDEX
							IF @indexid = 1
							BEGIN;
								SET @StatusMsg = @StatusMsg + @NewLine +  '-- Processing LOB table ' + (CASE ISNULL(@Schemaname, '') WHEN '' THEN ' ' ELSE @Schemaname END) 
									+ '.' + (CASE ISNULL(@Objectname, '') WHEN '' THEN ' ' ELSE @Objectname END) + ', CLUSTERED index ' + @indexname + ', ' + CHAR(13) 
									+ '-- partition ' + cast(@partitionnum as varchar(10)) + ', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
									+ ', avg page space used in percent ' + cast(@currentdensity as varchar(50))
							END;
							ELSE IF @indexid >= 32000
							BEGIN;
								SET @StatusMsg = @StatusMsg + @NewLine +  '-- Processing LOB table ' + (CASE ISNULL(@Schemaname, '') WHEN '' THEN ' ' ELSE @Schemaname END) 
									+ '.' + (CASE ISNULL(@Objectname, '') WHEN '' THEN ' ' ELSE @Objectname END) + ', XML index ' + @indexname + ', ' + CHAR(13) 
									+ '-- partition ' + cast(@partitionnum as varchar(10)) + ', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
      									+ ', avg page space used in percent ' + cast(@currentdensity as varchar(50))
							END;
							ELSE
							BEGIN;
								SET @StatusMsg = @StatusMsg + @NewLine +  '-- Processing LOB table ' + (CASE ISNULL(@Schemaname, '') WHEN '
' THEN ' ' ELSE @Schemaname END) 
									+ '.' + (CASE ISNULL(@Objectname, '') WHEN '' THEN ' ' ELSE @Objectname END) + ', STANDARD index ' + @indexname + ', ' + CHAR(13) 
									+ '-- partition ' + cast(@partitionnum as varchar(10)) + ', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
									+ ', avg page space used in percent ' + cast(@currentdensity as varchar(50))
							END;
						END;
						ELSE
						BEGIN;
							SELECT @err = @@error IF @err <> 0 GOTO FAILONINDEX
							IF @indexid = 1 
							BEGIN;
								SET @StatusMsg = @StatusMsg + @NewLine +  '-- Processing STANDARD table ' + (CASE ISNULL(@Schemaname, '') WHEN '' THEN ' ' ELSE @Schemaname END) 
									+ '.' + (CASE ISNULL(@Objectname, '') WHEN '' THEN ' ' ELSE @Objectname END) + ', CLUSTERED index ' + @indexname + ', ' + CHAR(13) 
									+ '-- partition ' + cast(@partitionnum as varchar(10)) + ', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
									+ ', avg page space used in percent ' + cast(@currentdensity as varchar(50))
							END;
							ELSE
							BEGIN; 
								SET @StatusMsg = @StatusMsg + @NewLine +  '-- Processing STANDARD table ' + (CASE ISNULL(@Schemaname, '') WHEN '' THEN ' ' ELSE @Schemaname END) 
									+ '.' + (CASE ISNULL(@Objectname, '') WHEN '' THEN ' ' ELSE @Objectname END) + ', STANDARD index ' + @indexname + ', ' + CHAR(13) 
									+ '-- partition ' + cast(@partitionnum as varchar(10)) + ', avg frag in percent ' + cast(@currentfrag as varchar(50)) 
									+ ', avg page space used in percent ' + cast(@currentdensity as varchar(50))
							END;
						END;

						SET @countprocessed = @countprocessed + 1
						IF @runrebuild = 1 SET @StatusMsg = @StatusMsg + @NewLine +  '-- Executed: ' + (CASE ISNULL(@command, '') WHEN '' THEN ' ' ELSE @command END);
						ELSE SET @StatusMsg = @StatusMsg + @NewLine +  '-- Code to be executed: ' + CHAR(13) + (CASE ISNULL(@command, '') WHEN '' THEN ' ' ELSE @command END);
						END;

						SELECT
							@postdensity	= fi.avg_page_space_used_in_percent,
							@postfrag = fi.avg_fragmentation_in_percent
						FROM sys.dm_db_index_physical_stats(db_id(@databasename), NULL, NULL, NULL, 'SAMPLED') AS fi 
						WHERE	index_id = @indexid and object_id = @tableid
						
						SET @StatusMsg = @StatusMsg + @NewLine +  '-- Results: ' + 'avg frag in percent ' + cast(@postfrag as varchar(50)) 
								+ ', avg page space used in percent ' + cast(@postdensity as varchar(50))						

						NEXTINDEX:
						FETCH NEXT FROM Local_Rebuildindex_Cursor INTO @indexid, @tableid, @indexname, @objectname, @schemaname, @indextype, @partitionnum, @partitioncount, @currentdensity, @currentfrag;
					END;

					-- Close and deallocate the cursor.
					CLOSE Local_Rebuildindex_Cursor;
					DEALLOCATE Local_Rebuildindex_Cursor;

					CODEEXIT:

					--- Alter recovery model BACK TO original after reindexing.
					--- Check database recovery model and change it to original if needed.
					SELECT @RecoveryMode = cast(DATABASEPROPERTYEX(@databasename, 'Recovery') as varchar(20))

					IF @RecoveryMode <> @RecoveryModeOld
					BEGIN;
						SELECT @altdbafter = N'ALTER DATABASE [' + @databasename + N'] SET RECOVERY ' + @RecoveryModeOld + N'; '
						EXEC(@altdbafter)
						SELECT @dbStatusMsg =  '-- Recovery model for database ' + @databasename + ' was set back to original ' + @RecoveryModeOld + ' from ' + @RecoveryMode + ' recovery mode.'
						SET @StatusMsg = @StatusMsg + @NewLine +  @dbStatusMsg						
					END;

					-- If database is in mirroring, change safety level back to original mode after reindexing

					IF @DBMirrorPerf = 1 and @dbmirrorold > 1   
					BEGIN;
						IF @dbmirrorold = 2   -- DB mirroring in high protection mode	
						BEGIN;
							SELECT @altdbmirrorafter = N'ALTER DATABASE [' + @databasename + N'] SET PARTNER SAFETY FULL; '
							EXEC(@altdbmirrorafter)
							SELECT @dbStatusMsg = '-- Mirror safety level for database ' + @databasename + ' was changed back to FULL.' 
							SET @StatusMsg = @StatusMsg + @NewLine +  @dbStatusMsg
						END;

						IF @dbmirrorold = 3  -- DB mirroring in high availability mode	
						BEGIN;	
							SELECT @altdbmirrorafter = N'ALTER DATABASE [' + @databasename + N'] SET PARTNER SAFETY FULL WITNESS [' + @dbmirrorwitness + N']; '
							EXEC(@altdbmirrorafter)
							SELECT @dbStatusMsg = '-- Mirror safety level for database ' + @databasename + ' was changed to FULL with witness.' 
							SET @StatusMsg = @StatusMsg + @NewLine +  @dbStatusMsg
						END;
					 END;

					SET @StatusMsg = @StatusMsg + @NewLine

					IF @countprocessed = 0 
					BEGIN;
						SET @StatusMsg = @StatusMsg + @NewLine +  '-- No indexes needed rebuilding in database ' + @databasename
					END;
					ELSE
					BEGIN;
						SELECT @altdbafter = N''
						SELECT @mycode = @altdbbefore + @mycode + @altdbafter
						IF @runrebuild = 1 
						BEGIN	
							SET @StatusMsg = @StatusMsg + @NewLine +  '-- ' + cast(@countprocessed as varchar(20)) + ' indexes were reorganized or rebuilt!'
						END
						ELSE
						BEGIN	
							SET @StatusMsg = @StatusMsg + @NewLine +  '-- Code for reorganize and/or rebuild of ' + cast(@countprocessed as varchar(20)) + ' indexes was generated!'
						END
					END;

					SET @StatusMsg = @StatusMsg + @NewLine

					-- Return codes (@outparm): 0=OK, 4=Exit on Other Error
					IF 	@outparm = 0
						BEGIN;
							SET @StatusMsg = @StatusMsg + @NewLine + N'-- Returned execution status for master.dbo.usp_RebuildIndexes after processing '  
							+ @databasename + N' on SQL Server ' + @@servername +  N' is Index rebuild OK!' 
							SET @Status = 'Ok'
						END;
					ELSE IF @outparm = 4
						BEGIN;  
							SET @StatusMsg = @StatusMsg + @NewLine + N'-- Returned execution status for master.dbo.usp_RebuildIndexes after processing '  
							+ @databasename + N' on SQL Server ' + @@servername +  N' is Exit on Other Error!'
							SET @Status = 'Exit on Other Error'
							GOTO MAXTIMEOUT
						END;
					ELSE
						BEGIN;  
							SET @StatusMsg = @StatusMsg + @NewLine + N'-- Returned execution status for master.dbo.usp_RebuildIndexes after processing '  
							+ @databasename + N' on SQL Server ' + @@servername +  N' is Unknown Exit Code!'
							SET @Status = 'Unknown Exit Code'
							GOTO MAXTIMEOUT
						END;

					BEGIN;
						---Calculate time remaining in seconds
						SELECT @totalsecondspassed = DATEDIFF(ss, @startmain, getdate())
						SELECT @endeddate = getdate()
						SET @StatusMsg = @StatusMsg + @NewLine + '-- END OF INDEX DEFRAG FOR DATABASE ' + @databasename + ' AT ' + CONVERT (VARCHAR(20), getdate(), 120)						
						SET @StatusMsg = @StatusMsg + @NewLine + '-- Processing time for database ' + @databasename + ' was ' + Cast((DATEDIFF(ss, @starteddate, getdate())) as varchar(20)) + ' seconds.'
						SET @StatusMsg = @StatusMsg + @NewLine + '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'	

					END;

					LOGSTATUS:
					--Insert Log in Job Log table
					INSERT INTO [master].[dbo].[ReorgRebuildIndexesJobLog]
							   ([DatabaseName]
							   ,[JobRunStartDateTime]
							   ,[JobRunEndDateTime]
							   ,[JobIndexCount]
							   ,[JobStatus]
							   ,[JobLog])
					VALUES
								(@databasename
								,@starteddate
								,GetDate()
								,@countprocessed
								,@Status
								,@StatusMsg)

					IF @SendEmail = 1 and @SendSummaryOnly = 0
					BEGIN
						-- Name of current sender
						SET @myfromname = N'Message from SQL Server ' + @@servername

						-- Get e-mail adresses of operators
						BEGIN
							SET @alladdresses = N''
							DECLARE  MAILResults_CURSOR CURSOR FORWARD_ONLY READ_ONLY FOR 
								 SELECT email_address FROM msdb.dbo.sysoperators WITH (NOLOCK) where email_address IS NOT NULL
							OPEN MAILResults_CURSOR
					
		FETCH NEXT FROM MAILResults_CURSOR INTO @myrecipients
							WHILE @@FETCH_STATUS = 0
								BEGIN
									SET @mycurrentaddres = @myrecipients + CHAR(59)
									SET @alladdresses = @alladdresses + @mycurrentaddres
									FETCH NEXT FROM MAILResults_CURSOR INTO @myrecipients
								END
							CLOSE MAILResults_CURSOR
							DEALLOCATE MAILResults_CURSOR
							IF @alladdresses <> N'' 
							BEGIN

								SET	@SubjectLocal = 'Status ' + @Status + ': Reorg\Rebuild - ' + @databasename + ' DB on ' + @@servername
								
								EXEC msdb.dbo.sp_send_dbmail
											 @profile_name = NULL
											,@recipients = @alladdresses
											,@copy_recipients = NULL
											,@blind_copy_recipients = NULL
											,@subject = @SubjectLocal
											,@body = @StatusMsg
											,@body_format = 'TEXT'
											,@importance = 'Normal'
											,@sensitivity = 'Normal'
							END
							SELECT @err = @@error IF @err <> 0 GOTO FAILONEMAIL	
						END						
					END

    				END;

					NEXTDB:
					SET	@StatusMsg = N''
    				FETCH NEXT FROM Main_Cursor INTO @databasename
			END;

			IF @SendEmail = 1 and @SendSummaryOnly = 1
			BEGIN
				-- Get e-mail adresses of operators
				BEGIN
					SET @alladdresses = N''
					DECLARE  MAILResults_CURSOR CURSOR FORWARD_ONLY READ_ONLY FOR 
						 SELECT email_address FROM msdb.dbo.sysoperators WITH (NOLOCK) where email_address IS NOT NULL
					OPEN MAILResults_CURSOR
					FETCH NEXT FROM MAILResults_CURSOR INTO @myrecipients
					WHILE @@FETCH_STATUS = 0
						BEGIN
							SET @mycurrentaddres = @myrecipients + CHAR(59)
							SET @alladdresses = @alladdresses + @mycurrentaddres
							FETCH NEXT FROM MAILResults_CURSOR INTO @myrecipients
						END
					CLOSE MAILResults_CURSOR
					DEALLOCATE MAILResults_CURSOR
					
					SET	@MailBody = 'Following is summary report Reorg\Rebuild Job ran on ' + @@servername
					
					DECLARE  MAILBody_CURSOR CURSOR FORWARD_ONLY READ_ONLY FOR 
						SELECT [DatabaseName]
							  ,[JobRunStartDateTime]
							  ,[JobRunEndDateTime]
							  ,[JobIndexCount]
							  ,[JobStatus]
						 FROM	[master].[dbo].[ReorgRebuildIndexesJobLog]
						 WHERE	JobRunStartDateTime >= @MainStartDateTime
					OPEN MAILBody_CURSOR
					FETCH NEXT FROM MAILBody_CURSOR INTO @Databasename, @JobRunStartDateTime, @JobRunEndDateTime, @JobIndexCount, @JobStatus
					WHILE @@FETCH_STATUS = 0
						BEGIN
							SET @MailBody = @MailBody + @NewLine
							SET @MailBody = @MailBody + @NewLine + 'Database: ' + @DatabaseName
							SET @MailBody = @MailBody + @NewLine + 'Status: ' + @JobStatus
							SET @MailBody = @MailBody + @NewLine + 'Indexes Reorg\Rebuild: ' + CONVERT(NVARCHAR (50), @JobIndexCount)							
							SET @MailBody = @MailBody + @NewLine + 'Duration: ' + CONVERT(NVARCHAR (50), DATEDIFF(ss, @JobRunStartDateTime, @JobRunEndDateTime)) + ' Second(s)'	
							
							FETCH NEXT FROM MAILBody_CURSOR INTO @Databasename, @JobRunStartDateTime, @JobRunEndDateTime, @JobIndexCount, @JobStatus
						END
					CLOSE MAILBody_CURSOR
					DEALLOCATE MAILBody_CURSOR
					
					IF @alladdresses <> N'' 
					BEGIN

						SET	@SubjectLocal = 'Reorg\Rebuild Summary Report For ' + @@servername
						
						EXEC msdb.dbo.sp_send_dbmail
									 @profile_name = NULL
									,@recipients = @alladdresses
									,@copy_recipients = NULL
									,@blind_copy_recipients = NULL								
									,@subject = @SubjectLocal
									,@body = @MailBody
									,@body_format = 'TEXT'
									,@importance = 'Normal'
									,@sensitivity = 'Normal'
					END
				END						
			END	
			MAXTIMEOUT:
			IF Cursor_Status('GLOBAL', 'Main_Cursor') >= 0
			BEGIN
				CLOSE Main_Cursor
				DEALLOCATE Main_Cursor
			END

			--Write Success to Event Log
			LOGINFOANDEXIT:
			EXEC master..xp_logevent 65555, 'Reorg / Rebuild Indexes Job ran successfully. Review [ReorgRebuildIndexesJobLog] table for details', INFORMATIONAL
			SET @Retry = -1
			RETURN
			
			FAILONDB:
			PRINT @ErrorMsg
			EXEC master..xp_logevent 65556, @ErrorMsg, ERROR
			IF Cursor_Status('GLOBAL', 'Main_Cursor') >= 0
			BEGIN
				CLOSE Main_Cursor
				DEALLOCATE Main_Cursor
			END
			RETURN

			FAILONINDEX:
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Reorg \ Rebuild Index Job Error Information For Database:' + @databasename
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error Number: ' + CONVERT(VARCHAR(50), ERROR_NUMBER()) 
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error Severity: ' + CONVERT(VARCHAR(5), Error_Severity()) 
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error State: ' + CONVERT(VARCHAR(5), Error_State())
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error Line: ' + CONVERT(VARCHAR(5), ERROR_LINE())
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error Message: ' + Error_Message()

			SET @StatusMsg = @StatusMsg + @NewLine + 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'	
			SET @StatusMsg = @StatusMsg + @NewLine + @ErrorMsg
			SET @StatusMsg = @StatusMsg + @NewLine + 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'	
			SET @Retry = @Retry + 1
			GOTO NEXTINDEX

			FAILONEMAIL:
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Reorg \ Rebuild Index Job Email Error Information For Database:' + @databasename
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error Number: ' + CONVERT(VARCHAR(50), ERROR_NUMBER()) 
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error Severity: ' + CONVERT(VARCHAR(5), Error_Severity()) 
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error State: ' + CONVERT(VARCHAR(5), Error_State())
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error Line: ' + CONVERT(VARCHAR(5), ERROR_LINE())
			SET @ErrorMsg = @ErrorMsg + @NewLine + 'Error Message: ' + Error_Message()
			SET @Retry = @Retry + 1
			GOTO NEXTDB		

	END
	
END




GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
