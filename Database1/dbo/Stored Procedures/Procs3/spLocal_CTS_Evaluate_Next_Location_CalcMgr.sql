
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Evaluate_Next_Location_CalcMgr
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-10-27-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Called by CalculationMgr
-- Description			: Evaluate location change
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-10-27		F. Bergeron				Initial Release 

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
	DECLARE 
	@Output VARCHAR(25)
	EXECUTE spLocal_CTS_Evaluate_Next_Location_CalcMgr
	@Output output,
	67492,
	1018702

	SELECT @Output
	Select * from event_details where pu_id = 8455
	Select * from event_details where event_id  = 986440

*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Evaluate_Next_Location_CalcMgr]
	@output						VARCHAR(25) OUTPUT,
	@ResultVarId				INTEGER,
	@ApplianceId				INTEGER




AS
BEGIN
	--=====================================================================================================================
	SET NOCOUNT ON;
	--=====================================================================================================================
	DECLARE 
	@TestId								INTEGER,
	@Status								VARCHAR(25),
	@Message							VARCHAR(255),
	@ApplianceIdTimestamp				DATETIME,
	@ApplianceIdPUId					INTEGER,
	@TopCommentId						INTEGER,
	@CommentId2							INTEGER,
	@UserId								INTEGER,
	@NewLocationPUIdVarId				INTEGER,
	@NewLocationPUId					INTEGER,
	@NewLocationPUIdEntryOn				DATETIME,
	@NewLocationPUDescVarId				INTEGER,
	@NewLocationPUDesc					VARCHAR(25),
	@NewLocationPUDescEntryOn			DATETIME,
	@NewLocationSerial					VARCHAR(25),
	@NewProcessOrderIdVarId				INTEGER,
	@NewProcessOrderId					INTEGER,
	@NewProcessOrderIdEntryOn			DATETIME,
	@NewProcessOrderDescVarId			INTEGER,
	@NewProcessOrderDesc				VARCHAR(25),
	@NewProcessOrderDescEntryOn			DATETIME,
	@ExecuteTransactionVarId			INTEGER,			
	@PathId								INTEGER
	-- For Variables result set (2)
	DECLARE
	@VUVarId				INTEGER,
	@VUPUId 				INTEGER,
	@VUUserId				INTEGER,
	@VUCanceled				INTEGER,
	@VUResult				VARCHAR(25),
	@VUResultOn				DATETIME,
	@VUTransactionType		INTEGER,
	@VUPostUpdate			INTEGER


	DECLARE @RSVariableUpdates TABLE
	(
		VUVarId					INTEGER,
		VUPUId					INTEGER,
		VUUserId				INTEGER,
		VUCanceled				INTEGER,
		VUResult				VARCHAR(25),
		VUResultOn				DATETIME,
		VUTransactionType		INTEGER,
		VUPostUpdate			INTEGER,
		VUSecondUserId			INTEGER,
		VUTransNum				INTEGER,
		VUEventId				INTEGER,
		VUArrayId				INTEGER,
		VUCommentId				INTEGER,
		VUEsignature			INTEGER
	)

	--------------------------------------------------------------------------------------------------------------------------------------
	-- GET APPLIANCE INFORMATION
	--------------------------------------------------------------------------------------------------------------------------------------
	
	SET @ApplianceIdTimestamp = (
								SELECT	timestamp 
								FROM	dbo.events WITH(NOLOCK) 
								WHERE	event_id = @ApplianceId
								)
	SET @ApplianceIdPUId = (
							SELECT	pu_id 
							FROM	dbo.events WITH(NOLOCK) 
							WHERE	event_id = @ApplianceId
							)

	--------------------------------------------------------------------------------------------------------------------------------------
	-- GET VARIABLE USING TEST NAME
	--------------------------------------------------------------------------------------------------------------------------------------

	-- DESTINATION LOCATION ID VAR ID ----------------------------------------------------------------------------------------------------
	SET @NewLocationPUIdVarId =
	(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @ApplianceIdPUId AND test_name = 'New location id')

	SET @NewLocationPUId = 
	(SELECT CAST(result AS INTEGER) FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewLocationPUIdVarId AND result_on = @ApplianceIdTimestamp)

	SET @NewLocationPUIdEntryOn = 
	(SELECT Entry_On FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewLocationPUIdVarId AND result_on = @ApplianceIdTimestamp)

	--------------------------------------------------------------------------------------------------------------------------------------
	-- DESTINATION LOCATION DESC VAR ID
	SET @NewLocationPUDescVarId =
	(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @ApplianceIdPUId AND test_name = 'New location desc')

	SET @NewLocationPUDesc = 
	(SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewLocationPUDescVarId AND result_on = @ApplianceIdTimestamp)
	
	SET @NewLocationPUDescEntryOn = 
	(SELECT Entry_on FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewLocationPUDescVarId AND result_on = @ApplianceIdTimestamp)
	--------------------------------------------------------------------------------------------------------------------------------------
	-- PROCESS ORDER ID VAR ID
	SET @NewProcessOrderIdVarId =
	(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @ApplianceIdPUId AND test_name = 'New process order Id')

	SET @NewProcessOrderId = 
	(SELECT CAST(result AS INTEGER) FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewProcessOrderIdVarId AND result_on = @ApplianceIdTimestamp)

	SET @NewProcessOrderIdEntryOn = 
	(SELECT Entry_on FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewProcessOrderIdVarId AND result_on = @ApplianceIdTimestamp)
	--------------------------------------------------------------------------------------------------------------------------------------
	-- PROCESS ORDER DESC VAR ID
	SET @NewProcessOrderDescVarId =
	(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @ApplianceIdPUId AND test_name = 'New process order desc')

	SET @NewProcessOrderDesc = 
	(SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewProcessOrderDescVarId AND result_on = @ApplianceIdTimestamp)

	SET @NewProcessOrderDescentryOn = 
	(SELECT Entry_on FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewProcessOrderDescVarId AND result_on = @ApplianceIdTimestamp)
	--------------------------------------------------------------------------------------------------------------------------------------
	-- EXECUTE TRANSACTION
	SET @ExecuteTransactionVarId =
	(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @ApplianceIdPUId AND test_name = 'Execute Transaction')
	--------------------------------------------------------------------------------------------------------------------------------------


	--------------------------------------------------------------------------------------------------------------------------------------
	-- SET LOCATION
	--------------------------------------------------------------------------------------------------------------------------------------
	IF @NewLocationPUId IS NULL AND @NewLocationPUDesc IS NOT NULL
	BEGIN

		SET @NewLocationPUId = (SELECT PU_id FROM dbo.prod_units_base WITH(NOLOCK) WHERE PU_Desc = @NewLocationPUDesc)
		SET @UserId =(	
						SELECT Entry_By 
						FROM	dbo.tests T WITH(NOLOCK)
								JOIN dbo.variables_base VB WITH(NOLOCK) 
									ON VB.var_id = T.var_id 
						WHERE	VB.var_id = COALESCE(@NewLocationPUIdVarId,@NewLocationPUDescVarId)
									AND T.Result_On = @ApplianceIdTimestamp
									AND T.entry_by > 50
					)
		INSERT INTO @RSVariableUpdates
		(
			VUVarId,
			VUPUId,
			VUUserId,	
			VUCanceled,	
			VUResult,		
			VUResultOn,			
			VUTransactionType,	
			VUPostUpdate,
			VUSecondUserId,
			VUTransNum,
			VUEventId,
			VUArrayId,
			VUCommentId,
			VUESignature
		)
		VALUES
		(
			@NewLocationPUIdVarId,
			@ApplianceIdPUId,
			@UserId,
			0,
			@NewLocationPUId,
			@ApplianceIdTimestamp,
			1,
			0,
			NULL,
			0,
			@ApplianceId,
			NULL,
			NULL,
			NULL
		)

			GOTO PROCESS_ORDER

	END

	IF @NewLocationPUId IS NOT NULL AND @NewLocationPUDesc IS NULL
	BEGIN
		SET @NewLocationPUDesc = (SELECT PU_desc FROM dbo.prod_units_base WITH(NOLOCK) WHERE PU_Id = @NewLocationPUId)

		SET @UserId =(	
						SELECT Entry_By 
						FROM	dbo.tests T WITH(NOLOCK)
								JOIN dbo.variables_base VB WITH(NOLOCK) 
									ON VB.var_id = T.var_id 
						WHERE	VB.var_id = COALESCE(@NewLocationPUIdVarId,@NewLocationPUIdVarId)
									AND T.Result_On = @ApplianceIdTimestamp
									AND T.entry_by > 50
					)

		INSERT INTO @RSVariableUpdates
		(
			VUVarId,
			VUPUId,
			VUUserId,	
			VUCanceled,	
			VUResult,		
			VUResultOn,			
			VUTransactionType,	
			VUPostUpdate,
			VUSecondUserId,
			VUTransNum,
			VUEventId,
			VUArrayId,
			VUCommentId,
			VUESignature
		)
		VALUES
		(
			@NewLocationPUDescVarId,
			@ApplianceIdPUId,
			@UserId,
			0,
			@NewLocationPUDesc,
			@ApplianceIdTimestamp,
			1,
			0,
			NULL,
			0,
			@ApplianceId,
			NULL,
			NULL,
			NULL
		)

		GOTO PROCESS_ORDER
	END

	IF @NewLocationPUId IS NOT NULL AND @NewLocationPUDesc IS NOT NULL
	BEGIN

		-- GET THE MOST RECENTLY UPDATED TEST
		IF @NewLocationPUDescEntryOn > @NewLocationPUIdEntryOn
		BEGIN
		--SELECT @NewLocationPUDesc

			SET @NewLocationPUId = (SELECT COALESCE(PU_id,-1) FROM dbo.prod_units_base WITH(NOLOCK) WHERE PU_Desc = @NewLocationPUDesc)
				

			SET @UserId =(	
							SELECT Entry_By 
							FROM	dbo.tests T WITH(NOLOCK)
									JOIN dbo.variables_base VB WITH(NOLOCK) 
										ON VB.var_id = T.var_id 
							WHERE	VB.var_id = @NewLocationPUDescVarId
										AND T.Result_On = @ApplianceIdTimestamp
										AND T.entry_by > 50
						)

			IF (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewLocationPUIdVarId AND result_on = @ApplianceIdTimestamp) <> COALESCE(@NewLocationPUId,-1)
			BEGIN

	
				INSERT INTO @RSVariableUpdates
				(
					VUVarId,
					VUPUId,
					VUUserId,	
					VUCanceled,	
					VUResult,		
					VUResultOn,			
					VUTransactionType,	
					VUPostUpdate,
					VUSecondUserId,
					VUTransNum,
					VUEventId,
					VUArrayId,
					VUCommentId,
					VUESignature
				)
				VALUES
				(
					@NewLocationPUIdVarId,
					@ApplianceIdPUId,
					@UserId,
					0,
					@NewLocationPUId,
					@ApplianceIdTimestamp,
					2,
					0,
					NULL,
					0,
					@ApplianceId,
					NULL,
					NULL,
					NULL
				)
				
				GOTO PROCESS_ORDER

			END
			ELSE
				GOTO PROCESS_ORDER
		END
		ELSE
		BEGIN
			SET @NewLocationPUDesc = (SELECT PU_Desc FROM dbo.prod_units_base WITH(NOLOCK) WHERE PU_Id = @NewLocationPUId)
			SET @UserId =(	
							SELECT Entry_By 
							FROM	dbo.tests T WITH(NOLOCK)
									JOIN dbo.variables_base VB WITH(NOLOCK) 
										ON VB.var_id = T.var_id 
							WHERE	VB.var_id = @NewLocationPUIdVarId
										AND T.Result_On = @ApplianceIdTimestamp
										--AND T.entry_by > 50
						)

			IF (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewLocationPUDescVarId AND result_on = @ApplianceIdTimestamp) <> @NewLocationPUDesc
			BEGIN

				INSERT INTO @RSVariableUpdates
				(
					VUVarId,
					VUPUId,
					VUUserId,	
					VUCanceled,	
					VUResult,		
					VUResultOn,			
					VUTransactionType,	
					VUPostUpdate,
					VUSecondUserId,
					VUTransNum,
					VUEventId,
					VUArrayId,
					VUCommentId,
					VUESignature
				)
				VALUES
				(
					@NewLocationPUDescVarId,
					@ApplianceIdPUId,
					@UserId,
					0,
					@NewLocationPUDesc,
					@ApplianceIdTimestamp,
					2,
					0,
					NULL,
					0,
					@ApplianceId,
					NULL,
					NULL,
					NULL
				)
				GOTO PROCESS_ORDER
			END
			ELSE
				GOTO PROCESS_ORDER
		END

	END


	--------------------------------------------------------------------------------------------------------------------------------------
	-- SET PROCESS ORDER
	--------------------------------------------------------------------------------------------------------------------------------------
	PROCESS_ORDER:


	SET @PathId =	(
					SELECT	PEP.path_Id
					FROM	dbo.prdExec_path_units PEPU WITH(NOLOCK)
							JOIN dbo.prdexec_paths PEP WITH(NOLOCK)
								ON PEP.path_id = PEPU.path_id
					WHERE	PEPU.PU_id = @NewLocationPUId
					)

	IF @NewProcessOrderId IS NOT NULL AND @NewProcessOrderDesc IS NULL
	BEGIN
		SET @NewProcessOrderDesc = (SELECT Process_order FROM dbo.production_plan WITH(NOLOCK) WHERE PP_id = @NewProcessOrderId AND path_id = @PathId)
		INSERT INTO @RSVariableUpdates
		(
			VUVarId,
			VUPUId,
			VUUserId,	
			VUCanceled,	
			VUResult,		
			VUResultOn,			
			VUTransactionType,	
			VUPostUpdate,
			VUSecondUserId,
			VUTransNum,
			VUEventId,
			VUArrayId,
			VUCommentId,
			VUESignature
		)
		VALUES
		(
			@NewProcessOrderDescVarId,
			@ApplianceIdPUId,
			@UserId,
			0,
			@NewProcessOrderDesc,
			@ApplianceIdTimestamp,
			1,
			0,
			NULL,
			0,
			@ApplianceId,
			NULL,
			NULL,
			NULL
		)
		GOTO EVALUATE

	END

	IF @NewProcessOrderId IS NULL AND @NewProcessOrderDesc IS NOT NULL
	BEGIN
		SET @NewProcessOrderId = (SELECT PP_ID FROM dbo.production_plan WITH(NOLOCK) WHERE process_order = @NewProcessOrderDesc AND path_id = @PathId)
		INSERT INTO @RSVariableUpdates
		(
			VUVarId,
			VUPUId,
			VUUserId,	
			VUCanceled,	
			VUResult,		
			VUResultOn,			
			VUTransactionType,	
			VUPostUpdate,
			VUSecondUserId,
			VUTransNum,
			VUEventId,
			VUArrayId,
			VUCommentId,
			VUESignature
		)
		VALUES
		(
			@NewProcessOrderIdVarId,
			@ApplianceIdPUId,
			@UserId,
			0,
			@NewProcessOrderId,
			@ApplianceIdTimestamp,
			1,
			0,
			NULL,
			0,
			@ApplianceId,
			NULL,
			NULL,
			NULL
		)
		GOTO EVALUATE
	END

	

	IF @NewProcessOrderId IS NOT NULL AND @NewProcessOrderDesc IS NOT NULL
	BEGIN
	-- GET THE MOST RECENTLY UPDATED TEST
		IF @NewProcessOrderDescEntryOn > @NewProcessOrderIdEntryOn
		BEGIN
			SET @NewProcessOrderId = (SELECT PP_ID FROM dbo.production_plan WITH(NOLOCK) WHERE process_order = @NewProcessOrderDesc AND path_id = @PathId)
			IF (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewProcessOrderIdVarId AND result_on = @ApplianceIdTimestamp) <> @NewProcessOrderId
			BEGIN
				INSERT INTO @RSVariableUpdates
				(
					VUVarId,
					VUPUId,
					VUUserId,	
					VUCanceled,	
					VUResult,		
					VUResultOn,			
					VUTransactionType,	
					VUPostUpdate,
					VUSecondUserId,
					VUTransNum,
					VUEventId,
					VUArrayId,
					VUCommentId,
					VUESignature
				)
				VALUES
				(
					@NewProcessOrderIdVarId,
					@ApplianceIdPUId,
					@UserId,
					0,
					@NewProcessOrderId,
					@ApplianceIdTimestamp,
					2,
					0,
					NULL,
					0,
					@ApplianceId,
					NULL,
					NULL,
					NULL
				)
				GOTO EVALUATE
			END
			ELSE
				GOTO EVALUATE
		END
		ELSE
		BEGIN
			SET @NewProcessOrderDesc = (SELECT Process_order FROM dbo.production_plan WITH(NOLOCK) WHERE PP_id = @NewProcessOrderId AND path_id = @PathId)
			IF (SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @NewProcessOrderDescVarId AND result_on = @ApplianceIdTimestamp) <> @NewProcessOrderDesc
			BEGIN
	
				INSERT INTO @RSVariableUpdates
				(
					VUVarId,
					VUPUId,
					VUUserId,	
					VUCanceled,	
					VUResult,		
					VUResultOn,			
					VUTransactionType,	
					VUPostUpdate,
					VUSecondUserId,
					VUTransNum,
					VUEventId,
					VUArrayId,
					VUCommentId,
					VUESignature
				)
				VALUES
				(
					@NewProcessOrderDescVarId,
					@ApplianceIdPUId,
					@UserId,
					0,
					@NewProcessOrderDesc,
					@ApplianceIdTimestamp,
					2,
					0,
					NULL,
					0,
					@ApplianceId,
					NULL,
					NULL,
					NULL
				)

				GOTO EVALUATE
			END
			ELSE
				GOTO EVALUATE
		END

	END
	

	EVALUATE:

	DECLARE @Location_Validation TABLE 
	(
		L_Status	INTEGER, -- -1 (REJECTED), 0(ACTION REQUIRED), 1 (ACCEPTED)
		L_Message	VARCHAR(500)
	)
	INSERT INTO @Location_Validation
	(
		L_Status,
		L_Message
	)
	SELECT  O_Status,
			O_Message
	FROM	dbo.fnLocal_CTS_Evaluate_Appliance_Movement(@ApplianceId,@NewLocationPUId,@NewProcessOrderId,@UserId)





