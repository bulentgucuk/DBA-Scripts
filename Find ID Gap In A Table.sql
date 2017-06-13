;WITH
cte AS (
    SELECT
        [StatementDeliveryConfigurationID],
        RowNum = ROW_NUMBER() OVER (ORDER BY [StatementDeliveryConfigurationID])
    FROM [Fin].[StatementDeliveryConfigurations]),
cte2 AS (
    SELECT *, DENSE_RANK() OVER (ORDER BY [StatementDeliveryConfigurationID] - RowNum) As Series
    FROM cte),
cte3 AS (
    SELECT *, COUNT(*) OVER (PARTITION BY Series) AS SCount
    FROM cte2),
cte4 AS (
    SELECT
        MinStatementDeliveryConfigurationID = MIN([StatementDeliveryConfigurationID]),
        MaxStatementDeliveryConfigurationID = MAX([StatementDeliveryConfigurationID]),
        Series
    FROM cte3
    GROUP BY Series)

SELECT GapStart = a.MaxStatementDeliveryConfigurationID, GapEnd = b.MinStatementDeliveryConfigurationID
	, b.MinStatementDeliveryConfigurationID - a.MaxStatementDeliveryConfigurationID AS GapRange
FROM cte4 a
    INNER JOIN cte4 b
        ON a.Series+1 = b.Series
ORDER BY GapStart DESC;