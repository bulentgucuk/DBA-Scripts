SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: Bulent Gucuk
-- Create date: 11/30/2010
-- Description: Return Comma Separated Strings as DataTable
-- =============================================
CREATE FUNCTION [dbo].[CommaSplit]
(
@InputString VARCHAR(MAX)
)
RETURNS
@OutputTable TABLE
(
-- Add the column definitions for the TABLE variable here
Val VARCHAR(MAX)
)
AS
BEGIN
-- Fill the table variable with the rows for your result set
DECLARE @Val VARCHAR(MAX),@Pos INT,@Len INT
SET @Len = LEN(@InputString)

SET @Pos=0
WHILE (CHARINDEX(',',@InputString,@Pos)-@Pos) > 0
BEGIN

SET @Val = SUBSTRING(@InputString,@Pos,(CHARINDEX(',',@InputString,@Pos)-@Pos))

INSERT INTO @OutputTable(Val)
SELECT @Val
SET @Pos = CHARINDEX(',',@InputString,@Pos)+1

END
IF @Pos <= @Len
BEGIN

SET @Val = SUBSTRING(@InputString,@Pos,(@Len+1)-@Pos)

INSERT INTO @OutputTable(Val)
SELECT @Val

END

RETURN
END

GO

SELECT * FROM dbo.CommaSplit('Bankrate,NetQuote,InsureMe')