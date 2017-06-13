
SELECT	'sys.' + name AS DmvName
FROM	sys.system_objects 
WHERE	name LIKE 'dm%';
GO 
