USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_TransLogMonitorReport]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[sp_TransLogMonitorReport]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[sp_TransLogMonitorReport]
	@tableHTML NVARCHAR(MAX) OUTPUT
AS
BEGIN

	DECLARE @Table NVARCHAR(MAX) = N''
	DECLARE @Yesterday DATE = CONVERT(DATE, GETDATE()-1);
	DECLARE @Today DATE = CONVERT(DATE, GETDATE());

	SELECT @Table = @Table +'<tr style="background-color:' + CASE WHEN (T.VLF_count - Y.VLF_count) > 0 THEN 'yellow' ELSE 'white' END +';font-size: 10px;">' +
	'<td>' + COALESCE(Y.DatabaseName,T.DatabaseName) + '</td>' +
	'<td>' + CAST(T.LogSizeMB AS VARCHAR(50)) + '</td>' +
	'<td>' + CAST(Y.LogSizeMB AS VARCHAR(50)) + '</td>' +
	'<td>' + CAST((T.LogSizeMB - Y.LogSizeMB)AS VARCHAR(50)) + '</td>' +
	'<td>' + CAST(T.LogSpaceUsed AS VARCHAR(50)) + '</td>' +
	'<td>' + CAST(Y.LogSpaceUsed AS VARCHAR(50)) + '</td>' +
	'<td>' + CAST((T.LogSpaceUsed - Y.LogSpaceUsed)AS VARCHAR(50)) + '</td>' +
	'<td>' + CAST((T.VLF_count)AS VARCHAR(50)) + '</td>' +
	'<td>' + CAST((Y.VLF_count)AS VARCHAR(50)) + '</td>' +
	'<td>' + CAST((T.VLF_count - Y.VLF_count)AS VARCHAR(50)) + '</td>' +
	'</tr>'
	FROM dbo.TransLogMonitor Y
	FULL OUTER JOIN dbo.TransLogMonitor T ON T.DatabaseName = Y.DatabaseName
	WHERE CONVERT(DATE, Y.LogDate) = @Yesterday AND CONVERT(DATE, T.LogDate) = @Today
	ORDER BY T.LogSizeMB DESC
	
	SET @tableHTML = 
	N'<table border="1" align="left" cellpadding="2" cellspacing="0" style="color:black;font-family:arial,helvetica,sans-serif;" >' +--text-align:center;" >' +
	N'<tr style ="font-size: 10px;font-weight: normal;background: white;">
	<th>DatabaseName</th>
	<th>TodaySizeMB</th>
	<th>YestSizeMB</th>
	<th>SizeDiff</th>
	<th>TodaySpaceUsed</th>
	<th>YestSpaceUsed</th>
	<th>UsedDiff</th>
	<th>TodayVLFs</th>
	<th>YestVLFs</th>
	<th>VLFDiff</th></tr>' + @Table +	N'</table>' 
END


GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
