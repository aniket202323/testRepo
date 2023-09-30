
--=====================================================================================================================
--	Name:		 		spLocal_SSI_Cmn_UserSecurityRoleUpdate
--	Type:				Stored Procedure
--	Editor Tab Spacing: 4	
--=====================================================================================================================
--	DESCRIPTION: 
--	The SP is used to refresh User_Security Table after the user is logged in.
--=====================================================================================================================
--	BUSINESS RULES:
--	Enter the business rules in this section...
--	1.	Validate User
--	2.	Call GE Stored Procedude dbo.spCSS_MaintainUserSecurityByRole
--=====================================================================================================================
--	EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who					What
--	========	====		===					====
--	1.0			2012-12-10	Luis Chaves			Initial Development
--	1.1			2013-05-24	Luis Chaves			Added validation to update an user only when it is Role Base Security
--=====================================================================================================================
--	EXEC Statement:
-----------------------------------------------------------------------------------------------------------------------
--	The DECLARE, SELECT, and EXEC statements in the following example should match the stored procedure input
--	parameters.
/*
	DECLARE
		@intReturnCode		INT				,
		@p_bitDebugFlag		BIT				,
		@p_intUserId		INT				,
		@op_uidErrorId		UNIQUEIDENTIFIER
	SELECT
		@p_bitDebugFlag		= NULL		,
		@p_intUserId		= 1			,
		@op_uidErrorId		= NULL
	EXEC	@intReturnCode	= dbo.spLocal_SSI_Cmn_UserSecurityRoleUpdate
		@op_uidErrorId		= @op_uidErrorId	OUTPUT	,
		@p_bitDebugFlag		= @p_bitDebugFlag			,
		@p_intUserId		= @p_intUserId
	IF	@intReturnCode	<> 0
	BEGIN
		SELECT	*
		FROM	dbo.fnLocal_SSI_Cmn_ErrorMessageByUniqueId(@op_uidErrorId)
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	dbo.User_Security	us	WITH(NOLOCK)
		WHERE	us.User_Id	= @p_intUserId
	END
*/
--=====================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_SSI_Cmn_UserSecurityRoleUpdate]
	@op_uidErrorId		UNIQUEIDENTIFIER	= NULL	OUTPUT	,
	@p_bitDebugFlag		BIT					= 0				,
	@p_intUserId		INT
AS
SET NOCOUNT ON
--=====================================================================================================================
--	DECLARE VARIABLES
--	The following variables will be used as internal variables to this Stored Procedure.
--=====================================================================================================================
--	INTEGER
-----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------
--	VARCHAR
-----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------
--	DATETIME
-----------------------------------------------------------------------------------------------------------------------
--=====================================================================================================================
--	The following variables are used for error handling logic
--=====================================================================================================================
DECLARE
	@intReturnCode		INT				,
	@intNestingLevel	INT				,
	@intPrimary			INT				,
	@intErrorSeverity	INT				,
	@consErrorCritical	INT				,
	@consErrorWarning	INT				,
	@consErrorInfo		INT				,
	@consErrorNone		INT				,
	@intErrorState		INT				,
	@intSeverityLevel	INT				,
	@intKeyId			INT				,
	@intTableId			INT				,
	@vchNestedObject	VARCHAR(256)	,
	@vchObjectName		VARCHAR(256)	,
	@nvchErrorMessage	NVARCHAR(2048)	,
	@vchErrorSection	VARCHAR(100)
--=====================================================================================================================
--	DECLARE VARIABLE CONSTANTS
--	The following variables will be used as internal constants to this Stored Procedure.
--=====================================================================================================================
DECLARE
	@vchConstRoleList	VARCHAR(1)
--=====================================================================================================================
--	DECLARE TABLE VARIABLES
--	The following Table Variables will be used to store temporary datasets within this Stored Procedure.
--=====================================================================================================================

--=====================================================================================================================
--	INITIALIZE VARIABLES and VARIABLE CONSTANTS
--	Use this section to initialize variables and set valuse for any variable constants.
--=====================================================================================================================
SELECT
	@vchConstRoleList	= '$'
