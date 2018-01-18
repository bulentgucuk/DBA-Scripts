
/*
A checkpoint writes the current in-memory modified pages (known as dirty pages) 
and transaction log information from memory to disk and, also,
records information about the transaction log
*/
checkpoint
go

/*
Removes all elements from the procedure plan cache, 
*/
dbcc freeproccache
go

/*
Use DBCC DROPCLEANBUFFERS to test queries with a cold buffer cache without shutting down and restarting the server.
To drop clean buffers from the buffer pool, first use CHECKPOINT to produce a cold buffer cache. 
This forces all dirty pages for the current database to be written to disk and cleans the buffers. 
After you do this, you can issue DBCC DROPCLEANBUFFERS command to remove all buffers from the buffer pool.
*/
dbcc dropcleanbuffers
