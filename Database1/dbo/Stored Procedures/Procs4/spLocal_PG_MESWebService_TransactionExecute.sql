

--=====================================================================================================================
--	Name:		 		spLocal_PG_MESWebService_TransactionExecute
--	Type:				Stored Procedure
--	Editor Tab Spacing: 4	
--=====================================================================================================================
--	DESCRIPTION: 
--=====================================================================================================================
--	EDIT HISTORY:
-----------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who						What
--	========	====		===						====
--	1.0			2016-11-03	Daniel Rodriguez-Demers	Initial Development
--=====================================================================================================================
--	EXEC Statement:
-----------------------------------------------------------------------------------------------------------------------
--	The DECLARE, SELECT, and EXEC statements in the following example should match the stored procedure input
--	parameters.
/*
	DECLARE
		@ReturnCode		INT				,
		@p_DebugFlag	BIT				,		
		@p_inputXml		VARCHAR(MAX)	,
		@p_Command		VARCHAR(25)		,
		@p_InstanceName VARCHAR(25)		,
		@p_userId		INT				,		
		@op_OutputXml	VARCHAR(MAX)	,	
		@op_ErrorGUID	UNIQUEIDENTIFIER		
	SELECT
		@p_debugFlag	= NULL		,
		@op_outputXml	= NULL		,
		@p_inputXml		= '<DoffUpdate><DoffSet>0000001</DoffSet><DoffStatus>1</DoffStatus></DoffUpdate>'		,
		@p_command		= 'GradeGet',
		@p_InstanceName = 'Test'	,
		@p_userId		= 1			,
		@op_ErrorGUID	= NULL
	EXEC	@ReturnCode	= dbo.spLocal_PG_MESWebService_TransactionExecute
		@op_ErrorGUID	= @op_ErrorGUID	OUTPUT	,
		@p_DebugFlag	= @p_debugFlag			,
		@op_outputXml	= @op_outputXml	OUTPUT	,
		@p_inputXml		= @p_inputXml			,
		@p_command		= @p_command			,
		@p_InstanceName = @p_InstanceName		,
		@p_UserId		= @p_userId
	SELECT
		@op_OutputXml	AS	[Output Xml]
	IF	@ReturnCode	<> 0
	BEGIN
		SELECT	*
		FROM	dbo.fnLocal_SSI_Cmn_ErrorMessageByUniqueId(@op_ErrorGUID)
	END
*/
--=====================================================================================================================
CREATE PROCEDURE [dbo].[spLocal_PG_MESWebService_TransactionExecute]
	@op_ErrorGUID		UNIQUEIDENTIFIER	= NULL	OUTPUT,
	@p_DebugFlag		BIT					= 0,
	@op_OutputXml		VARCHAR(MAX)		= NULL	OUTPUT,
	@p_InputXml			VARCHAR(MAX)		= NULL,
	@p_Command			VARCHAR(25),
	@p_InstanceName		VARCHAR(50),
	@p_UserId			INT,
	@p_TransId			INT					= 0
AS
SET NOCOUNT ON
--=====================================================================================================================
--	DECLARE VARIABLES
--	The following variables will be used as internal variables to this Stored Procedure.
--=====================================================================================================================
-----------------------------------------------------------------------------------------------------------------------
--	BIT
-----------------------------------------------------------------------------------------------------------------------
DECLARE
@IsTransaction			BIT
-----------------------------------------------------------------------------------------------------------------------
--	VARCHAR
-----------------------------------------------------------------------------------------------------------------------
DECLARE
@SpName					VARCHAR(256),
@CommandList			VARCHAR(MAX),
@SQLCmd					NVARCHAR(MAX)	
-----------------------------------------------------------------------------------------------------------------------
--	INT
-----------------------------------------------------------------------------------------------------------------------
DECLARE
@CmdId					INT,
@ReprocessTimeInMinute	INT,	
@InstanceId				INT
--=====================================================================================================================
--	The following variables are used for error handling logic
--=====================================================================================================================
DECLARE
@ReturnCode				INT,
@NestingLevel			INT,
@Primary				INT,
@ErrorSeverity			INT,
@ERROR_CRITICAL_CODE	INT,
@ERROR_WARNING_CODE		INT,
@ERROR_INFO_CODE		INT,
@ERROR_NONE_CODE		INT,
@ErrorState				INT,
@SeverityLevel			INT,
@NestedObject			VARCHAR(256),
@ObjectName				VARCHAR(256),
@ErrorMessage			NVARCHAR(2048),
@ErrorSection			VARCHAR(100)
--=====================================================================================================================
--	DECLARE VARIABLE CONSTANTS
--	The following variables will be used as internal constants to this Stored Procedure.
--=====================================================================================================================

