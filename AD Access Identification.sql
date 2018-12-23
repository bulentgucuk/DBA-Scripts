------------------------------------------------------------
-- The SQLBlimp AD Access Identification Script
-- By John F. Tamburo 2016-01-06
-- Feel free to use this - Freely given to the SQL community
------------------------------------------------------------
set nocount on;
declare @ctr nvarchar(max) = '', @AcctName sysname = ''

-- Create a table to store xp_logininfo commands
-- We have to individually execute them in case the login no longer exists

create table #ExecuteQueue(AcctName sysname,CommandToRun nvarchar(max));

-- Create a command list for windows-based SQL Logins
insert into #ExecuteQueue(AcctName,CommandToRun)
SELECT 
	[name]
	,CONVERT(NVARCHAR(max),'INSERT INTO #LoginsList EXEC xp_logininfo ''' + [name] + ''', ''all''; --insert group information' + CHAR(13) + CHAR(10)
		+ CASE 
			WHEN [TYPE] = 'G' THEN ' INSERT INTO #LoginsList EXEC xp_logininfo  ''' + [name] + ''', ''members''; --insert member information'  + CHAR(13) + CHAR(10)
            else '-- ' + rtrim([name]) + ' IS NOT A GROUP BABY!' + CHAR(13) + CHAR(10)
        END) as CMD_TO_RUN
FROM sys.server_principals 
WHERE 1=1
and TYPE IN ('U','G')    -- *Windows* Users and Groups.
and name not like '%##%' -- Eliminate Microsoft 
and name not like 'NT SERVICE\%' -- xp_logininfo does not work with NT SERVICE accounts
ORDER BY name, type_desc;

-- Create the table that the commands above will fill.
create table #LoginsList(
       [Account Name] nvarchar(128),
       [Type] nvarchar(128),
       [Privilege] nvarchar(128),
       [Mapped Login Name] nvarchar(128),
       [Permission Path] nvarchar(128) );

-- Jeff Moden: Please forgive me for the RBAR! (:-D)
declare cur cursor for select AcctName, CommandToRun from #ExecuteQueue

open cur
fetch next from cur into @AcctName,@ctr
while @@FETCH_STATUS = 0
begin
	BEGIN TRY
		print @ctr
		EXEC sp_executesql @ctr
	END TRY
	BEGIN CATCH
	    print ERROR_MESSAGE() + CHAR(13) + CHAR(10);
		IF ERROR_MESSAGE() like '%0x534%' -- Windows SQL Login no longer in AD
		BEGIN
			print '0x534 Logic'
			insert into #LoginsList([Account Name],[Type],[Privilege],[Mapped Login Name],[Permission Path])
			select @AcctName AccountName,'DELETED Windows User','user',@AcctName MappedLogin,@AcctName PermissionPath	
		END
		ELSE
			print ERROR_MESSAGE();
	END CATCH
	fetch next from cur into @AcctName,@ctr
	Print '-------------------------------'
END;

-- Clean up cursor 
close cur;
deallocate cur;

-- Add SQL Logins to the result
insert into #LoginsList([Account Name],[Type],[Privilege],[Mapped Login Name],[Permission Path])
select [name] AccountName,'user','user',[name] MappedLogin,[name] PermissionPath
FROM sys.server_principals 
WHERE 1=1
and (TYPE = 'S'		     -- SQL Server Logins only
and name not like '%##%') -- Eliminate Microsoft 
or (TYPE in('U','G') and [name] like 'NT SERVICE\%') -- capture NT Service information
ORDER BY [name];

-- Get Server Roles into the mix
-- Add column to table
alter table #LoginsList add Server_Roles nvarchar(max);

-- Fill column with server roles
update LL 
set 
	Server_Roles = ISNULL(STUFF((SELECT ', ' + CONVERT(VARCHAR(500),role.name)
					FROM sys.server_role_members
					JOIN sys.server_principals AS role
						ON sys.server_role_members.role_principal_id = role.principal_id
					JOIN sys.server_principals AS member
						ON sys.server_role_members.member_principal_id = member.principal_id
					WHERE member.name= (case when [Permission Path] is not null then [Permission Path] else [Account Name] end)
							FOR XML PATH('')),1,1,''),'public')
from #LoginsList LL;

-- Create a table to hold the users of each database.
create table #DB_Users(
	DBName sysname
	, UserName sysname
	, LoginType sysname
	, AssociatedRole varchar(max)
	,create_date datetime
	,modify_date datetime
)

-- Iterate the each database for its users and store them in the table.
INSERT #DB_Users
EXEC sp_MSforeachdb
'
use [?]
SELECT ''?'' AS DB_Name,
ISNULL(case prin.name when ''dbo'' then prin.name + '' (''+ (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end,'''') AS UserName,
prin.type_desc AS LoginType,
isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole ,create_date,modify_date
FROM sys.database_principals prin
LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
WHERE prin.sid IS NOT NULL 
and prin.sid NOT IN (0x00) 
and prin.is_fixed_role <> 1 
AND prin.name is not null
AND prin.name NOT LIKE ''##%'''

-- Refine the user permissions into a concatenated field by DB and user
SELECT
	dbname
	,username 
	,logintype 
	,create_date 
	,modify_date 
	,STUFF((SELECT ', ' + CONVERT(VARCHAR(500),associatedrole)
		FROM #DB_Users user2
		WHERE user1.DBName=user2.DBName 
		AND user1.UserName=user2.UserName
		FOR XML PATH('')),1,1,'') AS Permissions_user
into #UserPermissions
FROM #DB_Users user1
where logintype != 'DATABASE_ROLE'
GROUP BY
	dbname
	,username 
	,logintype 
	,create_date 
	,modify_date
ORDER BY DBName,username

-- Report out the results
Select 
	DISTINCT
	LL.[Account Name]
	,@@SERVERNAME as [Database Server]
	,UP.dbname as [Database Name]
	,LoginType
	--,LL.Privilege
	,LL.Server_Roles
	,LL.[Permission Path]
	,UP.Permissions_user as [User Privileges]
from #LoginsList LL
left join #UserPermissions UP
	on LL.[Permission Path] = UP.UserName
-- Comment out the where clause to see all logins that have no database users
-- and their server roles.
-- where exists(select 1 from #LoginsList U2 where U2.[Account Name] = UP.[UserName])
order by
	LL.[Account Name]
	,UP.DBName;

-- Clean up my mess
drop table #ExecuteQueue;
drop table #LoginsList;
drop table #DB_Users;
drop table #UserPermissions;
