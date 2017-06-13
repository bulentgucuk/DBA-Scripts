SET NOCOUNT ON
DECLARE @ver NVARCHAR(128)
DECLARE @majorVersion NVARCHAR(4)
SET @ver = CAST(SERVERPROPERTY('productversion') AS NVARCHAR)
SET @ver = SUBSTRING(@ver,1,CHARINDEX('.',@ver)+1)
SET @majorVersion  = CAST(@ver AS nvarchar)
SELECT SERVERPROPERTY('ServerName') AS [ServerName]
,SERVERPROPERTY('InstanceName') AS [Instance]
,SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [ComputerNamePhysicalNetBIOS]
,SERVERPROPERTY('ProductVersion') AS [ProductVersion]
,    CASE @MajorVersion
		WHEN '8.0' THEN 'SQL Server 2000'
		WHEN '9.0' THEN 'SQL Server 2005'
		WHEN '10.0' THEN 'SQL Server 2008'
		WHEN '10.5' THEN 'SQL Server 2008 R2'
		WHEN '11.0' THEN 'SQL Server 2012'
		WHEN '12.0' THEN 'SQL Server 2014'
		WHEN '13.0' THEN 'SQL Server 2016'
		END AS 'SQL'
,SERVERPROPERTY('ProductLevel') AS [ProductLevel]
,SERVERPROPERTY('Edition') AS [Edition]
,SERVERPROPERTY ('BuildClrVersion') AS NET
,    CASE SERVERPROPERTY('IsClustered')        
		WHEN 0 THEN 'NO'
		WHEN 1 THEN 'YES'
		END    AS [IsClustered]
,CASE 
	WHEN CHARINDEX('Hypervisor',@@VERSION)>0    OR CHARINDEX('VM',@@VERSION)>0 THEN 'VM'
	ELSE 'PHYSICAL'
	END AS [VM_PHYSICAL]
, CASE SERVERPROPERTY('IsIntegratedSecurityOnly')
	WHEN 1 THEN 'WINDOWS AUTHENTICATION ONLY'
	WHEN 0 THEN 'SQL & WINDOWS AUTHENTICATION'
	END AS 'SECURITY MODE'
