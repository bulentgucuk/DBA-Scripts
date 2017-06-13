CREATE TABLE [dbo].[waitstats]( 
[wait_type] [nvarchar](60) NOT NULL, 
[WaitSec] [numeric](26, 6) NULL, 
[ResourceSec] [numeric](26, 6) NULL, 
[SignalSec] [numeric](26, 6) NULL, 
[WaitCount] [bigint] NOT NULL, 
[AvgWait_Sec] [numeric](26, 6) NULL, 
[AvgRes_Sec] [numeric](26, 6) NULL, 
[AvgSig_Sec] [numeric](26, 6) NULL, 
[Percentage] [numeric](38, 15) NULL, 
[CaptureDate] [datetime] NULL 
) ON [PRIMARY] 
GO 