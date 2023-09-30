
--==============================================================================================================================================
--	Name:		 		spLocal_PG_MESWebService_Model_602ReprocessTransactions
--	Type:				Stored Procedure
--	Editor Tab Spacing: 4	
--==============================================================================================================================================
--	DESCRIPTION: 

--	Automatically reprocess incoming Web Service transactions
--==============================================================================================================================================
--	How to execute it: Example
------------------------------------------------------------------------------------------------------------------------------------------------
--	The DECLARE, SELECT, and EXEC statements in the following example should match the stored procedure input
--	parameters.
/*
	DECLARE
		@Success		INT,
		@ErrorMessage	VARCHAR(255)
	EXEC dbo.[spLocal_PG_MESWebService_Model_602ReprocessTransactions]
				@op_Success			= @Success		OUTPUT,
				@op_ErrorMessage	= @ErrorMessage	OUTPUT,
				@p_ECId 			= 869
	SELECT
		@Success			AS [SuccessFlag],
		@ErrorMessage		AS [ErrorMessage]

	SELECT	*
	FROM	dbo.Local_SSI_ErrorLogDetail	WITH(NOLOCK)
	WHERE	Object_Name = 'spLocal_PG_MESWebService_Model_602ReprocessTransactions'
	ORDER
	BY		TimeStamp ASC
*/
--==============================================================================================================================================
--	EDIT HISTORY:
------------------------------------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who						What
--	==========	=====		===						====
--	1.0			2016-11-03	Daniel Rodriguez-Demers	Original Development
--==============================================================================================================================================
CREATE	PROCEDURE	[dbo].[spLocal_PG_MESWebService_Model_602ReprocessTransactions]
	@op_Success			INT				OUTPUT,
	@op_ErrorMessage	VARCHAR(255)	OUTPUT,
	@p_ECId				INT
AS

SET NOCOUNT ON
--==============================================================================================================================================
--	DECLARE VARIABLES
--	The following variables will be used as internal variables to this Stored Procedure.
--==============================================================================================================================================
DECLARE
@PUId						INT,
@CurrentRecord				INT,
@UserId						INT,
@UserName					VARCHAR(50),
@ECDesc						VARCHAR(50),
@PLDesc						VARCHAR(50),
@PUDesc						VARCHAR(50),
@InstanceName				vARCHAR(20),
@CommandName				VARCHAR(100),
@OutputXML					VARCHAR(MAX),
@InputXML					VARCHAR(MAX),
@InstanceNameEMP			VARCHAR(100),
@TransactionId				INT
--==============================================================================================================================================
--	The following variables are used for error handling logic
--==============================================================================================================================================
DECLARE
@ErrorGUId					UNIQUEIDENTIFIER,
@DebugFlag					INT,
@ReturnCode					INT,
@NestingLevel				INT,
@PrimaryObjectFlag			INT,
@ErrorSeverity				INT,
@ERROR_CRITICAL				INT,
@ERROR_WARNING				INT,
@ERROR_INFO					INT,
@ERROR_NONE					INT,
@ErrorCode					INT,
@ErrorState					INT,
@SeverityLevel				INT,
@ErrorWasLogged				BIT,
@EMP_DEBUG_FLAG				VARCHAR(50),
@NestedObjectName			NVARCHAR(256),
@OBJECT_NAME				NVARCHAR(256),
@ErrorMessage				NVARCHAR(2048),
@DebugMessage				NVARCHAR(2048),
@ErrorSection				VARCHAR(100)
--==============================================================================================================================================
--	DECLARE VARIABLE CONSTANTS
--	The following variables will be used as internal constants to this Stored Procedure.
--==============================================================================================================================================
DECLARE
@USER_NAME_EVENT_MODEL		VARCHAR(50),
@USER_ID_EVENT_MANAGER		INT,
@MAX_RECORDS				INT
--==============================================================================================================================================
--	INITIALIZE VARIABLES and VARIABLE CONSTANTS
--	Use this section to initialize variables and set valuse for any variable constants.
--==============================================================================================================================================
SET @USER_NAME_EVENT_MODEL		= 'SSI_Parm_UserNameEventModel'
SET @USER_ID_EVENT_MANAGER		= 6	--	Event Manager
SET @MAX_RECORDS				= 1
SET @CurrentRecord				= 1
------------------------------------------------------------------------------------------------------------------------------------------------
--	Set constants used for error handling
------------------------------------------------------------------------------------------------------------------------------------------------
SET @ErrorGUId				= NEWID()
SET @NestingLevel			= @@NESTLEVEL
SET @OBJECT_NAME			= COALESCE(OBJECT_NAME(@@ProcId), 'SCRIPTED_spLocal_PG_MESWebService_Model_602ReprocessTransactions') -- SP name as litteral value 
SET @EMP_DEBUG_FLAG			= 'Debug Flag'
SET @PrimaryObjectFlag		= 1
SET @ERROR_CRITICAL			= -1
SET @ERROR_NONE				= 0
SET @ERROR_WARNING			= 1
SET @ERROR_INFO				= 2
SET @ErrorSeverity			= 11
SET @ErrorState				= 1
SET @ErrorWasLogged			= 0
------------------------------------------------------------------------------------------------------------------------------------------------
SET @op_Success				= 1			-- Success By Default. If it is set to zero Proficy will not process the Result sets
SET @DebugFlag				= 0			-- Set to zero normally. Only set to one during development.
										-- Can be turned on for individual models using the PA Admin
