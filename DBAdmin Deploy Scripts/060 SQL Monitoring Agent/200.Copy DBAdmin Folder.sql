DECLARE @OSCmd          VARCHAR(512)
DECLARE @InstallPath    VARCHAR(512)

SELECT @InstallPath = ParmValue
    FROM DBAdmin.dbo.DBAdmin_InstallParms
    WHERE ParmName = 'InstallPath'
    
SELECT @OSCmd = 'MD C:\DBAdmin'

EXECUTE master.dbo.xp_cmdshell @OSCmd
    
SELECT @OSCmd = 'COPY /Y "' + @InstallPath + '\060 SQL Monitoring Agent\DBAdmin\*.*" "C:\DBAdmin\"'

EXECUTE master.dbo.xp_cmdshell @OSCmd
 
 