USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[AuditLog]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[AuditLog]
	(
		[AuditLogID] [int] IDENTITY(1,1) NOT NULL,
		[CreateDate] [datetime] NULL,
		[LoginName] [sysname] NULL,
		[ComputerName] [sysname] NULL,
		[ProgramName] [varchar](255) NULL,
		[DBName] [sysname] NOT NULL,
		[SQLEvent] [sysname] NOT NULL,
		[SchemaName] [sysname] NULL,
		[ObjectName] [sysname] NULL,
		[SQLCmd] [nvarchar](max) NULL,
		[XmlEvent] [xml] NOT NULL,
		CONSTRAINT [PK_AuditLog_AuditLogID] PRIMARY KEY CLUSTERED 
(
	[AuditLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, DATA_COMPRESSION = PAGE) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO

IF NOT EXISTS (SELECT *
FROM sys.objects
WHERE object_id = OBJECT_ID(N'[dbo].[DF_AuditLog_CreateDate]') AND type = 'D')
BEGIN
	ALTER TABLE [dbo].[AuditLog] ADD  CONSTRAINT [DF_AuditLog_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
END
GO

IF NOT EXISTS (SELECT *
FROM sys.indexes
WHERE object_id = OBJECT_ID(N'[dbo].[AuditLog]') AND name = N'NCIX_AuditLog_CreateDate')
BEGIN
	CREATE NONCLUSTERED INDEX NCIX_AuditLog_CreateDate
		ON [dbo].[AuditLog]
		([CreateDate])
	WITH (DATA_COMPRESSION = PAGE)
END

--Create database role and grant insert permission to dbo.AuditLog
IF DATABASE_PRINCIPAL_ID('db_Database_DDL_Audit') IS NULL
BEGIN
	CREATE ROLE [db_Database_DDL_Audit];
END
GO
GRANT INSERT ON [dbo].[AuditLog] TO [db_Database_DDL_Audit];
GO

--Add role members

ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [SSBINFO\saag];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [SSBINFO\SSB Dev];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [SSBINFO\SSB IE];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [SSBINFO\SSB MDM];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [SSBINFO\SSB QA Security];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [SSBINFO\SSB Reporting];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [SSBINFO\SSBCRMSec];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [SSBINFO\SSBETLSec];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [svcDevOps];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [svcLogi];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [svcQA];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [svcsegmentation];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [svc_sc_segmentation];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [svcETL];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [svcReport];
ALTER ROLE [db_Database_DDL_Audit] ADD MEMBER [svcssbrp];

