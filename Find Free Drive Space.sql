SET NOCOUNT ON

DECLARE @hr int, @fso int, @drive char(1), @odrive int, @TotalSize varchar(20);

 

-- Create a temp table for our working data. Load free space info into it first for each drive

IF OBJECT_ID('tempdb..#drives') IS NOT NULL

   DROP TABLE #drives

CREATE TABLE #drives (drive char(1) PRIMARY KEY, FreeSpace int NULL,TotalSize int NULL)

INSERT #drives(drive,FreeSpace) EXEC master.dbo.xp_fixeddrives

 

-- Open up a connection to perfmon so we can get total space for a drive

EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT

IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

 

-- walk thru each drive and get the total space from perfmon

DECLARE dcur CURSOR LOCAL FAST_FORWARD FOR SELECT drive from #drives ORDER by drive

OPEN dcur FETCH NEXT FROM dcur INTO @drive

WHILE @@FETCH_STATUS=0

BEGIN

   EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @drive

   IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @TotalSize OUT

   IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive

   UPDATE #drives SET TotalSize=CONVERT(numeric,@TotalSize)/1024/1024 WHERE drive=@drive

   FETCH NEXT FROM dcur INTO @drive

END

-- cleanup after ourselves

CLOSE dcur

DEALLOCATE dcur

EXEC @hr=sp_OADestroy @fso IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso

 

-- return the results to the Ignite alert

-- For Ignite alerts, it expects this query to return the drive letter and then one more column

-- If you want to alert on Free MB, leave the drive and FreeSpace columns uncommented

-- If you want to alert on Free %, leave the drive and Free(%) columns uncommented - this is the default

SELECT drive,

   TotalSize as 'Total(MB)',

   FreeSpace as 'Free(MB)',

   100.0 * FreeSpace / TotalSize 'Free(%)'

   , CAST(100.0 * FreeSpace / TotalSize  AS DECIMAL (3,1)) AS 'NEWFree(%)'

FROM #drives

ORDER BY drive

DROP TABLE #drives