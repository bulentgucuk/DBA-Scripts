select	--*,
		OBJECT_SCHEMA_NAME(object_id) as SchemaName,
		name,
		OBJECT_NAME(parent_object_id) as parentobject,
		type,
		type_desc,
		create_date,
		is_ms_shipped
from	sys.objects
where	is_ms_shipped = 0
order by type,name