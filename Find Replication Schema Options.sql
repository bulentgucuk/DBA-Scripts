-- Find Replication Schema Options
DECLARE @schema_option VARBINARY(8) = 0x00000000082350DD; -- This is the replication schema option we want to find. Replace it with new option.
DECLARE @options TABLE (
	Value VARBINARY(8),
	[Description] VARCHAR(1000)
	)

INSERT INTO @options (Value, Description)
VALUES 
    (0x00, 'Disables scripting by the Snapshot Agent and uses creation_script.'),
    (0x01, 'Generates the object creation script (CREATE TABLE, CREATE PROCEDURE, and so on). This value is the default for stored procedure articles.'),
    (0x02, 'Generates the stored procedures that propagate changes for the article, if defined.'),
    (0x04, 'Identity columns are scripted using the IDENTITY property.'),
    (0x08, 'Replicate timestamp columns. If not set, timestamp columns are replicated as binary.'),
    (0x10, 'Generates a corresponding clustered index. Even if this option is not set, indexes related to primary keys and unique constraints are generated if they are already defined on a published table.'),
    (0x20, 'Converts user-defined data types (UDT) to base data types at the Subscriber. This option cannot be used when there is a CHECK or DEFAULT constraint on a UDT column, if a UDT column is part of the primary key, or if a computed column references a UDT column. Not supported for Oracle Publishers.'),
    (0x40, 'Generates corresponding nonclustered indexes. Even if this option is not set, indexes related to primary keys and unique constraints are generated if they are already defined on a published table.'),
    (0x80, 'Replicates primary key constraints. Any indexes related to the constraint are also replicated, even if options 0x10 and 0x40 are not enabled.'),
    (0x100, 'Replicates user triggers on a table article, if defined. Not supported for Oracle Publishers.'),
    (0x200, 'Replicates foreign key constraints. If the referenced table is not part of a publication, all foreign key constraints on a published table are not replicated. Not supported for Oracle Publishers.'),
    (0x400, 'Replicates check constraints. Not supported for Oracle Publishers.'),
    (0x800, 'Replicates defaults. Not supported for Oracle Publishers.'),
    (0x1000, 'Replicates column-level collation.'),
    (0x2000, 'Replicates extended properties associated with the published article source object. Not supported for Oracle Publishers.'),
    (0x4000, 'Replicates UNIQUE constraints. Any indexes related to the constraint are also replicated, even if options 0x10 and 0x40 are not enabled.'),
    (0x8000, 'This option is not valid for SQL Server 2005 Publishers.'),
    (0x10000, 'Replicates CHECK constraints as NOT FOR REPLICATION so that the constraints are not enforced during synchronization.'),
    (0x20000, 'Replicates FOREIGN KEY constraints as NOT FOR REPLICATION so that the constraints are not enforced during synchronization.'),
    (0x40000, 'Replicates filegroups associated with a partitioned table or index.'),
    (0x80000, 'Replicates the partition scheme for a partitioned table.'),
    (0x100000, 'Replicates the partition scheme for a partitioned index.'),
    (0x200000, 'Replicates table statistics.'),
    (0x400000, 'Default Bindings'),
    (0x800000, 'Rule Bindings'),
    (0x1000000, 'Full-text index'),
    (0x2000000, 'XML schema collections bound to xml columns are not replicated.'),
    (0x4000000, 'Replicates indexes on xml columns.'),
    (0x8000000, 'Create any schemas not already present on the subscriber.'),
    (0x10000000, 'Converts xml columns to ntext on the Subscriber.'),
    (0x20000000, 'Converts large object data types (nvarchar(max), varchar(max), and varbinary(max)) introduced in SQL Server 2005 to data types that are supported on SQL Server 2000. For information about how these types are mapped, see the "Mapping New Data Types for Earlier Versions" section in Using Multiple Versions of SQL Server in a Replication Topology.'),
    (0x40000000, 'Replicate permissions.'),
    (0x80000000, 'Attempt to drop dependencies to any objects that are not part of the publication.'),
    (0x100000000, 'Use this option to replicate the FILESTREAM attribute if it is specified on varbinary(max) columns. Do not specify this option if you are replicating tables to SQL Server 2005 Subscribers. Replicating tables that have FILESTREAM columns to SQL Server 2000 Subscribers is not supported, regardless of how this schema option is set. '),
    (0x200000000, 'Converts date and time data types (date, time, datetimeoffset, and datetime2) introduced in SQL Server 2008 to data types that are supported on earlier versions of SQL Server. For information about how these types are mapped, see the "Mapping New Data Types for Earlier Versions" section in Using Multiple Versions of SQL Server in a Replication Topology.'),
    (0x400000000, 'Replicates the compression option for data and indexes. For more information, see Creating Compressed Tables and Indexes.'),
    (0x800000000, 'Set this option to store FILESTREAM data on its own filegroup at the Subscriber. If this option is not set, FILESTREAM data is stored on the default filegroup. Replication does not create filegroups, therefore, if you set this option, you must create the filegroup before you apply the snapshot at the Subscriber. For more information about how to create objects before you apply the snapshot, see Executing Scripts Before and After the Snapshot Is Applied.'),
    (0x1000000000, 'Converts common language runtime (CLR) user-defined types (UDTs) that are larger than 8000 bytes to varbinary(max) so that columns of type UDT can be replicated to Subscribers that are running SQL Server 2005.'),
    (0x2000000000, 'Converts the hierarchyid data type to varbinary(max) so that columns of type hierarchyid can be replicated to Subscribers that are running SQL Server 2005. For more information about how to use hierarchyid columns in replicated tables, see hierarchyid (Transact-SQL).'),
    (0x4000000000, 'Replicates any filtered indexes on the table. For more information about filtered indexes, see Filtered Index Design Guidelines.'),
    (0x8000000000, 'Converts the geography and geometry data types to varbinary(max) so that columns of these types can be replicated to Subscribers that are running SQL Server 2005.'),
    (0x10000000000, 'Replicates indexes on columns of type geography and geometry.'),
    (0x20000000000, 'Replicates the SPARSE attribute for columns. For more information about this attribute, see Using Sparse Columns.')


SELECT CONVERT(INT, @schema_option, 1) & CONVERT(INT,value,1), *
FROM @options
WHERE CONVERT(INT, @schema_option, 1) & CONVERT(INT,value,1) <> 0;

