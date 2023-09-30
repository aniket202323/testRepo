
--==============================================================================================================================================
--	Name:		 		spLocal_PG_MESWebService_CmdExecute_Test
--	Type:				Stored Procedure
--	Editor Tab Spacing: 4	
--==============================================================================================================================================
--	DESCRIPTION: 
--	Stored procedure as a template and example of a command called from dbo.spLocal_PG_WebService_CmdExecute
--==============================================================================================================================================
--	BUSINESS RULES:
--	Enter the business rules in this section...
--	1.	Declare Variables 
--	2.	Declare Tables 
--	3.	Initialize Variables & Constants
--	4.	Validate Input Parameters
--	5.	Trap Errors
--==============================================================================================================================================
--	EDIT HISTORY:
------------------------------------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who						What
--	========	====		===						====
--	1.0			2016-11-03	Daniel Rodriguez-Demers	Initial Development
--==============================================================================================================================================
--	EXEC Statement:
------------------------------------------------------------------------------------------------------------------------------------------------
--	The DECLARE, SELECT, and EXEC statements in the following example should match the stored procedure input
--	parameters.
/*
DECLARE
@op_ErrorGUID			UNIQUEIDENTIFIER	= NULL,
@op_ValidationCode		INT					= NULL,
@op_ValidationMessage	VARCHAR(MAX)		= NULL,
@op_OutputXml			VARCHAR(MAX)		= NULL,
@p_DebugFlag			BIT					= 1,
@p_InputXml				VARCHAR(MAX)		= NULL,
@p_UserId				INT,
@p_TransactionId		INT					= NULL

SET	@p_InputXml = '<SentMessage><to>BD</to><from>Test Stored Procedure</from><heading>Test Stored Procedure Request</heading><body>Is everything fine?</body></SentMessage>'
	
EXEC	dbo.spLocal_PG_MESWebService_CmdExecute_Test
	@op_ErrorGUID			=	@op_ErrorGUID		OUTPUT,
	@p_DebugFlag			=	@p_DebugFlag,
	@op_OutputXml			=	@op_OutputXml,
	@p_InputXml				=	@p_InputXml,
	@p_UserId				=	@p_UserId,
	@p_TransactionId		=	@p_TransactionId,
	@op_ValidationCode		=	@ValidationCode		OUTPUT,
	@op_ValidationMessage	=	@ValidationMessage	OUTPUT

SELECT	@ValidationCode		AS	[Code],
		@ValidationMessage	AS	[Message],
		@op_OutputXml		AS	[Output Xml]
			   
SELECT	*
FROM	dbo.fnLocal_PG_Cmn_ErrorMessageByUniqueId(@op_ErrorGUID)
*/
--==============================================================================================================================================

CREATE PROCEDURE [dbo].[spLocal_PG_MESWebService_CmdExecute_Test]
	@op_ErrorGUID			UNIQUEIDENTIFIER	= NULL	OUTPUT,
	@op_ValidationCode		INT					= NULL	OUTPUT,	--	Negative: Critical Error, 0: Success, Positive :Warning
	@op_ValidationMessage	VARCHAR(MAX)		= NULL	OUTPUT,
	@op_OutputXml			VARCHAR(MAX)		= NULL  OUTPUT,
	@p_DebugFlag			BIT					= 0,
	@p_InputXml				VARCHAR(MAX)		= NULL,
	@p_UserId				INT					= NULL,
	@p_TransactionId		INT					= NULL

AS
SET NOCOUNT ON

