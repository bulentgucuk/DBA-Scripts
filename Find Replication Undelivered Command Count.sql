declare @tabDistStatus table(
           agent_id int
         , UndelivCmdsInDistDB bigint
		 , article_id int)
-- Refresh replication monitor data
Exec [distribution].sys.sp_replmonitorrefreshjob @iterations = 1;
 
insert into @tabDistStatus
SELECT ds.agent_id, sum(ds.UndelivCmdsInDistDB) UndelivCmdsInDistDB,article_id
  FROM distribution.dbo.MSdistribution_status ds WITH(NOLOCK) -- article level
GROUP BY ds.agent_id,article_id
 
SELECT md.agent_name + ': ' + a.Article, isnull(ds.UndelivCmdsInDistDB,0) UndelivCmdsInDistDB
  FROM distribution.dbo.MSreplication_monitordata md WITH(NOLOCK)
Left Join @tabDistStatus ds
    ON md.agent_id = ds.agent_id
Inner Join distribution.dbo.MSdistribution_agents ag with(nolock)
    On ag.id = md.agent_id
INNER JOIN distribution.dbo.MSpublications  (NOLOCK) AS p 
	ON p.publication = ag.publication
INNER JOIN distribution.dbo.MSarticles (NOLOCK)  AS a 
	ON a.article_id = ds.article_id and p.publication_id = a.publication_id
	where agent_type = 3
--and a.article = 'Customer'
order  by UndelivCmdsInDistDB desc