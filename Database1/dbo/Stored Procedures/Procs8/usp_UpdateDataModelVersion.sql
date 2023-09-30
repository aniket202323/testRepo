-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- Update the dbo.DataModelInfo table for the given schema name.


--DROP PROCEDURE [dbo].[usp_UpdateDataModelVersion]
--GO

CREATE PROCEDURE [dbo].[usp_UpdateDataModelVersion]
	@DataModelName          NVARCHAR(255),  -- the name of the schema to update/create
	@DataModelVersion       INT,           -- the updated version number
	@DataModelDescription   NVARCHAR(255), -- the schema description
	@debug               BIT = 0,       -- if 1, print debug statements
	@test                BIT = 0        -- if 1, do not actually add/update any records
AS
BEGIN

	DECLARE @trancount       INT         = @@TRANCOUNT
	DECLARE @loggingPrefix   VARCHAR(50) = 'usp_UpdateDataModelVersion: '
	DECLARE @trxName         VARCHAR(20) = '_UpdateDataModelVersion'
	DECLARE @existingVersion INT

	SET NOCOUNT ON

	IF (@debug = 1)
	BEGIN
		PRINT @loggingPrefix + 'DataModelName          : ' + @DataModelName
		PRINT @loggingPrefix + 'DataModelVersion       : ' + CONVERT(VARCHAR(5),@DataModelVersion)
		PRINT @loggingPrefix + 'DataModelDescription   : ' + @DataModelDescription
	END

	
	BEGIN try
		IF @trancount = 0
		BEGIN
			IF (@debug = 1) PRINT @loggingPrefix + 'BEGIN TRANSACTION'
			BEGIN TRANSACTION
		END
		ELSE
		BEGIN
			IF (@debug = 1) PRINT @loggingPrefix + 'SAVE TRANSACTION ' + @TrxName
			SAVE TRANSACTION @loggingPrefix
		END

		SELECT @existingVersion = [dbo].ufn_GetDataModelVersion(@DataModelName)

		IF (@existingVersion < 0)
		BEGIN
			PRINT 'Inserting DataModelInfo record for datamodel "' + @DataModelName + '", version ' + CONVERT(VARCHAR(50),@DataModelVersion)
			INSERT INTO [dbo].[DataModelInfo]  ([DataModel],[Description],[Version])
			VALUES (
				@DataModelName,
				@DataModelDescription,
				@DataModelVersion
			)
		END
		ELSE
		BEGIN
			PRINT 'Updating DataModelInfo record for datamodel "' + @DataModelName + '" to version ' + CONVERT(VARCHAR(50),@DataModelVersion)
			UPDATE [dbo].[DataModelInfo]  
				SET [Version] = @DataModelVersion,
					[Description] = @DataModelDescription				 
				WHERE [DataModel] = @DataModelName
		END
		-- Commit work
		IF (@debug = 1) PRINT @loggingPrefix + 'Trancount = ' + convert(VARCHAR(5),@trancount)
		IF (@trancount = 0)
		BEGIN
		IF (@test = 0)
		BEGIN
			IF (@debug = 1) PRINT @loggingPrefix + 'COMMIT'
			COMMIT
		END
		ELSE
		BEGIN
			IF (@debug = 1) PRINT @loggingPrefix + 'Just testing, ROLLBACK'
			ROLLBACK
		END
		END

	END try
	BEGIN catch
		DECLARE @error   INT = ERROR_NUMBER()
		DECLARE @xstate  INT = XACT_STATE()
		DECLARE @message VARCHAR(4000) = ERROR_MESSAGE()

		IF (@xstate = -1)
		BEGIN
			IF (@debug = 1) PRINT @loggingPrefix + 'ROLLBACK'
			ROLLBACK
		END
		IF (@xstate = 1 AND @trancount = 0)
		BEGIN
			IF (@debug = 1) PRINT @loggingPrefix + 'ROLLBACK'
			ROLLBACK
		END
		IF (@xstate = 1 AND @trancount > 0)
		BEGIN
			IF (@debug = 1) PRINT @loggingPrefix + 'ROLLBACK ' + @TrxName
			ROLLBACK TRANSACTION TrxName
		END

		RAISERROR('%d: %s',16,1, @error, @message)
	END catch

	-- return success
	RETURN 0
END