USE Ducks_Integration;
GO

-- PAGE CONTENT
DBCC PAGE (36, 1, 1950432,3);

-- PAGE METADATA
DBCC TRACEON (3604);
DBCC PAGE (36, 1, 1950432,0);
DBCC TRACEOFF (3604);
GO

--https://www.sqlskills.com/blogs/paul/finding-table-name-page-id/