SET	@InstanceNameEMP		= 'Web Service Instance Name'
SET @UserId					= @USER_ID_EVENT_MANAGER

--==============================================================================================================================================
--	BEGIN LOGIC
--==============================================================================================================================================
BEGIN TRY
	--==========================================================================================================================================
	--	Get Debug Flag and Configuration information
	--==========================================================================================================================================
	--	Debug.
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET @ErrorSection		= 'Get Debug Flag and Configuration information'
	SET @NestedObjectName	= ''
	SET @ErrorMessage		= NULL

	SET @DebugFlag = dbo.fnLocal_SSI_Cmn_EventModelParameter    (
																	@p_ECId, 
																	@EMP_DEBUG_FLAG, 
																	0
																)


	--==========================================================================================================================================
	--	Retry Interval (Mins) = Default to 15 if not supplied
	--==========================================================================================================================================
	SET	@InstanceName	= dbo.fnLocal_SSI_Cmn_EventModelParameter	(
																		@p_ECId, 
																		@InstanceNameEMP, 
																		''
																	)

	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Configuration info
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET		@ECDesc	= NULL
	SET		@PLDesc	= NULL
	SET		@PUDesc	= NULL
	SET		@PUId	= NULL
	
	SELECT	@ECDesc	= ec.EC_Desc,
			@PLDesc	= pl.PL_Desc,
			@PUDesc	= pu.PU_Desc,
			@PUId	= ec.PU_Id
	FROM	dbo.Event_Configuration	ec	WITH(NOLOCK)
	JOIN	dbo.Prod_Units			pu	WITH(NOLOCK)
										ON	ec.PU_Id = pu.PU_Id
	JOIN	dbo.Prod_Lines			pl	WITH(NOLOCK)
										ON	pu.PL_Id = pl.PL_Id
	WHERE	ec.EC_Id = @p_ECId
	
	SET @ErrorMessage = 'Line: [' + @PLDesc + '] Unit: [' + @PUDesc + '] EC: [' + @ECDesc + '] '
	--==========================================================================================================================================
	--	Get User for Event Models
	--==========================================================================================================================================
	SET	@UserName =	dbo.fnLocal_SSI_Cmn_ParameterValue	(
															dbo.fnLocal_SSI_Cmn_ParameterId	(@USER_NAME_EVENT_MODEL),
															NULL
														)
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Get User Id
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET @UserId	=	COALESCE
					(
						(
							SELECT	[User_Id]
							FROM	dbo.Users WITH(NOLOCK)
							WHERE	UserName = @UserName
						)
						, @USER_ID_EVENT_MANAGER -- 6 is Event Manager
					)		
	--==========================================================================================================================================
	--	Get first message to reprocess
	--==========================================================================================================================================
	SET @ErrorSection		= 'Get first message to reprocess'
	SET @NestedObjectName	= ''
	SET @ErrorMessage		= NULL

	----------------------------------------------------------------------------------------------------------------------------------------
	--Select @InstanceName
	----------------------------------------------------------------------------------------------------------------------------------------
	SET @TransactionId	=	(
								SELECT	MIN(t.Transaction_Id) 
								FROM    dbo.Local_PG_MESWebService_Transactions   t	(NOLOCK)
								JOIN    dbo.Local_PG_MESWebService_CommandType    ct  (NOLOCK)
																							ON t.Command_Type_Id    = ct.Command_Type_Id
								JOIN    dbo.Local_PG_MESWebService_Instances      i   (NOLOCK)
																							ON ct.Instance_Id       = i.Instance_Id
								WHERE   i.Instance_Desc	= @InstanceName 
								AND		t.Reprocess_After IS NOT NULL 
								AND		t.Reprocess_After <= GETDATE()
							)


	WHILE	@TransactionId IS NOT NULL
	AND		@CurrentRecord <= @MAX_RECORDS
	BEGIN
		SET @CommandName	= NULL
		SET @InputXML		= NULL
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Get command to execute
		----------------------------------------------------------------------------------------------------------------------------------------
		SELECT	@CommandName	= ct.Command_Type_Desc ,
				@InputXML		= t.Input_XML_Data
		FROM    dbo.Local_PG_MESWebService_Transactions	t	(NOLOCK)
		JOIN    dbo.Local_PG_MESWebService_CommandType   ct	(NOLOCK)
																	ON t.Command_Type_Id    = ct.Command_Type_Id
		WHERE	t.Transaction_Id  = @TransactionId 
		----------------------------------------------------------------------------------------------------------------------------------------
		--	Execute command against web service
		----------------------------------------------------------------------------------------------------------------------------------------
		EXEC	@ReturnCode	= dbo.spLocal_PG_MESWebService_TransactionExecute
						@op_ErrorGUID	= @ErrorGUID	OUTPUT	,
						@p_DebugFlag	= @DebugFlag			,
						@op_outputXml	= @OutputXml	OUTPUT	,
						@p_inputXml		= @InputXML 			,
						@p_command		= @CommandName 			,
						@p_InstanceName = @InstanceName			,
						@p_UserId		= @UserId

		----------------------------------------------------------------------------------------------------------------------------------------
		--	Write feedback to transaction table
		----------------------------------------------------------------------------------------------------------------------------------------
		IF @ReturnCode >= 0
		BEGIN				
			UPDATE	t 
			SET		Reprocess_After = NULL 
			FROM    dbo.Local_PG_MESWebService_Transactions   t	(NOLOCK)
			JOIN    dbo.Local_PG_MESWebService_CommandType    ct  (NOLOCK)
																		ON t.Command_Type_Id    = ct.Command_Type_Id
			WHERE	t.Transaction_Id = @TransactionId 
		END
		ELSE
		BEGIN
			UPDATE	t 
			SET		Reprocess_After		= DATEADD(minute, ct.Reprocess_Delay, GETDATE()) ,
					[Error_Message]		= [Error_Message]
			FROM    dbo.Local_PG_MESWebService_Transactions   t	(NOLOCK)
			JOIN    dbo.Local_PG_MESWebService_CommandType    ct  (NOLOCK)
																		ON t.Command_Type_Id    = ct.Command_Type_Id
			WHERE	t.Transaction_Id	= @TransactionId 
		END

		----------------------------------------------------------------------------------------------------------------------------------------
		--	Get next message to reprocess
		----------------------------------------------------------------------------------------------------------------------------------------
		SET @TransactionId	=	(
									SELECT	MIN(t.Transaction_Id) 
									FROM    dbo.Local_PG_MESWebService_Transactions   t	(NOLOCK)
									JOIN    dbo.Local_PG_MESWebService_CommandType    ct  (NOLOCK)
																								ON t.Command_Type_Id    = ct.Command_Type_Id
									JOIN    dbo.Local_PG_MESWebService_Instances      i   (NOLOCK)
																								ON ct.Instance_Id       = i.Instance_Id
									WHERE   i.Instance_Desc	= @InstanceName 
									AND		Reprocess_After		IS NOT NULL 
									AND		Reprocess_After		<= GETDATE()
									AND		t.Transaction_Id 	> @TransactionId
								)

		SET @CurrentRecord = @CurrentRecord + 1
	END