--==============================================================================================================================================
--	1.	Declare Variables
--	The following variables will be used as internal variables to this Stored Procedure.
--==============================================================================================================================================
--	The following variables are used for error handling logic
--==============================================================================================================================================
DECLARE
@NestingLevel			INT,
@Primary				INT,
@ErrorSeverity			INT,
@ERROR_CRITICAL_CODE	INT,
@ERROR_WARNING_CODE		INT,
@ERROR_INFO_CODE		INT,
@ERROR_NONE_CODE		INT,
@OBJECT_NAME			VARCHAR(256),
@ErrorState				INT,
@SeverityLevel			INT,
@NestedObject			VARCHAR(256),
@ErrorSection			VARCHAR(100),
@ErrorWasLogged			Bit
--==============================================================================================================================================
--	DECLARE VARIABLE CONSTANTS
--	The following variables will be used as internal constants to this Stored Procedure.
--==============================================================================================================================================
--	2.	Declare Tables
--	The following Table Variables will be used to store temporary datasets within this Stored Procedure.
--==============================================================================================================================================
--	3.	Initialize Variables & Constants
--	Use this section to initialize variables and set valuse for any variable constants.
--==============================================================================================================================================
------------------------------------------------------------------------------------------------------------------------------------------------
--	Set constants used for error handling
------------------------------------------------------------------------------------------------------------------------------------------------
SET @ERROR_CRITICAL_CODE	= -1
SET @ERROR_NONE_CODE		= 0
SET @ERROR_WARNING_CODE		= 1
SET @ERROR_INFO_CODE		= 2
SET @ErrorSeverity			= 11
SET @ErrorState				= 1
SET @NestingLevel			= @@NESTLEVEL
SET @OBJECT_NAME			= OBJECT_NAME(@@ProcId)
--==============================================================================================================================================
--	The @op_ErrorGUID parameter is used to determine if the SP has been called by another SP.  If the value is null
--	then it is assumed that this SP is the top level SP.
--	
--	If it is the top level SP then get a unique identifier that will be used to log error messages and set the flag
--	to indicate that this SP is the primary SP.
--==============================================================================================================================================
IF @op_ErrorGUID IS NULL
BEGIN
	SET @op_ErrorGUID	= NEWID()
	SET @Primary	= 1
END
ELSE
BEGIN
	SET @Primary	= 0
END
--==============================================================================================================================================
--	BEGIN LOGIC
--==============================================================================================================================================
BEGIN TRY
	IF  @p_DebugFlag = 1
	BEGIN
		SET @op_ValidationCode		=	NULL
		SET @ErrorSection			=	'Debug Section 1'
		SET @op_ValidationMessage	=	' @op_OutputXml = '
									+ COALESCE(CONVERT(VARCHAR(MAX), @op_OutputXml	), 'BLANK')
									+', @p_InputXml= '
									+ COALESCE(CONVERT(VARCHAR(MAX), @p_InputXml	), 'BLANK')
									+', @p_UserId = '
									+ COALESCE(CONVERT(VARCHAR(25), @p_UserId		), 'BLANK')

		EXECUTE @op_ValidationCode = dbo.spLocal_SSI_Cmn_LogErrorMessage
									@p_uidErrorId				= @op_ErrorGUID,
									@p_intNestingLevel			= @NestingLevel,
									@p_vchNestedObjectName		= @NestedObject,
									@p_vchObjectName			= @OBJECT_NAME,
									@p_vchErrorSection			= @ErrorSection,
									@p_nvchErrorMessage			= @op_ValidationMessage,
									@p_intErrorSeverity			= NULL,
									@p_intErrorState			= NULL,
									@p_bitPrimaryObjectFlag		= @Primary,
									@p_intErrorSeverityLevel	= @ERROR_INFO_CODE
	END
	--==========================================================================================================================================
	--	4.	Validate Input Parameters
	--==========================================================================================================================================
	--	Initialize section variables
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET @ErrorSection			= 'Validate Input parameters'
	SET @NestedObject			= ''
	SET @op_ValidationMessage	= NULL
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Validate Input parameters
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	a.	@p_UserId
	--		Business Rule
	--			Fatal Error if NULL
	--------------------------------------------------------------------------------------------------------------------------------------------
	IF NOT EXISTS
	(
		SELECT	[User_Id]
		FROM	dbo.Users WITH(NOLOCK)
		WHERE	[User_Id] = @p_UserId
	)
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Set the Error Message
		----------------------------------------------------------------------------------------------------------------------------------------
		SET @op_ValidationMessage	=	'@p_UserId is invalid. User_Id = '
										+ COALESCE(CONVERT(VARCHAR(25), @p_UserId), 'BLANK')
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Raise Error		
		----------------------------------------------------------------------------------------------------------------------------------------
		RAISERROR( @op_ValidationMessage, @ErrorSeverity, @ErrorState)	
	END
	--==========================================================================================================================================
	--	GET DATA
	--	Section contains the business logic for the stored procedure
	--==========================================================================================================================================
	--	Initialize section variables
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET @ErrorSection			= 'Get Data'
	SET @NestedObject			= ''
	SET @op_ValidationMessage	= NULL
	--------------------------------------------------------------------------------------------------------------------------------------------
	BEGIN TRY
		--======================================================================================================================================
		--	THIS IS AN EXAMPLE, REPLACE THIS CODE WITH THE FUNCTION YOU NEED
		--======================================================================================================================================
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Initialize section variables
		----------------------------------------------------------------------------------------------------------------------------------------
		SET @ErrorSection			= 'Get plant name from site parameters'
		SET @NestedObject			= ''
		SET @op_ValidationMessage	= NULL

		SET	@op_OutputXml	= '<ReturnMessage><to>Tester</to><from>Test Stored Procedure</from><heading>Test Stored Procedure Answer</heading><body>Everything is up and running!</body></ReturnMessage>'
	END TRY
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Catch Error and RAISE Error	to next TRY/CATCH Block	
	--------------------------------------------------------------------------------------------------------------------------------------------
	BEGIN CATCH
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Set the Error Message
		----------------------------------------------------------------------------------------------------------------------------------------
		SET @op_ValidationMessage = COALESCE(@op_ValidationMessage, ERROR_MESSAGE())
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Raise Error		
		----------------------------------------------------------------------------------------------------------------------------------------
		RAISERROR(@op_ValidationMessage, @ErrorSeverity, @ErrorState)
	END CATCH	
