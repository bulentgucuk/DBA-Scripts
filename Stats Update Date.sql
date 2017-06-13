--Get the date stats update date

SELECT name AS index_name, 
    STATS_DATE(OBJECT_ID, index_id) AS statistics_update_date
FROM sys.indexes 
WHERE OBJECT_ID = OBJECT_ID('dbo.Accounts');  -- change the table name