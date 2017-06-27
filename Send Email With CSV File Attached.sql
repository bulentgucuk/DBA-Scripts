declare @M varchar(8000)
declare @bodytext NVARCHAR(1000)

SELECT @M = 'use [Advatar]

SET NOCOUNT ON;
DECLARE @schday VARCHAR(2);
DECLARE @schmonth CHAR(1)
DECLARE @tomorrow DATETIME = DATEADD(DAY,1,GETDATE());

SELECT @schday = (Select DATEPART(day,@tomorrow));
SELECT @schmonth = 
					CASE
						WHEN (Select DATEPART(month,@tomorrow)) < 10 THEN (Select CAST(DATEPART(month,@tomorrow) AS VARCHAR (1)))
						WHEN (Select DATEPART(month,@tomorrow)) = 10 THEN ''A''
						WHEN (Select DATEPART(month,@tomorrow)) = 11 THEN ''B''
						WHEN (Select DATEPART(month,@tomorrow)) = 12 THEN ''C''
					END;

DECLARE @mdd VARCHAR(3);

if @schday < 10
select @mdd = (select CONVERT(varchar(2),@schmonth)+''0''+CONVERT(varchar(2), @schday))
else
select @mdd = (select CONVERT(varchar(2),@schmonth)+CONVERT(varchar(2), @schday))

print ''Zone 106 Schedule Imports for ''+convert(varchar(3), @mdd)
select DATEADD(HOUR, -4, ProcessTime),Name, statuscode from ScheduleFileStatus
where Name like CONVERT(varchar(3), @mdd)+''%106-%''or Name like CONVERT(varchar(3), @mdd)+''%601-%''
order by Name'

SET @bodytext = 'This email shows schedule import status for Zone 106 on the Strata-bdms.invidi.com test system' + CHAR(10) + CHAR(13) + 'If attachment shows no schedules in the list - ALL CLEAR ' + CHAR(10) + CHAR(13) + 'If attachment shows schedules and import times, validate that the import times were after 3pm local.'+ CHAR(10) + CHAR(13) + 'If import times are prior to 3pm - A request for a resend from the ad partner should be initiated'

EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'INVIDI',
--@recipients = 'supportalert@invidi.com',
@recipients = 'bgucuk@invidi.com',
@subject = 'Schedule Import Status',
@body = @bodytext,
@query = @M,
@attach_query_result_as_file = 1,
@query_attachment_filename = 'importstatus.csv'
