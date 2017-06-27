CREATE TABLE dbo.DuplicateRcordTable (Col1 INT, Col2 INT, Col3 VARCHAR(20))
INSERT INTO DuplicateRcordTable
SELECT 1, 1,'USA'
UNION ALL
SELECT 1, 1, 'USA' --duplicate
UNION ALL
SELECT 1, 1, 'USA' --duplicate
UNION ALL
SELECT 1, 2, 'UK'
UNION ALL
SELECT 1, 2, 'UK' --duplicate
UNION ALL
SELECT 1, 3, 'FR'
UNION ALL
SELECT 1, 4, 'SP'
GO 

/* It should give you 7 rows */
SELECT *
FROM DuplicateRcordTable
GO

/* Delete Duplicate records */
WITH CTE (COl1,Col2, DuplicateCount)
AS
(
SELECT COl1,Col2,
ROW_NUMBER() OVER(PARTITION BY COl1,Col2 ORDER BY Col1) AS DuplicateCount
FROM DuplicateRcordTable
)
DELETE
FROM CTE
WHERE DuplicateCount > 1

GO 

SELECT *
FROM DuplicateRcordTable
GO
DROP TABLE dbo.DuplicateRcordTable