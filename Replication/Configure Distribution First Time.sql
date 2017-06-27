/****** Scripting replication configuration. Script Date: 12/21/2011 10:14:34 AM ******/
/****** Please Note: For security reasons, all password parameters were scripted with either NULL or an empty string. ******/

/****** Installing the server as a Distributor. Script Date: 12/21/2011 10:14:34 AM ******/
use master
exec sp_adddistributor 
	@distributor = N'SQLCLR07-P',
	@password = N'$$waz00!*' -- Is the password of the distributor_admin login
GO
exec sp_adddistributiondb 
	@database = N'distribution',
	@data_folder = N'I:\Data\Distribution',
	@data_file_size = 5120, 
	@log_folder = N'G:\Log\Distribution',
	@log_file_size = 2048,
	@min_distretention = 0,
	@max_distretention = 72,
	@history_retention = 48,
	@security_mode = 1
GO

use [distribution] 
if (not exists (select * from sysobjects where name = 'UIProperties' and type = 'U ')) 
	create table UIProperties(id int) 
if (exists (select * from ::fn_listextendedproperty('SnapshotFolder', 'user', 'dbo', 'table', 'UIProperties', null, null))) 
	BEGIN
		EXEC sp_updateextendedproperty 
			N'SnapshotFolder',
			N'\\SQLCLR07-P\SQLRepl',
			'user',
			dbo,
			'table',
			'UIProperties' 
	END
else
	BEGIN
		EXEC sp_addextendedproperty 
			N'SnapshotFolder', 
			N'\\SQLCLR07-P\SQLRepl',
			'user',
			dbo,
			'table',
			'UIProperties'
	END
GO

exec sp_adddistpublisher 
	@publisher = N'SQLCLR07-P',
	@distribution_db = N'distribution',
	@security_mode = 1,
	@working_directory = N'\\SQLCLR07-P\SQLRepl',
	@trusted = N'false',
	@thirdparty_flag = 0,
	@publisher_type = N'MSSQLSERVER'
GO

-- ADJUST DISTRIBUTION DB FILE GROWTH SIZE
USE [master]
GO
ALTER DATABASE [distribution] MODIFY FILE ( NAME = N'distribution', FILEGROWTH = 1048576KB )
GO
ALTER DATABASE [distribution] MODIFY FILE ( NAME = N'distribution_log', FILEGROWTH = 1048576KB )
GO