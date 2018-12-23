-- Grant permissions on functions
SELECT
	CASE
		WHEN type in ('tf','if') then 'GRANT SELECT ON ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.'  + QUOTENAME (name) + ' TO [PUBLIC];'
		WHEN type in ('fn') then 'GRANT EXECUTE ON ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.'  + QUOTENAME (name) + ' TO [PUBLIC];'
	END AS GrantStatment
		, *
FROM	sys.objects
WHERE	is_ms_shipped = 0
AND		type in ('tf','if') -- SELECT PERMISSION
OR		type IN ('FN') -- EXECUTE PERMISSION
OPTION(RECOMPILE);
