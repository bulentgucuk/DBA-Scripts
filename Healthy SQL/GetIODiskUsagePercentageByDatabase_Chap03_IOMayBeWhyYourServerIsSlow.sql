WITH Cu_IO_Stats

AS

(

SELECT

DB_NAME(database_id) AS database_name,

CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576.

AS DECIMAL(12, 2)) AS io_in_mb

FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS DM_IO_Stats

GROUP BY database_id

)

SELECT

ROW_NUMBER() OVER(ORDER BY io_in_mb DESC) AS row_num,

database_name,

io_in_mb,

CAST(io_in_mb / SUM(io_in_mb) OVER() * 100

AS DECIMAL(5, 2)) AS pct

FROM Cu_IO_Stats

ORDER BY row_num; 