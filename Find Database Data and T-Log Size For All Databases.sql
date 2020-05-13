SELECT d.[Database],
d.[Database Total],
l.[Log File Name],
l.[Log Total]
FROM
(
SELECT d.name AS 'Database',
SUM(m.size * 8 / 1024) AS 'Database Total'
FROM sys.master_files m
INNER JOIN sys.databases d
ON d.database_id = m.database_id
WHERE m.data_space_id <> 0
GROUP BY d.name
) d
INNER JOIN
(
SELECT d.name AS 'Database',
m.name AS 'Log File Name',
m.size * 8 / 1024 AS 'Log Total'
FROM sys.master_files m
INNER JOIN sys.databases d
ON d.database_id = m.database_id
WHERE m.data_space_id = 0
) l
ON l.[Database] = d.[Database]
ORDER BY d.[Database];