--=====================================================================================================================
--	DECLARE TABLE VARIABLES
--	The following Table Variables will be used to store temporary datasets within this Stored Procedure.
--=====================================================================================================================
--=====================================================================================================================
--	INITIALIZE VARIABLES and VARIABLE CONSTANTS
--	Use this section to initialize variables and set valuse for any variable constants.
--=====================================================================================================================

-----------------------------------------------------------------------------------------------------------------------
--	Set constants used for error handling
-----------------------------------------------------------------------------------------------------------------------
SET	@ERROR_CRITICAL_CODE	= -1
SET	@ERROR_NONE_CODE		= 0
SET	@ERROR_WARNING_CODE		= 1
SET	@ERROR_INFO_CODE		= 2
SET	@ErrorSeverity			= 11
SET	@ErrorState				= 1
SET	@NestingLevel			= @@NESTLEVEL
SET	@ObjectName				= COALESCE(OBJECT_NAME(@@ProcId), 'SCRIPTED_spLocal_PG_MESWebService_TransactionExecute')	
--=====================================================================================================================
--	The @op_ErrorGUID parameter is used to determine if the SP has been called by another SP.  If the value is null
--	then it is assumed that this SP is the top level SP.
--	
--	If it is the top level SP then get a unique identifier that will be used to log error messages and set the flag
--	to indicate that this SP is the primary SP.
--=====================================================================================================================
IF	@op_ErrorGUID IS NULL
BEGIN
	SET	@op_ErrorGUID	= NEWID()
	SET	@Primary		= 1
END
ELSE
BEGIN
	SET	@Primary	= 0
END

