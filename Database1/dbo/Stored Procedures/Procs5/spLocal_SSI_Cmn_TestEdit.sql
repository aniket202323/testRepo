--=====================================================================================================================
-- Store Procedure: 	spLocal_SSI_Cmn_TestEdit
-- Sp Type:				Stored Procedure
-- Editor Tab Spacing: 	4	
--=====================================================================================================================
--	This stored procedure will update a "Tests" record in the Proficy Plant Applications database and will compose a
--	resultset that contains the Transaction Message for MessageBus.  This SP will be called by many displays and will
--	be the preferred way to update information to the Tests table.  It will support Inserts, Edits and Deletes.
--	
--	The resultsets include:
--		1	2							All data required to allow the calling program to publish a message to the
--										PPA MessageBus.
-----------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who					What
--	==========	=====		===					====
--	1.0			2008-04-30	Brent Seely			Original Development.
--	1.1			2009-03-05	Luis Chaves			Removed Email Message functionality
--	1.3			2009-05-05	Luis Chaves			Use Implied Parameters for GE Fanuc spServer_DBMgrUpd procedures
--	2.0			2009-11-23	Luis Chaves			Major changes incorporated.
--												Updated Error Handling methodology which relies on new child components
--												The changes also resulted in modifications to the input	parameters
--												as follows;
--												Error Handling parameter changes:
--												Removed @nvchErrorMessage VARCHAR(1000) OUTPUT
--												Added @op_uidErrorId UNIQUEIDENTIFIER OUTPUT
--	2.1			2010-05-26	Renata Piedmont		LIBRARY-73: add @op_vchErrorMessage as an optional parameter to support 
--												backward compatibility
--												Updated comments
--	2.2			2010-12-14	Luis Chaves			Increased Error Section size to 100
--	2.3			2011-07-22	Karla Bolaños		Standardize Error Handling logic
--	2.4			2012-05-18	Karla Ramirez		spLocal_SSI_Cmn_TestEdit: Add logic to Error Trapping code at bottom of 
--												sp to only set @op_uidErrorId to NULL if there are no errors and the sp
--												is the primary sp i.e.@intPrimary = 1
--	2.5			2012-08-29	Renata Piedmont		LIBRARY-236: Added some comments  
--  2.6			2012-09-03	Renata Piedmont		LIBRARY-236: Added a comment to correct the version number
--  2.7			2012-09-06	Renata Piedmont		LIBRARY-236: Added a comment to correct the version number
--	2.8			2012-10-19	Luis Chaves			Added some extra code to verify that supplied Event_Id belongs to 
--												Prod_Event Type
--	2.9			2013-10-17	Alexandre Turgeon	LIBRARY-340: Fixed varid validation
--	3.0			2018-11-26	Alex Klusmeyer		When Checking If's A Production Event Variable.. Check Its an Actual
--												Production Event Event Type...
-----------------------------------------------------------------------------------------------------------------------
--	How to execute it: Example
-----------------------------------------------------------------------------------------------------------------------
/*
	DECLARE	
		@dtmResultOn	DATETIME		 ,
		@uidErrorId		UNIQUEIDENTIFIER ,
		@intReturnCode  INT
	SELECT	
		@dtmResultOn	=	GETDATE()	,
		@uidErrorId		=	NULL
	EXEC	
		@intReturnCode = dbo.spLocal_SSI_Cmn_TestEdit	
		@op_uidErrorId			= @uidErrorId	OUTPUT	,	
		@p_bitWriteDirect		= 1						,						
		@p_intTransactionType	= 1						,	
		@p_intUserId			= NULL					,	
		@p_intVarId				= 1						,	
		@p_intEventId			= NULL					,
		@p_dtmResultOn			= @dtmResultOn			,	
		@p_vchResult			= 50					,	
		@p_dtmEntryOn			= NULL					,	
		@p_intArrayId			= NULL					,	
		@p_intCanceled			= 0						,
		@p_intCommentId			= NULL					,	
		@p_intLocked			= NULL					,	
		@p_intSecondUserId		= NULL					,	
		@p_intSignatureId		= NULL					
	IF	@intReturnCode	<>	0
	BEGIN
		SELECT *
		FROM dbo.fnLocal_SSI_Cmn_ErrorMessageByUniqueId (@uidErrorId)
	END
*/
--=====================================================================================================================
--	NOTE1:	If Transaction type = 2 OR 3 is used (which means UPDATE OR DELETE will be executed) it's REQUIRED to
--			fill the field @dtmResultOn with the same value of the Row that you want to update or delete.
--=====================================================================================================================
CREATE	PROCEDURE	[dbo].[spLocal_SSI_Cmn_TestEdit]
	@op_uidErrorId			UNIQUEIDENTIFIER	= NULL	OUTPUT,	--	Used for error handling
	@op_vchErrorMessage		VARCHAR(1000)		= NULL	OUTPUT,	--	An Output Parameter which will return any error messages.
																--	it is a VARCHAR(1000) because this is what it was before
																--	error handling was introduced
																--	eventually it should be changed to NVARCHAR(2048) to match 
																--	the table field datatype
	@p_bitWriteDirect		BIT					= 0		,
	@p_intTransactionType	INT					 		,	--	1 = INSERT; 2 = EDIT; 3 = DELETE
	@p_intUserId			INT					= NULL	,
	@p_intVarId				INT							,
	@p_intEventId			INT					= NULL	,
	@p_dtmResultOn			DATETIME			= NULL	,
	@p_vchResult			VARCHAR(25)			= NULL	,
	@p_dtmEntryOn			DATETIME			= NULL	,
	@p_intArrayId			INT					= NULL	,
	@p_intCanceled			INT					= 0		,
	@p_intCommentId			INT					= NULL	,
	@p_intLocked			INT					= NULL	,
	@p_intSecondUserId		INT					= NULL	,
	@p_intSignatureId		INT					= NULL	,
	@p_TemporalAccuracy		INT					= 0			-- 0 For Truncation of ms (backwards compatible)
															-- 1 To Preserve ms precision
