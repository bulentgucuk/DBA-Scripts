select suser_name()
exec [dbo].[sp_PMS_SelectTSAReport]
	@StartDate = '06/01/2008',
	@EndDate = '06/02/2008',
	@OutPutFile = '\\netquote\shared\BatchDeliveries\TSA\Production\tsa-netquote-BG-TEST.csv',
	@Separator = ','

-- old folder
-- \\netquote\shared\TSA-Production$
-- new folder
-- \\netquote\shared\BatchDeliveries\TSA\Production

DECLARE
@StartDate DateTime,
@EndDate   DateTime,
@OutPutFile Varchar(400),
@Separator  Varchar(1)

DECLARE @DBName varchar(100)
DECLARE @CMD VarChar(4000)

DECLARE @Error_List TABLE 
(
	Error varchar (255)
)

SELECT @DBName = db_name()

SET	@StartDate = '04/06/2008'
SET	@EndDate = '04/07/2008'
SET @OutPutFile = '\\netquote\shared\TSA-Production$\tsa-netquote-BG-TEST.csv'
SET	@Separator = ','


SET @CMD =  'bcp "' + @DBName  + '.dbo.TMP_TsaReport" out "' +  @OutPutFile +  '"  -t"\' + @Separator + '" -c -S' +  @@ServerName + ' -T'--U Netquote0\tsaaccount -P pNUn82Er'


PRINT @CMD

INSERT @Error_List (Error)
SELECT * FROM @Error_List

Exec master.dbo.xp_cmdshell @CMD

--SSC example
C:\>bcp.exe "exec [AdventureWorks].[dbo].[uspGetEmployeeManagers]  @EmployeeID = 153" queryout "c:\EmployeeManagers.txt"
-SCFEDERL -T -c