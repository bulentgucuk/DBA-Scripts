USE DISTRIBUTION
-- Find publications and Articles
select	--A.Publication_id as PublicationId,
		P.Publication as PublicationName,
		A.Source_Owner AS SourceSchema,
		A.Article ArticleName,
		P.Publisher_db AS PublisherDatabaseName, 
		Case P.Publication_type
			when 0  then 'Transactional'
			when 1  then 'Snapshot'
			when 2  then 'Merge'
		end as PublicationType
--into	NetQuoteTechnologyOperations.dbo.ReplicationObjects
from	MSarticles as a (nolock)
	inner join MSPublications as p (nolock)
		on a.publication_id = p.publication_id
order by P.Publisher_db,Publication,ArticleName
--order by ArticleName,Publication