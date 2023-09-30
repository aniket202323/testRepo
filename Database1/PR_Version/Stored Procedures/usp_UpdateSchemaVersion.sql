-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- Update the PR_Version.SchemaVersion table for the given schema name.

--DROP PROCEDURE [PR_Projects].[usp_UpdateSchemaVersion]
--GO
CREATE PROCEDURE [PR_Version].[usp_UpdateSchemaVersion]
-- PARAMETERS
	@SchemaName          NVARCHAR(50),  -- the name of the schema to update/create
	@SchemaVersion       INT,           -- the updated version number
	@SchemaDescription   NVARCHAR(100), -- the schema description
	@PublisherVersion    NVARCHAR(50),  -- the ConnectDatabaseUtility.exe version
	@PublisherDescription  NVARCHAR(255) = '<NULL>', -- optional further description of the schema if desired
	@debug               BIT = 0,       -- if 1, print debug statements
   @test                BIT = 0        -- if 1, do not actually add/update any records
-- END PARAMETERS
AS
BEGIN

	DECLARE @trancount INT
	DECLARE @procName  VARCHAR(20) =  'spUpdateVersion: '
	DECLARE @trxName   VARCHAR(20) =  'UpdateVersion'
	DECLARE @message   VARCHAR(4000)
	DECLARE @existingVersion INT
	DECLARE @vPublisherDescription NVARCHAR(255)

	SET NOCOUNT ON

-- Handle nested transactions
   SET @trancount = @@trancount

	IF (@debug = 1)
	BEGIN
		PRINT @ProcName + 'SchemaName          : ' + @SchemaName
		PRINT @ProcName + 'SchemaVersion       : ' + CONVERT(VARCHAR(5),@SchemaVersion)
		PRINT @ProcName + 'SchemaDescription   : ' + @SchemaDescription
		PRINT @ProcName + 'PublisherVersion    : ' + @PublisherVersion
		PRINT @ProcName + 'PublisherDescription: ' + @PublisherDescription
	END

	-- If no publisher description provided, set to NULL
	IF (@PublisherDescription = '<NULL>') 
		SET @vPublisherDescription = NULL
	ELSE
		 SET @vPublisherDescription = @PublisherDescription

	BEGIN try
		IF @trancount = 0
		BEGIN
			IF (@debug = 1) PRINT @ProcName + 'BEGIN TRANSACTION'
			BEGIN TRANSACTION
		END
		ELSE
		BEGIN
			IF (@debug = 1) PRINT @ProcName + 'SAVE TRANSACTION ' + @TrxName
			SAVE TRANSACTION @ProcName
		END

		SELECT @existingVersion = [PR_Version].ufn_GetSchemaVersion (@SchemaName)

		IF (@existingVersion < 0)
		BEGIN
			PRINT 'Inserting version record for schema "' + @SchemaName + '", version ' + CONVERT(VARCHAR(50),@SchemaVersion)
			INSERT INTO [PR_Version].[SchemaVersion]  ([SchemaName],[SchemaVersion],[SchemaDescription],[PublisherVersion],[PublisherDescription])
			VALUES (
				@SchemaName,
				@SchemaVersion,
				@SchemaDescription,
				@PublisherVersion,
				@vPublisherDescription
			)
		END
		ELSE
		BEGIN
			PRINT 'Updating version record for schema "' + @SchemaName + '" to version ' + CONVERT(VARCHAR(50),@SchemaVersion)
			UPDATE [PR_Version].[SchemaVersion]  
				SET [SchemaVersion] = @SchemaVersion,
					 [SchemaDescription] = @SchemaDescription,
					 [PublisherVersion] = @PublisherVersion,
					 [PublisherDescription] = @vPublisherDescription,
					 [LastModifiedDate] = GETUTCDATE()
			 WHERE [SchemaName] = @SchemaName
		END
		-- Commit work
		IF (@debug = 1) PRINT @ProcName + 'Trancount = ' + convert(VARCHAR(5),@trancount)
		IF (@trancount = 0)
		BEGIN
			IF (@test = 0)
			BEGIN
				IF (@debug = 1) PRINT @ProcName + 'COMMIT'
				COMMIT
			END
			ELSE
			BEGIN
				IF (@debug = 1) PRINT @ProcName + 'Just testing, ROLLBACK'
				ROLLBACK
			END
		END

	END try
	BEGIN catch
		DECLARE @error   INT = ERROR_NUMBER()
		DECLARE @xstate  INT = XACT_STATE()
		SELECT @message = ERROR_MESSAGE()

		IF (@xstate = -1)
		BEGIN
			IF (@debug = 1) PRINT @ProcName + 'ROLLBACK'
			ROLLBACK
		END
		IF (@xstate = 1 AND @trancount = 0)
		BEGIN
			IF (@debug = 1) PRINT @ProcName + 'ROLLBACK'
			ROLLBACK
		END
		IF (@xstate = 1 AND @trancount > 0)
		BEGIN
			IF (@debug = 1) PRINT @ProcName + 'ROLLBACK ' + @TrxName
			ROLLBACK TRANSACTION TrxName
		END
		RAISERROR('%d: %s',16,1, @error, @message)
		END catch

		-- return success
		RETURN 0
END

/* END MODULE: UpdateVersion */