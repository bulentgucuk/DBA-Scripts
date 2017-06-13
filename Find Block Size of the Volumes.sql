--Enable xp_cmdshell
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'xp_cmdshell', 1
RECONFIGURE
GO

CREATE TABLE #WMIC (
    ID INT IDENTITY PRIMARY KEY,
    CmdOutput VARCHAR(1000)
)

INSERT INTO #WMIC (CmdOutput)
EXECUTE master..xp_cmdshell 'WMIC.exe Volume get Label, BlockSize, Name /FORMAT:RAWXML'

DECLARE @Cmd VARCHAR(MAX) = ''
DECLARE @Xml XML

SELECT @Cmd = @Cmd + COALESCE(w.CmdOutput, '') 
FROM #WMIC w
ORDER BY w.ID

SET @Xml = CAST(@Cmd AS XML)

SELECT
    Label = Process.value('(PROPERTY[@NAME="Label"]/VALUE)[1]', 'VARCHAR(100)'),
    BlockSize = Process.value('(PROPERTY[@NAME="BlockSize"]/VALUE)[1]', 'INT'),
    Name = Process.value('(PROPERTY[@NAME="Name"]/VALUE)[1]', 'VARCHAR(100)')
FROM @Xml.nodes('/COMMAND/RESULTS/CIM/INSTANCE') AS WmiTbl(Process)
--Exclude the "system reserved" volume/disk.
WHERE 
    COALESCE(Process.value('(PROPERTY[@NAME="Label"]/VALUE)[1]', 'VARCHAR(100)'), '') <> 
    'System Reserved'
--My database files are not on C:\ -- exclude this volume/disk.
--AND Process.value('(PROPERTY[@NAME="Name"]/VALUE)[1]', 'VARCHAR(100)') <> 'C:\'
--Volumes with NULL block size?  Are these DVD/CD rom drives?  Exclude these.
AND Process.value('(PROPERTY[@NAME="BlockSize"]/VALUE)[1]', 'INT') IS NOT NULL

DROP TABLE #WMIC

--Disable xp_cmdshell
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'xp_cmdshell', 0
RECONFIGURE
GO