-----------------------------------------------------------------------------------------------------------------------
--	Set constants used for error handling
-----------------------------------------------------------------------------------------------------------------------
SELECT
	@consErrorCritical	= -1					,
	@consErrorNone		= 0						,
	@consErrorWarning	= 1						,
	@consErrorInfo		= 2						,
	@intErrorSeverity	= 11					,
	@intErrorState		= 1						,
	@intNestingLevel	= @@NESTLEVEL			,														
	@vchObjectName		= OBJECT_NAME(@@ProcId)		
--=====================================================================================================================
--	The @op_uidErrorId parameter is used to determine if the SP has been called by another SP.  If the value is null
--	then it is assumed that this SP is the top level SP.
--	
--	If it is the top level SP then get a unique identifier that will be used to log error messages and set the flag
--	to indicate that this SP is the primary SP.
--=====================================================================================================================
IF	@op_uidErrorId IS NULL
BEGIN
	SELECT	@op_uidErrorId	= NEWID()	,
			@intPrimary		= 1
END
ELSE
BEGIN
	SELECT	@intPrimary	= 0
END
--=====================================================================================================================
--	These variables need to be initialized when the user knows the Id and the object that is working on
--=====================================================================================================================
SELECT	@intKeyId	=	NULL	,
		@intTableId	=	NULL
--=====================================================================================================================
--	BEGIN LOGIC
--=====================================================================================================================
BEGIN TRY
	IF  @p_bitDebugFlag = 1
	BEGIN
		SELECT
			@intReturnCode		= NULL				,
			@vchErrorSection	= 'Debug Section 1'   ,
			@nvchErrorMessage	= ' @p_intUserId = '
								+ COALESCE(CONVERT(VARCHAR(25), @p_intUserId	), 'BLANK')
		EXECUTE @intReturnCode			= dbo.spLocal_SSI_Cmn_LogErrorMessage
			@p_uidErrorId				= @op_uidErrorId		,
			@p_intNestingLevel			= @intNestingLevel		,
			@p_vchNestedObjectName		= @vchNestedObject		,
			@p_vchObjectName			= @vchObjectName		,
			@p_vchErrorSection			= @vchErrorSection		,
			@p_nvchErrorMessage			= @nvchErrorMessage		,
			@p_intErrorSeverity			= NULL					,
			@p_intErrorState			= NULL					,
			@p_bitPrimaryObjectFlag		= @intPrimary			,
			@p_intErrorSeverityLevel	= @consErrorInfo
	END
	--=================================================================================================================
	--	VALIDATE STORED PROCEDURE INPUT PARAMETERS
	--=================================================================================================================
	--	Initialize section variables
	-------------------------------------------------------------------------------------------------------------------
	SELECT	@vchErrorSection	= 'Validate Input parameters'	,																	
			@vchNestedObject	= ''							,
			@nvchErrorMessage	= NULL
	-------------------------------------------------------------------------------------------------------------------
	--	Validate Input parameters
	-------------------------------------------------------------------------------------------------------------------			
	--	a.	@p_intUserId
	-------------------------------------------------------------------------------------------------------------------
	--	a.	@p_intUserId
	--		Business Rule
	--			Fatal Error if NULL
	-------------------------------------------------------------------------------------------------------------------
	IF	NOT EXISTS(
		SELECT	u.User_Id
		FROM	dbo.Users	u	WITH(NOLOCK)
		WHERE	u.User_Id	= @p_intUserId
			AND	u.Active	= 1
			AND	System		= 0)
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		--	Set the Error Message
		---------------------------------------------------------------------------------------------------------------
		SELECT 	@nvchErrorMessage	= '@p_intUserId Is Invalid: User_Id = '
									+ COALESCE(CONVERT(VARCHAR(25), @p_intUserId	), 'BLANK')
									+ '. Please check the user is active and it is not a System user.'
		---------------------------------------------------------------------------------------------------------------	
		--	Raise Error		
		---------------------------------------------------------------------------------------------------------------
		RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)	
	END
	--=================================================================================================================
	--	NESTED STORED PROCEDURE CALL
	--	Use this section to call a nested stored procedure
	--=================================================================================================================
	BEGIN TRY
		IF	EXISTS(
			SELECT	u.User_Id
			FROM	dbo.Users	u
			WHERE	u.User_Id	= @p_intUserId
				AND	u.Role_Based_Security	= 1)
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Initialize section variables
			-----------------------------------------------------------------------------------------------------------
			SELECT	@vchErrorSection	= 'Update User Security Role'				,
					@vchNestedObject	= 'dbo.spCSS_MaintainUserSecurityByRole'	,
					@nvchErrorMessage	= NULL
			-----------------------------------------------------------------------------------------------------------
			--	Call nested stored procedure
			-----------------------------------------------------------------------------------------------------------
			EXEC	@intReturnCode	= dbo.spCSS_MaintainUserSecurityByRole
					@vchConstRoleList	,
					@p_intUserId
			-----------------------------------------------------------------------------------------------------------
			--	If the SP returns an error, it sets the properly the error message
			-----------------------------------------------------------------------------------------------------------
			IF	@intReturnCode	< 0
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Set error message
				-------------------------------------------------------------------------------------------------------
				SELECT	@nvchErrorMessage	= 'Error calling dbo.spCSS_MaintainUserSecurityByRole.'
											+ 'Return code = ' + CONVERT(VARCHAR(25), @intReturnCode)
				-------------------------------------------------------------------------------------------------------
				--	Raise error message
				-------------------------------------------------------------------------------------------------------
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
	END TRY
	-------------------------------------------------------------------------------------------------------------------	
	--	Catch Error and RAISE Error	to next TRY/CATCH Block
	-------------------------------------------------------------------------------------------------------------------	
	BEGIN CATCH
		---------------------------------------------------------------------------------------------------------------
		--	Set the Error Message
		---------------------------------------------------------------------------------------------------------------
		SELECT	@nvchErrorMessage	=	COALESCE(@nvchErrorMessage,ERROR_MESSAGE())
		---------------------------------------------------------------------------------------------------------------
		--	Raise Error
		---------------------------------------------------------------------------------------------------------------
		RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
	END CATCH
