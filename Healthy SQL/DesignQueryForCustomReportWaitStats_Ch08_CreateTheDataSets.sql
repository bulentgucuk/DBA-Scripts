SELECT [wait_type] 
,[WaitSec] 
/* ,[ResourceSec] 
,[SignalSec] 
,[WaitCount] 
,[AvgWait_Sec] 
,[AvgRes_Sec] 
,[AvgSig_Sec] */ -- you only need WaitSec, Percentage & CaptureDate 
,[Percentage] 
,[CaptureDate] 
FROM [dbo].[waitstats] 
/*Where CaptureDate  between @BeginDate AND @EndDate 
AND (@WaitType= 'ALL' 
OR [Wait_type] in (@WaitType) )*/ --REMOVE COMMENTS AFTER PARAMS ARE CREATED