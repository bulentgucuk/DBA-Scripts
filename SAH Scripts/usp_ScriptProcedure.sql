USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_ScriptProcedure]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[usp_ScriptProcedure]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_ScriptProcedure] (
  @ObjectID INT,
  @Name NVARCHAR(128),
  @SchemaID INT
) 
AS 

DECLARE 
  @code VARCHAR(MAX),
  @newLine CHAR(2)

SET @newLine = CHAR(13) + CHAR(10)

SET @code = 
    'USE [' + DB_NAME() + ']' + @newLine + 'GO' + @newLine + @newLine
    + 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = '
    + 'OBJECT_ID(N''[' + SCHEMA_NAME(@schemaID) + '].[' + @Name + ']'') ' 
    + 'AND type IN (N''U''))' + @newLine 
    + 'DROP PROCEDURE [' + SCHEMA_NAME(@schemaID) + '].[' + @name + ']' 
    + @newLine + @newLine + 'SET ANSI_NULLS ON' + @newLine + 'GO' 
    + @newLine + @newLine + 'SET QUOTED_IDENTIFIER ON' + @newLine + 'GO'
    + @newLine + @newLine
    + OBJECT_DEFINITION(@ObjectID) + @newLine + 'GO' 
    + @newLine + @newLine + 'SET ANSI_NULLS OFF' + @newLine + 'GO' 
    + @newLine + @newLine + 'SET QUOTED_IDENTIFIER OFF' + @newLine + 'GO'

WHILE @code <> ''
BEGIN
  PRINT LEFT(@code,8000)
  SET @code = SUBSTRING(@code, 8001, LEN(@code))
END

GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