--	SELECT * FROM @Location_Validation

	IF (SELECT L_status FROM @Location_Validation) = -1
	BEGIN
		SET @Status  = 'Rejected'
	END

	IF (SELECT L_status FROM @Location_Validation) = 0
	BEGIN
		SET @Status  = 'Conditional'
	END

	IF (SELECT L_status FROM @Location_Validation) = 1
	BEGIN
		SET @Status  = 'Accepted'
	END

	IF @NewLocationPUId IS NULL
	BEGIN
		SET @Status  = 'Location not selected'
	END

	SET @Message = (SELECT L_status FROM @Location_Validation)

	
	-- WRITE IN COMMENT
	/*
	IF EXISTS(SELECT test_id FROM dbo.tests WITH(NOLOCK) WHERE var_id = @ThisVarId AND Result_on = @ApplianceIdTimestamp)
	BEGIN
		SET @TopCommentId = (SELECT comment_id FROM dbo.tests WITH(NOLOCK) WHERE var_id = @ThisVarId AND Result_on = @ApplianceIdTimestamp)
		IF @TopCommentId IS NOT NULL
		BEGIN
			EXEC [dbo].[spLocal_CTS_CreateComment] @TopCommentId,@Message,@UserId,@CommentId2 OUTPUT
		END
	END
	ELSE
	BEGIN
			EXEC [dbo].[spLocal_CTS_CreateComment] NULL,@Message,@UserId,@CommentId2 OUTPUT
	END
	*/