--=====================================================================================================================
--	BEGIN LOGIC
--=====================================================================================================================
BEGIN TRY
	IF COALESCE(@p_TransId, 0) = 0
	BEGIN
		--------------------------------------------------------------------------------------------------------------------------------------------
		--	Initialize @InstanceId
		--------------------------------------------------------------------------------------------------------------------------------------------
		SET @InstanceId	=	(
								SELECT 	Instance_Id
								FROM	dbo.Local_PG_MESWebService_Instances
								WHERE	Instance_Desc = @p_InstanceName
							)
		
		--------------------------------------------------------------------------------------------------------------------------------------------
		--	Validate @InstanceId
		--------------------------------------------------------------------------------------------------------------------------------------------
		IF	@InstanceId IS NULL
		BEGIN	
			SET @ErrorMessage = 'Instance_Id for the instance named ' + @p_InstanceName + ' was not found'			
			RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)	
		END
		
		--------------------------------------------------------------------------------------------------------------------------------------------
		--	Initialize @CmdId
		--------------------------------------------------------------------------------------------------------------------------------------------
		SET @CmdId =	(
							SELECT 	Command_Type_Id
							FROM	dbo.Local_PG_MESWebService_CommandType
							WHERE	Command_Type_Desc 	= @p_Command
							AND		Instance_Id			= @InstanceId
						)
		
		-------------------------------------------------------------------------------------------------------------------
		--	Makes sure @p_Command is include into Command_Type_Desc list
		-------------------------------------------------------------------------------------------------------------------
		IF @CmdId IS  NULL
		BEGIN
			SET	@CommandList	= ''
			---------------------------------------------------------------------------------------------------------------
			--	Prepare the Command list for the error message
			---------------------------------------------------------------------------------------------------------------
			SELECT	@CommandList	= @CommandList + UWSCT.Command_Type_Desc + ','
			FROM	dbo.Local_PG_MESWebService_CommandType AS UWSCT
			---------------------------------------------------------------------------------------------------------------
			--	Set the Error Message
			---------------------------------------------------------------------------------------------------------------
			SET 	@ErrorMessage	= '@p_command is Invalid. At least one action and only one Action should be '
										+ 'related to the Command.'
										+ ' @p_command = '
										+ COALESCE(@p_command,'BLANK')
										+ '. Available Commands configured:'
										+ COALESCE(@CommandList,'BLANK')
			---------------------------------------------------------------------------------------------------------------	
			--	Raise Error		
			---------------------------------------------------------------------------------------------------------------
			RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)	
		END

		SET @ReprocessTimeInMinute =	(
											SELECT 	Retry_Delay
											FROM	dbo.Local_PG_MESWebService_CommandTypeExecution
											WHERE	Command_Type_Id = @CmdId
										)
										
		SET @ReprocessTimeInMinute = COALESCE(@ReprocessTimeInMinute, 0)
		
		SET @IsTransaction 	= 	(
									SELECT 	Is_Reprocessable
									FROM	dbo.Local_PG_MESWebService_CommandType
									WHERE	Command_Type_Id = @CmdId
								)
		
		-------------------------------------------------------------------------------------------------------------------
		--	If the command is a Transaction, we enter the log of the transaction into the Transactions table
		------------------------------------------------------------------------------------------------------------------
		IF @IsTransaction = 1
		BEGIN
			INSERT	dbo.Local_PG_MESWebService_Transactions
			(
				[TimeStamp],
				Command_Type_Id,
				Input_XML_Data,
				Reprocess_After,
				Transaction_Status_Id
			)
			VALUES
			(
				GETDATE(),
				@CmdId,
				@p_InputXml,
				DATEADD(mm, +@ReprocessTimeInMinute, GETDATE()),
				1
			)

			SET @p_TransId = SCOPE_IDENTITY()
		END
	END
	--=================================================================================================================
	--	VALIDATE STORED PROCEDURE INPUT PARAMETERS
	--=================================================================================================================
	--	Initialize section variables
	-------------------------------------------------------------------------------------------------------------------
	SET	@ErrorSection	= 'Validate Input parameters'																
	SET	@NestedObject	= ''
	SET	@ErrorMessage	= ''
	-------------------------------------------------------------------------------------------------------------------
	--	If input XML is Blank Clear it completely
	-------------------------------------------------------------------------------------------------------------------
	IF COALESCE(@p_inputXml,'') = ''
	BEGIN
		SET	@p_inputXml	= NULL
	END
	--=================================================================================================================
	--	VALIDATE CONFIGURATION
	--	Use this section to retrieve external parameter values, such as Site or User parameters or User Defined Properties.
	--=================================================================================================================
	--	Initialize section variables
	-------------------------------------------------------------------------------------------------------------------
	SET	@ErrorSection	= 'Validate Configuration'
	SET	@NestedObject	= '@tblCommandList'
	SET	@ErrorMessage	= ''
	-------------------------------------------------------------------------------------------------------------------
	--	Initialize the Table of Commands. If a new command need to be added this is the point where it needs to be added
	--	PLEASE ADD MORE COMMANDS HERE AND STORED PROCEDURE NAMES DEDENDING ON REQUIRED FUNCTIONALITY
	--=================================================================================================================
	-------------------------------------------------------------------------------------------------------------------
	-- CATCH Error
	-------------------------------------------------------------------------------------------------------------------
	SET	@SpName	=		(
							SELECT	UWSCT.Sp_Name
							FROM	dbo.Local_PG_MESWebService_Instances UWSI
							JOIN	dbo.Local_PG_MESWebService_CommandType UWSCT	ON	UWSI.Instance_Id = UWSCT.Instance_Id
							WHERE	UWSCT.Command_Type_Desc	= @p_command
							AND		UWSI.Instance_Desc		= @p_InstanceName
							AND		UWSCT.Is_Active 		= 1
						)
	-------------------------------------------------------------------------------------------------------------------
	--	Makes sure only one Stored Procedure applies for the supplied Command
	-------------------------------------------------------------------------------------------------------------------
	IF @SpName IS  NULL
	BEGIN
		SET 	@ErrorMessage	= 'There is no procedure available for that command or the command is inactive.'

		IF @IsTransaction = 1
		BEGIN
			UPDATE	Local_PG_MESWebService_Transactions
			SET		Error_Message = @ErrorMessage
			WHERE	Transaction_Id = @p_TransId
		END
		
		---------------------------------------------------------------------------------------------------------------	
		--	Raise Error		
		---------------------------------------------------------------------------------------------------------------
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)	
	END
	--=================================================================================================================
	--	Populate the Specification Input List
	--=================================================================================================================
	--	Set the Section Description
	-------------------------------------------------------------------------------------------------------------------
	SET	@ErrorSection	= 'Executes SQL Command'
	SET	@NestedObject	= 'SP_EXECUTESQL'
	SET	@ErrorMessage	= NULL
	-------------------------------------------------------------------------------------------------------------------
	--	Call Stored procedure Dynamically
	-------------------------------------------------------------------------------------------------------------------
	BEGIN TRY
		---------------------------------------------------------------------------------------------------------------
		--	Build Stored Procedure Parameters if SP Name is found
		---------------------------------------------------------------------------------------------------------------'		
		IF	@SPName	<> ''
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Call sp dynamically
			-----------------------------------------------------------------------------------------------------------
			EXEC @ReturnCode =  @SPName
							@op_ErrorGUID		=	@op_ErrorGUID	OUTPUT	,
							@op_OutputXml		=	@op_OutputXml	OUTPUT	,
							@p_DebugFlag		=	@p_DebugFlag,
							@p_inputXml			=	@p_inputXml,
							@p_userId			=	@p_UserId,
							@p_TransactionId	=	@p_TransId

			-----------------------------------------------------------------------------------------------------------
			--  Checks to see if the Store Procedure was excecuted normally
			-----------------------------------------------------------------------------------------------------------
			IF	@ReturnCode < 0
			BEGIN
				--=====================================================================================================
				-- Get CATCH ERROR formatted message
				--=====================================================================================================
				SELECT	@ErrorMessage	= 'The call to '
											+ @SPName
											+ ' returned an error.  Code = '
											+ COALESCE(CONVERT(VARCHAR(25), @ReturnCode), 'BLANK')
											+ 'Dynamic execution = '
											+ @SQLCmd

				IF @IsTransaction = 1
				BEGIN
					UPDATE	Local_PG_MESWebService_Transactions
					SET		Error_Message = @ErrorMessage
					WHERE	Transaction_Id = @p_TransId
				END

				RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
			END
		END
		
		IF @IsTransaction = 1
		BEGIN
			UPDATE	Local_PG_MESWebService_Transactions
			SET		End_Timestamp			= GETDATE(),
					Reprocess_After			= NULL,
					Output_XML_Data			= @op_OutputXml,
					Transaction_Status_Id	= 0
			WHERE	Transaction_Id = @p_TransId
		END
	END TRY
	BEGIN CATCH
		---------------------------------------------------------------------------------------------------------------
		--	Set the Error Message
		---------------------------------------------------------------------------------------------------------------
		SET	@ErrorMessage	=	ERROR_MESSAGE()	--COALESCE(@ErrorMessage,ERROR_MESSAGE())
		---------------------------------------------------------------------------------------------------------------
		--	Raise Error
		---------------------------------------------------------------------------------------------------------------
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)
	END CATCH
