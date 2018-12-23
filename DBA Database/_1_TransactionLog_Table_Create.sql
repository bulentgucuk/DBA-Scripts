USE [DBA]
GO

/****** Object:  Table [dbo].[TransLogMonitor]    Script Date: 12/19/2018 6:09:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TransLogMonitor]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[TransLogMonitor](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[LogDate] [datetime] NOT NULL,
	[DatabaseName] [varchar](100) NOT NULL,
	[LogSizeMB] [decimal](18, 2) NOT NULL,
	[LogSpaceUsed] [decimal](18, 2) NOT NULL,
	[Status] [int] NOT NULL,
	[VLF_count] [int] NULL,
 CONSTRAINT [PK_TransLogMonitor_LogID] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_TransLogMonitor_LogDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[TransLogMonitor] ADD  CONSTRAINT [DF_TransLogMonitor_LogDate]  DEFAULT (getdate()) FOR [LogDate]
END
GO