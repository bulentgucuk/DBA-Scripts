-- Clean up Replication


-- Disable the publication database.
USE TransactionalQA
EXEC sp_removedbreplication 'TransactionalQA';

-- Remove the registration of the local Publisher at the Distributor.
USE master
EXEC sp_dropdistpublisher @publisher;

-- Delete the distribution database.
EXEC sp_dropdistributiondb @distributionDB;

-- Remove the local server as a Distributor.
EXEC sp_dropdistributor  @no_checks = 1,@ignore_distributor  =1;
GO