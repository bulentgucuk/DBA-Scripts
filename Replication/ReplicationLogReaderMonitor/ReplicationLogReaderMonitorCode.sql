USE distribution
go
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