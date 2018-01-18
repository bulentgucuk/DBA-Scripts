SET XACT_ABORT ON;
SET NOCOUNT ON;
BEGIN TRY
    BEGIN TRANSACTION;
        -- SQL statement goes here
		



	-- If statement succeeds, commit the transaction.	
	COMMIT TRANSACTION;


END TRY
BEGIN CATCH
	DECLARE	@ErrorNumber INT;
	DECLARE @ErrorSeverity INT;
	DECLARE	@ErrorState INT;
	DECLARE	@ErrorProcedure VARCHAR(128);
	DECLARE	@ErrorLine INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
        
    SELECT
		@ErrorNumber = ERROR_NUMBER(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
        @ErrorProcedure = ERROR_PROCEDURE(),
        @ErrorLine = ERROR_LINE(),
        @ErrorMessage = ERROR_MESSAGE();

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
    
	-- UNCOMMENT BELOW LINE IF ERROR DOES NOT NEED TO BE RAISED
    RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);

END CATCH;
GO