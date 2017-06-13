
------SCRIPT ----------------
--******TRANSACTIONAL REPLICATION******
 
DECLARE @SchemaOption binary(8)
DECLARE @intermediate binary(8)
DECLARE @OptionsInText varchar(4000)
SET @OptionsInText = '   **SCHEMA OPTIONS HERE ARE**  '
SET @OptionsInText = @OptionsInText + char(13) + '---------------------------------------'
 
----------------------------
--Set the schema_option value that you want to decrypt here
SET @schemaoption  = 0x00000000082350DD --<<<Your Schema Option here>>>     ---Replace the value here
------------------------------
SET NOCOUNT ON
SET @intermediate= cast(cast(@schemaoption as int) & 0x01 as binary(8))
      IF @intermediate = 0x0000000000000001
            SET @optionsinText = @optionsinText + char(13) + '0x01 - Generates the object creation script (CREATE TABLE, CREATE PROCEDURE, and so on). This value is the default for stored procedure articles.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x02 as binary(8))
      IF @intermediate = 0x0000000000000002
            SET @optionsinText = @optionsinText + char(13) + '0x02 - Generates the stored procedures that propagate changes for the article, if defined.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x04 as binary(8))
      IF @intermediate = 0x0000000000000004
            SET @optionsinText = @optionsinText + char(13) + '0x04 - Identity columns are scripted using the IDENTITY property.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x08 as binary(8))
      IF @intermediate = 0x0000000000000008
            SET @optionsinText = @optionsinText + char(13) + '0x08 - Replicate timestamp columns. If not set, timestamp columns are replicated as binary.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x10 as binary(8))
      IF @intermediate = 0x0000000000000010
            SET @optionsinText = @optionsinText + char(13) + '0x10 - Generates a corresponding clustered index. Even if this option is not set, indexes related to primary keys and unique constraints are generated if they are already defined on a published table.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x20 as binary(8))
      IF @intermediate = 0x0000000000000020
            SET @optionsinText = @optionsinText + char(13) + '0x20 - Converts user-defined data types (UDT) to base data types at the Subscriber. This option cannot be used when there is a CHECK or DEFAULT constraint on a UDT column, if a UDT column is part of the primary key, or if a computed column references a UDT column. Not supported for Oracle Publishers.'
 
SET @intermediate = cast(cast(@schemaoption as int) & 0x40 as binary(8))
      IF @intermediate = 0x0000000000000040
            SET @optionsinText = @optionsinText + char(13) + '0x40 - Generates corresponding nonclustered indexes. Even if this option is not set, indexes related to primary keys and unique constraints are generated if they are already defined on a published table.'
 
SET @intermediate = cast(cast(@schemaoption as int) & 0x80 as binary(8))
      IF @intermediate = 0x0000000000000080
             SET @optionsinText = @optionsinText + char(13) + '0x80 - Replicates primary key constraints. Any indexes related to the constraint are also replicated, even if options 0x10 and 0x40 are not enabled.'
 
