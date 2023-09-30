--==============================================================================================================================================
--	Name:		 		spLocal_E2P_FPP_Lines_List
--	Type:				Stored Procedure
--	Editor Tab Spacing: 4	
--==============================================================================================================================================
--	DESCRIPTION: 
--
--	Returns the list of production lines, added with a column declaring whether the line is associated to selected FPP or not.
--
--==============================================================================================================================================
--	EDIT HISTORY:
------------------------------------------------------------------------------------------------------------------------------------------------
--	Revision		Date		Who					What
--	========		====		===					====
--	1.0				2020-02-18	Keven Abel			Initial Development
--==============================================================================================================================================
--	CALLING EXAMPLE Statement:
------------------------------------------------------------------------------------------------------------------------------------------------
/*
DECLARE
@ErrorGUID			UNIQUEIDENTIFIER	,
@ValidationCode		INT					,
@ValidationMessage	VARCHAR(MAX)		,
@DebugFlag			BIT

SET	@DebugFlag	=	0

EXECUTE	dbo.spLocal_E2P_FPP_Lines_List
		@op_ErrorGUId			=	@ErrorGUID			OUTPUT	,
		@op_ValidationCode		=	@ValidationCode		OUTPUT	,
		@op_ValidationMessage	=	@ValidationMessage	OUTPUT	,
		@p_DebugFlag			=	@DebugFlag					,
		@p_FPPId				=	6

SELECT	@ErrorGUID			AS	[Error GUID]				,
		@ValidationCode		AS	[Validation Code]			,
		@ValidationMessage	AS	[Validation Message]
*/
--==============================================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_E2P_FPP_Lines_List]
	@op_ErrorGUID			UNIQUEIDENTIFIER	= NULL	OUTPUT	,	
	@op_ValidationCode		INT					= NULL	OUTPUT	,	--	<-1	: Expected Critical Errors
																	--	-1	: Unexpected Critical Errors
																	--	0	: Success
																	--	>0	: Warning
	@op_ValidationMessage	VARCHAR(MAX)		= NULL	OUTPUT	,	--	Validation Message
	@p_DebugFlag			BIT					= 0				,
	@p_FPPId				INT
AS
SET NOCOUNT ON
--==============================================================================================================================================
--	DECLARE VARIABLES
--	The following variables will be used as internal variables to this Stored Procedure.
--==============================================================================================================================================
DECLARE
@StatusNewVersion	INT				,
@ProcessingStatus	INT				,
@UniqueId			VARCHAR(100)	,
@Version			VARCHAR(10)
--==============================================================================================================================================
--	DECLARE TABLES
--	The following tables will be used as internal tables to this Stored Procedure.
--==============================================================================================================================================
--==============================================================================================================================================
--	DECLARE TEMPORARY TABLES
--	The following tables will be used as temporary tables to this Stored Procedure and others. Will be dropped after SP completion.
--==============================================================================================================================================
--==============================================================================================================================================
--	The following variables and constants that are used for error handling logic
--==============================================================================================================================================
DECLARE
@ReturnCode			INT				,
@NestingLevel		INT				,
@PrimaryObjectFlag	INT				,
@ErrorSeverity		INT				,
@ERROR_CRITICAL		INT				,
@ERROR_WARNING		INT				,
@ERROR_INFO			INT				,
@ERROR_NONE			INT				,
@OBJECT_NAME		NVARCHAR(256)	,
@ErrorState			INT				,
@SeverityLevel		INT				,
@NestedObjectName	NVARCHAR(256)	,
@ErrorSection		VARCHAR(100)	,
@ErrorWasLogged		BIT
--==============================================================================================================================================
--	DECLARE VARIABLE CONSTANTS
--	The following variables will be used as internal constants to this Stored Procedure.
--==============================================================================================================================================
DECLARE
@DEAD_PREFIX		NVARCHAR(10)	,
@RAW_MATERIALS		NVARCHAR(20)	,
@STATUS_NEW_VERSION	NVARCHAR(30)
--==============================================================================================================================================
--	INITIALIZE VARIABLE CONSTANTS
--	Use this section to initialize variables and set valuse for any variable constants.
--==============================================================================================================================================
SET	@DEAD_PREFIX		=	'zobs%'
SET	@RAW_MATERIALS		=	'%Raw Materials%'
SET	@STATUS_NEW_VERSION	=	'New Version'
------------------------------------------------------------------------------------------------------------------------------------------------
--	Set constants used for error handling
------------------------------------------------------------------------------------------------------------------------------------------------
SET @ERROR_CRITICAL		=	-1
SET @ERROR_NONE			=	0
SET @ERROR_WARNING		=	1
SET @ERROR_INFO			=	2
SET @ErrorSeverity		=	11
SET @ErrorState			=	1
SET @ErrorWasLogged		=	0
SET @NestingLevel		=	@@NESTLEVEL
SET @OBJECT_NAME		=	COALESCE(OBJECT_NAME(@@ProcId), 'SCRIPTED_spLocal_E2P_FPP_Lines_List')
--==============================================================================================================================================
--	The @op_ErrorGUID parameter is used to determine if the SP has been called by another SP.  If the value is null
--	then it is assumed that this SP is the top level SP.
--	
--	If it is the top level SP then get a unique identifier that will be used to log error messages and set the flag
--	to indicate that this SP is the primary SP.
--==============================================================================================================================================
IF @op_ErrorGUID IS NULL
BEGIN
	SET @op_ErrorGUID		= NEWID()
	SET @PrimaryObjectFlag	= 1
