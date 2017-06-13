USE master
go

SET NOCOUNT ON
DECLARE @crDate DateTime; 
DECLARE @hours DECIMAL(18,3), @Days int;
DECLARE @FinalHours int, @FinalMinutes int, @FinalSeconds int, @total_seconds  int;


-- Determine uptime by checking Tempdb creation datetime:
SELECT top 1 @crdate=create_date FROM sys.databases WHERE NAME='tempdb'
SELECT @hours = DATEDIFF(ss,@crDate,GETDATE())/CAST(60 AS Decimal)/CAST(60 AS Decimal);
PRINT 'SQL Server instance '+ @@SERVERNAME + '\' + @@SERVICENAME + ' is Up since: ' + CAST (@crdate as varchar)  ;

-- From hours to days:
SELECT @Days = @hours/CAST(24 AS Decimal);

-- Determine the remaining part of the hours: 
SELECT @FinalHours = @hours - (@Days*CAST(24 AS Decimal))

-- Remaining minutes: 
SELECT @FinalMinutes = (@hours - (@Days*CAST(24 AS Decimal)) - @FinalHours ) * 60;

-- Remaining seconds: 
SELECT @FinalSeconds = (((@hours - (@Days*CAST(24 AS Decimal)) - @FinalHours ) * 60) - @Finalminutes) * 60;

PRINT 'Or: '+ CAST(@Days as varchar) + ' Days, ' + CAST(@FinalHours as varchar) + ' Hours,'
+ CAST(@FinalMinutes as varchar) + ' Minutes and ' +  CAST(@FinalSeconds as varchar) + ' Seconds.'

SELECT  @total_seconds = (CAST(@Days AS decimal(12,2))*24*3600 + CAST(@Finalhours AS decimal(12,2))*3600 + CAST(@Finalminutes AS decimal(12,2))*60 )
+ CAST(@Finalseconds AS decimal(12,2))
PRINT 'Total uptime in seconds: '+ CONVERT(VARCHAR(20) ,@total_seconds )

SELECT @@SERVERNAME as Hostname, @@SERVICENAME as Instancename, @crdate AS SQL_Start_Date_Time ,  @total_seconds as TotalSeconds_Up

SELECT  DB_NAME(database_id) AS [Database Name] ,
        file_id ,
        io_stall_read_ms ,
        num_of_reads ,
            (num_of_bytes_read / 1024 / 1024 /1024) as GB_Read_Total,
            num_of_bytes_read / @total_seconds * 3600 * 24 /1024/1024/1024  as AVG_GB_read_per_day_ESTIMATE,
        CAST(io_stall_read_ms / ( 1.0 + num_of_reads ) AS NUMERIC(10, 1))
            AS [avg_read_stall_ms] ,
        io_stall_write_ms ,
        num_of_writes ,
            num_of_bytes_written / 1024 / 1024/1024 as GB_Written_Total,
            num_of_bytes_written /@total_seconds * 3600 * 24 /1024/1024/1024  as AVG_GB_Written_per_day_ESTIMATE,
        CAST(io_stall_write_ms / ( 1.0 + num_of_writes ) AS NUMERIC(10, 1))
            AS [avg_write_stall_ms] ,
        io_stall_read_ms + io_stall_write_ms AS [IO_Stalls] ,
        num_of_reads + num_of_writes AS [Total_IO] ,
        CAST(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads
                                                          + num_of_writes)
           AS NUMERIC(10,1)) AS [AVG_IO_stall_ms]
FROM    sys.dm_io_virtual_file_stats(NULL, NULL)
--ORDER BY avg_io_stall_ms DESC ;
order by GB_read_total DESC