AS
--=====================================================================================================================
--	Define all variables.
--=====================================================================================================================
DECLARE	@bitIsEventType		BIT	,
		@intPUId			INT	,	--	Production Unit
		@intTestId			INT	,	--	Table Key
		@PROD_EVENT_TYPE	INT
--=====================================================================================================================
--	The following variables are used for error handling logic
--=====================================================================================================================
DECLARE	@intReturnCode		INT	,	--	Temp variable to store the result of the
									--	Store Procedure "dbo.spServer_DBMgrUpdTest2"
		@intNestingLevel	INT	,
		@intPrimary			INT	,
		@intErrorSeverity	INT	,
		@consErrorCritical	INT	,
		@consErrorWarning	INT	,
		@consErrorInfo		INT	,
		@consErrorNone		INT	,
		@intErrorState		INT	,
		@vchNestedObject	VARCHAR(256)	,
		@vchObjectName		VARCHAR(256)	,
		@nvchErrorMessage	NVARCHAR(2048)	,
		@vchErrorSection	VARCHAR(100)
--=====================================================================================================================
--	Set constants used for error handling
--=====================================================================================================================
SELECT	@consErrorCritical	= -1	,
		@consErrorNone		= 0		,
		@consErrorWarning	= 1		,
		@consErrorInfo		= 2		,
		@intErrorSeverity	= 11	,
		@intErrorState		= 1
--=====================================================================================================================
--	Initialize all variables.
--=====================================================================================================================
SELECT	@intPUId			= NULL	,
		@intTestId			= NULL	,
		@intReturnCode		= NULL	,
		@bitIsEventType		= 0		,
		@PROD_EVENT_TYPE	= 1
--=====================================================================================================================
--	Initialize all variables.  The only items hard-coded within this stored procedure are items that are specific to this
--	application and are unlikely to be used by any other application.  Acceptable items are Variable Aliases and Display
--	Option Descriptions.
--=====================================================================================================================
SELECT	@p_dtmEntryOn		=	COALESCE(@p_dtmEntryOn, GETDATE())			,
		@p_bitWriteDirect	=	COALESCE(@p_bitWriteDirect	,	0)			,
		@p_intCanceled		=	COALESCE(@p_intCanceled		,	0)

IF	@p_TemporalAccuracy	=	0
BEGIN
	SET	@p_dtmResultOn		=	CONVERT(VARCHAR(25), @p_dtmResultOn, 120)
END
ELSE IF	@p_TemporalAccuracy	=	1
BEGIN
	--	@p_dtmResultOn is left as input, in DATETIME format precise to the millisecond
	SET	@p_dtmResultOn	=	@p_dtmResultOn