END TRY
BEGIN CATCH		
	SET	@ReturnCode		= NULL
	SET	@ErrorMessage   = ERROR_MESSAGE()														
	SET	@ErrorSeverity	= ERROR_SEVERITY()																
	SET	@ErrorState		= ERROR_STATE()																	
    EXECUTE	@ReturnCode = dbo.spLocal_SSI_Cmn_LogErrorMessage
			@p_uidErrorId				= @op_ErrorGUID,
			@p_intNestingLevel			= @NestingLevel,
			@p_vchNestedObjectName		= @NestedObject,
			@p_vchObjectName			= @ObjectName,
			@p_vchErrorSection			= @ErrorSection,
			@p_nvchErrorMessage			= @ErrorMessage,
			@p_intErrorSeverity			= @ErrorSeverity,
			@p_intErrorState			= @ErrorState,
			@p_bitPrimaryObjectFlag		= @Primary,
			@p_intErrorSeverityLevel	= @ERROR_CRITICAL_CODE
	GOTO ERRORFinish				
END CATCH		
--=====================================================================================================================
--	TRAP Errors
--	Set return code and error id output values
--=====================================================================================================================
ERRORFinish:

IF	EXISTS
(
    SELECT	1
    FROM	dbo.Local_SSI_ErrorLogHeader	WITH(NOLOCK)
    WHERE	Error_Id = @op_ErrorGUID
	AND		Primary_Object_Name	= OBJECT_NAME(@@ProcId)
)
BEGIN
    SET	@ReturnCode	=	(
							SELECT	MIN(Error_Severity_Level)
							FROM    dbo.Local_SSI_ErrorLogDetail
							WHERE	Error_Id = @op_ErrorGUID
							AND		[Object_Name] = OBJECT_NAME(@@ProcId)
						)
	IF
	(
		@op_OutputXml IS NULL
		OR
		@op_OutputXml = ''
	) 
	AND	EXISTS	(	
					SELECT	1
					FROM	dbo.Local_SSI_ErrorLogDetail 
					WHERE	Error_Id = @op_ErrorGUID 
				)
	BEGIN
		SET	@op_OutputXml =	(
								SELECT	Error_Message [ErrorMessage]
								FROM	dbo.Local_SSI_ErrorLogDetail [MESErrorMessage]
								WHERE	Error_Id = @op_ErrorGUID 
								ORDER
								BY		Nesting_Level DESC
								FOR 	XML AUTO,
										ELEMENTS
							)
	END
    RETURN @ReturnCode
END
ELSE
BEGIN
	IF	@Primary	=	1
	BEGIN
		SET	@op_ErrorGUID = NULL
	END
    RETURN @ERROR_NONE_CODE
END
--=====================================================================================================================
--	RETURN CODE
--=====================================================================================================================
SET NOCOUNT OFF
RETURN