END TRY
--==============================================================================================================================================
--	Log critcal error messages raised in the main body of logic.
--==============================================================================================================================================
BEGIN CATCH
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Assign error message parameter values.
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET @ErrorMessage	= ERROR_MESSAGE()
	SET @ErrorSeverity	= ERROR_SEVERITY()
	SET @ErrorState		= ERROR_STATE()
	SET @ErrorWasLogged = 1
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Log error message.
	--------------------------------------------------------------------------------------------------------------------------------------------
	EXEC dbo.spLocal_SSI_Cmn_LogErrorMessage
							@p_uidErrorId				= @ErrorGUID,
							@p_intNestingLevel			= @NestingLevel,
							@p_vchNestedObjectName		= @NestedObjectName,
							@p_vchObjectName			= @OBJECT_NAME,
							@p_vchErrorSection			= @ErrorSection,
							@p_nvchErrorMessage			= @ErrorMessage,
							@p_intErrorSeverity			= @ErrorSeverity,
							@p_intErrorState			= @ErrorState,
							@p_bitPrimaryObjectFlag		= @PrimaryObjectFlag,
							@p_intErrorCode				= @ErrorCode,
							@p_intErrorSeverityLevel	= @ERROR_CRITICAL
END CATCH
--==============================================================================================================================================
--	Set return code and error message output values
--==============================================================================================================================================
ERRORFinish:

IF @ErrorWasLogged = 1
BEGIN
	--------------------------------------------------------------------------------------------------------------------------------------------
	--	Get error message detail data.
	--------------------------------------------------------------------------------------------------------------------------------------------
	SET @op_ErrorMessage    = 'Error Log ID: ' + CONVERT(VARCHAR(50), @ErrorGUId) + ' ' + @ErrorMessage
	SET @op_Success			= 0
END
ELSE
BEGIN
	SET @op_ErrorMessage = NULL
END
--==============================================================================================================================================
--	Finish
--==============================================================================================================================================
SET NOCOUNT OFF