SET @intermediate=  cast(cast(@schemaoption as int) & 0x100 as binary(8))
      IF @intermediate = 0x0000000000000100
             SET @optionsinText = @optionsinText + char(13) + '0x100 - Replicates user triggers on a table article, if defined. Not supported for Oracle Publishers.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x200  as binary(8))
      IF @intermediate = 0x0000000000000200
             SET @optionsinText = @optionsinText + char(13) + '0x200 - Replicates foreign key constraints. If the referenced table is not part of a publication, all foreign key constraints on a published table are not replicated. Not supported for Oracle Publishers.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x400  as binary(8))
      IF @intermediate = 0x0000000000000400
             SET @optionsinText = @optionsinText + char(13) + '0x400 - Replicates check constraints. Not supported for Oracle Publishers.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x800  as binary(8))
      IF @intermediate = 0x0000000000000800
             SET @optionsinText = @optionsinText + char(13) + '0x800 - Replicates defaults. Not supported for Oracle Publishers.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x1000  as binary(8))
      IF @intermediate = 0x0000000000001000
             SET @optionsinText = @optionsinText + char(13) + '0x1000 - Replicates column-level collation'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x2000  as binary(8))
      IF @intermediate = 0x0000000000002000
             SET @optionsinText = @optionsinText + char(13) + '0x2000 - Replicates extended properties associated with the published article source object. Not supported for Oracle Publishers'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x4000  as binary(8))
      IF @intermediate = 0x0000000000004000
             SET @optionsinText = @optionsinText + char(13) + '0x4000 - Replicates UNIQUE constraints. Any indexes related to the constraint are also replicated, even if options 0x10 and 0x40 are not enabled'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x8000  as binary(8))
      IF @intermediate = 0x0000000000008000
             SET @optionsinText = @optionsinText + char(13) + '0x8000 - This option is not valid for SQL Server 2005 Publishers'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x10000  as binary(8))
      IF @intermediate = 0x0000000000010000
             SET @optionsinText = @optionsinText + char(13) + '0x10000 - Replicates CHECK constraints as NOT FOR REPLICATION so that the constraints are not enforced during synchronization'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x20000  as binary(8))
      IF @intermediate = 0x0000000000020000
             SET @optionsinText = @optionsinText + char(13) + '0x20000 - Replicates FOREIGN KEY constraints as NOT FOR REPLICATION so that the constraints are not enforced during synchronization'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x40000  as binary(8))
      IF @intermediate = 0x0000000000040000
             SET @optionsinText = @optionsinText + char(13) + '0x40000 - Replicates filegroups associated with a partitioned table or index'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x80000  as binary(8))
      IF @intermediate = 0x0000000000080000
             SET @optionsinText = @optionsinText + char(13) + '0x80000 - Replicates the partition scheme for a partitioned table'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x100000  as binary(8))
      IF @intermediate = 0x0000000000100000
             SET @optionsinText = @optionsinText + char(13) + '0x100000 - Replicates the partition scheme for a partitioned index'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x200000  as binary(8))
      IF @intermediate = 0x0000000000200000
             SET @optionsinText = @optionsinText + char(13) + '0x200000 - Replicates table statistics'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x400000  as binary(8))
      IF @intermediate = 0x0000000000400000
             SET @optionsinText = @optionsinText + char(13) + '0x400000 - Replicates default Bindings'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x800000  as binary(8))
      IF @intermediate = 0x0000000000800000
             SET @optionsinText = @optionsinText + char(13) + '0x800000 - Replicates rule Bindings'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x1000000  as binary(8))
      IF @intermediate = 0x0000000001000000
             SET @optionsinText = @optionsinText + char(13) + '0x1000000 - Replicates the full-text index'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x2000000  as binary(8))
      IF @intermediate = 0x0000000002000000
             SET @optionsinText = @optionsinText + char(13) + '0x2000000 - XML schema collections bound to xml columns are not replicated'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x4000000  as binary(8))
      IF @intermediate = 0x0000000004000000
             SET @optionsinText = @optionsinText + char(13) + '0x4000000 - Replicates indexes on xml columns'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x8000000  as binary(8))
      IF @intermediate = 0x0000000008000000
             SET @optionsinText = @optionsinText + char(13) + '0x8000000 - Creates any schemas not already present on the subscriber'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x10000000 as binary(8))
      IF @intermediate = 0x0000000010000000
             SET @optionsinText = @optionsinText + char(13) + '0x10000000 - Converts xml columns to ntext on the Subscriber'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x20000000 as binary(8))
      IF @intermediate = 0x0000000020000000
             SET @optionsinText = @optionsinText + char(13) + '0x20000000 - Converts large object data types introduced in SQL Server 2005 to data types supported on earlier versions of Microsoft SQL Server'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x40000000 as binary(8))
      IF @intermediate = 0x0000000040000000
             SET @optionsinText = @optionsinText + char(13) + '0x40000000 - Replicates permissions'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x80000000 as binary(8))
      IF @intermediate = 0x0000000080000000
             SET @optionsinText = @optionsinText + char(13) + '0x80000000 - Attempts to drop dependencies to any objects that are not part of the publication'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x100000000 as binary(8))
      IF @intermediate = 0x0000000100000000
             SET @optionsinText = @optionsinText + char(13) + '0x100000000 - Use this option to replicate the FILESTREAM attribute if it is specified on varbinary(max) columns.'
 
SET @intermediate= cast(cast(@schemaoption as int) & 0x400000000 as binary(8))
      IF @intermediate = 0x0000000400000000
             SET @optionsinText = @optionsinText + char(13) + '0x400000000 - Replicates the compression option for data and indexes.'
            
SET @intermediate= cast(cast(@schemaoption as int) & 0x800000000 as binary(8))
      IF @intermediate = 0x0000000800000000
             SET @optionsinText = @optionsinText + char(13) + '0x800000000 - Set this option to store FILESTREAM data on its own filegroup at the Subscriber.'
            
SET @intermediate= cast(cast(@schemaoption as int) & 0x1000000000 as binary(8))
      IF @intermediate = 0x0000001000000000
             SET @optionsinText = @optionsinText + char(13) + '0x1000000000 - Converts common language runtime (CLR) user-defined types (UDTs) that are larger than 8000 bytes to varbinary(max).'
            
SET @intermediate= cast(cast(@schemaoption as int) & 0x2000000000 as binary(8))
      IF @intermediate = 0x0000002000000000
             SET @optionsinText = @optionsinText + char(13) + '0x2000000000 - Converts the hierarchyid data type to varbinary(max).'
            
SET @intermediate= cast(cast(@schemaoption as int) & 0x4000000000 as binary(8))
      IF @intermediate = 0x0000004000000000
             SET @optionsinText = @optionsinText + char(13) + '0x4000000000 - Replicates any filtered indexes on the table.'
            
SET @intermediate= cast(cast(@schemaoption as int) & 0x8000000000 as binary(8))
      IF @intermediate = 0x0000008000000000
             SET @optionsinText = @optionsinText + char(13) + '0x8000000000 - Converts the geography and geometry data types to varbinary(max).'
            
SET @intermediate= cast(cast(@schemaoption as int) & 0x10000000000 as binary(8))
      IF @intermediate = 0x0000010000000000
             SET @optionsinText = @optionsinText + char(13) + '0x10000000000 - Replicates indexes on columns of type geography and geometry.'
            
SET @intermediate= cast(cast(@schemaoption as int) & 0x20000000000 as binary(8))
      IF @intermediate = 0x0000020000000000
             SET @optionsinText = @optionsinText + char(13) + '0x20000000000 - Replicates the SPARSE attribute for columns.'
 
--Print the result now
PRINT @optionsinText
----END OF SCRIPT --------------