	

*** Backup and Restore Replicated db and try to drop it if not run the following statement.
USE MASTER EXEC dbo.sp_removedbreplication @dbname = 'MyDatabase'