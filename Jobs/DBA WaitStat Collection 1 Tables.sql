USE [DBA]
GO

/****** Object:  Index [NCIX_DatabaseFileLatency]    Script Date: 7/8/2016 11:47:41 PM ******/
DROP INDEX [NCIX_DatabaseFileLatency] ON [dbo].[DatabaseFileLatency]
GO

/****** Object:  Index [CIX_DatabaseFileLatency]    Script Date: 7/8/2016 11:47:41 PM ******/
DROP INDEX [CIX_DatabaseFileLatency] ON [dbo].[DatabaseFileLatency] WITH ( ONLINE = OFF )
GO

/****** Object:  Table [dbo].[DatabaseFileLatency]    Script Date: 7/8/2016 11:47:41 PM ******/
DROP TABLE [dbo].[DatabaseFileLatency]
GO

/****** Object:  Table [dbo].[DatabaseFileLatency]    Script Date: 7/8/2016 11:47:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DatabaseFileLatency](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[CaptureID] [int] NOT NULL,
	[CaptureDate] [datetime2](7) NULL,
	[ReadLatency] [bigint] NULL,
	[WriteLatency] [bigint] NULL,
	[Latency] [bigint] NULL,
	[AvgBPerRead] [bigint] NULL,
	[AvgBPerWrite] [bigint] NULL,
	[AvgBPerTransfer] [bigint] NULL,
	[Drive] [nvarchar](2) NULL,
	[DB] [nvarchar](128) NULL,
	[database_id] [smallint] NOT NULL,
	[file_id] [smallint] NOT NULL,
	[sample_ms] [int] NOT NULL,
	[num_of_reads] [bigint] NOT NULL,
	[num_of_bytes_read] [bigint] NOT NULL,
	[io_stall_read_ms] [bigint] NOT NULL,
	[num_of_writes] [bigint] NOT NULL,
	[num_of_bytes_written] [bigint] NOT NULL,
	[io_stall_write_ms] [bigint] NOT NULL,
	[io_stall] [bigint] NOT NULL,
	[size_on_disk_MB] [numeric](25, 6) NULL,
	[file_handle] [varbinary](8) NOT NULL,
	[physical_name] [nvarchar](260) NOT NULL,
 CONSTRAINT [PK_dbo_DatabaseFileLatency_RowID] PRIMARY KEY NONCLUSTERED 
(
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]
WITH
(
DATA_COMPRESSION = PAGE
)

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Index [CIX_DatabaseFileLatency]    Script Date: 7/8/2016 11:47:41 PM ******/
CREATE CLUSTERED INDEX [CIX_DatabaseFileLatency] ON [dbo].[DatabaseFileLatency]
(
	[CaptureDate] ASC,
	[RowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, DATA_COMPRESSION = PAGE) ON [PRIMARY]
GO

/****** Object:  Index [NCIX_DatabaseFileLatency]    Script Date: 7/8/2016 11:47:41 PM ******/
CREATE NONCLUSTERED INDEX [NCIX_DatabaseFileLatency] ON [dbo].[DatabaseFileLatency]
(
	[CaptureID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON [PRIMARY]
GO


USE [DBA]
GO

/****** Object:  Table [dbo].[WaitingTasks]    Script Date: 7/8/2016 11:48:18 PM ******/
DROP TABLE [dbo].[WaitingTasks]
GO

/****** Object:  Table [dbo].[WaitingTasks]    Script Date: 7/8/2016 11:48:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WaitingTasks](
	[WaitingTaskID] [bigint] IDENTITY(1,1) NOT NULL,
	[session_id] [smallint] NULL,
	[exec_context_id] [int] NULL,
	[wait_duration_ms] [bigint] NULL,
	[wait_type] [nvarchar](60) NULL,
	[blocking_session_id] [smallint] NULL,
	[blocking_exec_context_id] [int] NULL,
	[resource_description] [nvarchar](3072) NULL,
	[program_name] [nvarchar](128) NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[text] [nvarchar](max) NULL,
	[query_plan] [xml] NULL,
	[cpu_time] [int] NOT NULL,
	[memory_usage] [int] NOT NULL,
	[CreatedDate] [smalldatetime] NULL CONSTRAINT [DF_dbo_WaitingTasks_CreatedDate]  DEFAULT (getdate()),
 CONSTRAINT [PK_dbo_WaitingTasks_WaitingTaskID] PRIMARY KEY CLUSTERED 
(
	[WaitingTaskID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

USE [DBA]
GO

/****** Object:  Table [dbo].[Waits]    Script Date: 7/8/2016 11:48:33 PM ******/
DROP TABLE [dbo].[Waits]
GO

/****** Object:  Table [dbo].[Waits]    Script Date: 7/8/2016 11:48:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Waits](
	[WaitID] [bigint] IDENTITY(1,1) NOT NULL,
	[WaitType] [nvarchar](60) NOT NULL,
	[Wait_S] [decimal](14, 2) NULL,
	[Resource_S] [decimal](14, 2) NULL,
	[Signal_S] [decimal](14, 2) NULL,
	[WaitCount] [bigint] NOT NULL,
	[Percentage] [decimal](4, 2) NULL,
	[AvgWait_S] [decimal](14, 4) NULL,
	[AvgRes_S] [decimal](14, 4) NULL,
	[AvgSig_S] [decimal](14, 4) NULL,
	[CreatedDate] [smalldatetime] NOT NULL CONSTRAINT [DF_dbo_Waits_CreatedDate]  DEFAULT (getdate()),
 CONSTRAINT [PK_dbo_Waits_WaitID] PRIMARY KEY CLUSTERED 
(
	[WaitID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, DATA_COMPRESSION = PAGE) ON [PRIMARY]
) ON [PRIMARY]

GO

USE [DBA]
GO

/****** Object:  Index [NCIX_dbo_WhoIsActive_collection_time]    Script Date: 7/8/2016 11:48:46 PM ******/
DROP INDEX [NCIX_dbo_WhoIsActive_collection_time] ON [dbo].[WhoIsActive]
GO

/****** Object:  Table [dbo].[WhoIsActive]    Script Date: 7/8/2016 11:48:46 PM ******/
DROP TABLE [dbo].[WhoIsActive]
GO

/****** Object:  Table [dbo].[WhoIsActive]    Script Date: 7/8/2016 11:48:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, DATA_COMPRESSION = ROW) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Index [NCIX_dbo_WhoIsActive_collection_time]    Script Date: 7/8/2016 11:48:46 PM ******/
CREATE NONCLUSTERED INDEX [NCIX_dbo_WhoIsActive_collection_time] ON [dbo].[WhoIsActive]
(
	[collection_time] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, DATA_COMPRESSION = ROW) ON [PRIMARY]
GO

