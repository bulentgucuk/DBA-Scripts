SELECT
perf1.[object_name],
perf1.counter_name,
perf1.instance_name,
perf1.cntr_type,
'value' = CASE perf1.cntr_type
WHEN 537003008 -- This counter is expressed as a ratio and requires calculation. (Sql 2000)
THEN CONVERT(FLOAT,
perf1.cntr_value) /
(SELECT CASE perf2.cntr_value
WHEN 0 THEN 1
ELSE perf2.cntr_value
END
FROM sys.dm_os_performance_counters perf2
WHERE (perf1.counter_name + ' '
= SUBSTRING(perf2.counter_name,
1,
PATINDEX('% Base%', perf2.counter_name)))
AND perf1.[object_name] = perf2.[object_name]
AND perf1.instance_name = perf2.instance_name
AND perf2.cntr_type in (1073939459,1073939712)
)
WHEN 537003264 -- This counter is expressed as a ratio and requires calculation. >=SQL2005
THEN CONVERT(FLOAT,
perf1.cntr_value) /
(SELECT CASE perf2.cntr_value
WHEN 0 THEN 1
ELSE perf2.cntr_value
END
FROM sys.dm_os_performance_counters perf2
WHERE (perf1.counter_name + ' '
= SUBSTRING(perf2.counter_name,
1,
PATINDEX('% Base%', perf2.counter_name)))
AND perf1.[object_name] = perf2.[object_name]
AND perf1.instance_name = perf2.instance_name
AND perf2.cntr_type in (1073939712)
)
ELSE perf1.cntr_value -- The values of the other counter types are
-- already calculated.
END
FROM sys.dm_os_performance_counters perf1
WHERE perf1.cntr_type not in (1073939712) -- Don't display the divisors.
ORDER BY 1,2,3,4
