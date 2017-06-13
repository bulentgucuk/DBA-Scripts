USE distribution;
--Query to find replication status
SELECT publisher
    , publisher_db
    , publication
    , agent_name
    , last_distsync
    , CASE
        WHEN status = 1 THEN 'Started'
        WHEN status = 2 THEN 'Succeeded'
        WHEN status = 3 THEN 'In progress'
        WHEN status = 4 THEN 'Idle'
        WHEN status = 5 THEN 'Retrying'
        WHEN status = 6 THEN 'Failed'
    END AS StatedStates
    --, *
FROM dbo.MSreplication_monitordata;

--Query to find replication errrors
SELECT	*
FROM	dbo.MSrepl_errors
ORDER BY [time] DESC;

--Query to find Status Information From Replication Distribution Agents
SELECT 
    a.name PublicationName
    , a.publication Publication
    , ditosu.comments AS MessageText
    , ditosu.[time] CommandDate
    , ditosu.xact_seqno xact_seqno
FROM MSdistribution_agents a
    INNER JOIN MSpublications p ON a.publisher_db = p.publisher_db
        AND a.publication = p.publication
    INNER JOIN MSdistribution_history ditosu ON ditosu.agent_id = a.id
-- Apply a filter here can minimize the noise
ORDER BY ditosu.[time] DESC;