END
--=====================================================================================================================
--	The @op_uidErrorId parameter is used to determine if the SP has been called by another SP.  If the value is null
--	then it is assumed that this SP is the top level SP.
--	
--	If it is the top level SP then get a unique identifier that will be used to log error messages and set the flag to
--	indicate that this SP is the primary SP.
--=====================================================================================================================
IF	@op_uidErrorId IS NULL
BEGIN
	SELECT	@op_uidErrorId	= NEWID(),
			@intPrimary		= 1
END
ELSE
BEGIN
	SELECT	@intPrimary = 0
END
BEGIN TRY
	--=================================================================================================================
	--	Validate the inputs.
	--	Use the clause WITH (NO LOCK) because that way it is possible to read data without using dirty read on the most
	--	common tables, which means that a lot of process access these tables.
	--=================================================================================================================
	SELECT	@vchErrorSection = 'Input Validation'
	BEGIN TRY
		---------------------------------------------------------------------------------------------------------------
		--	Array Id.
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intArrayId IS NOT NULL
		BEGIN
			IF	NOT EXISTS	(
								SELECT	*
								FROM	dbo.Array_Data	WITH (NOLOCK)
								WHERE	Array_Id = @p_intArrayId
							)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Array Id is invalid.  ArrayId = '
												+ COALESCE(CONVERT(VARCHAR(25), @p_intArrayId), '')
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Comment Id.
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intCommentId IS NOT NULL
		BEGIN
			IF	NOT EXISTS	(
								SELECT	*
								FROM	dbo.Comments	WITH (NOLOCK)
								WHERE	Comment_Id = @p_intCommentId
							)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Comment Id is invalid.  CommentId = '
												+ COALESCE(CONVERT(VARCHAR(25), @p_intCommentId), '')
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	EntryBy.
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intUserId IS NOT NULL
		BEGIN
			IF	NOT EXISTS	(
								SELECT	*
								FROM	dbo.Users	WITH (NOLOCK)
								WHERE	User_Id = @p_intUserId
							)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Entry By is invalid.  EntryBy = '
												+ COALESCE(CONVERT(VARCHAR(25), @p_intUserId), '')
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	VarId.
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intVarId IS NOT NULL
		BEGIN
			IF	NOT EXISTS	(
								SELECT	*
								FROM	dbo.Variables	WITH (NOLOCK)
								WHERE	Var_Id = @p_intVarId
							)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Var Id is invalid.  VarId = '
												+ COALESCE(CONVERT(VARCHAR(25), @p_intVarId), '')
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
			-----------------------------------------------------------------------------------------------------------
			--	Check if variable is of Type Production_Event
			-----------------------------------------------------------------------------------------------------------
			IF	EXISTS	(
							SELECT	1
							FROM	dbo.Variables	WITH(NOLOCK)
							WHERE	Var_Id = @p_intVarId
							AND		Event_Type	=	@PROD_EVENT_TYPE
						)
			BEGIN
				SELECT	@bitIsEventType	= 1
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	EventId.
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intEventId IS NOT NULL
		AND	@bitIsEventType = 1
		BEGIN
			IF	NOT EXISTS	(
								SELECT	*
								FROM	dbo.Events	WITH (NOLOCK)
								WHERE	Event_Id = @p_intEventId
							)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Event Id is invalid.  Event Id = '
												+ COALESCE(CONVERT(VARCHAR(25), @p_intEventId), '')
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	SecondUserId.
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intSecondUserId IS NOT NULL
		BEGIN
			IF	NOT EXISTS	(
								SELECT	*
								FROM	dbo.Users	WITH (NOLOCK)
								WHERE	User_Id = @p_intSecondUserId
							)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Second User Id is invalid.  SecondUserId = '
												+ COALESCE(CONVERT(VARCHAR(25), @p_intSecondUserId), '')
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	SignatureId.
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intSignatureId IS NOT NULL
		BEGIN
			IF	NOT EXISTS	(
								SELECT	*
								FROM	dbo.Users	WITH (NOLOCK)
								WHERE	User_Id = @p_intSignatureId
							)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Signature Id is invalid.  SignatureId = '
												+ COALESCE(CONVERT(VARCHAR(25), @p_intSignatureId), '')
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	TransactionType.
		---------------------------------------------------------------------------------------------------------------
		IF	NOT	@p_intTransactionType BETWEEN 1 AND 3
		BEGIN
			SELECT	@nvchErrorMessage	= 'Supplied Transaction Type is invalid.  It must be 1, 2 or 3.  TransactionType = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intTransactionType), '')
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	ResultOn.
		---------------------------------------------------------------------------------------------------------------
		IF @p_dtmResultOn IS NULL
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Try to figure out the Result On from the Events table if the Event Id was passed
			-----------------------------------------------------------------------------------------------------------
			IF @p_intEventId IS NOT NULL
			BEGIN
				IF (SELECT	Event_Type FROM Variables WHERE Var_Id = @p_intVarId AND Event_Type = @PROD_EVENT_TYPE) = 1
				BEGIN
					SELECT	@p_dtmResultOn	=	Timestamp
					FROM	dbo.Events	WITH	(NOLOCK)
					WHERE	Event_Id		=	@p_intEventId
				END
			END
			IF	@p_dtmResultOn	IS	NULL
			BEGIN
				SELECT	@nvchErrorMessage	= 'SP Call failed to provided a Time for @p_dtmResultOn or @p_intEventId, one '
												+ 'of which is required'
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
	END TRY
	BEGIN CATCH
		---------------------------------------------------------------------------------------------------------------
		--	Set error message
		---------------------------------------------------------------------------------------------------------------
		SELECT	@nvchErrorMessage	= COALESCE(@nvchErrorMessage, ERROR_MESSAGE())
		---------------------------------------------------------------------------------------------------------------
		--	Raise Error
		---------------------------------------------------------------------------------------------------------------
		RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
	END CATCH
	-------------------------------------------------------------------------------------------------------------------
	--	Test Id.
	-------------------------------------------------------------------------------------------------------------------
	SELECT	@intTestId	= Test_Id
	FROM	dbo.Tests	WITH (NOLOCK)
	WHERE	Var_Id		= @p_intVarId
		AND	Result_On	= @p_dtmResultOn
	--=================================================================================================================
	--	Determine if the value needs to be updated.
	--=================================================================================================================
	--	Check if an insert or update, and data is already there.
	-------------------------------------------------------------------------------------------------------------------
	IF	@p_intTransactionType BETWEEN 1 AND 2
		AND	@intTestId	IS NOT NULL
		AND	EXISTS	(	SELECT	*
						FROM	dbo.Tests WITH (NOLOCK)
						WHERE	Test_Id = @intTestId
							AND	Entry_By = @p_intUserId
							AND	(Array_Id = @p_intArrayId
								OR	(Array_Id IS NULL
									AND	@p_intArrayId IS NULL
									)
								)
							AND	Canceled = @p_intCanceled
							AND	(Comment_Id = @p_intCommentId
								OR	(Comment_Id IS NULL
									AND	@p_intCommentId IS NULL
									)
								)
							AND	(	@bitIsEventType = 1
								AND	Event_Id = @p_intEventId
								OR	(Event_Id IS NULL
									AND	@p_intEventId IS NULL
									)
								)
							AND	(Locked = @p_intLocked	
								OR	(Locked IS NULL
									AND	@p_intLocked IS NULL
									)
								)
							AND	(Result = @p_vchResult
								OR	(Result IS NULL
									AND	@p_vchResult IS NULL
									)
								)
							AND	(Second_User_Id = @p_intSecondUserId
								OR	(Second_User_Id IS NULL
									AND	@p_intSecondUserId IS NULL
									)
								)
							AND	(Signature_Id = @p_intSignatureId
								OR	(Signature_Id IS NULL
									AND	@p_intSignatureId IS NULL
									)
								)
					)
	BEGIN
		RETURN	0
	END
	-------------------------------------------------------------------------------------------------------------------
	--	Check if a delete and there is no record.
	-------------------------------------------------------------------------------------------------------------------
	IF		@p_intTransactionType = 3
		AND	@intTestId IS NULL
	BEGIN
		RETURN	0
	END
	--=================================================================================================================
	--	Call the PPA system stored procedure to have it make the database changes.
	--=================================================================================================================
	SELECT	@intPUId	=	PU_Id
	FROM	dbo.Variables	WITH (NOLOCK)
	WHERE	Var_Id		=	@p_intVarId
	-------------------------------------------------------------------------------------------------------------------
	--	If transaction type is INSERT OR UPDATE
	-------------------------------------------------------------------------------------------------------------------
	IF	@p_intTransactionType BETWEEN 1 AND 2
	BEGIN
		IF @p_bitWriteDirect = 0
		BEGIN
			SELECT	[ResultSetType]		= 2						,
					[VarId]				= @p_intVarId			,
					[PUId]				= @intPUId				,
					[UserId]			= @p_intUserId			,
					[Canceled]			= @p_intCanceled		,
					[Result]			= @p_vchResult			,
					[ResultOn]			= @p_dtmResultOn		,
					[TransactionType]	= @p_intTransactionType	,
					[PostDB]			= 0						,
					[SecondUserId]		= @p_intSecondUserId	,
					[TransNum]			= 0						,
					[EventId]			= @p_intEventId			,
					[ArrayId]			= @p_intArrayId			,
					[CommentId]			= @p_intCommentId		,
					[ESignature]		= @p_intSignatureId		
		END
		ELSE
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Set the Section for the Error handling
			-----------------------------------------------------------------------------------------------------------
			SELECT	@vchErrorSection = 'spServer_DBMgrUpdTest2'
			BEGIN TRY
				-------------------------------------------------------------------------------------------------------
				--	Call the Sproc
				-------------------------------------------------------------------------------------------------------
				EXEC	@intReturnCode	=	dbo.spServer_DBMgrUpdTest2
												@p_intVarId			,	--	@Var_Id
												@p_intUserId		,	--	@User_Id
												@p_intCanceled		,	--	@Canceled
												@p_vchResult		,	--	@New_Result
												@p_dtmResultOn		,	--	@Result_On
												0					,	--	@TransNum
												@p_intCommentId		,	--	@CommentId
												@p_intArrayId		,	--	@ArrayId
												@p_intEventId		,	--	@EventId
												@intPUId			,	--	@PU_Id
												@intTestId	OUTPUT	,	--	@Test_Id
												@p_dtmEntryOn		,	--	@Entry_On
												@p_intSecondUserId	,	--	@SecondUserId
												NULL				,	--	@HasHistory
												@p_intSignatureId		--	@SignatureId
				--=====================================================================================================
				--  Checks to see if the Store Procedure was excecuted normally
				--=====================================================================================================
				IF	@intReturnCode < 0
				BEGIN
					SELECT	@nvchErrorMessage	= 'The call to spServer_DBMgrUpdTest2 returned an error.  Code = '
													+ COALESCE(CONVERT(VARCHAR(25), @intReturnCode), '')
					--=================================================================================================
					--	Raise Error
					--=================================================================================================
					RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
				END
				--=====================================================================================================
				--  Send Resultset regarding this Test Insert/Update
				--=====================================================================================================
				SELECT		[ResultSetType]			=	2						,
							[VarId]					=	t.Var_Id				,
							[PUId]					=	v.PU_Id					,
							[UserId]				=	t.Entry_By				,
							[Canceled]				=	t.Canceled				,
							[Result]				=	t.Result				,
							[ResultOn]				=	t.Result_On				,
							[TransactionType]		=	@p_intTransactionType	,
							[PostDB]				=	1						,
							[SecondUserId]			=	t.Second_User_Id		,
							[TransNum]				=	0						,
							[EventId]				=	t.Event_Id				,
							[ArrayId]				=	t.Array_Id				,
							[CommentId]				=	t.Comment_Id			,
							[ESignature]			=	t.Signature_Id
				FROM		dbo.Tests		t	WITH(NOLOCK)
					JOIN	dbo.Variables	v	WITH(NOLOCK)
												ON	t.Var_Id	=	v.Var_Id
				WHERE		t.Test_Id = @intTestId
			END TRY
			BEGIN CATCH
				--=====================================================================================================
				--	Rollback Transaction
				--=====================================================================================================
				IF	@@TRANCOUNT	>	0
				BEGIN
					ROLLBACK TRANSACTION
				END
				-------------------------------------------------------------------------------------------------------
				--	Set error message
				-------------------------------------------------------------------------------------------------------
				SELECT	@nvchErrorMessage	= COALESCE(@nvchErrorMessage, ERROR_MESSAGE())
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END CATCH
		END
	END
	-------------------------------------------------------------------------------------------------------------------
	--	If transaction type is DELETE
	-------------------------------------------------------------------------------------------------------------------
	ELSE	IF	@p_intTransactionType = 3
	BEGIN
		BEGIN TRANSACTION
		---------------------------------------------------------------------------------------------------------------
		--	Set the Section for the Error handling
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchErrorSection = 'Delete Tests Record'
		BEGIN TRY
			DELETE
			FROM	dbo.Tests
			WHERE	Test_Id = @intTestId
			-----------------------------------------------------------------------------------------------------------
			--	Issue the result set
			-----------------------------------------------------------------------------------------------------------
			SELECT	[ResultSetType]		= 2						,
					[VarId]				= @p_intVarId			,
					[PUId]				= @intPUId				,
					[UserId]			= @p_intUserId			,
					[Canceled]			= @p_intCanceled		,
					[Result]			= @p_vchResult			,
					[ResultOn]			= @p_dtmResultOn		,
					[TransactionType]	= @p_intTransactionType	,
					[PostDB]			= 1						,
					[SecondUserId]		= @p_intSecondUserId	,
					[TransNum]			= 0						,
					[EventId]			= @p_intEventId			,
					[ArrayId]			= @p_intArrayId			,
					[CommentId]			= @p_intCommentId		,
					[ESignature]		= @p_intSignatureId		
		END TRY
		BEGIN CATCH
			--=========================================================================================================
			--  Rollback Transaction
			--=========================================================================================================
			IF	@@TRANCOUNT	>	0
			BEGIN
				ROLLBACK TRANSACTION
			END
			-----------------------------------------------------------------------------------------------------------
			--	Set error message
			-----------------------------------------------------------------------------------------------------------
			SELECT	@nvchErrorMessage	= COALESCE(@nvchErrorMessage, ERROR_MESSAGE())
			-----------------------------------------------------------------------------------------------------------
			--	Raise Error
			-----------------------------------------------------------------------------------------------------------
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END CATCH
		--=============================================================================================================
		--  Commit Transaction
		--=============================================================================================================
		IF	@@TRANCOUNT	>	0
		BEGIN
			COMMIT TRANSACTION
		END
	END
