-- Physical CPU count
SELECT  cpu_count / hyperthread_ratio AS PhysicalCPUsFROM
FROM	sys.dm_os_sys_info

-- Logical CPU count
SELECT  cpu_count AS logicalCPUsFROM
FROM	sys.dm_os_sys_info