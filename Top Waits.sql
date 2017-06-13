-- Clear Wait Stats
	--DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);


-- Isolate top waits
    WITH Waits AS
    (
      SELECT
        wait_type,
        wait_time_ms / 1000. AS wait_time_s,
        100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
        ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
      FROM sys.dm_os_wait_stats
      WHERE wait_type NOT LIKE '%SLEEP%'
      -- filter out additional irrelevant waits
    )
    SELECT
      W1.wait_type, 
      CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
      CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
      CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
    FROM Waits AS W1
    INNER JOIN Waits AS W2
    ON W2.rn <= W1.rn
    GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
    HAVING SUM(W2.pct) - W1.pct < 90 -- percentage threshold
    ORDER BY W1.rn;