--==============================================================================================================================================
--	Name:		 		spLocal_E2P_RMUI_LogMessage
--	Type:				Stored Procedure
--	Editor Tab Spacing: 4	
--==============================================================================================================================================
--	DESCRIPTION: 
--
--	Logs a message in processing section -- reject FPP is possible.
--
--==============================================================================================================================================
--	EDIT HISTORY:
------------------------------------------------------------------------------------------------------------------------------------------------
--	Revision		Date		Who					What
--	========		====		===					====
--	1.0				2020-04-28	Keven Abel			Initial Development
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

EXECUTE	dbo.spLocal_E2P_RMUI_LogMessage
		@op_ErrorGUId			=	@ErrorGUID			OUTPUT	,
		@op_ValidationCode		=	@ValidationCode		OUTPUT	,
		@op_ValidationMessage	=	@ValidationMessage	OUTPUT	,
		@p_DebugFlag			=	@DebugFlag					,
		@p_FPPId				=	198

SELECT	@ErrorGUID			AS	[Error GUID]				,
		@ValidationCode		AS	[Validation Code]			,
		@ValidationMessage	AS	[Validation Message]
*/
--==============================================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_E2P_RMUI_LogMessage]
	@op_ErrorGUID			UNIQUEIDENTIFIER	= NULL	OUTPUT	,	
	@op_ValidationCode		INT					= NULL	OUTPUT	,	--	<-1	: Expected Critical Errors
																	--	-1	: Unexpected Critical Errors
																	--	0	: Success
																	--	>0	: Warning
	@op_ValidationMessage	VARCHAR(MAX)		= NULL	OUTPUT	,	--	Validation Message
	@p_DebugFlag			BIT					= 0				,
	@p_FPPId				INT                                 ,
    @p_MessageType          VARCHAR(10)                         ,
    @p_Content              VARCHAR(MAX)                        ,
    @p_RejectFPP            BIT                 = 0
AS
SET NOCOUNT ON
--==============================================================================================================================================
--	DECLARE VARIABLES
--	The following variables will be used as internal variables to this Stored Procedure.
--==============================================================================================================================================
--==============================================================================================================================================
--	DECLARE TABLES
--	The following tables will be used as internal tables to this Stored Procedure.
--==============================================================================================================================================
--==============================================================================================================================================
--	DECLARE TEMPORARY TABLES
--	The following tables will be used as temporary tables to this Stored Procedure and others. Will be dropped after SP completion.
--==============================================================================================================================================
IF	OBJECT_ID(N'tempdb..#ProcessingMessages')	IS NOT NULL
BEGIN
    CREATE TABLE	#ProcessingMessages
    (
        RowNumber	INT IDENTITY(1,1)	,
        [Type]		VARCHAR(10)			,
        [Message]	VARCHAR(MAX)
    )
END
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
@TYPE_INFO          VARCHAR(10) ,
@PROCESSING_SECTION VARCHAR(10)
--==============================================================================================================================================
--	INITIALIZE VARIABLE CONSTANTS
--	Use this section to initialize variables and set valuse for any variable constants.
--==============================================================================================================================================
SET @TYPE_INFO          =   'INFO'
SET @PROCESSING_SECTION =   'Processing'
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
SET @OBJECT_NAME		=	COALESCE(OBJECT_NAME(@@ProcId), 'SCRIPTED_spLocal_E2P_RMUI_LogMessage')
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
	--	FPPId
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
	-- 	Log message
	--==========================================================================================================================================
	INSERT INTO #ProcessingMessages
    (
        [Type] ,
        [Message]
    )
    SELECT  COALESCE(@p_MessageType ,   @TYPE_INFO)  ,
            @p_Content
    --------------------------------------------------------------------------------------------------------------------------------------------
    --  Reject FPP if needed
    --------------------------------------------------------------------------------------------------------------------------------------------
    IF  @p_RejectFPP    =   1
    BEGIN
        EXEC	spLocal_E2P_RMUI_FPP_Reject
            @op_ErrorGUId			=	@op_ErrorGUID			OUTPUT	,
            @op_ValidationCode		=	@op_ValidationCode		OUTPUT	,
            @op_ValidationMessage	=	@op_ValidationMessage	OUTPUT	,
            @p_DebugFlag			=	@p_DebugFlag					,
            @p_FPPId				=	@p_FPPId						,
            @p_Username				=	NULL							,
            @p_Section				=	@PROCESSING_SECTION				,
            @p_Comment				=	@op_ValidationMessage			,
            @p_IsManual				=	0
    END
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
