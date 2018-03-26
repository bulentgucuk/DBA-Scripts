USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AuditLog]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[AuditLog](
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

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_AuditLog_CreateDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[AuditLog] ADD  CONSTRAINT [DF_AuditLog_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
END
GO
