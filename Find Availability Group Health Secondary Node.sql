USE master;
SET NOCOUNT ON;
SELECT TOP 1
	  cn.node_name
	--, rs.role_desc
	--, rs.synchronization_health
	--, rs.synchronization_health_desc
	--, cs.replica_server_name
	--, rs.role
FROM	sys.dm_hadr_availability_replica_states AS RS
	INNER JOIN sys.dm_hadr_availability_replica_cluster_states AS CS ON rs.replica_id = cs.replica_id
	INNER JOIN sys.dm_hadr_availability_replica_cluster_nodes AS CN ON cs.replica_server_name = CN.replica_server_name
WHERE	rs.role = 2
AND		rs.synchronization_health = 2;
