--Find record count per minute and lag collection_time from dbo.WhoIsActive
USE DBA;
select	cast(collection_time as smalldatetime) as 'minutes'
	, count(rowid) as 'records/PM'
	,LAG(cast(collection_time as smalldatetime), 1,0) OVER (ORDER BY cast(collection_time as smalldatetime)) AS 'PreviousMinute' 
	,datediff(MINUTE, cast(collection_time as smalldatetime),LAG(cast(collection_time as smalldatetime), 1,0) OVER (ORDER BY cast(collection_time as smalldatetime))) AS MIndiff
from	dbo.whoisactive with(nolock)
where	collection_time > '20180130 04:00'
and		collection_time < '20180130 09:50'
group by cast(collection_time as smalldatetime)
order by cast(collection_time as smalldatetime)