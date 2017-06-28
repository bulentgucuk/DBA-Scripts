USE distribution;
GO
-- Find publications and Articles
SELECT	@@SERVERNAME AS Servername,
		P.Publication AS PublicationName,
		A.Source_Owner AS SourceSchema,
		A.Article AS ArticleName,
		P.Publisher_db AS PublisherDatabaseName, 
		CASE P.Publication_type
			WHEN 0  THEN 'Transactional'
			WHEN 1  THEN 'Snapshot'
			WHEN 2  THEN 'Merge'
		END AS PublicationType
--INTO	tempdb.dbo.ProdSQLReplicatedObjects
FROM	dbo.MSarticles AS a (NOLOCK)
	INNER JOIN dbo.MSPublications AS p (NOLOCK) ON a.publication_id = p.publication_id
ORDER BY P.Publisher_db,Publication,ArticleName
