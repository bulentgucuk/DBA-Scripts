

drop table if exists [email].[DimCampaignActivityType_New];

/****** Object:  Table [email].[DimCampaignActivityType]    Script Date: 8/26/2018 8:26:44 PM ******/
SET ANSI_NULLS ON

SET QuOTED_IDENTIFIER ON


CREATE TABLE [email].[DimCampaignActivityType_New](
	[DimCampaignActivityTypeId] [int] IDENTITY(-2,1) NOT NULL,
	[ActivityTypeCode] [varchar](50) NULL,
	ActivityTypeDesc varchar(255) null,
	[CreatedBy] [varchar](255) NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedBy] [varchar](255) NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[DimCampaignActivityTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


ALTER TABLE [email].[DimCampaignActivityType_new] ADD  DEFAULT (user_name()) FOR [CreatedBy]


ALTER TABLE [email].[DimCampaignActivityType_new] ADD  DEFAULT (getdate()) FOR [CreatedDate]


ALTER TABLE [email].[DimCampaignActivityType_new] ADD  DEFAULT (user_name()) FOR [UpdatedBy]


ALTER TABLE [email].[DimCampaignActivityType_new] ADD  DEFAULT (getdate()) FOR [UpdatedDate]





exec sp_rename 'email.DimCampaignActivityType', 'DimCampaignActivityType_Dropme'
exec sp_rename 'email.DimCampaignActivityType_new', 'DimCampaignActivityType'




Exec sp_rename '[email].[FactCampaignEmailDetail]', 'FactCampaignEmailDetail_Orig'

drop table if exists [email].[FactCampaignEmailDetail] 

/****** Object:  Table [email].[FactCampaignEmailDetail]    Script Date: 8/27/2018 8:16:38 AM ******/
SET ANSI_NULLS ON


SET QUOTED_IDENTIFIER ON


CREATE TABLE [email].[FactCampaignEmailDetail](
	[FactCampaignEmailDetailId] [int] IDENTITY(1,1) NOT NULL,
	[DimCampaignId] [int] not  NULL,
	[DimSegmentId] int not null,
	[DimEmailId] [int]  not NULL,
	[DimCampaignActivityTypeId] [int] not NULL,
	[DimBrowserId] [int] not NULL default -1,
	[DimOperationSystemId] [int]  not NULL default -1,
	[DimEmailClientId] [int]  not NULL default -1,
	[DimDeviceId] [int]  not NULL default -1,
	[DimCampaignTypeId] [int]  not NULL default -1,
	[DimChannelId] [int]  not NULL default -1,
	[ActivityReason] [varchar](max) NULL,
	[IPAddress] [varchar](20) NULL,
	[ActivityDateTime] [datetime] NULL,
	[PurchaseOrderID] varchar(50) null,
	[PurchaseItem] varchar(255) null,
	[PurchaseAmount] decimal(22,5) null,
	[URL] [varchar](max) NULL,
	[URLAlias] [varchar](max) NULL,
	[Src_SendId] [int] NULL,
	[Src_ActivityId] [int] NULL,
	[CreatedBy] [varchar](255) NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedBy] [varchar](255) NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[FactCampaignEmailDetailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]


ALTER TABLE [email].[FactCampaignEmailDetail] ADD  DEFAULT (user_name()) FOR [CreatedBy]


ALTER TABLE [email].[FactCampaignEmailDetail] ADD  DEFAULT (getdate()) FOR [CreatedDate]


ALTER TABLE [email].[FactCampaignEmailDetail] ADD  DEFAULT (user_name()) FOR [UpdatedBy]


ALTER TABLE [email].[FactCampaignEmailDetail] ADD  DEFAULT (getdate()) FOR [UpdatedDate]


ALTER TABLE [email].[FactCampaignEmailDetail]  WITH CHECK ADD FOREIGN KEY([DimBrowserId])
REFERENCES [email].[DimBrowser] ([DimBrowserId])


ALTER TABLE [email].[FactCampaignEmailDetail]  WITH CHECK ADD FOREIGN KEY([DimCampaignId])
REFERENCES [email].[DimCampaign] ([DimCampaignId])


ALTER TABLE [email].[FactCampaignEmailDetail]  WITH CHECK ADD FOREIGN KEY([DimCampaignActivityTypeId])
REFERENCES [email].[DimCampaignActivityType] ([DimCampaignActivityTypeId])


ALTER TABLE [email].[FactCampaignEmailDetail]  WITH CHECK ADD FOREIGN KEY([DimCampaignTypeId])
REFERENCES [email].[DimCampaignType] ([DimCampaignTypeId])


ALTER TABLE [email].[FactCampaignEmailDetail]  WITH CHECK ADD FOREIGN KEY([DimChannelId])
REFERENCES [email].[DimChannel] ([DimChannelId])


ALTER TABLE [email].[FactCampaignEmailDetail]  WITH CHECK ADD FOREIGN KEY([DimDeviceId])
REFERENCES [email].[DimDevice] ([DimDeviceId])


ALTER TABLE [email].[FactCampaignEmailDetail]  WITH CHECK ADD FOREIGN KEY([DimEmailId])
REFERENCES [email].[DimEmail] ([DimEmailID])


ALTER TABLE [email].[FactCampaignEmailDetail]  WITH CHECK ADD FOREIGN KEY([DimEmailClientId])
REFERENCES [email].[DimEmailClient] ([DimEmailClientId])


ALTER TABLE [email].[FactCampaignEmailDetail]  WITH CHECK ADD FOREIGN KEY([DimOperationSystemId])
REFERENCES [email].[DimOperatingSystem] ([DimOperatingSystemId])





Drop table if exists [email].[FactCampaignSummary];

/****** Object:  Table [email].[FactCampaignSummary]    Script Date: 8/28/2018 7:57:07 AM ******/
SET ANSI_NULLS ON


SET QUOTED_IDENTIFIER ON


CREATE TABLE [email].[FactCampaignSummary](
	[FactCampaignSummaryId] [int] IDENTITY(1,1) NOT NULL,
	[DimCampaignId] [int] NULL,
TotalSent int null,
TotalHardBounce int null,
TotalSoftBounce int null,
TotalOpens int null,
UniqueOpens int null,
TotalClicks int null,
UniqueClicks int null,
TotalForwards int null,
UniqueForwards int null,
TotalPurchases int null,
UniquePurchasers int null, 
TotalPurchaseAmount int null,
ActivityStartDate datetime null,
LastActivityDate datetime null,
	[CreatedBy] [varchar](255) NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedBy] [varchar](255) NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[FactCampaignSummaryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


ALTER TABLE [email].[FactCampaignSummary] ADD  DEFAULT (user_name()) FOR [CreatedBy]


ALTER TABLE [email].[FactCampaignSummary] ADD  DEFAULT (getdate()) FOR [CreatedDate]


ALTER TABLE [email].[FactCampaignSummary] ADD  DEFAULT (user_name()) FOR [UpdatedBy]


ALTER TABLE [email].[FactCampaignSummary] ADD  DEFAULT (getdate()) FOR [UpdatedDate]


ALTER TABLE [email].[FactCampaignSummary]  WITH CHECK ADD FOREIGN KEY([DimCampaignId])
REFERENCES [email].[DimCampaign] ([DimCampaignId])


drop table if exists email.FactCampaignSegmentSummary;


SET ANSI_NULLS ON


SET QUOTED_IDENTIFIER ON


CREATE TABLE [email].[FactCampaignSegmentSummary](
	[FactCampaignSegmentSummaryId] [int] IDENTITY(1,1) NOT NULL,
	[DimCampaignId] [int] NULL,
	[DimSegmentID] int null,
	[TotalSent] [int] NULL,
	[TotalHardBounce] [int] NULL,
	[TotalSoftBounce] [int] NULL,
	[TotalOpens] [int] NULL,
	[UniqueOpens] [int] NULL,
	[TotalClicks] [int] NULL,
	[UniqueClicks] [int] NULL,
	[TotalForwards] [int] NULL,
	[UniqueForwards] [int] NULL,
	[TotalPurchases] [int] NULL,
	[UniquePurchasers] [int] NULL,
	[TotalPurchaseAmount] [int] NULL,
	[ActivityStartDate] [datetime] NULL,
	[LastActivityDate] [datetime] NULL,
	[CreatedBy] [varchar](255) NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedBy] [varchar](255) NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[FactCampaignSegmentSummaryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


ALTER TABLE [email].[FactCampaignSegmentSummary] ADD  DEFAULT (user_name()) FOR [CreatedBy]


ALTER TABLE [email].[FactCampaignSegmentSummary] ADD  DEFAULT (getdate()) FOR [CreatedDate]


ALTER TABLE [email].[FactCampaignSegmentSummary] ADD  DEFAULT (user_name()) FOR [UpdatedBy]


ALTER TABLE [email].[FactCampaignSegmentSummary] ADD  DEFAULT (getdate()) FOR [UpdatedDate]


ALTER TABLE [email].[FactCampaignSegmentSummary]  WITH CHECK ADD FOREIGN KEY([DimCampaignId])
REFERENCES [email].[DimCampaign] ([DimCampaignId])


ALTER TABLE [email].[FactCampaignSegmentSummary]  WITH CHECK ADD FOREIGN KEY([DimSegmentId])
REFERENCES [email].[DimSegment] ([DimSegmentId])


drop table if exists email.FactEmailSummary;

/****** Object:  Table [email].[FactCampaignSummary]    Script Date: 8/28/2018 9:36:39 AM ******/
SET ANSI_NULLS ON


SET QUOTED_IDENTIFIER ON


CREATE TABLE [email].[FactEmailSummary](
	[FactEmailSummaryId] [int] IDENTITY(1,1) NOT NULL,
	[DimEmailId] [int] NULL,
	[TotalSent] [int] NULL,
	LastSentDate datetime null,
	[TotalHardBounce] [int] NULL,
	[TotalSoftBounce] [int] NULL,
	[TotalOpens] [int] NULL,
	[UniqueOpens] [int] NULL,
	LastOpenDate datetime null,
	[TotalClicks] [int] NULL,
	[UniqueClicks] [int] NULL,
	LastClickDate datetime null,
	[TotalForwards] [int] NULL,
	[UniqueForwards] [int] NULL,
	[TotalPurchases] [int] NULL,
	[UniquePurchasers] [int] NULL,
	[TotalPurchaseAmount] [int] NULL,
	LastPurchaseDate datetime null,
	[ActivityStartDate] [datetime] NULL,
	[LastActivityDate] [datetime] NULL,
	[CreatedBy] [varchar](255) NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedBy] [varchar](255) NULL,
	[UpdatedDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[FactEmailSummaryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


ALTER TABLE [email].[FactEmailSummary] ADD  DEFAULT (user_name()) FOR [CreatedBy]


ALTER TABLE [email].[FactEmailSummary] ADD  DEFAULT (getdate()) FOR [CreatedDate]


ALTER TABLE [email].[FactEmailSummary] ADD  DEFAULT (user_name()) FOR [UpdatedBy]


ALTER TABLE [email].[FactEmailSummary] ADD  DEFAULT (getdate()) FOR [UpdatedDate]

ALTER TABLE [email].[FactEmailSummary]  WITH CHECK ADD FOREIGN KEY([DimEmailId])
REFERENCES [email].[DimEmail] ([DimEmailId])


drop table if exists email.FactCampaignEmailSummary
drop table if exists email.FactCampaignEmailDetail_Orig


