
-- Deplying proc
use [distribution]
go
CREATE PROC uspGetLogReaderAgentStatus
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT ma2.publisher_db,
		mh1.delivery_latency / ( 1000 * 60 ) AS delivery_latency_Minutes,
		mh1.agent_id ,
		mh1.time, 
		CAST(mh1.comments AS XML) AS comments, 
		CASE mh1.runstatus
			WHEN 1 THEN 'Start'
			WHEN 2 THEN 'Succeed.'
			WHEN 3 THEN 'In progress.'
			WHEN 4 THEN 'Idle.'
			WHEN 5 THEN 'Retry.'
			WHEN 6 THEN 'Fail'
		END AS Status,
		mh1.duration, 
		mh1.xact_seqno, 
		mh1.delivered_transactions, 
		mh1.delivered_commands, 
		mh1.average_commands, 
		mh1.delivery_time, 
		mh1.delivery_rate, 
		ma2.name as jobname
	FROM mslogreader_history mh1 
		JOIN (
			SELECT mh1.agent_id, MAX(mh1.time) as maxtime
			FROM mslogreader_history mh1
				JOIN MSlogreader_agents ma on ma.id = mh1.agent_id
			GROUP BY mh1.agent_id) AS mh2 ON mh1.agent_id = mh2.agent_id and mh1.time = mh2.maxtime
		JOIN MSlogreader_agents ma2 on ma2.id = mh2.agent_id  
	ORDER BY mh1.delivery_latency desc
END
GO

-- Monitoring  Sample code that you can use job to run.

use [distribution]
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/******************************************************************************/

DECLARE @AlertThresholdinMin INT = 10 -- If more than X min, delay, get alerts

/******************************************************************************/

SET @AlertThresholdinMin = @AlertThresholdinMin * 1000 * 60

SELECT cast(ma2.publisher_db as varchar(32)) as dbname,
	cast(mh1.delivery_latency / ( 1000 * 60 ) as int) AS delivery_latency_Minutes,
	mh1.time
INTO ##tmpLogReaderLatencyStatus
FROM mslogreader_history mh1 
	JOIN (
		SELECT mh1.agent_id, MAX(mh1.time) as maxtime
		FROM mslogreader_history mh1
			JOIN MSlogreader_agents ma on ma.id = mh1.agent_id
		GROUP BY mh1.agent_id) AS mh2 ON mh1.agent_id = mh2.agent_id and mh1.time = mh2.maxtime
	JOIN MSlogreader_agents ma2 on ma2.id = mh2.agent_id  
WHERE mh1.delivery_latency > @AlertThresholdinMin
	and mh1.comments not like '%No replicated transactions are available.%'

IF @@ROWCOUNT > 0
BEGIN

	DECLARE @p_body as nvarchar(max), @p_subject as nvarchar(max)
	DECLARE @p_recipients as nvarchar(max), @p_profile_name as nvarchar(max)

	SET @p_profile_name = N'You SQL Mail Profile'
	SET @p_recipients = N'recipient@testemail.com;multiple.recipients@dbmail.com'
	SET @p_subject = N'[SQL Alert] Log Reader Latency'
	SET @p_body = 'Please run exec distribution.dbo.uspGetLogReaderAgentStatus to get detail 	'

	EXEC msdb.dbo.sp_send_dbmail
	  @profile_name = @p_profile_name,
	  @recipients = @p_recipients,
	  @query = 'select * from ##tmpLogReaderLatencyStatus',
	  @attach_query_result_as_file= 1,
	  @body = @p_body,
	  @body_format = 'HTML',
	  @subject = @p_subject

END 

DROP TABLE ##tmpLogReaderLatencyStatus
go
