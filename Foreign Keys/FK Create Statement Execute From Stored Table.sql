------------------------------------------------------------------------
--
--  This job step recreates foreign keys following the purging of data..
--
------------------------------------------------------------------------
USE NetQuoteDevCut
SET XACT_ABORT ON;
SET NOCOUNT ON
-- RECREATE FK CONSTRAINTS
DECLARE @MaxFKid INT,
		@TableName VARCHAR(256),
		@ReferencedTableName VARCHAR(256),
		@Str VARCHAR(1024)

SELECT	@MaxFKid = MAX(FKid)
FROM	dbo.FKCreate

WHILE	@MaxFKid > 0
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION;
				-- SQL statement goes here
				SELECT	@Str = '',
						@TableName = '',
						@ReferencedTableName = ''
				SELECT	@Str = [Str],
						@TableName = TableName,
						@ReferencedTableName = ReferencedTableName
				FROM	dbo.FKCreate
				WHERE	FKid = @MaxFKid
				
				IF OBJECT_ID(@TableName) IS NOT NULL AND OBJECT_ID(@ReferencedTableName) IS NOT NULL 
					BEGIN
						PRINT	@Str
						EXEC	(@Str)
					END
				SELECT	@MaxFKid = @MaxFKid - 1
			-- If statement succeeds, commit the transaction.	
			COMMIT TRANSACTION;

		END TRY
		BEGIN CATCH
			SELECT 
				ERROR_NUMBER() AS ErrorNumber,
				ERROR_SEVERITY() AS ErrorSeverity,
				ERROR_STATE() as ErrorState,
				ERROR_PROCEDURE() as ErrorProcedure,
				ERROR_LINE() as ErrorLine,
				ERROR_MESSAGE() as ErrorMessage;

			-- Test XACT_STATE for 0, 1, or -1.
			-- If 1, the transaction is committable.
			-- If -1, the transaction is uncommittable and should 
			--     be rolled back.
			-- XACT_STATE = 0 means there is no transaction and
			--     a commit or rollback operation would generate an error.

			-- Test whether the transaction is uncommittable.
			IF (XACT_STATE()) = -1
			BEGIN
				PRINT 'The transaction is in an uncommittable state.' +
					  ' Rolling back transaction.'
				ROLLBACK TRANSACTION;
			END;

			-- Test whether the transaction is active and valid.
			IF (XACT_STATE()) = 1
			BEGIN
				PRINT 'The transaction is committable.' + 
					  ' Committing transaction.'
				COMMIT TRANSACTION;   
			END;
		END CATCH;
	END
GO
