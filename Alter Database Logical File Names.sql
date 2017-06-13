
--ALTER DATABASE database_name MODIFY FILE ( NAME = logical_file_name, NEWNAME = new_logical_name )

ALTER DATABASE SOCPlatform_BETA MODIFY FILE ( NAME = 'LYCEUM', NEWNAME = 'SOCPlatform_Primary')
GO
ALTER DATABASE SOCPlatform_BETA MODIFY FILE ( NAME = 'LYCEUM_LOG', NEWNAME = 'SOCPlatform_Log')
