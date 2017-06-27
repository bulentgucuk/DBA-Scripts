
--ALTER PROCEDURE dbo.dbaGenerateIndexesScript
--(

DECLARE
    @IncludeFileGroup  bit = 1,
    @IncludeDrop       bit = 1,
    @IncludeFillFactor bit = 1

--)
--AS

BEGIN
    -- Get all existing indexes, but NOT the primary keys
    DECLARE Indexes_cursor CURSOR
        FOR SELECT SC.Name          AS      SchemaName,
                   SO.Name          AS      TableName,
                   SI.OBJECT_ID     AS      TableId,
                   SI.[Name]         AS  IndexName,
                   SI.Index_ID       AS  IndexId,
                   FG.[Name]       AS FileGroupName,
                   CASE WHEN SI.Fill_Factor = 0 THEN 100 ELSE SI.Fill_Factor END  Fill_Factor
              FROM sys.indexes SI
              LEFT JOIN sys.filegroups FG
                     ON SI.data_space_id = FG.data_space_id
              INNER JOIN sys.objects SO
                      ON SI.OBJECT_ID = SO.OBJECT_ID
              INNER JOIN sys.schemas SC
                      ON SC.schema_id = SO.schema_id
             WHERE OBJECTPROPERTY(SI.OBJECT_ID, 'IsUserTable') = 1
               AND SI.[Name] IS NOT NULL
               AND SI.is_primary_key = 0
               AND SI.is_unique_constraint = 0
               AND INDEXPROPERTY(SI.OBJECT_ID, SI.[Name], 'IsStatistics') = 0
			-- AND SI.data_space_id = 1  To return only the indexes on specific filegroup
             ORDER BY OBJECT_NAME(SI.OBJECT_ID), SI.Index_ID

    DECLARE @SchemaName     sysname
    DECLARE @TableName      sysname
    DECLARE @TableId        int
    DECLARE @IndexName      sysname
    DECLARE @FileGroupName  sysname
    DECLARE @IndexId        int
    DECLARE @FillFactor     int

    DECLARE @NewLine nvarchar(4000)
    SET @NewLine = char(13) + char(10)
    DECLARE @Tab  nvarchar(4000)
    SET @Tab = SPACE(4)

    -- Loop through all indexes
    OPEN Indexes_cursor

    FETCH NEXT
     FROM Indexes_cursor
     INTO @SchemaName, @TableName, @TableId, @IndexName, @IndexId, @FileGroupName, @FillFactor

    WHILE (@@FETCH_STATUS = 0)
        BEGIN

            DECLARE @sIndexDesc nvarchar(4000)
            DECLARE @sCreateSql nvarchar(4000)
            DECLARE @sDropSql           nvarchar(4000)

            SET @sIndexDesc = '-- Index ' + @IndexName + ' on table ' + @TableName
            SET @sDropSql = 'IF EXISTS(SELECT 1' + @NewLine
                          + '            FROM sysindexes si' + @NewLine
                          + '            INNER JOIN sysobjects so' + @NewLine
                          + '                   ON so.id = si.id' + @NewLine
                          + '           WHERE si.[Name] = N''' + @IndexName + ''' -- Index Name' + @NewLine
                          + '             AND so.[Name] = N''' + @TableName + ''')  -- Table Name' + @NewLine
                          + 'BEGIN' + @NewLine
                          + '    DROP INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + ']' + @NewLine
                          + 'END' + @NewLine

            SET @sCreateSql = 'CREATE '

            -- Check if the index is unique
            IF (IndexProperty(@TableId, @IndexName, 'IsUnique') = 1)
                BEGIN
                    SET @sCreateSql = @sCreateSql + 'UNIQUE '
                END
            --END IF
            -- Check if the index is clustered
            IF (IndexProperty(@TableId, @IndexName, 'IsClustered') = 1)
                BEGIN
                    SET @sCreateSql = @sCreateSql + 'CLUSTERED '
                END
            --END IF

            SET @sCreateSql = @sCreateSql + 'INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + ']' + @NewLine + '(' + @NewLine

            -- Get all columns of the index
            DECLARE IndexColumns_cursor CURSOR
                FOR SELECT SC.[Name],
                           IC.[is_included_column],
                           IC.is_descending_key
                      FROM sys.index_columns IC
                     INNER JOIN sys.columns SC
                             ON IC.OBJECT_ID = SC.OBJECT_ID
                            AND IC.Column_ID = SC.Column_ID
                     WHERE IC.OBJECT_ID = @TableId
                       AND Index_ID = @IndexId
                     ORDER BY IC.[is_included_column],
                              IC.key_ordinal

            DECLARE @IxColumn      sysname
            DECLARE @IxIncl        bit
            DECLARE @Desc          bit
            DECLARE @IxIsIncl      bit
            SET @IxIsIncl = 0
            DECLARE @IxFirstColumn   bit
            SET @IxFirstColumn = 1

            -- Loop through all columns of the index and append them to the CREATE statement
            OPEN IndexColumns_cursor
            FETCH NEXT
             FROM IndexColumns_cursor
             INTO @IxColumn, @IxIncl, @Desc

            WHILE (@@FETCH_STATUS = 0)
                BEGIN
                    IF (@IxFirstColumn = 1)
                        BEGIN
                            SET @IxFirstColumn = 0
                        END
                    ELSE
                        BEGIN
                            --check to see if it's an included column
                            IF (@IxIsIncl = 0) AND (@IxIncl = 1)
                                BEGIN
                                    SET @IxIsIncl = 1
                                    SET @sCreateSql = @sCreateSql + @NewLine + ')' + @NewLine + 'INCLUDE' + @NewLine + '(' + @NewLine
                                END
                            ELSE
                                BEGIN
                                    SET @sCreateSql = @sCreateSql + ',' + @NewLine
                                END
                            --END IF
                        END
                    --END IF

                    SET @sCreateSql = @sCreateSql + @Tab + '[' + @IxColumn + ']'
                    -- check if ASC or DESC
                    IF @IxIsIncl = 0
                        BEGIN
                            IF @Desc = 1
                                BEGIN
                                    SET @sCreateSql = @sCreateSql + ' DESC'
                                END
                            ELSE
                                BEGIN
                                    SET @sCreateSql = @sCreateSql + ' ASC'
                                END
                            --END IF
                        END
                    --END IF
                    FETCH NEXT
                     FROM IndexColumns_cursor
                     INTO @IxColumn, @IxIncl, @Desc
                END
            --END WHILE
            CLOSE IndexColumns_cursor
            DEALLOCATE IndexColumns_cursor

            SET @sCreateSql = @sCreateSql + @NewLine + ') '

            IF @IncludeFillFactor = 1
                BEGIN
                    SET @sCreateSql = @sCreateSql + @NewLine + 'WITH (FillFactor = ' + CAST(@FillFactor AS varchar(13)) + ')' + @NewLine
                END
            --END IF

            IF @IncludeFileGroup = 1
                BEGIN
                    SET @sCreateSql = @sCreateSql + 'ON ['+ @FileGroupName + ']' + @NewLine
                END
            ELSE
                BEGIN
                    SET @sCreateSql = @sCreateSql + @NewLine
                END
            --END IF

            PRINT '-- **********************************************************************'
            PRINT @sIndexDesc
            PRINT '-- **********************************************************************'

            IF @IncludeDrop = 1
                BEGIN
                    PRINT @sDropSql
                    PRINT 'GO'
                END
            --END IF

            PRINT @sCreateSql
            PRINT 'GO' + @NewLine  + @NewLine

            FETCH NEXT
             FROM Indexes_cursor
             INTO @SchemaName, @TableName, @TableId, @IndexName, @IndexId, @FileGroupName, @FillFactor
        END
    --END WHILE
    CLOSE Indexes_cursor
    DEALLOCATE Indexes_cursor

END
GO



