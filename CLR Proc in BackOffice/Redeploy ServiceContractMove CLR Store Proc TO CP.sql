
-- DISABLE THE JOB NAMED CP_Move_ServiceContracts CLR PROC AND WAIT IF IT'S RUNNING TO COMPLETE

-- 1. Drop CLR stored proc
-- 2. Drop Assembly
-- 3. Backup and Delete old DLL file
-- 4. Copy the new DLL to the location on hard drive
-- 5. Create Assembly
-- 6. Create Stored Procedure


-- 1
USE [BackOfficeCurrentProduction]
GO
DROP PROCEDURE dbo.ServiceContractMove

-- 2
USE [BackOfficeCurrentProduction]
GO
DROP ASSEMBLY [ServiceContractsMovement]

-- 3
-- BACKUP OR DELETE OLD DLL

-- 4
-- COPY THE NEW DLL

-- 5
USE [BackOfficeCurrentProduction]
GO
ALTER AUTHORIZATION ON DATABASE::BackOfficeCurrentProduction TO SA;
GO

ALTER DATABASE BackOfficeCurrentProduction SET TRUSTWORTHY ON; 
GO
CREATE ASSEMBLY [ServiceContractsMovement]
    AUTHORIZATION [dbo]
    FROM 'F:\ServiceContracts\CurrentProduction\ServiceContractsMovement.dll'
    WITH PERMISSION_SET = UNSAFE;

GO
USE [BackOfficeCurrentProduction]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ServiceContractMove
	@minuteDelay INT
AS	
EXTERNAL NAME [ServiceContractsMovement].[ServiceContractsMovement.StoredProcedures].[ServiceContractMove]

GO