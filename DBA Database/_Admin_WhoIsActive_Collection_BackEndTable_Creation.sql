USE [DBA]
GO

/****** Object:  Table [dbo].[WhoIsActive]    Script Date: 12/20/2017 4:03:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[WhoIsActive]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[WhoIsActive](
	[RowId] [bigint] IDENTITY(1,1) NOT NULL,
	[dd hh:mm:ss.mss] [varchar](32) NULL,
	[session_id] [smallint] NOT NULL,
	[sql_text] [xml] NULL,
	[login_name] [nvarchar](128) NOT NULL,
	[wait_info] [nvarchar](4000) NULL,
	[tran_log_writes] [nvarchar](4000) NULL,
	[CPU] [varchar](30) NULL,
	[tempdb_allocations] [varchar](30) NULL,
	[tempdb_current] [varchar](30) NULL,
	[blocking_session_id] [smallint] NULL,
	[reads] [varchar](30) NULL,
	[writes] [varchar](30) NULL,
	[physical_reads] [varchar](30) NULL,
	[query_plan] [xml] NULL,
	[used_memory] [varchar](30) NULL,
	[status] [varchar](30) NOT NULL,
	[tran_start_time] [datetime] NULL,
	[open_tran_count] [varchar](30) NULL,
	[percent_complete] [varchar](30) NULL,
	[host_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[program_name] [nvarchar](128) NULL,
	[start_time] [datetime] NOT NULL,
	[login_time] [datetime] NULL,
	[request_id] [int] NULL,
	[collection_time] [datetime] NOT NULL,
 CONSTRAINT [PK_dbo_WhoIsActive_RowId] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO

SET ANSI_PADDING OFF
GO

/****** Object:  Index [idx_whoisactive_start_time]    Script Date: 12/20/2017 4:03:07 PM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[WhoIsActive]') AND name = N'idx_whoisactive_start_time')
CREATE NONCLUSTERED INDEX [idx_whoisactive_start_time] ON [dbo].[WhoIsActive]
(
	[start_time] ASC,
	[session_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
GO

/****** Object:  Index [NCIX_dbo_WhoIsActive_collection_time]    Script Date: 12/20/2017 4:03:07 PM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[WhoIsActive]') AND name = N'NCIX_dbo_WhoIsActive_collection_time')
CREATE NONCLUSTERED INDEX [NCIX_dbo_WhoIsActive_collection_time] ON [dbo].[WhoIsActive]
(
	[collection_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
GO


USE [DBA]
GO

/****** Object:  Table [dbo].[CpuUtilization]    Script Date: 12/20/2017 4:05:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CpuUtilization]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CpuUtilization](
	[SqlCpuUtilization] [int] NOT NULL,
	[SystemIdleProcess] [int] NOT NULL,
	[OtherProcessCpuUtilization] [int] NOT NULL,
	[EventTime] [datetime] NOT NULL,
 CONSTRAINT [PK_dbo_CpuUtilization_EventTime] PRIMARY KEY CLUSTERED 
(
	[EventTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
END
GO

