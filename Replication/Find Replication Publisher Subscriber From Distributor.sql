--USE Distribution
GO
-- Find publications and Articles
SELECT	@@SERVERNAME AS DistributerServername,
		P.Publication AS PublicationName,
		A.Source_Owner AS SourceSchema,
		A.Article AS ArticleName,
		P.Publisher_db AS PublisherDatabaseName, 
		CASE P.Publication_type
			WHEN 0  THEN 'Transactional'
			WHEN 1  THEN 'Snapshot'
			WHEN 2  THEN 'Merge'
		END AS PublicationType
		,S.name AS SubscriberServerName
		, s1.name AS PublisherServerName
		, sub.*
--INTO	tempdb.dbo.ProdSQLReplicatedObjects
FROM	dbo.MSarticles AS a (NOLOCK)
	INNER JOIN dbo.MSPublications AS p (NOLOCK) ON a.publication_id = p.publication_id and a.publisher_db = p.publisher_db
	INNER JOIN dbo.MSsubscriptions AS sub (NOLOCK) ON a.article_id = sub.article_id and a.publisher_db = sub.publisher_db
	INNER JOIN sys.servers as s (NOLOCK) ON sub.subscriber_id = s.server_id
	INNER JOIN sys.servers as s1 (NOLOCK) ON s1.server_id = sub.publisher_id
--WHERE s.name like 'wsod-04-sql1'
--AND	p.publication like 'Bridge_dw_%'
--ORDER BY P.Publisher_db,Publication,ArticleName
ORDER BY s.name, p.publication, a.article
OPTION(RECOMPILE);