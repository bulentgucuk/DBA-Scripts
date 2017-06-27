
SELECT	NAME,
		physical_name AS current_file_location
FROM	sys.master_files
WHERE	NAME LIKE 'N%'