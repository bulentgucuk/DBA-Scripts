-- create the new table
USE [NetQuoteTest]
GO
/****** Object:  Table [dbo].[VisitorSessionsPub]    Script Date: 08/14/2008 12:10:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VisitorSessionsPubNew](
	[VisitorSessionID] [char](24) NOT NULL,
	[StartDate] [datetime] NOT NULL CONSTRAINT [DF_VisitorSessionsPubNew_StartDate]  DEFAULT (getdate()),
	[EndDate] [datetime] NOT NULL CONSTRAINT [DF_VisitorSessionsPubNew_EndDate]  DEFAULT (getdate()),
	[PartnerID] [int] NOT NULL,
	[PartnerCode] [varchar](100) NOT NULL CONSTRAINT [DF_VisitorSessionsPubNew_PartnerCode]  DEFAULT ('[Default]'),
	[PartnerParameters] [varchar](512) NULL,
	[UserAgent] [varchar](255) NOT NULL,
	[RemoteIPAddress] [varchar](15) NOT NULL,
	[BrandID] [int] NULL,
 CONSTRAINT [PK_VisitorSessionsPubNew] PRIMARY KEY NONCLUSTERED 
(
	[VisitorSessionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF

-- Load the data only for what we need

insert into dbo.visitorsessionspubNew
select	*
from	dbo.visitorsessionsPub (nolock)
where	startdate > cast(floor(cast(getdate()-3 as float)) as datetime)


-- drop subscription firsts
USE NetquoteTest
DECLARE @publication AS sysname;
DECLARE @subscriber AS sysname;
SET @publication = N'VisitorSessionsPub';
SET @subscriber = N'Vilnius';


EXEC sp_dropsubscription 
  @publication = @publication, 
  @article = N'VisitorSessionsPub',
  @subscriber = @subscriber;
GO



-- drop the article
USE NetQuoteTest
DECLARE @publication AS sysname;
DECLARE @article AS sysname;
DECLARE @table AS sysname;

SET @publication = N'VisitorSessionsPub'; -- name of the publication
SET @table = N'VisitorSessionsPub'; -- name of the object being published

EXEC sp_droparticle 
	@publication = @publication, 
	@article = @table,
	@force_invalidate_snapshot = 1; 


-- drop the old table

DROP TABLE dbo.VisitorSessionsPub

-- rename the new table to old table name

EXEC dbo.sp_rename 'visitorsessionspubNew','VisitorSessionsPub'

-- add the table as article to publication
DECLARE @publication    AS sysname;
DECLARE @table AS sysname;
DECLARE @schemaowner AS sysname;

SET @publication = N'VisitorSessionsPub'; 
SET @table = N'VisitorSessionsPub';
SET @schemaowner = N'dbo';


EXEC dbo.sp_addarticle 
	@publication = @publication, 
	@article = @table, 
	@source_object = @table,
	@source_owner = @schemaowner;


-- Start snapshot of the publication
EXEC sp_startpublication_snapshot @publication = 'VisitorSessionsPub' 


-- Remove defunct subscriptions Run on subscriber
USE ODSQA
EXEC sp_subscription_cleanup
		@publisher =  'Vilnius',
		@publisher_db = 'NetquoteTest',
		@publication = 'VisitorSessionsPub'



-- Create New Subscription execute this batch at the Subscriber
USE ODSQA
DECLARE @publication AS sysname;
DECLARE @publisher AS sysname;
DECLARE @publicationDB AS sysname;
SET @publication = N'VisitorSessionsPub';
SET @publisher = N'Vilnius';
SET @publicationDB = N'NetQuoteTest';

-- At the subscription database, create a pull subscription 
-- to a transactional publication.
USE ODSQA
EXEC sp_addpullsubscription 
  @publisher = @publisher, 
  @publication = @publication, 
  @publisher_db = @publicationDB;

-- Add an agent job to synchronize the pull subscription.
EXEC sp_addpullsubscription_agent 
  @publisher = @publisher, 
  @publisher_db = @publicationDB, 
  @publication = @publication, 
  @distributor = @publisher, 
  @job_login = 'Netquote0\Nqapp', 
  @job_password = 'nq2001'
  @frequency_type = 64;
GO

-- Start REPL-Distribution Job
-- make sure job has   -Continuous flag at the end for execution



