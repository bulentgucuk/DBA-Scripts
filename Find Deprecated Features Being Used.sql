select	instance_name as [Deprecated Feature]
		,cntr_value as [Frequency Used]
from	sys.dm_os_performance_counters
where	object_name = 'SQLServer:Deprecated Features'  
		--object_name = 'MSSQL$ODS:Deprecated Features' -- CHANGE THE INSTANCE NAME 
and cntr_value > 0
order by cntr_value desc
