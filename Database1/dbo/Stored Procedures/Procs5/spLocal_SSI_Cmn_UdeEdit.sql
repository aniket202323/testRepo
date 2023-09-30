--=====================================================================================================================
-- Store Procedure: 	spLocal_SSI_Cmn_UdeEdit
-- Sp Type:				Stored Procedure
-- Editor Tab Spacing: 	4	
--=====================================================================================================================
--	This stored procedure will update a "User Defined Events" record in the Proficy Plant Applications database and will
--	compose a resultset that contains the Transaction Message for MessageBus.  This SP will be called by many displays
--	and will be the preferred way to update information to the Tests table.  It will support Inserts, Edits and Deletes.
--
--	The User Defined Events table has several fields for Reasons.  Currently, they will not be supported by this SP.
--=====================================================================================================================
--	Revision	Date		Who					What
--	========	=====		===					====
--	1.0			2008-04-30	Brent Seely			Original Development.
--	1.1			2009-03-05	Luis Chaves			Removed Email Message functionality
--	1.2			2009-03-20	Luis Chaves			Added a validation for UDE_Desc
--	1.3			2009-03-31	Luis Chaves			Added a logic to change comment columns no matter what value Write direct has
--	1.4			2009-04-01	Luis Chaves			Added logic to Support Coalesce Off parameter and TransNum = 2
--	1.5			2009-04-15	Luis Chaves			Added a logic to write to User_Defined_Events.Local_SUp_Fault_Id
--	1.6			2009-05-04	Luis Chaves			Use Implied Parameters for GE Fanuc spServer_DBMgrUpd procedures
--	1.7			2010-02-02	Luis Chaves			Modified to split functionality related to table Local_User_Defined_Events
--	2.0			2010-02-25	Luis Chaves			Major changes incorporated.
--												Updated Error Handling methodology which relies on new child components
--												The changes also resulted in modifications to the input	parameters
--												as follows:
--												Error Handling parameter changes:
--												Removed @nvchErrorMessage VARCHAR(1000)		OUTPUT
--												Added	@op_uidErrorId		UNIQUEIDENTIFIER	OUTPUT
--	2.1			2010-05-26	Renata Piedmont		LIBRARY-74: add @op_vchErrorMessage as an optional parameter to support 
--												backward compatibility
--												Updated comments
--	2.2			2010-07-07	Luis Chaves			Added logic to support Error Handling on dbo.spLocal_SSI_Cmn_ReasonTreeNodeId
--	2.3			2010-11-09	Luis Chaves			Removed Output statement from sub SPs to keep tracking of Error Messages
--	2.4			2010-12-16	Dan Hinchey			Added Parent_UDE_Id.
--	2.5			2011-05-18	Dan Hinchey			Fixed bug that was assigning Cause_Tree_Id to Event Reason_Tree_Data_Id
--  2.6			2011-07-22	Karla Bolaños		Standardize Error Handling logic
--  2.7			2011-08-12	Karla Bolaños		Remove End Time validation requested by Luis Chaves
--  2.8			2012-05-18	Karla Ramirez		Library 170 : Add logic to Error Trapping code at bottom of sp to only set 
--												@op_uidErrorId to NULL if there are no errors and the sp is the primary sp 
--												i.e.@intPrimary = 1
--	2.9			2012-08-29	Renata Piedmont		LIBRARY-236: Added some comments  
--	2.10		2012-08-31	Karla Bolaños		Add EventId to COALESCE logic for Comments Edit sp
--	2.11		2012-11-29	Luis Chaves			Changed Coalesce logic order to set the values before the verification
--												of the existence of the row
--	2.12		2013-09-03	Alexandre Turgeon	LIBRARY-299: Fixed typo in Parent UDE Id error message
--												LIBRARY-300: Fixed typo in Ack By error message
--	2.13		2013-09-16	Alexandre Turgeon	LIBRARY-302: Fixed coalesce in error log
--	2.14		2013-10-19	Luis Chaves			Added Coalesce for the Comment Id on the Update transaction
--	2.15		2014-03-27	Karla Bolanos		Added logic to populate Cause and Action comment
--	2.16		2016-11-26	Alex Klusmeyer		Addressing issues with Temporal Rounding, added new flag @p_TemporalAccuracy
-----------------------------------------------------------------------------------------------------------------------
--	How to execute it: Example
-----------------------------------------------------------------------------------------------------------------------
/*
	DECLARE
		@dtmTime		DATETIME			,
		@op_uidErrorId		UNIQUEIDENTIFIER	,
		@intUDEId		INT					,
		@intReturnCode	INT,
		@intResult	int
	SELECT
		@intUDEId	= NULL	,
		@intResult	= NULL	,
		@op_uidErrorId	= NULL	,
		@dtmTime	='2011-08-04 23:00:00.000'
	EXEC	
		@intReturnCode	= dbo.spLocal_SSI_Cmn_UdeEdit
		@op_uidErrorId			= @op_uidErrorId	OUTPUT	,
		@p_bitWriteDirect		= 1						,	--	1 = WRITE TO DATABASE, 0 = SEND RESULTSETS
		@p_intTransactionType	= 1						,	--	1 = INSERT; 2 = EDIT; 3 = DELETE
		@p_intUserId			= 1						,
		@op_intUDEId			= @intUDEId		OUTPUT	,
		@p_vchUDEDesc			= 'Test'				,
		@p_intPUId				= 772					,
		@p_intSubtypeId			= 53					,
		@p_dtmStartTime			= @dtmTime				,
		@p_dtmEndTime			= NULL				,
		@p_intEventId			= NULL					,
		@p_intParentUDEId		= NULL					,
		@p_intCommentId			= NULL					,
		@p_bitAck				= 0						,
		@p_dtmAckOn				= @dtmTime				,
		@p_intAckBy				= 1						,
		@p_intCause1			= NULL					,
		@p_intCause2			= NULL					,
		@p_intCause3			= NULL					,
		@p_intCause4			= NULL					,
		@p_intCauseCommentId	= 6						,
		@p_intAction1			= NULL					,
		@p_intAction2			= NULL					,
		@p_intAction3			= NULL					,
		@p_intAction4			= NULL					,
		@p_intActionCommentId	= 11					,
		@p_vchNewValue			= 'Active'				,
		@p_intResearchCommentId	= 370					,
		@p_bitCoalesceOff		= 0
	IF	@intReturnCode	<>	0
		BEGIN
			SELECT *
			FROM dbo.fnLocal_SSI_Cmn_ErrorMessageByUniqueId (@op_uidErrorId)
	END
*/
--=====================================================================================================================
CREATE 	PROCEDURE	[dbo].[spLocal_SSI_Cmn_UdeEdit]
	@op_uidErrorId			UNIQUEIDENTIFIER	= NULL	OUTPUT	,	--	Used for error handling
	@op_vchErrorMessage		VARCHAR(1000)		= NULL	OUTPUT	,	--	An Output Parameter which will return any error messages.
																		--	it is a VARCHAR(1000) because this is what it was before
																		--	error handling was introduced
																		--	eventually it should be changed to NVARCHAR(2048) to match 
																		--	the table field datatype
	@p_bitWriteDirect		BIT					= 0				,
	@p_intTransactionType	INT					= NULL			,	--	1 = INSERT; 2 = EDIT; 3 = DELETE
	@p_intUserId			INT									,
	@op_intUDEId			INT					= NULL	OUTPUT	,
	@p_vchUDEDesc			VARCHAR(1000)		= NULL			,
	@p_intPUId				INT					= NULL			,
	@p_intSubTypeId			INT					= NULL			,
	@p_dtmStartTime			DATETIME			= NULL			,
	@p_dtmEndTime			DATETIME			= NULL			,
	@p_intEventId			INT					= NULL			,		
	@p_intParentUDEId		INT					= NULL			,
	@p_intCommentId			INT					= NULL			,
	@p_bitAck				BIT					= 0				,
	@p_dtmAckOn				DATETIME			= NULL			,
	@p_intAckBy				INT					= NULL			,
	@p_intCause1			INT					= NULL			,
	@p_intCause2			INT					= NULL			,
	@p_intCause3			INT					= NULL			,
	@p_intCause4			INT					= NULL			,
	@p_intCauseCommentId	INT					= NULL			,
	@p_intAction1			INT					= NULL			,
	@p_intAction2			INT					= NULL			,
	@p_intAction3			INT					= NULL			,
	@p_intAction4			INT					= NULL			,
	@p_intActionCommentId	INT					= NULL			,
	@p_vchNewValue			VARCHAR(25)			= NULL			,
	@p_intResearchCommentId	INT					= NULL			,
	@p_bitCoalesceOff		BIT					= 0				,	--	This is necesary when it is wanted a NULL value in a parameter
	@p_TemporalAccuracy		INT					= 0					-- 0 For Truncation of ms (backwards compatible)
																	-- 1 To Preserve ms precision
