SELECT message, message_time, em.package_name, event_name, message_source_name, em.package_path, em.execution_path, em.event_message_id,operation_id, * 
FROM ssisdb.catalog.executions e WITH (NOLOCK)
LEFT JOIN SSISDB.catalog.event_messages em WITH (NOLOCK) ON e.execution_id = em.operation_id
WHERE  event_name = 'onerror' 
AND em.message_time > '2019-02-05 05:00:07.1610477 +00:00'
AND em.message_time < '2019-02-05 05:30:07.1610477 +00:00'
ORDER BY 2 DESC