/*

	EXEC dbo.spServer_DBMgrUpdTest2 
		@ResultVarId,				--Var_id
		@UserId	,					--User_id
		0,							--Cancelled
		@Status,					--New_result
		@ApplianceIdTimestamp,		--result_on
		NULL,						--Transnum
		@CommentId2,				--Comment_id
		NULL,						--ArrayId
		@ApplianceId,				--event_id
		@ApplianceIdPUId,			--Pu_id
		@TestId	OUTPUT,				--testId
		NULL,						--Entry_On
		NULL,
		NULL,
		NULL,
		NULL
*/


	-- RESULT SET
	IF NOT EXISTS(SELECT test_id FROM dbo.tests WITH(NOLOCK) WHERE var_id = @ResultVarId AND Result_on = @ApplianceIdTimestamp AND Result <> 'Executed')
	BEGIN
		SET @VUTransactionType = 1
	END
	ELSE
	BEGIN
		SET @VUTransactionType = 2
	END
			INSERT INTO @RSVariableUpdates
			(
				VUVarId,
				VUPUId,
				VUUserId,	
				VUCanceled,	
				VUResult,		
				VUResultOn,			
				VUTransactionType,	
				VUPostUpdate,
				VUSecondUserId,
				VUTransNum,
				VUEventId,
				VUArrayId,
				VUCommentId,
				VUESignature
			)
			VALUES
			(
				@ResultVarId,
				@ApplianceIdPUId,
				@UserId,
				0,
				@Status,
				@ApplianceIdTimestamp,
				@VUTransactionType,
				0,
				NULL,
				0,
				@ApplianceId,
				NULL,
				NULL,
				NULL
			)





	-- SET THE VALUE OF THE TRANSACTION RELEASE VARIABLE TO NA
	IF NOT EXISTS(SELECT test_id FROM dbo.tests WITH(NOLOCK) WHERE var_id = @ExecuteTransactionVarId AND Result_on = @ApplianceIdTimestamp)

	BEGIN
		SET @VUTransactionType = 1
	END
	ELSE
	BEGIN
		SET @VUTransactionType = 2
	END

	INSERT INTO @RSVariableUpdates
	(
		VUVarId,
		VUPUId,
		VUUserId,	
		VUCanceled,	
		VUResult,		
		VUResultOn,			
		VUTransactionType,	
		VUPostUpdate,
		VUSecondUserId,
		VUTransNum,
		VUEventId,
		VUArrayId,
		VUCommentId,
		VUESignature
	)
	VALUES
	(
		@ExecuteTransactionVarId,
		@ApplianceIdPUId,
		@UserId,
		0,
		'NA',
		@ApplianceIdTimestamp,
		@VUTransactionType,
		0,
		NULL,
		0,
		@ApplianceId,
		NULL,
		NULL,
		NULL
	)

	SELECT 2, * FROM @RSVariableUpdates

	SET @output = 'OK'




--=====================================================================================================================
	SET NOCOUNT OFF
--=====================================================================================================================
END

GRANT EXECUTE ON [dbo].[spLocal_CTS_Evaluate_Next_Location_CalcMgr] TO ctsWebService
GRANT EXECUTE ON [dbo].[spLocal_CTS_Evaluate_Next_Location_CalcMgr] TO comxclient