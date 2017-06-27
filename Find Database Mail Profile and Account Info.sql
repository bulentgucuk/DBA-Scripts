USE msdb;
GO
SELECT	p.profile_id, a.account_id, a.email_address, a. display_name,s.servertype, s.servername, s.port, s.username, s.credential_id
		, a.name, p.[description] as 'ProfileDesc' ,a.[description] as 'AccountDesc'
FROM	dbo.sysmail_profileaccount as pa
	INNER JOIN dbo.sysmail_account as a on pa.account_id = a.account_id
	INNER JOIN dbo.sysmail_profile as p on p.profile_id = pa.profile_id
	INNER JOIN dbo.sysmail_server as s on s.account_id = a.account_id