SELECT instance_name AS 'Database Name',
   MAX(CASE
           WHEN counter_name = 'Data File(s) Size (KB)'
               THEN cntr_value
           ELSE 0
       END) AS 'Data File(s) Size (KB)',
   MAX(CASE
           WHEN counter_name = 'Log File(s) Size (KB)'
               THEN cntr_value
           ELSE 0
       END) AS 'Log File(s) Size (KB)',
   MAX(CASE
           WHEN counter_name = 'Log File(s) Used Size (KB)'
               THEN cntr_value
           ELSE 0
       END) AS 'Log File(s) Used Size (KB)',
   MAX(CASE
           WHEN counter_name = 'Percent Log Used'
               THEN cntr_value
           ELSE 0
       END) AS 'Percent Log Used'
--FROM sysperfinfo -- SQL Server 2000 system table deprecated
FROM	sys.dm_os_performance_counters
WHERE counter_name IN
   (
       'Data File(s) Size (KB)',
       'Log File(s) Size (KB)',
       'Log File(s) Used Size (KB)',
       'Percent Log Used'
   )
  AND instance_name != '_total'
GROUP BY instance_name 