END TRY
BEGIN CATCH
	--=================================================================================================================
	--	Rollback Transaction
	--=================================================================================================================
	IF	@@TRANCOUNT	>	0
	BEGIN
		ROLLBACK TRANSACTION
	END
	-------------------------------------------------------------------------------------------------------------------
	--	Log critical error message and exit.
	-------------------------------------------------------------------------------------------------------------------
	SELECT
		@intReturnCode		= NULL					,
		@intNestingLevel	= @@NESTLEVEL			,
		@vchObjectName		= OBJECT_NAME(@@ProcId)	,
		@nvchErrorMessage	= ERROR_MESSAGE()		,
		@intErrorSeverity	= ERROR_SEVERITY()		,
		@intErrorState		= ERROR_STATE()
	EXECUTE @intReturnCode = dbo.spLocal_SSI_Cmn_LogErrorMessage
		@p_uidErrorId				= @op_uidErrorId	,
		@p_intNestingLevel			= @intNestingLevel	,
		@p_vchNestedObjectName		= @vchNestedObject	,
		@p_vchObjectName			= @vchObjectName	,
		@p_vchErrorSection			= @vchErrorSection	,
		@p_nvchErrorMessage			= @nvchErrorMessage	,
		@p_intErrorSeverity			= @intErrorSeverity	,
		@p_intErrorState			= @intErrorState	,
		@p_bitPrimaryObjectFlag		= @intPrimary		,
		@p_intErrorSeverityLevel	= @consErrorCritical
	GOTO	ReturnFinish
END CATCH
--=====================================================================================================================
--    Set return code and error id output values
--=====================================================================================================================
RETURNFinish:
IF	EXISTS(
	SELECT	Error_Id
	FROM	dbo.Local_SSI_ErrorLogHeader  WITH(NOLOCK)
	WHERE	Error_Id			= @op_uidErrorId
		AND Primary_Object_Name	= OBJECT_NAME(@@ProcId))
BEGIN
	SELECT	@intReturnCode	= MIN(Error_Severity_Level)
	FROM	dbo.Local_SSI_ErrorLogDetail	 WITH(NOLOCK)
	WHERE	Error_Id		= @op_uidErrorId
		AND [Object_Name]	= OBJECT_NAME(@@ProcId)
	RETURN	@intReturnCode
END
ELSE
BEGIN
	IF @intPrimary = 1
	BEGIN
		SET	@op_uidErrorId = NULL
	END
	-------------------------------------------------------------------------------------------------------------------
	--	Return the Return Code
	-------------------------------------------------------------------------------------------------------------------
	RETURN	@consErrorNone
END
--=====================================================================================================================
--	Finished.
--=====================================================================================================================