AS
--=====================================================================================================================
--	Define all variables.
--=====================================================================================================================
DECLARE
	@intActionTreeId		INT			,	--	Used to validate Actions
	@intReasonTreeDataId	INT			,
	@intCauseTreeId			INT			,	--	Used to validate causes
	@intTransNum			INT			,
	@vchSubtypeDesc			VARCHAR(100),	--	Variable to store human readable description instead of use an Id
	@vchConstErrorType		VARCHAR(10)		--	Const value for the error type of the resultset
--=====================================================================================================================
--	The following variables are used for error handling logic
--=====================================================================================================================
DECLARE
	@intReturnCode			INT		,
	@intNestingLevel		INT		,
	@intPrimary				INT		,
	@intErrorSeverity		INT		,
	@consErrorCritical		INT		,
	@consErrorWarning		INT		,
	@consErrorInfo			INT		,
	@consErrorNone			INT		,
	@intErrorState			INT		,
	@vchNestedObject		VARCHAR(256)	,
	@vchObjectName			VARCHAR(256)	,
	@nvchErrorMessage		NVARCHAR(2048)	,
	@vchErrorSection		VARCHAR(100)
--=====================================================================================================================
--	Set constants used for error handling
--=====================================================================================================================
SELECT
	@consErrorCritical	= -1,
	@consErrorNone		= 0	,
	@consErrorWarning	= 1	,
	@consErrorInfo		= 2	,
	@intErrorSeverity	= 11,
	@intErrorState		= 1
--=====================================================================================================================
--	Initialize all variables.  The only items hard-coded within this stored procedure are items that are specific to this
--	application and are unlikely to be used by any other application.  Acceptable items are Variable Aliases and Display
--	Option Descriptions.
--=====================================================================================================================
SELECT
	@intReturnCode		= NULL	,
	@vchSubtypeDesc		= NULL	,
	@intTransNum		= 2

IF	@p_TemporalAccuracy	=	0
BEGIN
	SET	@p_dtmStartTime	= CONVERT(VARCHAR(25), @p_dtmStartTime, 120)
	SET	@p_dtmEndTime	= CONVERT(VARCHAR(25), @p_dtmEndTime, 120)

