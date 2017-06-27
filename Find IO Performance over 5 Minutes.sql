SET NOCOUNT ON

DECLARE @IOStats TABLE (
        [database_id] [smallint] NOT NULL,
        [file_id] [smallint] NOT NULL,
        [num_of_reads] [bigint] NOT NULL,
        [num_of_bytes_read] [bigint] NOT NULL,
        [io_stall_read_ms] [bigint] NOT NULL,
        [num_of_writes] [bigint] NOT NULL,
        [num_of_bytes_written] [bigint] NOT NULL,
        [io_stall_write_ms] [bigint] NOT NULL)
INSERT INTO @IOStats
        SELECT database_id,
                vio.file_id,
                num_of_reads,
                num_of_bytes_read,
                io_stall_read_ms,
                num_of_writes,
                num_of_bytes_written,
                io_stall_write_ms
        FROM sys.dm_io_virtual_file_stats (NULL, NULL) vio
DECLARE @StartTime datetime, @DurationInSecs int
SET @StartTime = GETDATE()
WAITFOR DELAY '00:05:00'
SET @DurationInSecs = DATEDIFF(ss, @startTime, GETDATE())
SELECT DB_NAME(vio.database_id) AS [Database],
        mf.name AS [Logical name],
        mf.type_desc AS [Type],
                (vio.io_stall_read_ms - old.io_stall_read_ms) / CASE (vio.num_of_reads-old.num_of_reads) WHEN 0 THEN 1 ELSE vio.num_of_reads-old.num_of_reads END AS [Ave read speed (ms)],
        vio.num_of_reads - old.num_of_reads AS [No of reads over period],
        CONVERT(DEC(14,2), (vio.num_of_reads - old.num_of_reads) / (@DurationInSecs * 1.00)) AS [No of reads/sec],
        CONVERT(DEC(14,2), (vio.num_of_bytes_read - old.num_of_bytes_read) / 1048576.0) AS [Tot MB read over period],
        CONVERT(DEC(14,2), ((vio.num_of_bytes_read - old.num_of_bytes_read) / 1048576.0) / @DurationInSecs) AS [Tot MB read/sec],
        (vio.num_of_bytes_read - old.num_of_bytes_read) / CASE (vio.num_of_reads-old.num_of_reads) WHEN 0 THEN 1 ELSE vio.num_of_reads-old.num_of_reads END AS [Ave read size (bytes)],
                (vio.io_stall_write_ms - old.io_stall_write_ms) / CASE (vio.num_of_writes-old.num_of_writes) WHEN 0 THEN 1 ELSE vio.num_of_writes-old.num_of_writes END AS [Ave write speed (ms)],
        vio.num_of_writes - old.num_of_writes AS [No of writes over period],
        CONVERT(DEC(14,2), (vio.num_of_writes - old.num_of_writes) / (@DurationInSecs * 1.00)) AS [No of writes/sec],
        CONVERT(DEC(14,2), (vio.num_of_bytes_written - old.num_of_bytes_written)/1048576.0) AS [Tot MB written over period],
        CONVERT(DEC(14,2), ((vio.num_of_bytes_written - old.num_of_bytes_written)/1048576.0) / @DurationInSecs) AS [Tot MB written/sec],
        (vio.num_of_bytes_written-old.num_of_bytes_written) / CASE (vio.num_of_writes-old.num_of_writes) WHEN 0 THEN 1 ELSE vio.num_of_writes-old.num_of_writes END AS [Ave write size (bytes)],
        mf.physical_name AS [Physical file name],
        size_on_disk_bytes/1048576 AS [File size on disk (MB)]
FROM sys.dm_io_virtual_file_stats (NULL, NULL) vio,
        sys.master_files mf,
        @IOStats old
WHERE mf.database_id = vio.database_id AND
        mf.file_id = vio.file_id AND
        old.database_id = vio.database_id AND
        old.file_id = vio.file_id AND
        ((vio.num_of_bytes_read - old.num_of_bytes_read) + (vio.num_of_bytes_written - old.num_of_bytes_written)) > 0
ORDER BY ((vio.num_of_bytes_read - old.num_of_bytes_read) + (vio.num_of_bytes_written - old.num_of_bytes_written)) DESC
GO