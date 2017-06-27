select 'table_name'=object_name(i.id)
		,i.indid
		,'index_name'=i.name
		,i.groupid
		,'filegroup'=f.name
		,'file_name'=d.physical_name
		,'dataspace'=s.name
from	sys.sysindexes i
		,sys.filegroups f
		,sys.database_files d
		,sys.data_spaces s
where objectproperty(i.id,'IsUserTable') = 1
and f.data_space_id = i.groupid
and f.data_space_id = d.data_space_id
and f.data_space_id = s.data_space_id
order by f.name,object_name(i.id),groupid
go
