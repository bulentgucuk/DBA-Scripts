DECLARE @physical_name varchar(260),
	@cmd nvarchar(500)
Declare TNAMES_CURSOR CURSOR FOR
		SELECT DISTINCT(b.physical_device_name)	
		FROM backupset a, backupmediafamily b 
		WHERE a.type= 'D' AND a.backup_start_date >= getdate() - 3 AND
			a.backup_start_date <= getdate() - 1 AND
			a.media_set_id = b.media_set_id AND
			b.physical_device_name LIKE '%Backup%'
			--and b.physical_device_name NOT LIKE '%example%'

OPEN TNAMES_CURSOR

FETCH NEXT FROM TNAMES_CURSOR
INTO @physical_name

WHILE (@@fetch_status <> -1)
BEGIN 
	IF (@@fetch_status <>-2)
	BEGIN
		SELECT @cmd = 'del /A: -A ' + @physical_name 
PRINT @CMD
	--EXEC master.dbo.xp_cmdshell @cmd
	END

	FETCH NEXT FROM tnames_cursor INTO @physical_name

END

DEALLOCATE tnames_cursor


	