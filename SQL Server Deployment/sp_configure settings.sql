EXEC sp_configure 'show advanced options',1
GO
RECONFIGURE
GO
EXEC sp_configure 'max server memory (MB)',179200 -- 175GB x 1024
GO
RECONFIGURE
GO
EXEC sp_configure 'min server memory (MB)',174080 -- 170GB x 1024
GO
RECONFIGURE
GO
EXEC sp_configure 'backup checksum default',1
GO
RECONFIGURE
GO
EXEC sp_configure 'backup compression default',1
GO
RECONFIGURE
GO
EXEC sp_configure 'optimize for ad hoc workloads',1
GO
RECONFIGURE
GO
EXEC sp_configure 'remote admin connections',1
GO
RECONFIGURE
GO
EXEC sp_configure 'remote admin connections',1
GO
RECONFIGURE
GO
EXEC sp_configure 'xp_cmdshell',1
GO
RECONFIGURE
GO
