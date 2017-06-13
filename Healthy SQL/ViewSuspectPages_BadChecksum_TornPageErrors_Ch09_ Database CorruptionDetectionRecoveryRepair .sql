/*View stored history on suspect pages by querying the suspect_pages table, introduced in SQL Server 2005. */
SELECT * 
FROM msdb..suspect_pages; 
GO 
/* badchecksum and torn page errors by filtering by event type, as such: 
-- Select nonspecific 824, bad checksum, and torn page errors. */
SELECT * 
FROM msdb..suspect_pages 
WHERE (event_type = 1 OR event_type = 2 OR event_type = 3); 
GO 