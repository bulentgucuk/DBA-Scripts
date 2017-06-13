USE [DBAdmin]
GO

/****** Object:  Table [dbo].[CheckIdentity]    Script Date: 3/28/2016 10:24:52 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CheckIdentity]') AND type IN (N'U'))
BEGIN
CREATE TABLE [dbo].[CheckIdentity](
	[CheckIdentityID] [INT] IDENTITY(1,1) NOT NULL,
	[ServerName] [VARCHAR](64) NOT NULL,
	[DatabaseName] [VARCHAR](64) NOT NULL,
	[TableName] [VARCHAR](128) NOT NULL,
	[ColumnName] [VARCHAR](128) NOT NULL,
	[DataType] [VARCHAR](10) NOT NULL,
	[CurrentIdentityValue] [BIGINT] NOT NULL,
	[PercentageUsed] [DECIMAL](5, 2) NOT NULL,
	[CreatedDate] [DATETIME] NOT NULL CONSTRAINT [DF_CheckIdentity_CreatedDate]  DEFAULT (GETDATE()),
	[CreatedBy] [VARCHAR](64) NOT NULL CONSTRAINT [DF_CheckIdentity_CreatedBy]  DEFAULT (SUSER_NAME()),
 CONSTRAINT [PK_CheckIdentity_CheckIdentityID] PRIMARY KEY CLUSTERED 
(
	[CheckIdentityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO

SET ANSI_PADDING OFF
GO


