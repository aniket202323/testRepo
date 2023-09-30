-- �2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PROCEDURE: [PR_Personnel].usp_MigrateData

-- Top-level stored procedure to migrate data from the ollowing Personnel tables
-- to their PR_Personnel equivalents.

CREATE PROCEDURE [PR_Personnel].usp_MigrateData
@debug BIT = 1,                    -- if 1, print out all statements before executing
@test  BIT = 0                     -- if 1, do not make any changes
AS 
BEGIN

	SET NOCOUNT ON

	DECLARE @loggingPrefix VARCHAR(50) = '[PR_Personnel].usp_MigrateData: '

	DECLARE	@transactionCount INT = @@trancount
	BEGIN try
		IF @transactionCount = 0
		BEGIN
			IF (@debug = 1) PRINT @LoggingPrefix + 'BEGIN TRANSACTION'
			BEGIN TRANSACTION
		END

		-- clear out target tables
		IF (@debug = 1)
		BEGIN
			PRINT @loggingPrefix + 'clear out target tables'
		END
		DELETE FROM [PR_Authorization].[Privilege]
		DELETE FROM [PR_Authorization].[UserGroupMember]
		DELETE FROM [PR_Authorization].[UserAccount]
		DELETE FROM [PR_Authorization].[UserGroup]
		DELETE FROM [PR_Authorization].[Person]

		IF (@debug = 1)
		BEGIN
			PRINT @loggingPrefix + 'execute data migration procedures'
		END
		-- execute the migration procedures
		EXEC [PR_Personnel].[usp_MigratePersonData] @debug, @test
		EXEC [PR_Personnel].[usp_MigrateUserAccountData] @debug, @test
		EXEC [PR_Personnel].[usp_MigratePersonnelGroupData] @debug, @test
		EXEC [PR_Personnel].[usp_MigratePersonAndGroupData] @debug, @test
		EXEC [PR_Personnel].[usp_MigratePersonnelPrivilegesData] @debug, @test

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

	END try
	BEGIN catch

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

	END catch
END