END TRY
BEGIN CATCH
	SELECT
		@intReturnCode		= NULL					,
		@nvchErrorMessage   = ERROR_MESSAGE()		,
		@intErrorSeverity   = ERROR_SEVERITY()		,
		@intErrorState		= ERROR_STATE()
     EXEC	@intReturnCode	= dbo.spLocal_SSI_Cmn_LogErrorMessage
		@p_uidErrorId				= @op_uidErrorId	,
		@p_intNestingLevel			= @intNestingLevel	,
		@p_vchNestedObjectName		= @vchNestedObject	,
		@p_vchObjectName			= @vchObjectName	,
		@p_vchErrorSection			= @vchErrorSection	,
		@p_nvchErrorMessage			= @nvchErrorMessage	,
		@p_intErrorSeverity			= @intErrorSeverity	,
		@p_intErrorState			= @intErrorState	,
		@p_bitPrimaryObjectFlag		= @intPrimary		,
		@p_intErrorSeverityLevel	= @consErrorCritical,
		@p_intKeyId					= @intKeyId			,
		@p_intTableId				= @intTableId
END CATCH		
--=====================================================================================================================
--	TRAP Errors
--	Set return code and error id output values
--=====================================================================================================================
ERRORFinish:

IF	EXISTS(
    SELECT	Error_Id
    FROM	dbo.Local_SSI_ErrorLogHeader	WITH(NOLOCK)
    WHERE	Error_Id = @op_uidErrorId
		AND	Primary_Object_Name	= @vchObjectName)
BEGIN
    SELECT	@intReturnCode	= MIN(Error_Severity_Level)
    FROM    dbo.Local_SSI_ErrorLogDetail	WITH(NOLOCK)
    WHERE	Error_Id		= @op_uidErrorId
		AND	[Object_Name]	= @vchObjectName
    RETURN	@intReturnCode
END
ELSE
BEGIN
	IF	@intPrimary	=	1
	BEGIN
		SELECT	@op_uidErrorId = NULL
	END
    RETURN @consErrorNone
END
--=====================================================================================================================
--	RETURN CODE
--=====================================================================================================================
SET NOCOUNT OFF
RETURN
