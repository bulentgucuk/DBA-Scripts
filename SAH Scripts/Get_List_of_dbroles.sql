USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Get_List_of_dbroles]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[Get_List_of_dbroles]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



Create procedure [dbo].[Get_List_of_dbroles]
as
declare @dbname varchar(200)
declare @mSql1	varchar(8000)

DECLARE DBName_Cursor CURSOR FOR 
 select name 
	from	master.dbo.sysdatabases 
	where name not in ('mssecurity','tempdb')
	Order by name

OPEN DBName_Cursor

FETCH NEXT FROM DBName_Cursor INTO @dbname

WHILE @@FETCH_STATUS = 0
 BEGIN
  Set @mSQL1 = '	Insert into DBROLES ( DBName, UserName, db_owner, db_accessadmin, 
                  db_securityadmin, db_ddladmin, db_datareader, db_datawriter,
	               db_denydatareader, db_denydatawriter )
	SELECT '+''''+@dbName +''''+ ' as DBName ,UserName, '+char(13)+	'	
    Max(CASE RoleName WHEN ''db_owner''  	 THEN ''Yes'' ELSE ''No'' END) AS db_owner,
	 Max(CASE RoleName WHEN ''db_accessadmin ''   THEN ''Yes'' ELSE ''No'' END) AS db_accessadmin ,
	 Max(CASE RoleName WHEN ''db_securityadmin''  THEN ''Yes'' ELSE ''No'' END) AS db_securityadmin,
	 Max(CASE RoleName WHEN ''db_ddladmin''  	 THEN ''Yes'' ELSE ''No'' END) AS db_ddladmin,
	 Max(CASE RoleName WHEN ''db_datareader''  	 THEN ''Yes'' ELSE ''No'' END) AS db_datareader,
	 Max(CASE RoleName WHEN ''db_datawriter''  	 THEN ''Yes'' ELSE ''No'' END) AS db_datawriter,
    Max(CASE RoleName WHEN ''db_denydatareader'' THEN ''Yes'' ELSE ''No'' END) AS db_denydatareader,
	 Max(CASE RoleName WHEN ''db_denydatawriter'' THEN ''Yes'' ELSE ''No'' END) AS db_denydatawriter
	from (
       select b.name as USERName, c.name as RoleName 
      	from ' + @dbName+'.dbo.sysmembers a '+char(13)+ 
			'	join '+ @dbName+'.dbo.sysusers  b '+char(13)+
       	'	on a.memberuid = b.uid 	join '+@dbName +'.dbo.sysusers c
	         on a.groupuid = c.uid )s 	
		   Group by USERName 
         order by UserName'

  --Print @mSql1
  Execute (@mSql1)

  FETCH NEXT FROM DBName_Cursor INTO @dbname
 END

CLOSE DBName_Cursor
DEALLOCATE DBName_Cursor


GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
