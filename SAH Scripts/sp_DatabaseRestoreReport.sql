USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[sp_DatabaseRestoreReport]    Script Date: 8/1/2018 3:54:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROC [dbo].[sp_DatabaseRestoreReport]
	@tableHTML NVARCHAR(MAX) OUTPUT
AS
BEGIN

	DECLARE @Table NVARCHAR(MAX) = N'';
	DECLARE @Yesterday DATE = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()));
	

	SELECT @Table = @Table +'<tr style="background-color:white;font-size: 10px;">' +
		'<td>' + CAST([rs].[destination_database_name] AS VARCHAR(128)) + '</td>' +
		'<td>' + CAST([rs].[restore_date] AS VARCHAR(20)) + '</td>' +
		'<td>' + CAST([bs].[backup_start_date] AS VARCHAR(20)) + '</td>' +
		'<td>' + CAST([bs].[backup_finish_date] AS VARCHAR(20)) + '</td>' +
		'<td>' + CAST([bs].[database_name] AS VARCHAR(128)) + '</td>' +
		'<td>' + CAST([bmf].[physical_device_name] AS VARCHAR(256)) + '</td>' +
		'</tr>'
	FROM	msdb.dbo.restorehistory AS rs
		INNER JOIN msdb.dbo.backupset AS bs ON [rs].[backup_set_id] = [bs].[backup_set_id]
		INNER JOIN msdb.dbo.backupmediafamily AS bmf ON [bs].[media_set_id] = [bmf].[media_set_id] 
	WHERE	RS.restore_date > @Yesterday
	ORDER BY [rs].[restore_date] DESC;
	
	SET @tableHTML = 
	N'<table border="1" align="left" cellpadding="2" cellspacing="0" style="color:black;font-family:arial,helvetica,sans-serif;" >' +--text-align:center;" >' +
	N'<tr style ="font-size: 10px;font-weight: normal;background: white;">
	<th>RestoredDatabaseName</th>
	<th>RestoreDate</th>
	<th>BackupStartDate</th>
	<th>BackupFinishDate</th>
	<th>SourceDatabaseName</th>
	<th>BackupFileUsedForRestore</th></tr>' + @Table +	N'</table>';
	
END

GO
