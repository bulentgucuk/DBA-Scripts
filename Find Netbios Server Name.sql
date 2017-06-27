SELECT
	  @@SERVERNAME AS ServerName
	, SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS 'ServerNetbiosName';
