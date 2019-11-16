use msdb
GO
SELECT
	CASE
		WHEN s.name IS NULL THEN 'TotalJobCountForServer'
		ELSE s.name
	END AS categoryname
	, COUNT(j.name) AS JobCount
FROM dbo.syscategories AS s
	INNER JOIN dbo.sysjobs AS J ON J.category_id = s.category_id
WHERE	j.enabled = 1
GROUP BY ROLLUP (s.name)
ORDER BY s.name;

