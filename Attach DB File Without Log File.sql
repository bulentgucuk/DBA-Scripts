USE master;
GO
-- Detach the db
exec sp_detach_db ODSQA;

-- Delete the log file
EXEC master.dbo.xp_cmdshell 'del  D:\ODS_QA.LDF', NO_OUTPUT;

-- Attach the database with new log
CREATE DATABASE ODSQA
	ON (NAME = 'ODS_QA',
		FILENAME = 'H:\ODS_QA.MDF')
	FOR ATTACH_REBUILD_LOG;






