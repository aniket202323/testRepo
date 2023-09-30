-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: [PR_Personnel].usp_VerifyMigration

-- Top-level stored procedure to call all verify migration stored procedures

CREATE PROCEDURE [PR_Personnel].[usp_VerifyMigration]
	@debug BIT = 1,                    -- if 1, print out all statements before executing
	@test  BIT = 0                     -- if 1, do not make any changes
AS
	SET NOCOUNT ON

	DECLARE @loggingPrefix VARCHAR(50) = '[PR_Personnel].usp_VerifyMigration: '

	DECLARE	@transactionCount INT = @@trancount
	BEGIN TRY
		IF @transactionCount = 0
		BEGIN
			IF (@debug = 1) PRINT @LoggingPrefix + 'BEGIN TRANSACTION'
			BEGIN TRANSACTION
		END

		-- Call our verify stored procedures
		IF (@debug = 1)
		BEGIN
			PRINT @loggingPrefix + 'call our stored procedures'
		END
		
		EXEC [PR_Personnel].[usp_VerifyPersonMigration] @debug, @test		
		EXEC [PR_Personnel].[usp_VerifyPersonnelGroupMigration] @debug, @test
		EXEC [PR_Personnel].[usp_VerifyUserAccountMigration] @debug, @test
		EXEC [PR_Personnel].[usp_VerifyPersonAndGroupMigration] @debug, @test
		EXEC [PR_Personnel].[usp_VerifyPrivilegeMigration] @debug, @test
		-- if we are testing, ROLLBACK any changes
		IF (@test = 1)
		BEGIN
			IF (@transactionCount = 0)
			BEGIN
				IF (@debug = 1)
				BEGIN
					PRINT @loggingPrefix + 'In test mode, ROLLBACK'
				END
				ROLLBACK
			END
		END
		ELSE
		BEGIN
			IF (@transactionCount = 0)
			BEGIN
				-- Commit  
				IF (@debug = 1)
				BEGIN
					PRINT @loggingPrefix + 'COMMIT'
				END
				COMMIT
			END
		END
	END TRY
	BEGIN CATCH
		-- Collect info on the error and rollback
		DECLARE @error INT = ERROR_NUMBER()
		DECLARE @message VARCHAR(4000) = ERROR_MESSAGE()
		DECLARE @transactionState  INT = XACT_STATE()

		IF (@transactionState = -1)
		BEGIN
			IF (@debug = 1) PRINT @LoggingPrefix + 'ROLLBACK'
			ROLLBACK
		END
		IF (@transactionState = 1 AND @transactionCount = 0)
		BEGIN
			IF (@debug = 1) PRINT @LoggingPrefix + 'ROLLBACK'
			ROLLBACK
		END

		RAISERROR('%s: %d: %s',16,1, @LoggingPrefix, @error, @message)

	END CATCH
RETURN 0