END
ELSE
BEGIN
	SET @PrimaryObjectFlag = 0
END
--==============================================================================================================================================
--	BEGIN LOGIC
--==============================================================================================================================================
BEGIN TRY
	IF @p_DebugFlag = 1
	BEGIN
		SET @ErrorSection			=	@OBJECT_NAME + ' <STARTING>'

		SET @op_ValidationMessage	=	'@p_FPPId = '	+ COALESCE(CONVERT(NVARCHAR(1000),	@p_FPPId		), 'NULL')

		EXECUTE	dbo.spLocal_PG_Cmn_LogErrorMessage
					@p_uidErrorId				=	@op_ErrorGUID			,
					@p_intNestingLevel			=	@NestingLevel			,
					@p_vchNestedObjectName		=	@NestedObjectName		,
					@p_vchObjectName			=	@OBJECT_NAME			,
					@p_vchErrorSection			=	@ErrorSection			,
					@p_nvchErrorMessage			=	@op_ValidationMessage	,
					@p_intErrorSeverity			=	NULL					,
					@p_intErrorState			=	NULL					,
					@p_bitPrimaryObjectFlag		=	@PrimaryObjectFlag		,
					@p_intErrorSeverityLevel	=	@ERROR_INFO
	END
	--==========================================================================================================================================
	--	VALIDATE STORED PROCEDURE INPUT PARAMETERS
	--==========================================================================================================================================
	SET @ErrorSection			= 'Validate Input Parameters'
	SET @NestedObjectName		= ''
	SET @op_ValidationMessage	= NULL
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	StatusId
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF	@p_FPPId	IS NOT NULL
	AND	NOT EXISTS	(
						SELECT	1
						FROM	dbo.Local_E2P_Received_FPP	WITH(NOLOCK)
						WHERE	FPPId	=	@p_FPPId
					)
	BEGIN
		SET	@op_ValidationCode		=	-2
		SET @op_ValidationMessage	=	'Entered input for FPP [' + COALESCE(CONVERT(VARCHAR(10), @p_FPPId),	'NULL') + '] not found. Cannot proceed.'		
		RAISERROR(@op_ValidationMessage, @ErrorSeverity, @ErrorState)
	END
	--==========================================================================================================================================
	-- 	RETRIEVE PRODUCT RESULT SET
	--==========================================================================================================================================
	SET	@StatusNewVersion	=	(
									SELECT	fs.StatusId
									FROM	dbo.Local_E2P_Received_FPP_Statuses	fs	WITH(NOLOCK)
									WHERE	fs.[Description]	=	@STATUS_NEW_VERSION
								)

	IF	@StatusNewVersion	IS NULL
	BEGIN
		SET @op_ValidationMessage	=	'Status "' + @STATUS_NEW_VERSION + '" not found. Unable to retrieve previously assigned lines.'

		EXEC	dbo.spLocal_PG_Cmn_LogErrorMessage
			@p_uidErrorId				=	@op_ErrorGUID			,
			@p_intNestingLevel			=	@NestingLevel			,
			@p_vchNestedObjectName		=	@NestedObjectName		,
			@p_vchObjectName			=	@OBJECT_NAME			,
			@p_vchErrorSection			=	@ErrorSection			,
			@p_nvchErrorMessage			=	@op_ValidationMessage	,
			@p_intErrorSeverity			=	NULL					,
			@p_intErrorState			=	NULL					,
			@p_bitPrimaryObjectFlag		=	@PrimaryObjectFlag		,
			@p_intErrorSeverityLevel	=	@ERROR_INFO
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Check for historical data. If Processing status is 'New Version', we get the earlier line assignments and reassign FPPId to previous version
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET	@ProcessingStatus	=	NULL
	SET	@UniqueId			=	NULL
	SET @Version			=	NULL

	SELECT	@ProcessingStatus	=	ProcessingStatus	,
			@UniqueId			=	UniqueId			,
			@Version			=	[Version]
	FROM	dbo.Local_E2P_Received_FPP	WITH(NOLOCK)
	WHERE	FPPId				=	@p_FPPId

	IF	@ProcessingStatus	=	@StatusNewVersion
	BEGIN
		SET	@p_FPPId	=	(
								SELECT	FPPId
								FROM	dbo.Local_E2P_Received_FPP	WITH(NOLOCK)
								WHERE	UniqueId	=	@UniqueId
								AND		CONVERT(INT,	[Version])	<	CONVERT(INT,	@Version)
							)
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Get list of lines
	--------------------------------------------------------------------------------------------------------------------------------------------
	;WITH	CTE	(LineId)
	AS
	(
		SELECT	LineId
		FROM	dbo.Local_E2P_Received_FPP_Lines	WITH(NOLOCK)
		WHERE	FPPId		=	@p_FPPId
	)
	SELECT	pl.PL_Id												,
			pl.PL_Desc												,
			IIF(c.LineId	IS NOT NULL, 1, 0)	AS	[AssignedToFPP]	
	FROM	dbo.Prod_Lines_Base		pl	WITH(NOLOCK)
	LEFT
	JOIN	CTE						c	ON	c.LineId	=	pl.PL_Id
	WHERE	pl.PL_Id	>	0
	AND		pl.PL_Desc	NOT LIKE	@DEAD_PREFIX
	AND		pl.PL_Desc	NOT LIKE	@RAW_MATERIALS
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Stored procedure was executed successfully
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET	@op_ValidationCode		= @ERROR_NONE
END TRY
--==============================================================================================================================================
--	Log critcal error messages raised in the main body of logic.
--==============================================================================================================================================
BEGIN CATCH
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	If crashed out of nowhere, put internal error code
	--------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Assign error message parameter values.
	--------------------------------------------------------------------------------------------------------------------------------------------	
	SET @op_ValidationMessage   = ERROR_MESSAGE()
	SET @ErrorState				= ERROR_STATE()
	SET @ErrorWasLogged			= 1
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	If the stored procedure is nested, we can't reraise the error to the calling stored procedure since we are losing the OUTPUT
	--	parameters values.  We are then assigning an error severity of 10 in order of logging the error to Local_PG_ErrorLogDetail but this
	--	will not raise an error to the calling stored procedure.  Calling stored procedure needs to check @op_ValidationCode DataFieldValue to know
	--	if an error occurred or not.
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF @PrimaryObjectFlag = 0
	BEGIN
		SET @ErrorSeverity	= 10
	END
	ELSE
	BEGIN
		SET @ErrorSeverity	= ERROR_SEVERITY()
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Set the output validation code parameter to a critical error if it still NULL
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF @op_ValidationCode IS NULL
	BEGIN
		SET	@op_ValidationCode = @ERROR_CRITICAL
	END
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Log error message.
	--------------------------------------------------------------------------------------------------------------------------------------------
    EXECUTE dbo.spLocal_PG_Cmn_LogErrorMessage
				@p_uidErrorId				=	@op_ErrorGUID			,
				@p_intNestingLevel			=	@NestingLevel			,
				@p_vchNestedObjectName		=	@NestedObjectName		,
				@p_vchObjectName			=	@OBJECT_NAME			,
				@p_vchErrorSection			=	@ErrorSection			,
				@p_nvchErrorMessage			=	@op_ValidationMessage	,
				@p_intErrorSeverity			=	@ErrorSeverity			,
				@p_intErrorState			=	@ErrorState				,
				@p_bitPrimaryObjectFlag		=	@PrimaryObjectFlag		,
				@p_intErrorCode				=	@op_ValidationCode		,
				@p_intErrorSeverityLevel	=	@ERROR_CRITICAL
END CATCH		
--==============================================================================================================================================
--	TRAP Errors
--	Set return code and error id output values
--==============================================================================================================================================
Finish:
IF	@ErrorWasLogged		= 0
AND @PrimaryObjectFlag	= 1
BEGIN
	SET @op_ErrorGUID = NULL
END

IF @ErrorWasLogged = 1
BEGIN
	SET @ReturnCode = @ERROR_CRITICAL
END
ELSE
BEGIN
	SET @ReturnCode = @ERROR_NONE
END

RETURN @ReturnCode
--==============================================================================================================================================
--	Finish
--==============================================================================================================================================
SET NOCOUNT OFF
