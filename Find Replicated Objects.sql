USE DISTRIBUTION
-- Find publications and Articles
select	A.Publication_id as PublicationId,
		P.Publication as PublicationName,
		A.Article ArticleName, 
		Case P.Publication_type
			when 0  then 'Transactional'
			when 1  then 'Snapshot'
			when 2  then 'Merge'
		end as PublicationType
--into	NetQuoteTechnologyOperations.dbo.ReplicationObjects
from	MSarticles as a (nolock)
	inner join MSPublications as p (nolock)
		on a.publication_id = p.publication_id

order by ArticleName,Publication