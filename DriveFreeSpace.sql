SET NOCOUNT ON 
DECLARE @hr int 
DECLARE @fso int 
DECLARE @size float 
DECLARE @mbtotal int 
DECLARE @drive char(1) 
DECLARE @fso_Method varchar(255) 
SET @mbTotal = 0 

CREATE TABLE Tempdb.dbo.Drvspace (drive char(1), mbfree int, mbtotalSpace int) 
INSERT INTO Tempdb.dbo.Drvspace (drive, mbfree) EXEC master.dbo.xp_fixeddrives 

EXEC @hr = master.dbo.sp_OACreate 'Scripting.FilesystemObject', @fso OUTPUT 

DECLARE cDrives CURSOR FAST_FORWARD FOR SELECT drive FROM Tempdb.dbo.Drvspace 
OPEN cDrives 
FETCH NEXT FROM cDrives INTO @drive 

WHILE @@FETCH_STATUS = 0 
BEGIN 
SET @fso_Method = 'Drives("' + @drive + ':").TotalSize' 
EXEC @hr = sp_OAMethod @fso, @fso_method, @size OUTPUT 

update Tempdb.dbo.Drvspace set mbtotalSpace = @size/(1024*1024)
where drive = @drive
FETCH NEXT FROM cDrives INTO @drive 
END 
CLOSE cDrives 
DEALLOCATE cDrives 
EXEC @hr = sp_OADestroy @fso 



select * from Tempdb.dbo.Drvspace
drop table Tempdb.dbo.Drvspace