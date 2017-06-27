USE [msdb]
GO

/****** Object:  Job [DBA Weekly Backup Report]    Script Date: 09/20/2011 09:16:35 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/20/2011 09:16:35 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Weekly Backup Report', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Weekly Backup Report]    Script Date: 09/20/2011 09:16:36 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Weekly Backup Report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use NetquoteTechnologyOperations;
go
Begin Try
exec sp_dropserver ''BKUPEXCEL'';
exec sp_linkedservers;
End Try
Begin Catch
Print ''Just keep going'';
End Catch;
Declare @date varchar(100), @sqltxt varchar(8000), @sqltxt2 varchar(8000), @month varchar(2);
set @date = Cast(MONTH(getdate()) as varchar(2))+CAST(day(getdate()) as varchar(2))+
	CAST(year(getdate()) as varchar(4));
set @month = cast(month(getdate()) as varchar(2));


--set @sqltxt = ''spexecute_adodb_sql @ddl = ''''CREATE table backupreport''+@date+''  (server_name varchar(20), db_name varchar(30), dbmode varchar(10),
--      last_dbfull_copy varchar(24), last_dbdiff_copy varchar(24), last_dblog_copy varchar(24))'''',
--	  @Datasource = ''''C:\backupreports.xls'''''';

--exec (@sqltxt);


-------------------------------------
use tempdb;
IF OBJECT_ID (''dbo.BKUPWORK1'', ''U'') IS NOT NULL
    DROP TABLE dbo.BKUPWORK1;
IF OBJECT_ID (''dbo.BKUPWORK2'', ''U'') IS NOT NULL
    DROP TABLE dbo.BKUPWORK2;
IF OBJECT_ID (''dbo.BKUPWORK3'', ''U'') IS NOT NULL
    DROP TABLE dbo.BKUPWORK3;
IF OBJECT_ID (''dbo.BKUPWORK4'', ''U'') IS NOT NULL
    DROP TABLE dbo.BKUPWORK4;
--**********************************************************************
Create table BKUPWORK1 (report_date datetime, report_year varchar(4), 
report_month varchar(2), report_day varchar(2), report_hour varchar(2), 
report_min varchar(2), report_concat_date varchar(12));
Declare @TTDATE datetime;
DECLARE @TTYEAR varchar(4);
DECLARE @TTMONTH varchar(2);
DECLARE @TTDAY varchar(2);
DECLARE @TTHOUR varchar(2);
DECLARE @TTMIN varchar(2);
DECLARE @TTCDATE varchar(12);
SET @TTDATE = (Select GETDATE());
SET @TTYEAR = (SELECT Datepart(yyyy,@TTDATE));
SET @TTMONTH = (SELECT datepart(mm,@TTDATE));
SET @TTDAY = (SELECT datepart(dd,@TTDATE));
SET @TTHOUR = (SELECT datepart(hh, @TTDATE));
SET @TTMIN = (SELECT datepart(MI, @TTDATE));
SET @TTCDATE = @TTYEAR + @TTMONTH + @TTDAY + @TTHOUR + @TTMIN;
Insert dbo.BKUPWORK1
 Values(@TTDATE,@TTYEAR,@TTMONTH,@TTDAY,@TTHOUR,@TTMIN,@TTCDATE);
--**********************************************************************
Create table BKUPWORK2 (server_name varchar(20), db_name varchar(30), env_name varchar(20), dbmode varchar(10),
      last_dbfull_copy varchar(24), last_dbdiff_copy varchar(24), last_dblog_copy varchar(24),
      constraint PK_BKUP2 PRIMARY KEY(server_name, db_name));
--**********************************************************************
Create table BKUPWORK3 (server_name varchar(20), step_name varchar(10), ErrorNumber int, ErrorSeverity int, ErrorState int, ErrorLine int,
      ErrorProcedure varchar(80), ErrorMessage varchar(100));
BEGIN TRY
DEALLOCATE server_cursor;
END TRY
BEGIN CATCH
Insert dbo.BKUPWORK3 
 SELECT Cast(''server_cursor'' as char(20)) as server_name, Cast(''deallocate'' as char(10)) as step_name,
        ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() as ErrorState, ERROR_LINE () as ErrorLine,
        ERROR_PROCEDURE() as ErrorProcedure, ERROR_MESSAGE() as ErrorMessage;
END CATCH
--**********************************************************************
Create table BKUPWORK4 (subsys_name char(20),server_name varchar(20), env_name char(20),
            constraint PK_BKUP4 PRIMARY KEY(subsys_name, server_name));
	Insert dbo.BKUPWORK4
 Values(''BKUP1'',''qadb.nq.corp'','''');
	Insert dbo.BKUPWORK4
 Values(''BKUPPRDTRS01'',''spdbxx0006\TRS01'',''PortalReports'');
	Insert dbo.BKUPWORK4
 Values(''BKUPPRDBUS01'',''spdbxx0001\BUS01'',''Business'');
	Insert dbo.BKUPWORK4
 Values(''BKUPPRDBO01'',''spdbxx0013\BO01'',''BackOffice'');
	Insert dbo.BKUPWORK4
 Values(''BKUPPRDWEBNW'',''spdbxx0021\webnew'',''Webnew'');
	Insert dbo.BKUPWORK4
 Values(''BKUPPRDODS'',''spdbxx0028\ODS02'',''ODS'');
	Insert dbo.BKUPWORK4
 Values(''BKUPPRDDIST'',''SPDBXX0026\DIST02'',''DIST'');
    Insert dbo.BKUPWORK4
 Values(''BKUPPRDLMS'',''SPDBXX0007\LMS01'',''LMS'');
    Insert dbo.BKUPWORK4
 Values(''BKUPPRDWA'',''SPDBXX0015'',''WebA'');
--     Insert dbo.BKUPWORK4
-- Values(''BKUPPRDCRM'',''SPDBXX0022\CRM01'',''CRM'');
 

--**********************************************************************
BEGIN
Use tempdb;
DECLARE server_cursor CURSOR READ_ONLY FOR 
SELECT subsys_name,server_name, env_name FROM dbo.BKUPWORK4;
DECLARE @subsys char(20), @server_nm varchar(20), @env_nm varchar(20);
Open server_cursor
Fetch next from server_cursor into @subsys,@server_nm,@env_nm;
--**********************************************************************
WHILE @@FETCH_STATUS = 0
BEGIN
Begin Try
exec sp_addlinkedserver @server= @subsys, @srvproduct = '' '', @provider = ''SQLNCLI'',
      @datasrc = @server_nm;
Insert dbo.BKUPWORK3 
 SELECT Cast(@server_nm as char(20)) as server_name, Cast(''Add Link'' as char(10)) as step_name,
        ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() as ErrorState, ERROR_LINE () as ErrorLine,
        ERROR_PROCEDURE() as ErrorProcedure, ERROR_MESSAGE() as ErrorMessage;
End Try
Begin Catch
Select * from dbo.BKUPWORK3;
End Catch
------------------------------------------
IF (Select ErrorLine From dbo.BKUPWORK3 Where server_name = @server_nm
      and step_name = ''Add Link'') IS NULL
Begin
Begin Try
DECLARE @SLCT1 varchar(4000);
SET @SLCT1 = ''Select cast('''''' + @server_nm + '''''' as char(20)) as server_name,
   cast(rtrim(db_name) as char(25))as db_name, cast('''''' + @env_nm + '''''' as char(20)) as env_name, 
   dbmode, cast(rtrim(last_dbfull_copy) as char(24)) as last_dbfull_copy, 
   cast(rtrim(last_dbdiff_copy) as char(24)) as last_dbdiff_copy,
   cast(rtrim(last_dblog_copy) as char(24)) as last_dblog_copy 
   from (Select name as db_name, sysdb.recovery_model_desc as dbmode, 
   cast(FULL_COPY.last_copy as varchar) as last_dbfull_copy,
   cast(DIFF_COPY.last_copy as varchar) as last_dbdiff_copy, 
   cast(LOG_COPY.last_copy as varchar) as last_dblog_copy  
   from '' + RTRIM(@subsys) + ''.master.sys.databases sysdb 
   left outer join (select database_name, type, max(backup_finish_date) as last_copy
   from '' + RTRIM(@subsys) +''.msdb.dbo.backupset where type = ''''D'''' group by database_name, type) FULL_COPY 
   on sysdb.name = FULL_COPY.database_name left outer join (select database_name, type, max(backup_finish_date) as last_copy
   from '' + RTRIM(@subsys) + ''.msdb.dbo.backupset where type = ''''I'''' group by database_name, type) DIFF_COPY 
   on sysdb.name = DIFF_COPY.database_name left outer join (select database_name, type, max(backup_finish_date) as last_copy
   from '' + RTRIM(@subsys) + ''.msdb.dbo.backupset where type = ''''L'''' group by database_name, type) LOG_COPY
   on sysdb.name = LOG_COPY.database_name where name <> ''''tempdb'''' ) big_pic ;'';

print @slct1;
Insert dbo.BKUPWORK2 
  EXEC(@SLCT1);
End Try
Begin Catch
Insert dbo.BKUPWORK3 
 SELECT Cast(@server_nm as char(20)) as server_name, Cast(''Query'' as char(10)) as step_name,
        ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() as ErrorState, ERROR_LINE () as ErrorLine,
        ERROR_PROCEDURE() as ErrorProcedure, ERROR_MESSAGE() as ErrorMessage;
End Catch
End 
EXEC sp_dropserver @server=@subsys;
Insert dbo.BKUPWORK3 
 SELECT Cast(@server_nm as char(20)) as server_name, Cast(''Drop Link'' as char(10)) as step_name,
        ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() as ErrorState, ERROR_LINE () as ErrorLine,
        ERROR_PROCEDURE() as ErrorProcedure, ERROR_MESSAGE() as ErrorMessage;
Fetch next from server_cursor into @subsys,@server_nm,@env_nm;
END 
END
--------------------------------------------------
Declare backup_cursor CURSOR READ_ONLY FOR
 SELECT server_name, db_name,env_name, last_dbfull_copy, last_dbdiff_copy, last_dblog_copy 
 FROM dbo.BKUPWORK2;
DECLARE @CRDT varchar(24),@bkup_server_nm varchar(20), @bkup_dbname varchar(25),@bkup_env_nm varchar(20),
      @bkup_dbfull_copy varchar(24), @bkup_dbdiff_copy varchar(24), @bkup_dblog_copy varchar(24);
SET @CRDT = getdate();
Print @CRDT;
Open backup_cursor
Fetch next from backup_cursor into @bkup_server_nm,@bkup_dbname,@bkup_env_nm,@bkup_dbfull_copy,
      @bkup_dbdiff_copy, @bkup_dblog_copy;
--**********************************************************************
WHILE @@FETCH_STATUS = 0
Begin
If (datediff(day,@bkup_dbfull_copy,@CRDT) > 7)
 or (@bkup_dbfull_copy is NULL)
 Begin
 Print @bkup_dbfull_copy;
 Update dbo.BKUPWORK2
  SET last_dbfull_copy = ''no recent full copy''
  Where server_name = @bkup_server_nm
    and db_name = @bkup_dbname
    and env_name = @bkup_env_nm;
 End
If datediff(day,@bkup_dbdiff_copy,@CRDT) > 7
 or (@bkup_dbdiff_copy is NULL)
 Begin
 Print @bkup_dbdiff_copy;
 Update dbo.BKUPWORK2
  SET last_dbdiff_copy = ''no recent diff copy''
  Where server_name = @bkup_server_nm
    and db_name = @bkup_dbname
    and env_name = @bkup_env_nm;
 End
If datediff(day,@bkup_dblog_copy,@CRDT) > 7
 or (@bkup_dblog_copy is NULL)
 Begin
 Print @bkup_dblog_copy;
 Update dbo.BKUPWORK2
  SET last_dblog_copy = ''no recent log copy''
  Where server_name = @bkup_server_nm
    and db_name = @bkup_dbname
    and env_name = @bkup_env_nm;
 End
Fetch next from backup_cursor into @bkup_server_nm,@bkup_dbname,@bkup_env_nm,@bkup_dbfull_copy,
      @bkup_dbdiff_copy, @bkup_dblog_copy;
END

DEALLOCATE server_cursor;
DEALLOCATE backup_cursor;
exec sp_linkedservers;
select * from dbo.BKUPWORK1;
select distinct * from (
select server_name, [db_name], dbmode, last_dbfull_copy, last_dbdiff_copy =
case when dbmode = ''simple'' then ''Not applicable''
     else last_dbdiff_copy
     end,
last_dblog_copy =
case when dbmode = ''simple'' then ''Not applicable''
     else last_dblog_copy
     end
from dbo.BKUPWORK2
 where ([db_name] not like ''NetQuoteTechnology%''
    and [db_name] not like ''NetQuoteArchive%'')) sq
 order by server_name,db_name;
select * from dbo.BKUPWORK3;
select * from dbo.BKUPWORK4;
----------------------------------------------------------------
--This sections commented out until path to load doc to share is know and access understood
--use NetquoteTechnologyOperations;
--exec sp_addlinkedserver ''BKUPEXCEL'',@srvproduct = '''', @provider = ''Microsoft.Jet.OLEDB.4.0'',
--@datasrc = '' @Datasource = C:\backupreports.xls'',
--@provstr = ''Excel 8.0;''
--
--
--Declare @excel_server varchar(20),@excel_dbname varchar(24),@dbmode varchar(10),
--     @excel_lastfull varchar(24), @excel_lastdiff varchar(24), @excel_lastlog varchar(24);
--Declare excel_cursor CURSOR READ_ONLY FOR
--	select distinct * from (
--select server_name, [db_name], dbmode, last_dbfull_copy, last_dbdiff_copy =
--case when dbmode = ''simple'' then ''Not applicable''
--     else last_dbdiff_copy
--     end,
--last_dblog_copy =
--case when dbmode = ''simple'' then ''Not applicable''
--     else last_dblog_copy
--     end
--from tempdb.dbo.BKUPWORK2
-- where ([db_name] not like ''NetQuoteTechnology%''
--    and [db_name] not like ''NetQuoteArchive%'')) sq
-- order by server_name,db_name;
--Open excel_cursor;
--Fetch next from excel_cursor into @excel_server,@excel_dbname,@dbmode,@excel_lastfull,
--      @excel_lastdiff, @excel_lastlog;
--While @@Fetch_Status = 0
--Begin

--Set @sqltxt2 = ''spexecute_adodb_sql @ddl=''''insert into backupreport''+@date+'' (server_name, db_name, 
--dbmode, last_dbfull_copy, last_dbdiff_copy, last_dblog_copy) values(''''''''''+@excel_server+'''''''''',
--''''''''''+@excel_dbname+'''''''''',''''''''''+@dbmode+'''''''''',''''''''''+@excel_lastfull+'''''''''',''''''''''+@excel_lastdiff+'''''''''',''''''''''
--+@excel_lastlog+'''''''''')'''', @Datasource = ''''C:\backupreports.xls'''''';
--print @sqltxt2;
--exec (@sqltxt2);
--Fetch next from excel_cursor into @excel_server,@excel_dbname,@dbmode,@excel_lastfull,
--      @excel_lastdiff, @excel_lastlog;
--End     
--
--deallocate excel_cursor;

Begin Try
exec sp_dropserver ''BKUP%'';
exec sp_linkedservers;
End Try
Begin Catch
Print ''Just keep going'';
End Catch
-------------------------------------

go
exec msdb.dbo.sp_send_dbmail 
	@recipients = ''gucuk@netquote.com'', --''gucuk@netquote.com;hesse@netquote.com'',
	@subject = ''Daily backup report'', 
	@query =  ''select distinct * from (
select server_name, [db_name], dbmode, last_dbfull_copy, last_dbdiff_copy =
case when dbmode = ''''simple'''' then ''''Not applicable''''
     else last_dbdiff_copy
     end,
last_dblog_copy =
case when dbmode = ''''simple'''' then ''''Not applicable''''
     else last_dblog_copy
     end
from tempdb.dbo.BKUPWORK2
 where ([db_name] not like ''''NetQuoteTechnology%''''
    and [db_name] not like ''''NetQuoteArchive%'''')) sq
 order by server_name,db_name;  '' 
 --  @attach_results = ''TRUE''
go
use tempdb;
IF OBJECT_ID (''dbo.BKUPWORK1'', ''U'') IS NOT NULL
    DROP TABLE dbo.BKUPWORK1;
IF OBJECT_ID (''dbo.BKUPWORK2'', ''U'') IS NOT NULL
    DROP TABLE dbo.BKUPWORK2;
IF OBJECT_ID (''dbo.BKUPWORK3'', ''U'') IS NOT NULL
    DROP TABLE dbo.BKUPWORK3;
IF OBJECT_ID (''dbo.BKUPWORK4'', ''U'') IS NOT NULL
    DROP TABLE dbo.BKUPWORK4;


', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Monday reporting', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=3, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20100602, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=235959, 
		@schedule_uid=N'8354cb11-364b-4895-9191-142a4c4e3d6a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