END TRY
BEGIN CATCH
	SET @op_ValidationCode		= NULL
	SET @op_ValidationMessage   = ERROR_MESSAGE()
	SET @ErrorSeverity			= ERROR_SEVERITY()
	SET @ErrorState				= ERROR_STATE()
	
    EXEC @op_ValidationCode = dbo.spLocal_SSI_Cmn_LogErrorMessage
							@p_uidErrorId				= @op_ErrorGUID,
							@p_intNestingLevel			= @NestingLevel,
							@p_vchNestedObjectName		= @NestedObject,
							@p_vchObjectName			= @OBJECT_NAME,
							@p_vchErrorSection			= @ErrorSection,
							@p_nvchErrorMessage			= @op_ValidationMessage,
							@p_intErrorSeverity			= @ErrorSeverity,
							@p_intErrorState			= @ErrorState,
							@p_bitPrimaryObjectFlag		= @Primary,
							@p_intErrorSeverityLevel	= @ERROR_CRITICAL_CODE
END CATCH		
--==============================================================================================================================================
--	5.	Trap Errors
--	Set return code and error id output values
--==============================================================================================================================================
ERRORFinish:

IF	EXISTS(
    SELECT	Error_Id
    FROM	dbo.Local_SSI_ErrorLogHeader	WITH(NOLOCK)
    WHERE	Error_Id = @op_ErrorGUID
	AND		Primary_Object_Name	= OBJECT_NAME(@@ProcId))
BEGIN
    SET	@op_ValidationCode	=	(
						SELECT	MIN(Error_Severity_Level)
						FROM    dbo.Local_SSI_ErrorLogDetail
						WHERE	Error_Id = @op_ErrorGUID
						AND		[Object_Name] = OBJECT_NAME(@@ProcId)
						)
    RETURN	@op_ValidationCode
END
ELSE
BEGIN
	IF @Primary = 1
	BEGIN
		SET @op_ErrorGUID = NULL
	END
    RETURN @ERROR_NONE_CODE
END
--==============================================================================================================================================
--	RETURN CODE
--==============================================================================================================================================
SET NOCOUNT OFF
RETURN
