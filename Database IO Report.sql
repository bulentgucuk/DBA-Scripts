

-- total read and write activities by database
select db_name(mf.database_id) as database_name, mf.physical_name, 
left(mf.physical_name, 1) as drive_letter, 
vfs.num_of_writes, vfs.num_of_bytes_written, vfs.io_stall_write_ms, 
mf.type_desc, vfs.num_of_reads, vfs.num_of_bytes_read, vfs.io_stall_read_ms,
vfs.io_stall, vfs.size_on_disk_bytes
from sys.master_files mf
join sys.dm_io_virtual_file_stats(NULL, NULL) vfs
on mf.database_id=vfs.database_id and mf.file_id=vfs.file_id
order by vfs.num_of_bytes_written desc


-- total read and write activities of a logical drive
select left(mf.physical_name, 1) as drive_letter, sample_ms,
sum(vfs.num_of_writes) as total_num_of_writes, 
sum(vfs.num_of_bytes_written) as total_num_of_bytes_written, 
sum(vfs.io_stall_write_ms) as total_io_stall_write_ms, 
sum(vfs.num_of_reads) as total_num_of_reads, 
sum(vfs.num_of_bytes_read) as total_num_of_bytes_read, 
sum(vfs.io_stall_read_ms) as total_io_stall_read_ms, 
sum(vfs.io_stall) as total_io_stall, 
sum(vfs.size_on_disk_bytes) as total_size_on_disk_bytes
from sys.master_files mf
join sys.dm_io_virtual_file_stats(NULL, NULL) vfs
on mf.database_id=vfs.database_id and mf.file_id=vfs.file_id
group by left(mf.physical_name, 1), sample_ms
