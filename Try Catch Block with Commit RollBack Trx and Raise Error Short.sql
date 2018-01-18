SET XACT_ABORT ON;
SET NOCOUNT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    -- SQL statement goes here
		



	-- If statement succeeds, commit the transaction.	
	COMMIT TRANSACTION;

END TRY
BEGIN CATCH
	DECLARE	
		  @ErrorMessage NVARCHAR(4000)
		, @ErrorSeverity INT
		, @ErrorState INT;
        
    SELECT
		  @ErrorMessage = ERROR_MESSAGE()
		, @ErrorSeverity = ERROR_SEVERITY()
		, @ErrorState = ERROR_STATE();

    -- Test XACT_STATE for 0, 1, or -1.
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- If 0 means there is no transaction and a commit or rollback operation would generate an error.

    -- Test whether the transaction is uncommittable.
    IF (XACT_STATE()) = -1
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    -- Test whether the transaction is active and valid.
    IF (XACT_STATE()) = 1
    BEGIN
        COMMIT TRANSACTION;   
    END;
    
	-- RAISERROR
    RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);

END CATCH;
GO