END
ELSE IF	@p_TemporalAccuracy	=	1
BEGIN
	--	@p_dtmStartTime and @p_dtmEndTime are left as input, in DATETIME format precise to the millisecond
	SET	@p_dtmStartTime	=	@p_dtmStartTime
	SET	@p_dtmEndTime	=	@p_dtmEndTime
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
	--	Validate the inputs, if the transaction type is not DELETE
	--=================================================================================================================
	SELECT	@vchErrorSection = 'Input Validation 1'
	BEGIN TRY
		---------------------------------------------------------------------------------------------------------------
		--	UDE Id
		---------------------------------------------------------------------------------------------------------------
		IF		@op_intUDEId IS NOT NULL
			AND	@p_intTransactionType <> 3
		BEGIN
			IF	NOT EXISTS	(
				SELECT	UDE_Id
				FROM	dbo.User_Defined_Events	WITH(NOLOCK)
				WHERE	UDE_Id	= @op_intUDEId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied UDE Id is invalid.  UDEId = '
											+ COALESCE(CONVERT(VARCHAR(25), @op_intUDEId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	PU Id
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intPUId IS NOT NULL
			AND	@p_intTransactionType <> 3
		BEGIN
			IF	NOT EXISTS	(
				SELECT	PU_Id
				FROM	dbo.Prod_Units	WITH(NOLOCK)
				WHERE	PU_Id	= @p_intPUId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied PU Id is invalid.  PUId = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intPUId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Event Subtype Id
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intSubtypeId IS NOT NULL
			AND	@p_intTransactionType <> 3
		BEGIN
			IF	NOT EXISTS	(
				SELECT	Event_Subtype_Id
				FROM	dbo.Event_Subtypes	WITH(NOLOCK)
				WHERE	Event_Subtype_Id	= @p_intSubtypeId
					AND	ET_Id				= 14)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Event Subtype Id is invalid.  Event Subtype Id = '
											+	COALESCE(CONVERT(VARCHAR(25), @p_intSubtypeId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Event Id.
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intEventId IS NOT NULL
			AND	@p_intTransactionType <> 3
		BEGIN
			IF	NOT EXISTS	(
				SELECT	Event_Id
				FROM	dbo.Events	WITH(NOLOCK)
				WHERE	Event_Id = @p_intEventId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Event Id is invalid.  Event Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intEventId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Parent UDE Id.
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intParentUDEId IS NOT NULL
			AND	@p_intTransactionType <> 3
		BEGIN
			IF	NOT EXISTS	(
				SELECT	UDE_Id
				FROM	dbo.User_Defined_Events	WITH(NOLOCK)
				WHERE	UDE_Id = @p_intParentUDEId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Parent UDE Id is invalid.  Parent UDE Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intParentUDEId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	User Id.
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intUserId IS NOT NULL
		BEGIN
			IF	NOT EXISTS	(
				SELECT	User_Id
				FROM	dbo.Users	WITH(NOLOCK)
				WHERE	User_Id	= @p_intUserId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied User Id is invalid.  User Id = '
											+	COALESCE(CONVERT(VARCHAR(25), @p_intUserId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	TransactionType.
		---------------------------------------------------------------------------------------------------------------
		IF	NOT	@p_intTransactionType BETWEEN 1 AND 3
		BEGIN
			SELECT	@nvchErrorMessage	= 'Supplied Transaction Type is invalid.  It must be 1, 2 or 3.  TransactionType = '
										+ COALESCE(CONVERT(VARCHAR(25), @p_intTransactionType), 'BLANK')
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	Ack By.
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intAckBy IS NOT NULL
		BEGIN
			IF	NOT EXISTS	(
				SELECT	User_Id
				FROM	dbo.Users	WITH(NOLOCK)
				WHERE	User_Id	= @p_intAckBy)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Ack By is invalid.  Ack By = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intAckBy), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	If this value is supplied it means that the user wants to change the action levels. If not then we have to use
		--	the COALESCE logic
		--	Action Level 1
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intAction1	IS	NOT	NULL
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Clear Action Tree
			-----------------------------------------------------------------------------------------------------------
			SELECT	@intActionTreeId	= NULL
			-----------------------------------------------------------------------------------------------------------
			--	Retrieve Action Tree
			-----------------------------------------------------------------------------------------------------------
			SELECT	@intActionTreeId	= Action_Tree_Id
			FROM	dbo.Event_Subtypes	WITH(NOLOCK)
			WHERE	Event_Subtype_Id	= @p_intSubtypeId
			-----------------------------------------------------------------------------------------------------------
			--	Validate the Action levels
			-----------------------------------------------------------------------------------------------------------
			IF	@intActionTreeId	IS	NOT	NULL
			BEGIN
				SELECT	@intReasonTreeDataId	= NULL
				BEGIN TRY
					EXEC	@intReturnCode	= dbo.spLocal_SSI_Cmn_ReasonTreeNodeId
						@op_uidErrorId	= @op_uidErrorId		OUTPUT	,
						@p_intTreeId	= @intActionTreeId				,
						@op_intReason1	= @p_intAction1			OUTPUT	,
						@op_intReason2	= @p_intAction2			OUTPUT	,
						@op_intReason3	= @p_intAction3			OUTPUT	,
						@op_intReason4	= @p_intAction4			OUTPUT	,
						@op_intNodeId	= @intReasonTreeDataId	OUTPUT
					IF	@intReturnCode	< 0
					BEGIN
						-----------------------------------------------------------------------------------------------
						-- Set the error message variable
						-----------------------------------------------------------------------------------------------
						SELECT	@nvchErrorMessage	= 'The call to dbo.spLocal_SSI_Cmn_ReasonTreeNodeId returned'
													+ ' an error. Code = '
													+ COALESCE(CONVERT(VARCHAR(25), @intReturnCode), 'BLANK')
						-----------------------------------------------------------------------------------------------
						--	Return	Error
						-----------------------------------------------------------------------------------------------
						RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
					END
				END TRY
				BEGIN CATCH
					---------------------------------------------------------------------------------------------------
					--	Set error message
					---------------------------------------------------------------------------------------------------
					SELECT	@nvchErrorMessage	= COALESCE(@nvchErrorMessage, ERROR_MESSAGE())
					---------------------------------------------------------------------------------------------------
					--	Raise Error
					---------------------------------------------------------------------------------------------------
					RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
				END CATCH
				-------------------------------------------------------------------------------------------------------
				--	Validates if the Node Retrieved was a valid one
				-------------------------------------------------------------------------------------------------------
				IF	@intReasonTreeDataId	IS	NULL
				BEGIN
					---------------------------------------------------------------------------------------------------
					-- Set the error message variable
					---------------------------------------------------------------------------------------------------
					SELECT	@nvchErrorMessage	= 'Error: The Action Levels are invalid for Production Unit = '
												+ COALESCE((SELECT	PU_Desc
															FROM	dbo.Prod_Units	WITH(NOLOCK)
															WHERE	PU_Id	= @p_intPUId),
															'BLANK')
												+ ' And Action Tree Name	= '
												+ COALESCE((SELECT	Tree_Name
															FROM	dbo.Event_Reason_Tree WITH(NOLOCK)
															WHERE	Tree_Name_Id	= @intActionTreeId),
															'BLANK')
					---------------------------------------------------------------------------------------------------
					-- Return Error
					---------------------------------------------------------------------------------------------------
					RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
				END
			END
		END
		ELSE IF		@p_intTransactionType	= 2
				AND	@p_bitCoalesceOff		= 0
		BEGIN
			SELECT	@p_intAction1	= COALESCE(@p_intAction1, Action1	),
					@p_intAction2	= COALESCE(@p_intAction2, Action2	),
					@p_intAction3	= COALESCE(@p_intAction3, Action3	),
					@p_intAction4	= COALESCE(@p_intAction4, Action4	)
			FROM	dbo.User_Defined_Events	WITH(NOLOCK)
			WHERE	UDE_Id	= @op_intUDEId
		END
		---------------------------------------------------------------------------------------------------------------
		--	If this value is supplied it means that the user wants to change the reason levels. If not then we have to use
		--	the COALESCE logic
		--	Reason Level 1
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intCause1	IS	NOT	NULL
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Clear Reason Tree
			-----------------------------------------------------------------------------------------------------------
			SELECT	@intCauseTreeId	= NULL
			-----------------------------------------------------------------------------------------------------------
			--	Retrieve Action Tree and Reason Tree
			-----------------------------------------------------------------------------------------------------------
			SELECT	@intCauseTreeId		= Cause_Tree_Id
			FROM	dbo.Event_Subtypes	WITH(NOLOCK)
			WHERE	Event_Subtype_Id	= @p_intSubtypeId
			-----------------------------------------------------------------------------------------------------------
			--	Validate the Reason levels
			-----------------------------------------------------------------------------------------------------------
			IF	@intCauseTreeId	IS	NOT	NULL
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Validate the Reason levels
				-------------------------------------------------------------------------------------------------------
				SELECT	@intReasonTreeDataId	= NULL
				BEGIN TRY
					EXEC	@intReturnCode	= dbo.spLocal_SSI_Cmn_ReasonTreeNodeId
						@op_uidErrorId	= @op_uidErrorId		OUTPUT	,
						@p_intTreeId	= @intCauseTreeId				,
						@op_intReason1	= @p_intCause1			OUTPUT	,
						@op_intReason2	= @p_intCause2			OUTPUT	,
						@op_intReason3	= @p_intCause3			OUTPUT	,
						@op_intReason4	= @p_intCause4			OUTPUT	,
						@op_intNodeId	= @intReasonTreeDataId	OUTPUT
					IF	@intReturnCode	< 0
					BEGIN
						-----------------------------------------------------------------------------------------------
						-- Set the error message variable
						-----------------------------------------------------------------------------------------------
						SELECT	@nvchErrorMessage	= 'The call to dbo.spLocal_sfSQL_GetReasonTreeNodeId returned'
													+ ' an error. Code = '
													+ COALESCE(CONVERT(VARCHAR(25), @intReturnCode), 'BLANK')
						-----------------------------------------------------------------------------------------------
						--	Raise Error
						-----------------------------------------------------------------------------------------------
						RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
					END
				END TRY
				BEGIN CATCH
					---------------------------------------------------------------------------------------------------
					--	Set error message
					---------------------------------------------------------------------------------------------------
					SELECT	@nvchErrorMessage	= COALESCE(@nvchErrorMessage, ERROR_MESSAGE())
					---------------------------------------------------------------------------------------------------
					--	Raise Error
					---------------------------------------------------------------------------------------------------
					RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
				END CATCH
				-------------------------------------------------------------------------------------------------------
				--	Validates if the Node Retrieved was a valid one
				-------------------------------------------------------------------------------------------------------
				IF	@intReasonTreeDataId	IS	NULL
				BEGIN
					---------------------------------------------------------------------------------------------------
					-- Set the error message variable
					---------------------------------------------------------------------------------------------------
					SELECT	@nvchErrorMessage	= 'Error: The Reason Levels are invalid for Production Unit = '
												+ COALESCE((SELECT	PU_Desc
															FROM	dbo.Prod_Units WITH(NOLOCK)
															WHERE	PU_Id	= @p_intPUId),
															'BLANK')
												+ ' And Reason Tree Name	= '
												+ COALESCE((SELECT	Tree_Name
															FROM	dbo.Event_Reason_Tree WITH(NOLOCK)
															WHERE	Tree_Name_Id	= @intCauseTreeId),
															'BLANK')
					---------------------------------------------------------------------------------------------------
					--	Return	Error
					---------------------------------------------------------------------------------------------------
					RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
				END
			END
		END
		ELSE IF		@p_intTransactionType	= 2
				AND	@p_bitCoalesceOff		= 0
		BEGIN
			SELECT	@p_intCause1	= COALESCE(@p_intCause1	,Cause1	),
					@p_intCause2	= COALESCE(@p_intCause2	,Cause2	),
					@p_intCause3	= COALESCE(@p_intCause3	,Cause3	),
					@p_intCause4	= COALESCE(@p_intCause4	,Cause4	)
			FROM	dbo.User_Defined_Events	WITH(NOLOCK)
			WHERE	UDE_Id	= @op_intUDEId
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
	--=================================================================================================================
	--	Check if Coalesce is required
	--=================================================================================================================
	IF	@p_intTransactionType BETWEEN 1 AND 2
	BEGIN
		IF	EXISTS	(
			SELECT	UDE_Id
			FROM	dbo.User_Defined_Events	WITH(NOLOCK)
			WHERE	UDE_Id	= @op_intUDEId)
		BEGIN
			SELECT	@p_intTransactionType	= 2
			IF	@p_bitCoalesceOff	= 0
			BEGIN
				SELECT	@p_intSubtypeId			= COALESCE(@p_intSubtypeId		, Event_Subtype_Id			),
						@p_intPUId				= COALESCE(@p_intPUId			, PU_Id						),
						@p_intEventId			= COALESCE(@p_intEventId		, Event_Id					),
						@p_vchUDEDesc			= COALESCE(@p_vchUDEDesc		, UDE_Desc					),
						@p_dtmStartTime			= COALESCE(@p_dtmStartTime		, Start_Time				),
						@p_dtmEndTime			= COALESCE(@p_dtmEndTime		, End_Time					),
						@p_vchNewValue			= COALESCE(@p_vchNewValue		, NewValue					),
						@p_intCommentId			= COALESCE(@p_intCommentId		, Comment_Id				),
						@p_intCauseCommentId	= COALESCE(@p_intCauseCommentId	, Cause_Comment_Id			),
						@p_intActionCommentId	= COALESCE(@p_intActionCommentId, Action_Comment_Id			),
						@intReasonTreeDataId	= COALESCE(@intReasonTreeDataId	, Event_Reason_Tree_Data_Id	)
				FROM	dbo.User_Defined_Events	WITH(NOLOCK)
				WHERE	UDE_Id	= @op_intUDEId
			END
		END
		ELSE
		BEGIN
			SELECT	@p_intTransactionType	= 1
			IF (@p_vchUDEDesc IS NULL)
			BEGIN
				SELECT  @nvchErrorMessage	= 'Error: UDE Description is a required value. It can''t be a NULL value'
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
	END
	--=================================================================================================================
	--	Determine if the value needs to be updated.
	--=================================================================================================================
	--	Check if an INSERT or UPDATE, and data is already there.
	-------------------------------------------------------------------------------------------------------------------
	IF		@p_intTransactionType BETWEEN 1 AND 2
		AND	EXISTS	(
			SELECT	UDE_Id
			FROM	dbo.User_Defined_Events	WITH(NOLOCK)
			WHERE	UDE_Id								= @op_intUDEId
				AND	(	End_Time						= @p_dtmEndTime
					OR	(	End_Time					IS NULL
						AND	@p_dtmEndTime				IS NULL
						)
					)
				AND	(	Event_Id						= @p_intEventId
					OR	(	Event_Id					IS NULL
						AND	@p_intEventId				IS NULL
						)
					)
				AND	(	Parent_UDE_Id					= @p_intParentUDEId
					OR	(	Parent_UDE_Id				IS NULL
						AND	@p_intParentUDEId			IS NULL
						)
					)
				AND	(	Event_Subtype_Id				= @p_intSubtypeId
					OR	(	Event_Subtype_Id			IS NULL
						AND	@p_intSubtypeId				IS NULL
						)
					)
				AND	(	PU_Id							= @p_intPUId
					OR	(	PU_Id						IS NULL
						AND	@p_intPUId					IS NULL
						)
					)
				AND	(	Start_Time						= @p_dtmStartTime
					OR	(	Start_Time					IS NULL
						AND	@p_dtmStartTime				IS NULL
						)
					)
				AND	(	UDE_Desc						= @p_vchUDEDesc
					OR	(	UDE_Desc					IS NULL
						AND	@p_vchUDEDesc				IS NULL
						)
					)
				AND	(	NewValue						= @p_vchNewValue
					OR	(	NewValue					IS NULL
						AND	@p_vchNewValue				IS NULL
						)
					)
				AND	(	User_Id							= @p_intUserId
					OR	(	User_Id						IS NULL
						AND	@p_intUserId				IS NULL
						)
					)
				AND	(	Ack								= @p_bitAck
					OR	(	Ack							IS NULL
						AND	@p_bitAck					IS NULL
						)
					)
				AND	(	Ack_On							= @p_dtmAckOn
					OR	(	Ack_On						IS NULL
						AND	@p_dtmAckOn					IS NULL
						)
					)
				AND	(	Ack_By							= @p_intAckBy
					OR	(	Ack_By						IS NULL
						AND	@p_intAckBy					IS NULL
						)
					)
				AND	(	Comment_Id						= @p_intCommentId
					OR	(	Comment_Id					IS NULL
						AND	@p_intCommentId				IS NULL
						)
					)
				AND	(	Action_Comment_Id				= @p_intActionCommentId
					OR	(	Action_Comment_Id			IS NULL
						AND	@p_intActionCommentId		IS NULL
						)
					)
				AND	(	Cause_Comment_Id				= @p_intCauseCommentId
					OR	(	Cause_Comment_Id			IS NULL
						AND	@p_intCauseCommentId		IS NULL
						)
					)
				AND	(	Research_Comment_Id				= @p_intResearchCommentId
					OR	(	Research_Comment_Id			IS NULL
						AND	@p_intResearchCommentId		IS NULL
						)
					)
				AND	(	Action1							= @p_intAction1
					OR	(	Action1						IS NULL
						AND	@p_intAction1				IS NULL
						)
					)
				AND	(	Action2							= @p_intAction2
					OR	(	Action2						IS NULL
						AND	@p_intAction2				IS NULL
						)
					)
				AND	(	Action3							= @p_intAction3
					OR	(	Action3						IS NULL
						AND	@p_intAction3				IS NULL
						)
					)
				AND	(	Action4							= @p_intAction4
					OR	(	Action4						IS NULL
						AND	@p_intAction4				IS NULL
						)
					)
				AND	(	Cause1							= @p_intCause1
					OR	(	Cause1						IS NULL
						AND	@p_intCause1				IS NULL
						)
					)
				AND	(	Cause2							= @p_intCause2
					OR	(	Cause2						IS NULL
						AND	@p_intCause2				IS NULL
						)
					)
				AND	(	Cause3							= @p_intCause3
					OR	(	Cause3						IS NULL
						AND	@p_intCause3				IS NULL
						)
					)
				AND	(	Cause4							= @p_intCause4
					OR	(	Cause4						IS NULL
						AND	@p_intCause4				IS NULL
						)
					)
				AND	(	Event_Reason_Tree_Data_Id		= @intReasonTreeDataId
					OR	(	Event_Reason_Tree_Data_Id	IS NULL
						AND	@intCauseTreeId				IS NULL
						)
					)
			)
	BEGIN
		GOTO ReturnFinish
	END
	-------------------------------------------------------------------------------------------------------------------
	--	Check if a delete and there is no record.
	-------------------------------------------------------------------------------------------------------------------
	IF		@p_intTransactionType	= 3
		AND	NOT EXISTS	(
			SELECT	UDE_Id
			FROM	dbo.User_Defined_Events	WITH(NOLOCK)
			WHERE	UDE_Id = @op_intUDEId)
	BEGIN
		GOTO ReturnFinish
	END
	--=================================================================================================================
	--	Call the PPA system stored procedure to have it make the database changes.
	--=================================================================================================================
	--	If the transaction type is INSERT OR UPDATE
	-------------------------------------------------------------------------------------------------------------------
	IF	@p_intTransactionType BETWEEN 1 AND 2
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		--	Set Error Section
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchErrorSection = 'Input Validation 2'
		BEGIN TRY
			-----------------------------------------------------------------------------------------------------------
			--	Start Time
			-----------------------------------------------------------------------------------------------------------
			IF	@p_dtmStartTime IS NULL
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Start Time is empty.'
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
			-----------------------------------------------------------------------------------------------------------
			--	Start Time must be earlier than End Time.
			-----------------------------------------------------------------------------------------------------------
			IF	DATEDIFF(SECOND, @p_dtmStartTime, @p_dtmEndTime) < 0
			BEGIN
				SELECT	@nvchErrorMessage	= 'Start Time is later than End Time.  Start Time = '
											+ CONVERT(VARCHAR(25), @p_dtmStartTime, 120) + '.  End Time = '
											+ CONVERT(VARCHAR(25), @p_dtmEndTime, 120) + '.'
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END TRY
		BEGIN CATCH
			-----------------------------------------------------------------------------------------------------------
			--	Set error message
			-----------------------------------------------------------------------------------------------------------
			SELECT	@nvchErrorMessage	= COALESCE(@nvchErrorMessage, ERROR_MESSAGE())
			-----------------------------------------------------------------------------------------------------------
			--	Raise Error
			-----------------------------------------------------------------------------------------------------------
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END CATCH
		---------------------------------------------------------------------------------------------------------------
		--	GET the Subtype Description 
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchSubtypeDesc		= Event_Subtype_Desc
		FROM	dbo.Event_Subtypes	WITH(NOLOCK)
		WHERE	Event_Subtype_Id	= @p_intSubtypeId
		---------------------------------------------------------------------------------------------------------------
		--	Determine if SP should do a direct write to the database, or just send back a properly formated result set
		---------------------------------------------------------------------------------------------------------------
		IF		@p_bitWriteDirect	= 0
			AND @p_intEventId		IS	NULL
		BEGIN
			IF	NOT EXISTS	(
				SELECT	UDE_Id
				FROM	dbo.User_Defined_Events	WITH(NOLOCK)
				WHERE	UDE_Id							= @op_intUDEId
					AND	(	Action_Comment_Id			= @p_intActionCommentId
						OR	(	Action_Comment_Id			IS	NULL
							AND	@p_intActionCommentId		IS	NULL
							)
						)
					AND	(	Cause_Comment_Id			= @p_intCommentId
						OR	(	Cause_Comment_Id			IS	NULL
							AND	@p_intCommentId				IS	NULL
							)
						)
					AND	(	NewValue					= @p_vchNewValue
						OR	(	NewValue					IS	NULL
							AND	@p_vchNewValue				IS	NULL
							)
						)
					AND	(	Research_Comment_Id			= @p_intResearchCommentId
						OR	(	Research_Comment_Id			IS	NULL
							AND	@p_intResearchCommentId		IS	NULL
							)
						)
				)
			BEGIN
				--=====================================================================================================
				-- Action_Comment_Id, Cause_Comment_Id, @p_intResearchCommentId are not updated by
				--	dbo.spServer_DBMgrUpdWasteEvent
				--=====================================================================================================
				BEGIN TRANSACTION
				UPDATE	dbo.User_Defined_Events
				SET		Event_Id			= @p_intEventId			,
						NewValue			= @p_vchNewValue		,
						Action_Comment_Id	= @p_intActionCommentId	,
						Comment_Id			= @p_intCommentId		,
						Cause_Comment_Id	= @p_intCauseCommentId	,
						Research_Comment_Id	= @p_intResearchCommentId
				WHERE	UDE_Id				= @op_intUDEId
				IF	@@TRANCOUNT	>	0
				BEGIN
					COMMIT TRANSACTION
				END
			END
			-----------------------------------------------------------------------------------------------------------
			--	Send back a Result Set to be published by the receiving application (either CalcMgr, EventMgr, or a Display)
			-----------------------------------------------------------------------------------------------------------
			SELECT
				[RSType]			= 8							,
				[PreDB]				= 1							,
				[UDEId]				= @op_intUDEId				,
				[UDENum]			= @p_vchUDEDesc				,
				[PUId]				= @p_intPUId				,
				[EventSubtypeId]	= @p_intSubtypeId			,
				[StartTime]			= @p_dtmStartTime			,
				[EndTime]			= @p_dtmEndTime				,
				[Duration]			= NULL						,
				[Ack]				= @p_bitAck					,
				[AckOn]				= @p_dtmAckOn				,
				[AckBy]				= @p_intAckBy				,
				[Cause1]			= @p_intCause1				,
				[Cause2]			= @p_intCause2				,
				[Cause3]			= @p_intCause3				,
				[Cause4]			= @p_intCause4				,
				[CauseCommentId]	= @p_intCauseCommentId		,
				[Action1]			= @p_intAction1				,
				[Action2]			= @p_intAction2				,
				[Action3]			= @p_intAction3				,
				[Action4]			= @p_intAction4				,
				[ActionCommentId]	= @p_intActionCommentId		,
				[ResearchUserId]	= NULL						,
				[ResearchStatusId]	= NULL						,
				[ResearchOpenDate]	= NULL						,
				[ResearchCloseDate]	= NULL						,
				[ResearchCommentId]	= @p_intResearchCommentId	,
				[UDECommentId]		= @p_intCommentId			,
				[TransType]			= @p_intTransactionType		,
				[EventSubTypeDesc]	= @vchSubtypeDesc			,
				[TransNum]			= @intTransNum				,
				[UserId]			= @p_intUserId				,
				[ESignature]		= NULL
		END 
		ELSE
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Set Error Section
			-----------------------------------------------------------------------------------------------------------
			SELECT	@vchErrorSection	= 'User Defined Event'				,
					@vchNestedObject	= 'spServer_DBMgrUpdUserEvent'	,
					@nvchErrorMessage	= NULL
			-----------------------------------------------------------------------------------------------------------
			--	Start a Try And add a transaction clause
			-----------------------------------------------------------------------------------------------------------
			BEGIN TRY
				--=====================================================================================================
				--	Write a new, or update an existing, User Defined Event record within the database.
				--=====================================================================================================
				EXEC	@intReturnCode	= dbo.spServer_DBMgrUpdUserEvent
					@intTransNum			,	--	@TransNum
					@vchSubtypeDesc			,	--	@EventSubTypeDesc
					@p_intActionCommentId	,	--	@ActionCommentId
					@p_intAction4			,	--	@Action4
					@p_intAction3			,	--	@Action3
					@p_intAction2			,	--	@Action2
					@p_intAction1			,	--	@Action1
					@p_intCauseCommentId	,	--	@CauseCommentId
					@p_intCause4			,	--	@Cause4
					@p_intCause3			,	--	@Cause3
					@p_intCause2			,	--	@Cause2
					@p_intCause1			,	--	@Cause1
					@p_intAckBy				,	--	@AckBy
					@p_bitAck				,	--	@Ack
					NULL					,	--	@Duration
					@p_intSubtypeId			,	--	@EventSubTypeId
					@p_intPUId				,	--	@PUId
					@p_vchUDEDesc			,	--	@EventNum
					@op_intUDEId	OUTPUT	,	--	@UDE_Id
					@p_intUserId			,	--	@UserId
					@p_dtmAckOn				,	--	@AckOn
					@p_dtmStartTime			,	--	@StartTime
					@p_dtmEndTime			,	--	@EndTime
					@p_intResearchCommentId	,	--	@ResearchCommentId
					NULL					,	--	@ResearchStatusId
					NULL					,	--	@ResearchUserId
					NULL					,	--	@ResearchOpenDate
					NULL					,	--	@ResearchCloseDate
					@p_intTransactionType	,	--	@TransType
					@p_intCommentId			,	--	@UDECommentId
					@intReasonTreeDataId	,	--	@Event_Reason_Tree_Data_Id
					NULL						--	@SignatureId
				-------------------------------------------------------------------------------------------------------
				--	If the SP returns an error, it sets the properly the error message
				-------------------------------------------------------------------------------------------------------
				IF	@intReturnCode < 0
				BEGIN
					SELECT	@nvchErrorMessage	= 'The insert/update call to spServer_DBMgrUpdUserEvent returned an error.  Code = '
												+ COALESCE(CONVERT(VARCHAR(25), @intReturnCode), 'BLANK')
					--=================================================================================================
					--	Return	Error
					--=================================================================================================
					RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
				END
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
			-----------------------------------------------------------------------------------------------------------
			--	Connect the User Defined Event to the Production Event.  There is no way to set the "Event_Id" field and
			--	"New_Value" field through the spServer SP, so we have to do a direct update to the record.
			--	Same For Comment_Id
			--	Same for "Parent_UDE_Id" field.
			-----------------------------------------------------------------------------------------------------------
			IF		@p_intEventId			IS	NOT	NULL
				OR	@p_intParentUDEId		IS	NOT	NULL
				OR	@p_vchNewValue			IS	NOT	NULL
				OR	@p_intActionCommentId	IS	NOT	NULL
				OR	@p_intCommentId			IS	NOT	NULL
				OR	@p_intResearchCommentId	IS	NOT	NULL
				OR	@p_intCauseCommentId	IS	NOT	NULL
				OR	@p_intActionCommentId	IS	NOT NULL
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Set Error Section
				-------------------------------------------------------------------------------------------------------
				SELECT	@vchErrorSection	= 'Update User Defined Events'	,
						@vchNestedObject	= 'User_Defined_Events'		,
						@nvchErrorMessage	= NULL
				-------------------------------------------------------------------------------------------------------
				--	Update the field that can't be updated using the SP server
				-------------------------------------------------------------------------------------------------------
				BEGIN TRANSACTION
				BEGIN TRY
					UPDATE	dbo.User_Defined_Events
					SET		Event_Id			= @p_intEventId			,
							Parent_UDE_Id		= @p_intParentUDEId		,
							NewValue			= @p_vchNewValue		,
							Action_Comment_Id	= @p_intActionCommentId	,
							Comment_Id			= @p_intCommentId		,
							Research_Comment_Id	= @p_intResearchCommentId,
							Cause_Comment_Id	= @p_intCauseCommentId	
					WHERE	UDE_Id	= @op_intUDEId
				END TRY
				BEGIN CATCH
					--=================================================================================================
					--  Rollback Transaction
					--=================================================================================================
					IF	@@TRANCOUNT	>	0
					BEGIN
						ROLLBACK TRANSACTION
					END
					---------------------------------------------------------------------------------------------------
					--	Set error message
					---------------------------------------------------------------------------------------------------
					SELECT	@nvchErrorMessage	= COALESCE(@nvchErrorMessage, ERROR_MESSAGE())
					---------------------------------------------------------------------------------------------------
					--	Raise Error
					---------------------------------------------------------------------------------------------------
					RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
				END CATCH
				--=====================================================================================================
				--  Commit Transaction
				--=====================================================================================================
				IF	@@TRANCOUNT	>	0
				BEGIN
					COMMIT TRANSACTION
				END
			END
		END
	END
	-------------------------------------------------------------------------------------------------------------------
	--	If the transaction type is DELETE
	-------------------------------------------------------------------------------------------------------------------
	ELSE	IF	@p_intTransactionType = 3
	BEGIN
		SELECT	@p_intSubtypeId	= Event_Subtype_Id	,
				@p_intPUId		= PU_Id				,
				@p_vchUDEDesc	= UDE_Desc			,
				@p_dtmStartTime	= Start_Time		,
				@p_dtmEndTime	= End_Time
		FROM	dbo.User_Defined_Events		WITH(NOLOCK)
		WHERE	UDE_Id	= @op_intUDEId
		---------------------------------------------------------------------------------------------------------------
		--	GET the Subtype Description 
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchSubtypeDesc		= Event_Subtype_Desc
		FROM	dbo.Event_Subtypes	WITH(NOLOCK)
		WHERE	Event_Subtype_Id	= @p_intSubtypeId
		--=============================================================================================================
		--	Write a new User Defined Event record into the database.
		--=============================================================================================================
		--	Set Error Section
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchErrorSection	= 'Call UDE Procedure'				,
				@vchNestedObject	= 'dbo.spServer_DBMgrUpdUserEvent'	,
				@nvchErrorMessage	= NULL
		---------------------------------------------------------------------------------------------------------------
		--	Start a Try and add a transaction clause
		---------------------------------------------------------------------------------------------------------------
		BEGIN TRY
				EXEC	@intReturnCode	= dbo.spServer_DBMgrUpdUserEvent
					@intTransNum				,	--	@TransNum
					@vchSubtypeDesc				,	--	@EventSubTypeDesc
					@p_intActionCommentId		,	--	@ActionCommentId
					@p_intAction4				,	--	@Action4
					@p_intAction3				,	--	@Action3
					@p_intAction2				,	--	@Action2
					@p_intAction1				,	--	@Action1
					@p_intCauseCommentId		,	--	@CauseCommentId
					@p_intCause4				,	--	@Cause4
					@p_intCause3				,	--	@Cause3
					@p_intCause2				,	--	@Cause2
					@p_intCause1				,	--	@Cause1
					@p_intAckBy					,	--	@AckBy
					@p_bitAck					,	--	@Ack
					NULL						,	--	@Duration
					@p_intSubtypeId				,	--	@EventSubTypeId
					@p_intPUId					,	--	@PUId
					@p_vchUDEDesc				,	--	@EventNum
					@op_intUDEId		OUTPUT	,	--	@UDE_Id
					@p_intUserId				,	--	@UserId
					@p_dtmAckOn					,	--	@AckOn
					@p_dtmStartTime				,	--	@StartTime
					@p_dtmEndTime				,	--	@EndTime
					@p_intResearchCommentId		,	--	@ResearchCommentId
					NULL						,	--	@ResearchStatusId
					NULL						,	--	@ResearchUserId
					NULL						,	--	@ResearchOpenDate
					NULL						,	--	@ResearchCloseDate
					@p_intTransactionType		,	--	@TransType
					@p_intCommentId				,	--	@UDECommentId
					NULL							--	@Event_Reason_Tree_Data_Id
			-----------------------------------------------------------------------------------------------------------
			--	If the SP returns an error, it sets the properly the error message
			-----------------------------------------------------------------------------------------------------------
			IF	@intReturnCode	<	0
			BEGIN
				SELECT	@nvchErrorMessage	= 'The delete call to spServer_DBMgrUpdUserEvent returned an error.  Code = '
											+ COALESCE(CONVERT(VARCHAR(25), @intReturnCode), 'BLANK')
				--=====================================================================================================
				--	Return	Error
				--=====================================================================================================
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END TRY
		BEGIN CATCH
			--=========================================================================================================
			--	Rollback Transaction
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
