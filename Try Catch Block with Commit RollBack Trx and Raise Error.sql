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
    
	---- RAISERROR
    --RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);
	
	-- THROW ERROR
    THROW 50001, @ErrorMessage, @ErrorState;

END CATCH;
GO