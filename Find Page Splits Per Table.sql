-- Find page splits
SELECT	Operation,
		AllocUnitName,
		COUNT(*) AS NumberofIncidents
FROM	::FN_DBLOG(NULL, NULL)
WHERE	Operation = N'LOP_DELETE_SPLIT'
--AND		AllocUnitName LIKE 'dbo.partnerxml.%'  -- Change the table name
GROUP BY Operation, AllocUnitName