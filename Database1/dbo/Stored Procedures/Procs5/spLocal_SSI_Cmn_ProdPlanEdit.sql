--=====================================================================================================================
-- Store Procedure: 	spLocal_SSI_Cmn_ProdPlanEdit
-- Sp Type:				Stored Procedure
-- Editor Tab Spacing: 	4	
--=====================================================================================================================
--	This stored procedure will update a "Production Plan" record in the Proficy Plant Applications database and will 
--	compose a resultset that contains the Transaction Message. This SP will be the preferred way to update information
--	to the Production Plan table.  It supports Inserts, Edits and Deletes.
-----------------------------------------------------------------------------------------------------------------------
--	Revision	Date		Who				What
--	==========	=====		===				====
--	1.0			2008-04-30	Luis Chaves		Original Development.
--	1.1			2009-02-13	Luis Chaves		Removed Validation on Forecast Dates. Both can be NULL values
--	1.2			2009-03-05	Luis Chaves		Removed Email Message functionality
--	1.3			2009-03-25	Luis Chaves		Added a COALESCE and CONVERT VARCHAR to a INT parameter validation
--	1.4			2010-04-28	Luis Chaves		Added logic to set Forecast Quantity con update
--	1.5			2010-05-27	Luis Chaves		Fixed bug related to implied sequence lack of Path_Id on query to retrieve
--											count of iterations to move a record implied sequence, also parameter forced
--											to be NULL if supplied value is zero
--	1.6			2010-06-23	Luis Chaves		Added 4 new optional Parameters User General 1 to 3 and Extended Info
--	2.0			2010-06-28	Luis Chaves		Major changes incorporated.
--											Updated Error Handling methodology which relies on new child components
--											The changes also resulted in modifications to the input	parameters
--											as follows;
--											Error Handling parameter changes:
--												Added @op_uidErrorId UNIQUEIDENTIFIER OUTPUT
--	2.1			2011-01-28	Luis Chaves		Incremented Implied Sequence limit to 100 000
--	2.2			2011-02-04	Luis Chaves		Added @p_intUserId parameter on delete call
--	2.3			2011-03-23	Luis Chaves		Added logic to ignore Comment_Id validation on Delete call
--	2.4			2011-06-24	Marco Jimenez	Added logic to validate when Entry_On is NULL set it as GETDATE()
--  2.5			2011-07-20	Karla Bolaños	Standardize Error Handling logic
--  2.6			2011-09-16	Karla Bolaños	Validate the ProcessOrder does not exists on the Path on Inserts
--  2.7		    2012-05-17	Karla Ramirez	Library 161:spLocal_SSI_Cmn_ProdPlanEdit: Add logic to Error Trapping code at 
--											bottom of sp to only set @op_uidErrorId to NULL if there are no errors and the 
--											sp is the primary sp i.e.@intPrimary = 1
--	2.8			2012-08-29	Renata Piedmont	LIBRARY-236: Added some comments  
--  2.9			2012-09-03	Renata Piedmont	LIBRARY-236: Added a comment to correct the version number
--  2.10		2012-09-06	Renata Piedmont	LIBRARY-236: Added a comment to correct the version number
--	2.11		2013-07-31	Luis Chaves		Fix incorrect message for Bom Formulation Id and Parent PPId parameters.
--											Jira cases: SUP-3128 and SUP-3129
--	2.12		2013-08-05	Luis Chaves		Fix a bug related to the query that calculates the Implied sequence
--	2.13		2015-03-30	CCM				Edits would only take place for Comments and ForeCast Quantity :( 
--											Needed to also add ForeCastDate edits
-- 	2.14		2019-01-18	Wendong Xu		Updated the ResultSet to in line with output from dbo.spServer_CmnShowResultSets(PPA 7.228.308)
-----------------------------------------------------------------------------------------------------------------------
--	TODO LIST:
--		1:	The logic to Update Comment which TRANSNUM is 01 can't be used by now when Write Direct Parameter is 1.
--			Problem is because there is a bug in SP "dbo.spServer_DBMgrUpdProdPlan"
--			and this SP don't have this functionality yet, so the logic in "dbo.spLocal_SSI_Cmn_ProdPlanEdit"
--			is done, but it depends on the proficy SP to work
-----------------------------------------------------------------------------------------------------------------------
--	How to execute it: Example
-----------------------------------------------------------------------------------------------------------------------
/*
	DECLARE	@intPPId			INT			,
			@intImpliedSequence	INT			,
			@intErrorCode		INT			,
			@vchProcessOrder	VARCHAR(50)	,
			@dtmEntryOn			DATETIME	,
			@dtmStartTime		DATETIME	,
			@dtmEndTime			DATETIME	,
			@op_uidErrorId		UNIQUEIDENTIFIER ,
			@intReturnCode      INT
	SELECT	@intPPId			= NULL		,
			@dtmStartTime		= GETDATE()	,
			@dtmEndTime			= DATEADD(HOUR,2,@dtmStartTime)	,
			@intImpliedSequence	= 3								,
			@vchProcessOrder	= 'PO000018'
	EXEC	@intErrorCode = dbo.spLocal_SSI_Cmn_ProdPlanEdit
				@op_uidErrorId			= @op_uidErrorId		OUTPUT	,
				@p_bitWriteDirect		= 1							,
				@p_intTransType			= 1							,
				@p_intUserId			= 1							,
				@op_intPPId				= @intPPId			OUTPUT	,
				@p_intPathId			= 18							,
				@p_intCommentId			= NULL						,
				@p_intProdId			= 1							,
				@op_intImpliedSequence	= @intImpliedSequence		,
				@p_intPPStatusId		= 1							,
				@p_intPPTypeId			= 1							,
				@p_intSourcePPId		= 0							,
				@p_intParentPPId		= NULL						,
				@p_intControlType		= 1							,
				@p_dtmForecastStartTime	= @dtmStartTime				,
				@p_dtmForecastEndTime	= @dtmEndTime				,
				@op_dtmEntryOn			= @dtmEntryOn				,
				@p_fltForecastQuantity	= NULL						,
				@p_fltProductionRate	= NULL						,
				@p_fltAdjustedQuantity	= NULL						,
				@p_vchBlockNumber		= NULL						,
				@p_vchProcessOrder		= @vchProcessOrder			,
				@p_intBOMFormulationId	= NULL						,
				@p_vchUserGeneral1		= NULL						,
				@p_vchUserGeneral2		= NULL						,
				@p_vchUserGeneral3		= NULL						,
				@p_vchExtendedInfo		= NULL
	IF	@intReturnCode	<>	0
	BEGIN
		SELECT *
		FROM dbo.fnLocal_SSI_Cmn_ErrorMessageByUniqueId (@op_uidErrorId)
	END
*/
--=====================================================================================================================
--	NOTE1:	The following Transaction Numbers are allowed to use in this SP
-----------------------------------------------------------------------------------------------------------------------
--			00 - COALESCE
--			01 - Comment Update
--			02 - No Coalesce
--			97 - Process Order Status Transition
--			98 - Move Process Order Back
--			99 - Move Process Order Forward
-----------------------------------------------------------------------------------------------------------------------
--			The following Transaction Numbers are NOT allowed to use in this SP
-----------------------------------------------------------------------------------------------------------------------
--			91 - Return To Parent Process Order
--			92 - Create Child Process Order Based On Start Time (@p_intParentPPSetupId	= Parent_PP_Setup_Id)
--			93 - Create Child Process Order Before Process Order (@p_intParentPPSetupId	= Parent_PP_Setup_Id)
--			94 - Create Child Process Order After Process Order (@p_intParentPPSetupId	= Parent_PP_Setup_Id)
--			95 - Re Work Process Order
--			96 - Bind/UnBind Process Order
--=====================================================================================================================
--	NOTE2:	SP will now receive a new output parameter to return back any error message instead of creating a new resultset
--			with the error message		
--=====================================================================================================================
CREATE 	PROCEDURE	[dbo].[spLocal_SSI_Cmn_ProdPlanEdit]
	@op_uidErrorId			UNIQUEIDENTIFIER	= NULL	OUTPUT	,	--	Used for error handling
	@op_vchErrorMessage		VARCHAR(1000)		= NULL	OUTPUT	,	--	An Output Parameter which will return any 
																	--	error messages.
	@p_bitWriteDirect		BIT				= 0					,	--	If it is Zero this SP only reads the database to retrieve data
	@p_intTransType			INT									,
	@p_intUserId			INT									,
	@op_intPPId				INT				= NULL	OUTPUT		,	--	It is a required field, but in Insert Case, it has to be NULL
	@p_intPathId			INT				= NULL				,
	@p_intCommentId			INT				= NULL				,	--	Transnum 01
	@p_intProdId			INT				= NULL				,
	@op_intImpliedSequence	INT				= NULL	OUTPUT		,	--	Transnum 98 or 99
	@p_intPPStatusId		INT				= NULL				,	--	TransNum 97
	@p_intPPTypeId			INT				= NULL				,
	@p_intSourcePPId		INT				= NULL				,
	@p_intParentPPId		INT				= NULL				,
	@p_intControlType		TINYINT			= NULL				,
	@p_dtmForecastStartTime	DATETIME		= NULL				,
	@p_dtmForecastEndTime	DATETIME		= NULL				,
	@op_dtmEntryOn			DATETIME		= NULL	OUTPUT		,
	@p_fltForecastQuantity	FLOAT			= NULL				,
	@p_fltProductionRate	FLOAT			= NULL				,
	@p_fltAdjustedQuantity	FLOAT			= NULL				,
	@p_vchBlockNumber		VARCHAR(50)		= NULL				,
	@p_vchProcessOrder		VARCHAR(50)		= NULL				,
	@p_intBOMFormulationId	BIGINT			= NULL				,
	@p_vchUserGeneral1		VARCHAR(255)	= NULL				,
	@p_vchUserGeneral2		VARCHAR(255)	= NULL				,
	@p_vchUserGeneral3		VARCHAR(255)	= NULL				,
	@p_vchExtendedInfo		VARCHAR(255)	= NULL
AS
--=====================================================================================================================
--	Define all variables.
--=====================================================================================================================
DECLARE
	@dtmTransactionTime		DATETIME	,
	-------------------------------------------------------------------------------------------------------------------
	--	Variable used for call the SP "dbo.spServer_DBMgrUpdProdPlan" with the right instruction without complicate the
	--	programmer logic.
	-------------------------------------------------------------------------------------------------------------------
	@intTransNum			INT	,
	-------------------------------------------------------------------------------------------------------------------
	--	It will store the Implied Sequence Count between the Stored Implied intDBImpliedSequence AND @p_intImpliedSequence
	-------------------------------------------------------------------------------------------------------------------
	@intImpSeqCount			INT	,
	-------------------------------------------------------------------------------------------------------------------
	--	Varaible to loop through the implied sequence loop.
	-------------------------------------------------------------------------------------------------------------------
	@i						INT	,
-----------------------------------------------------------------------------------------------------------------------
--	Constants
-----------------------------------------------------------------------------------------------------------------------
--	Const value for prevent a possible problem if Implied sequence record count is to high
-----------------------------------------------------------------------------------------------------------------------
	@intConstImpSeqLimit	INT	,			
	@intConstCoalesceUpdate	INT	,			-- 00 - COALESCE.
	@intConstCommentUpdate	INT	,			-- 01 - Comment Update.
	@intConstPOStatusTrans	INT	,			-- 97 - Process Order Status Transition.
	@intConstPOBack			INT	,			-- 98 - Move Process Order Back.
	@intConstPOForward		INT	,			-- 99 - Move Process Order Forward.
-----------------------------------------------------------------------------------------------------------------------
--	Temporal Variables
-----------------------------------------------------------------------------------------------------------------------
	@intDBCommentId			INT	,			-- Temp value to compare the comment id from the DB with the parameter.
	@intDBImpliedSequence	INT	,			-- Temp value to compare the Implied Sequence from the DB with the parameter.
	@intDBPPStatusId		INT	,			-- Temp value to compare the PP Status id from the DB with the parameter.
	@fltDBForecastQuantity	FLOAT			-- Temp value to compare the Quantity from the DB with the parameter.
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
	@vchNestedObject	VARCHAR(256)	,
	@vchObjectName		VARCHAR(256)	,
	@nvchErrorMessage	NVARCHAR(2048)	,
	@vchErrorSection	VARCHAR(100)
--=====================================================================================================================
--	Set constants used for error handling
--=====================================================================================================================
SELECT
	@consErrorCritical	= -1	,
	@consErrorNone		= 0		,
	@consErrorWarning	= 1		,
	@consErrorInfo		= 2		,
	@intErrorSeverity	= 11	,
	@intErrorState		= 1
--=====================================================================================================================
--	Initialize all variables.  The only items hard-coded within this stored procedure are items that are specific to this
--	application and are unlikely to be used by any other application.  Acceptable items are Variable Aliases and Display
--	Option Descriptions.
--=====================================================================================================================
SELECT
	@intConstCoalesceUpdate	= 00		,
	@intConstCommentUpdate	= 01		,
	@intConstPOStatusTrans	= 97		,
	@intConstPOBack			= 98		,
	@intConstPOForward		= 99		,
	@intConstImpSeqLimit	= 100000	,	-- Default value used as a limit record count to abort the process
	@intTransNum			= 2			,	-- Default value used to create new records on the database
	@intReturnCode			= NULL		,
	@intDBCommentId			= NULL		,
	@intDBImpliedSequence	= NULL		,
	@intDBPPStatusId		= NULL		,
	@fltDBForecastQuantity	= NULL
--=====================================================================================================================
--	The @op_uidErrorId parameter is used to determine if the SP has been called by another SP.  If the value is null
--	then it is assumed that this SP is the top level SP.
--	
--	If it is the top level SP then get a unique identifier that will be used to log error messages and set the flag to
--	indicate that this SP is the primary SP.
--=====================================================================================================================
IF	@op_uidErrorId IS NULL
BEGIN
	SELECT	@op_uidErrorId = NEWID(),
			@intPrimary = 1
END
ELSE
BEGIN
	SELECT	@intPrimary = 0
END
BEGIN TRY
	--=================================================================================================================
	--	This parameters are validated only if the transaction type is not INSERT
	--	Use COALESCE for transaction type UPDATE
	--=================================================================================================================
	SELECT	@vchErrorSection = 'Input Validation A'
	BEGIN TRY
		-------------------------------------------------------------------------------------------------------------------
		--	Production Plan Id.
		-------------------------------------------------------------------------------------------------------------------
		IF		(@p_intTransType <> 1)
			AND	(	@op_intPPId  IS NULL 
				OR	@op_intPPId = 0)
		BEGIN
			-----------------------------------------------------------------------------------------------------------	
			--	This parameter is validated only if the Production Plan Id is BLANK
			-----------------------------------------------------------------------------------------------------------
			IF		(	@p_intPathId IS NULL 
					OR	@p_intPathId = 0)
				AND	(	@p_vchProcessOrder IS NULL 
					OR	LTRIM(RTRIM(@p_vchProcessOrder)) = '')
			BEGIN
				SELECT	@nvchErrorMessage	= 'The (Production Plan Id) OR (Path ID AND Process Order) '
											+ 'are required for transaction types: Update/Delete.'
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
			--=========================================================================================================
			--	Get the previous values from the DB for later analisys to generate the TransNum Properly
			--=========================================================================================================
			SELECT	@op_intPPId		= PP_Id
			FROM	dbo.Production_Plan	WITH (NOLOCK)
 			WHERE	Path_Id			= @p_intPathId
				AND	Process_Order	= @p_vchProcessOrder
			-----------------------------------------------------------------------------------------------------------
			--	Validates if the two parameters allows to retrieve the Production Plan Id
			-----------------------------------------------------------------------------------------------------------
			IF	@op_intPPId IS NULL
			BEGIN
				SELECT	@nvchErrorMessage	= 'The Path Id AND Process Order are invalid. Path Id = '
											+ COALESCE(CONVERT(VARCHAR(25),@p_intPathId),'BLANK')
											+ ' and ProcessOrder = '
											+ COALESCE(@p_vchProcessOrder,'BLANK')
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
	--	Validate the Process Order does not exists in the same path on Insert transactions
	-------------------------------------------------------------------------------------------------------------------
	IF	@p_intTransType = 1
	AND EXISTS(
		SELECT	pp.PP_Id
		FROM dbo.Production_Plan	pp	WITH(NOLOCK)
		WHERE	pp.Process_Order	=	@p_vchProcessOrder
			AND	pp.Path_Id			=	@p_intPathId
	)
	BEGIN
			SELECT	@nvchErrorMessage	= 'The ProcessOrder = '
											+ COALESCE(CONVERT(VARCHAR(25),@p_vchProcessOrder),'BLANK')
											+ ' already exists on the PathId = '
											+COALESCE(CONVERT(VARCHAR(25),@p_intPathId),'BLANK')
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
	END
	-------------------------------------------------------------------------------------------------------------------
	--	If supplied value is initialized incorrectly then clear it with a NULL value
	-------------------------------------------------------------------------------------------------------------------
	IF	@op_intImpliedSequence	= 0
	BEGIN
		SELECT	@op_intImpliedSequence	=	NULL
	END
	-------------------------------------------------------------------------------------------------------------------
	--	Validate Entry_On field
	-------------------------------------------------------------------------------------------------------------------
	IF	@op_dtmEntryOn	IS NULL
	BEGIN
		SELECT	@op_dtmEntryOn	=	GETDATE()
	END
	--=================================================================================================================
	--	USE COALESCE FUNCTION to get the previous value from the database with the key parameter only if the
	--	parameters are NULL
	--=================================================================================================================
	SELECT	@op_intPPId				= COALESCE(@op_intPPId				,PP_Id						),
			@p_intPathId			= COALESCE(@p_intPathId				,Path_Id					),
			@p_intCommentId			= COALESCE(@p_intCommentId			,Comment_Id					),
			@p_intProdId			= COALESCE(@p_intProdId				,Prod_Id					),
			@op_intImpliedSequence	= COALESCE(@op_intImpliedSequence	,Implied_Sequence			),
			@p_intPPStatusId		= COALESCE(@p_intPPStatusId			,PP_Status_Id				),
			@p_intPPTypeId			= COALESCE(@p_intPPTypeId			,PP_Type_Id					),
			@p_intSourcePPId		= COALESCE(@p_intSourcePPId			,Source_PP_Id				),
			@p_intUserId			= COALESCE(@p_intUserId				,User_Id					),
			@p_intParentPPId		= COALESCE(@p_intParentPPId			,Parent_PP_Id				),
			@p_intControlType		= COALESCE(@p_intControlType		,Control_Type,	2			),
			@p_dtmForecastStartTime	= COALESCE(@p_dtmForecastStartTime	,Forecast_Start_Date		),
			@p_dtmForecastEndTime	= COALESCE(@p_dtmForecastEndTime	,Forecast_End_Date			),
			@p_fltForecastQuantity	= COALESCE(@p_fltForecastQuantity	,Forecast_Quantity			),
			@p_fltProductionRate	= COALESCE(@p_fltProductionRate		,Production_Rate			),
			@p_fltAdjustedQuantity	= COALESCE(@p_fltAdjustedQuantity	,Adjusted_Quantity			),
			@p_vchBlockNumber		= COALESCE(@p_vchBlockNumber		,Block_Number				),
			@p_vchProcessOrder		= COALESCE(@p_vchProcessOrder		,Process_Order				),
			@p_intBOMFormulationId	= COALESCE(@p_intBOMFormulationId	,BOM_Formulation_Id			),
			@p_vchUserGeneral1		= COALESCE(@p_vchUserGeneral1		,User_General_1				),
			@p_vchUserGeneral2		= COALESCE(@p_vchUserGeneral2		,User_General_2				),
			@p_vchUserGeneral3		= COALESCE(@p_vchUserGeneral3		,User_General_3				),
			@p_vchExtendedInfo		= COALESCE(@p_vchExtendedInfo		,Extended_Info				),
			@intDBCommentId			= Comment_Id						,
			@intDBImpliedSequence	= Implied_Sequence					,
			@intDBPPStatusId		= PP_Status_Id						,
			@fltDBForecastQuantity	= Forecast_Quantity					,
			@dtmTransactionTime		= GETDATE()
	FROM	dbo.Production_Plan	WITH	(NOLOCK)
	WHERE	PP_Id					=	@op_intPPId
	--=================================================================================================================
	--	Validate the inputs, if the transaction type is not DELETE
	--=================================================================================================================
	SELECT	@vchErrorSection = 'Input Validation A'
	BEGIN TRY
		---------------------------------------------------------------------------------------------------------------
		--	Transaction Type.
		---------------------------------------------------------------------------------------------------------------
		IF	NOT	@p_intTransType BETWEEN 1 AND 3
		BEGIN
			SELECT	@nvchErrorMessage	= 'Supplied Transaction Type is invalid.  It must be 1, 2 or 3.  TransactionType = '
										+ COALESCE(CONVERT(VARCHAR(25), @p_intTransType), 'BLANK')
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	@PathId.
		--	Required field
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intPathId	IS NULL
			OR	@p_intPathId	= 0
		BEGIN
			SELECT	@nvchErrorMessage	= 'Path Id is Required.'
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	Validate the @PathId.
		---------------------------------------------------------------------------------------------------------------
		ELSE
		BEGIN
			IF	NOT EXISTS	(
				SELECT	Path_Id
				FROM	dbo.Prdexec_Paths	WITH(NOLOCK)
				WHERE	Path_Id	= @p_intPathId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Path Id is invalid.  Path Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intPathId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Comment Id.
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intCommentId IS NOT NULL
			AND	@p_intCommentId <> 0
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	If it is about to be deleted and the comment is invalid do not raise an error. It is mainly because the
			--	comment was already deleted
			-----------------------------------------------------------------------------------------------------------
			IF	@p_intTransType	<> 3
				AND	NOT EXISTS	(
				SELECT	Comment_Id
				FROM	dbo.Comments	WITH(NOLOCK)
				WHERE	Comment_Id	=	@p_intCommentId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Comment Id is invalid.  Comment Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intCommentId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Prod Id.
		--	Required Field
		--	If the transaction type is not DELETE AND the information is BLANK
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intTransType <> 3
			AND (	@p_intProdId IS NULL 
				OR	@p_intProdId = 0)
		BEGIN
			SELECT	@nvchErrorMessage	= 'Product Id is Required.'
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	Prod Id.
		--	If the transaction type is not DELETE AND the value is set
		---------------------------------------------------------------------------------------------------------------
		ELSE IF @p_intTransType <> 3
		BEGIN
			IF	NOT EXISTS	(
				SELECT	Prod_Id
				FROM	dbo.Products	WITH(NOLOCK)
				WHERE	Prod_Id	=	@p_intProdId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Product Id is invalid.  Product Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intProdId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Production Plan Status Id.
		--	Required Field
		--	If the transaction type is not DELETE AND the information is BLANK
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intTransType	<> 3
			AND	(	@p_intPPStatusId  IS NULL
				OR	@p_intPPStatusId  = 0)
		BEGIN
			SELECT	@nvchErrorMessage	= 'Production Plan Status Id is Required.'
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	Production Plan Status Id.
		--	If the transaction type is not DELETE AND the value is set
		---------------------------------------------------------------------------------------------------------------
		ELSE IF @p_intTransType <> 3
		BEGIN
			IF	NOT EXISTS	(
				SELECT	PP_Status_Id
				FROM	dbo.Production_Plan_Statuses	WITH(NOLOCK)
				WHERE	PP_Status_Id	= @p_intPPStatusId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Production Plan Status Id is invalid. Production Plan Status Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intPPStatusId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Production Plan Type Id.
		--	Required Field
		--	If the transaction type is not DELETE AND the information is BLANK
		---------------------------------------------------------------------------------------------------------------
		IF	@p_intTransType <> 3
			AND	(	@p_intPPTypeId	IS NULL
				OR	@p_intPPTypeId	=	0)
		BEGIN
			SELECT	@nvchErrorMessage	= 'Production Plan Type Id is Required.'
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	Production Plan Type Id.
		--	If the transaction type is not DELETE AND the value is set
		---------------------------------------------------------------------------------------------------------------
		ELSE IF @p_intTransType <> 3
		BEGIN
			IF	NOT EXISTS(
				SELECT	PP_Type_Id
				FROM	dbo.Production_Plan_Types	WITH (NOLOCK)
				WHERE	PP_Type_Id	= @p_intPPTypeId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Production Plan Type Id is invalid. Production Plan Type Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intPPTypeId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Source Production Plan Id.
		--	If the transaction type is not DELETE AND the value is set
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intTransType		<> 3
			AND	@p_intSourcePPId	IS NOT NULL
			AND @p_intSourcePPId	<> 0
		BEGIN
			IF	NOT EXISTS	(
				SELECT	PP_Id
				FROM	dbo.Production_Plan	WITH(NOLOCK)
				WHERE	PP_Id	= @p_intSourcePPId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Source Production Plan Id is invalid. Source Production Plan Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intSourcePPId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	User Id.
		--	Required Field
		--	If the transaction type is not DELETE AND the information is BLANK
		---------------------------------------------------------------------------------------------------------------
		IF		(@p_intTransType <> 3)
			AND	(	@p_intUserId IS NULL
				OR	@p_intUserId = 0)
		BEGIN
			SELECT	@nvchErrorMessage	= 'User Id is Required.'
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	User Id.
		--	If the transaction type is not DELETE AND the value is set
		---------------------------------------------------------------------------------------------------------------
		ELSE IF @p_intTransType <> 3
		BEGIN
			IF	NOT EXISTS	(
				SELECT	User_Id
				FROM	dbo.Users	WITH (NOLOCK)
				WHERE	User_Id	=	@p_intUserId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied User Id is invalid. User Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intUserId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Parent Production Plan Id.
		--	If the transaction type is not DELETE AND the value is set
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intTransType		<> 3
			AND	@p_intParentPPId	IS NOT NULL
			AND @p_intParentPPId	<> 0
		BEGIN
			IF	NOT EXISTS	(
				SELECT	PP_Id
				FROM	dbo.Production_Plan	WITH(NOLOCK)
				WHERE	PP_Id	= @p_intParentPPId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Supplied Parent Production Plan Id is invalid. Parent Production Plan Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intParentPPId), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Control Type Id.
		--	Required Field
		--	If the parameter is BLANK
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intControlType IS NULL 
			OR	@p_intControlType = 0
		BEGIN
			SELECT	@nvchErrorMessage	= 'Control Type Id is Required.'
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	Control Type Id.
		--	If the value is set
		---------------------------------------------------------------------------------------------------------------
		ELSE
		BEGIN
			IF	NOT EXISTS	(
				SELECT	Control_Type_Id
				FROM	dbo.Control_Type	WITH (NOLOCK)
				WHERE	Control_Type_Id	=	@p_intControlType)
			BEGIN
				SELECT	@nvchErrorMessage	= 'Control Type Id is invalid. Control Type Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intControlType), 'BLANK')
				RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	Forecast Start Time
		--	Forecast End Time
		--	If the transaction type is not DELETE AND the value are set
		--	AND ForecastStartTime is not greater than ForecastEndTime 
		---------------------------------------------------------------------------------------------------------------
		IF		@p_dtmForecastStartTime	IS	NOT	NULL
			AND	@p_dtmForecastEndTime	IS	NOT	NULL
			AND	DATEDIFF(SECOND, @p_dtmForecastStartTime, @p_dtmForecastEndTime) < 0
		BEGIN
			SELECT	@nvchErrorMessage	= 'Forecast StartTime is later than Forecast EndTime. Forecast StartTime = '
										+ CONVERT(VARCHAR(25), @p_dtmForecastStartTime)
										+ ' Forecast EndTime = '
										+ CONVERT(VARCHAR(25), @p_dtmForecastEndTime)
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	Process Order.
		--	Required Field
		--	If the parameter is BLANK
		---------------------------------------------------------------------------------------------------------------
		IF		@p_vchProcessOrder IS NULL 
			OR	LTRIM(RTRIM(@p_vchProcessOrder)) = ''
		BEGIN
			SELECT	@nvchErrorMessage	= 'Process Order is Required.'
			RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
		END
		---------------------------------------------------------------------------------------------------------------
		--	Entry On.
		---------------------------------------------------------------------------------------------------------------
		IF	@op_dtmEntryOn IS NULL
		BEGIN
			SELECT @op_dtmEntryOn = @dtmTransactionTime
		END
		---------------------------------------------------------------------------------------------------------------
		--	BOM Formulation Id.
		--	If the value is set
		---------------------------------------------------------------------------------------------------------------
		IF		@p_intBOMFormulationId IS NOT NULL 
			AND	@p_intBOMFormulationId <> 0
		BEGIN
			IF	NOT EXISTS	(
				SELECT	BOM_Formulation_Id
				FROM	dbo.Bill_Of_Material_Formulation	WITH(NOLOCK)
				WHERE	BOM_Formulation_Id	=	@p_intBOMFormulationId)
			BEGIN
				SELECT	@nvchErrorMessage	= 'BOM Formulation Id is invalid. BOM Formulation Id = '
											+ COALESCE(CONVERT(VARCHAR(25), @p_intBOMFormulationId), 'BLANK')
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
	--=================================================================================================================
	--	if Transaction type is INSERT
	--=================================================================================================================
	IF	@p_intTransType = 1
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		--	Clean Primary Key parameter
		---------------------------------------------------------------------------------------------------------------
		SELECT	@op_intPPId			= NULL
		---------------------------------------------------------------------------------------------------------------
		--	Check @p_bitWriteDirect to see if the user want to write directly on the DB
		---------------------------------------------------------------------------------------------------------------	
		IF @p_bitWriteDirect = 0
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Return Production Plan Result Set
			-----------------------------------------------------------------------------------------------------------
			 SELECT	[RSTId]				= 15						,
					[PreDB]				= 1							,	--	NOT POST DB
					[TransType]			= @p_intTransType			,	--	@TransType int,
					[TransNum]			= @intTransNum				,	--	@TransNum int,5
					[PathId]			= @p_intPathId				,	--	@PathId int, 
					[PPId]				= @op_intPPId				,	--	@PPId int OUTPUT,		
					[CommentId]			= @p_intCommentId			,	--	@CommentId int,
					[ProdId]			= @p_intProdId				,	--	@ProdId int,
					[ImpliedSequence]	= @op_intImpliedSequence	,	--	@ImpliedSequence int OUTPUT,
					[PPStatusId]		= @p_intPPStatusId			,	--	@PPStatusId int,
					[PPTypeId]			= @p_intPPTypeId			,	--	@PPTypeId int,
					[SourcePPId]		= @p_intSourcePPId			,	--	@SourcePPId int,
					[UserId]			= @p_intUserId				,	--	@UserId int,
					[ParentPPId]		= @p_intParentPPId			,	--	@ParentPPId int,
					[ControlType]		= @p_intControlType			,	--	@ControlType tinyint,
					[ForecastStartTime]	= @p_dtmForecastStartTime	,	--	@ForecastStartTime datetime,
					[ForecastEndTime]	= @p_dtmForecastEndTime		,	--	@ForecastEndTime datetime,
					[EntryOn]			= @op_dtmEntryOn			,	--	@EntryOn datetime OUTPUT,
					[ForecastQuantity]	= @p_fltForecastQuantity	,	--	@ForecastQuantity float,
					[ProductionRate]	= @p_fltProductionRate		,	--	@ProductionRate float, 
					[AdjustedQuantity]	= @p_fltAdjustedQuantity	,	--	@AdjustedQuantity float, 
					[BlockNumber]		= @p_vchBlockNumber			,	--	@BlockNumber varchar(50),
					[ProcessOrder]		= @p_vchProcessOrder		,	--	@ProcessOrder varchar(50),
					[TransactionTime]	= @dtmTransactionTime		,	--	@TransactionTime datetime,
					[Misc]				= NULL						,	--	@Misc1 int,
					[Misc]				= NULL						,	--	@Misc2 int,
					[Misc]				= NULL						,	--	@Misc3 int,
					[Misc]				= NULL						,	--	@Misc4 int,
					[BOMFormulationId]	= @p_intBOMFormulationId	,	--	@BOMFormulationId bigint = NULL
					[UserGen1]			= NULL						,
					[UserGen2]			= NULL						,
					[UserGen3]			= NULL						,
					[ExtendedInfo]		= NULL											
		END
		---------------------------------------------------------------------------------------------------------------
		--	Otherwise it will excecute the SP directly to affect the DB
		---------------------------------------------------------------------------------------------------------------
		ELSE
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Sets error Section
			-----------------------------------------------------------------------------------------------------------
			SELECT	@vchErrorSection	= 'GE UpdProdPlan Call Insert'		,
					@vchNestedObject	= 'dbo.spServer_DBMgrUpdProdPlan'
			BEGIN TRY
				--=====================================================================================================
				--	Write a new Production Plan record within the database.
				--=====================================================================================================
				EXEC	@intReturnCode	= dbo.spServer_DBMgrUpdProdPlan
					@op_intPPId				OUTPUT	,	--	@PPId int OUTPUT,
					@p_intTransType					,	--	@TransType int,
					@intTransNum					,	--	@TransNum int,
					@p_intPathId					,	--	@PathId int, 
					@p_intCommentId					,	--	@CommentId int,
					@p_intProdId					,	--	@ProdId int,
					@op_intImpliedSequence	OUTPUT	,	--	@ImpliedSequence int OUTPUT,
					@p_intPPStatusId				,	--	@PPStatusId int,
					@p_intPPTypeId					,	--	@PPTypeId int,
					@p_intSourcePPId				,	--	@SourcePPId int,
					@p_intUserId					,	--	@UserId int,
					@p_intParentPPId				,	--	@ParentPPId int,
					@p_intControlType				,	--	@ControlType tinyint,
					@p_dtmForecastStartTime			,	--	@ForecastStartTime datetime,
					@p_dtmForecastEndTime			,	--	@ForecastEndTime datetime,
					@op_dtmEntryOn			OUTPUT	,	--	@EntryOn datetime OUTPUT,
					@p_fltForecastQuantity			,	--	@ForecastQuantity float,
					@p_fltProductionRate			,	--	@ProductionRate float, 
					@p_fltAdjustedQuantity			,	--	@AdjustedQuantity float, 
					@p_vchBlockNumber				,	--	@BlockNumber varchar(50),
					@p_vchProcessOrder				,	--	@ProcessOrder varchar(50),
					@dtmTransactionTime				,	--	@TransactionTime datetime,
					NULL							,	--	@Misc1 int,
					NULL							,	--	@Misc2 int,
					NULL							,	--	@Misc3 int,
					NULL							,	--	@Misc4 int,
					@p_intBOMFormulationId				--	@BOMFormulationId bigint = NULL
				-------------------------------------------------------------------------------------------------------
				--	If the SP returns an error, it sets the properly the error message
				-------------------------------------------------------------------------------------------------------
				IF	@intReturnCode < 0
				BEGIN
					SELECT	@nvchErrorMessage	= 'The insert call to dbo.spServer_DBMgrUpdProdPlan returned an error. '
												+ 'Code = ' + COALESCE(CONVERT(VARCHAR(25), @intReturnCode), 'BLANK')
					---------------------------------------------------------------------------------------------------
					--	Raise Error
					---------------------------------------------------------------------------------------------------
					RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
				END
			END TRY
			BEGIN CATCH
				-------------------------------------------------------------------------------------------------------
				--	Rollback Transaction
				-------------------------------------------------------------------------------------------------------
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
	--=================================================================================================================
	--	If the transaction type is UPDATE
	--=================================================================================================================
	ELSE IF		@p_intTransType = 2
	BEGIN
		--=============================================================================================================
		--	Start to asign the TransNum according to the key fields that TransNum should be modify
		--	a.	Comment Id
		--	b.	PP Status Id
		--	c.	Implied Sequence
		--	d.	COALESCE
		--=============================================================================================================
		--	a.	Comment Id
		--	Verifies that the fields have values and they are different
		---------------------------------------------------------------------------------------------------------------
		IF	(		NOT	@intDBCommentId	IS NULL
				AND	NOT	@p_intCommentId	IS NULL
				AND		@intDBCommentId	<> @p_intCommentId
			)
			OR
			(		@intDBCommentId	IS NULL
				AND	@p_intCommentId	IS NOT NULL
			)
			OR
			(		@fltDBForecastQuantity	IS	NOT	NULL
				AND	@p_fltForecastQuantity	IS	NOT	NULL
				AND	@fltDBForecastQuantity	<>	@p_fltForecastQuantity)
			OR
			(		@fltDBForecastQuantity	IS	NULL
				AND	@p_fltForecastQuantity	IS	NOT	NULL
			)
			OR
			(	@p_dtmForecastStartTime	IS	NOT	NULL
				OR	@p_dtmForecastEndTime IS NOT NULL)
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Check @p_bitWriteDirect to see if the user want to write directly on the DB
			-----------------------------------------------------------------------------------------------------------
			IF @p_bitWriteDirect = 0
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Return Production Plan Result Set
				--	Overwrite the value for Comment Id, replace the @intDBCommentId with @p_intCommentId
				-------------------------------------------------------------------------------------------------------
				 SELECT	[RSTId]				= 15						,	
						[PreDB]				= 1							,	--	NOT POST DB
						[TransType]			= @p_intTransType			,	--	@TransType int,
						[TransNum]			= @intConstCommentUpdate	,	--	@TransNum int,
						[PathId]			= @p_intPathId				,	--	@PathId int, 
						[PPId]				= @op_intPPId				,	--	@PPId int OUTPUT,		
						[CommentId]			= @p_intCommentId			,	--	@CommentId int,
						[ProdId]			= @p_intProdId				,	--	@ProdId int,
						[ImpliedSequence]	= @op_intImpliedSequence	,	--	@ImpliedSequence int OUTPUT,
						[PPStatusId]		= @p_intPPStatusId			,	--	@PPStatusId int,
						[PPTypeId]			= @p_intPPTypeId			,	--	@PPTypeId int,
						[SourcePPId]		= @p_intSourcePPId			,	--	@SourcePPId int,
						[UserId]			= @p_intUserId				,	--	@UserId int,
						[ParentPPId]		= @p_intParentPPId			,	--	@ParentPPId int,
						[ControlType]		= @p_intControlType			,	--	@ControlType tinyint,
						[ForecastStartTime]	= @p_dtmForecastStartTime	,	--	@ForecastStartTime datetime,
						[ForecastEndTime]	= @p_dtmForecastEndTime		,	--	@ForecastEndTime datetime,
						[EntryOn]			= @op_dtmEntryOn			,	--	@EntryOn datetime OUTPUT,
						[ForecastQuantity]	= @p_fltForecastQuantity	,	--	@ForecastQuantity float,
						[ProductionRate]	= @p_fltProductionRate		,	--	@ProductionRate float, 
						[AdjustedQuantity]	= @p_fltAdjustedQuantity	,	--	@AdjustedQuantity float, 
						[BlockNumber]		= @p_vchBlockNumber			,	--	@BlockNumber varchar(50),
						[ProcessOrder]		= @p_vchProcessOrder		,	--	@ProcessOrder varchar(50),
						[TransactionTime]	= @dtmTransactionTime		,	--	@TransactionTime datetime,
						[Misc]				= NULL						,	--	@Misc1 int,
						[Misc]				= NULL						,	--	@Misc2 int,
						[Misc]				= NULL						,	--	@Misc3 int,
						[Misc]				= NULL						,	--	@Misc4 int,
						[BOMFormulationId]	= @p_intBOMFormulationId	,	--	@BOMFormulationId bigint = NULL
						[UserGen1]			= NULL						,
						[UserGen2]			= NULL						,
						[UserGen3]			= NULL						,
						[ExtendedInfo]		= NULL												
			END
			-----------------------------------------------------------------------------------------------------------
			--	Otherwise it will excecute the SP directly to affect the DB
			-----------------------------------------------------------------------------------------------------------
			ELSE
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Set Error Section
				-------------------------------------------------------------------------------------------------------
				SELECT	@vchErrorSection	= 'GE UpdProdPlan Call Update A'	,
						@vchNestedObject	= 'dbo.spServer_DBMgrUpdProdPlan'
				BEGIN TRY
					--=================================================================================================
					--	Update a Production Plan record within the database.
					--	TransNum = 01
					--	NOTE:	See TODO List to now about the problem with this functionality
					--=================================================================================================
					EXEC	@intReturnCode	= dbo.spServer_DBMgrUpdProdPlan
						@op_intPPId				OUTPUT	,	--	@PPId int OUTPUT,
						@p_intTransType					,	--	@TransType int,
						@intConstCommentUpdate			,	--	@TransNum int,
						@p_intPathId					,	--	@PathId int, 
						@p_intCommentId					,	--	@CommentId int,
						@p_intProdId					,	--	@ProdId int,
						@op_intImpliedSequence	OUTPUT	,	--	@ImpliedSequence int OUTPUT,
						@p_intPPStatusId				,	--	@PPStatusId int,
						@p_intPPTypeId					,	--	@PPTypeId int,
						@p_intSourcePPId				,	--	@SourcePPId int,
						@p_intUserId					,	--	@UserId int,
						@p_intParentPPId				,	--	@ParentPPId int,
						@p_intControlType				,	--	@ControlType tinyint,
						@p_dtmForecastStartTime			,	--	@ForecastStartTime datetime,
						@p_dtmForecastEndTime			,	--	@ForecastEndTime datetime,
						@op_dtmEntryOn			OUTPUT	,	--	@EntryOn datetime OUTPUT,
						@p_fltForecastQuantity			,	--	@ForecastQuantity float,
						@p_fltProductionRate			,	--	@ProductionRate float, 
						@p_fltAdjustedQuantity			,	--	@AdjustedQuantity float, 
						@p_vchBlockNumber				,	--	@BlockNumber varchar(50),
						@p_vchProcessOrder				,	--	@ProcessOrder varchar(50),
						@dtmTransactionTime				,	--	@TransactionTime datetime,
						NULL							,	--	@Misc1 int,
						NULL							,	--	@Misc2 int,
						NULL							,	--	@Misc3 int,
						NULL							,	--	@Misc4 int,
						@p_intBOMFormulationId				--	@BOMFormulationId bigint = NULL
					---------------------------------------------------------------------------------------------------
					--	If the SP returns an error, it sets the properly the error message
					---------------------------------------------------------------------------------------------------
					IF	@intReturnCode < 0
					BEGIN
						SELECT	@nvchErrorMessage	= 'The update call to dbo.spServer_DBMgrUpdProdPlan returned an error.'
													+ ' Code = ' + COALESCE(CONVERT(VARCHAR(25), @intReturnCode), '')
						-----------------------------------------------------------------------------------------------
						--	Raise Error
						-----------------------------------------------------------------------------------------------
						RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
					END
				END TRY
				BEGIN CATCH
					--=================================================================================================
					--	Rollback Transaction
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
				-------------------------------------------------------------------------------------------------------
				--	At this point it is necesary to update directly the Forecast Quantity directly, because the proficy
				--	sproc is not doing this functionality
				-------------------------------------------------------------------------------------------------------
				IF	@p_fltForecastQuantity	IS NOT NULL
				BEGIN
					---------------------------------------------------------------------------------------------------
					--	Set Error Section
					---------------------------------------------------------------------------------------------------
					SELECT	@vchErrorSection	= 'Production Plan Update A'	,
							@vchNestedObject	= 'dbo.Production_Plan'
					BEGIN TRANSACTION
					BEGIN TRY
						UPDATE	dbo.Production_Plan
						SET		Forecast_Quantity	=	COALESCE(@p_fltForecastQuantity	,Forecast_Quantity	)
						WHERE	PP_Id	=	@op_intPPId
					END TRY
					BEGIN CATCH
						-----------------------------------------------------------------------------------------------
						--	Rollback Transaction
						-----------------------------------------------------------------------------------------------
						IF	@@TRANCOUNT	>	0
						BEGIN
							ROLLBACK TRANSACTION
						END
						-----------------------------------------------------------------------------------------------
						--	Set error message
						-----------------------------------------------------------------------------------------------
						SELECT	@nvchErrorMessage	= COALESCE(@nvchErrorMessage, ERROR_MESSAGE())
						-----------------------------------------------------------------------------------------------
						--	Raise Error
						-----------------------------------------------------------------------------------------------
						RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
					END CATCH
					---------------------------------------------------------------------------------------------------
					--	Commit Transaction
					---------------------------------------------------------------------------------------------------
					IF	@@TRANCOUNT	>	0
					BEGIN
						COMMIT TRANSACTION
					END
				END
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	b.	PP Status Id
		---------------------------------------------------------------------------------------------------------------
		IF		NOT	@intDBPPStatusId	IS NULL
			AND	NOT	@p_intPPStatusId	IS NULL
			AND		@intDBPPStatusId	<> @p_intPPStatusId
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Check @p_bitWriteDirect to see if the user want to write directly on the DB
			-----------------------------------------------------------------------------------------------------------
			IF @p_bitWriteDirect = 0
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Return Production Plan Result Set
				--	Overwrite the value for Production Status Id replace the @intDBPPStatusId with @p_intPPStatusId
				-------------------------------------------------------------------------------------------------------
				 SELECT	[RSTId]				= 15						,
						[PreDB]				= 1							,	--	NOT POST DB
						[TransType]			= @p_intTransType			,	--	@TransType int,
						[TransNum]			= @intConstPOStatusTrans	,	--	@TransNum int,
						[PathId]			= @p_intPathId				,	--	@PathId int, 
						[PPId]				= @op_intPPId				,	--	@PPId int OUTPUT,		
						[CommentId]			= @p_intCommentId			,	--	@CommentId int,
						[ProdId]			= @p_intProdId				,	--	@ProdId int,
						[ImpliedSequence]	= @op_intImpliedSequence	,	--	@ImpliedSequence int OUTPUT,
						[PPStatusId]		= @p_intPPStatusId			,	--	@PPStatusId int,
						[PPTypeId]			= @p_intPPTypeId			,	--	@PPTypeId int,
						[SourcePPId]		= @p_intSourcePPId			,	--	@SourcePPId int,
						[UserId]			= @p_intUserId				,	--	@UserId int,
						[ParentPPId]		= @p_intParentPPId			,	--	@ParentPPId int,
						[ControlType]		= @p_intControlType			,	--	@ControlType tinyint,
						[ForecastStartTime]	= @p_dtmForecastStartTime	,	--	@ForecastStartTime datetime,
						[ForecastEndTime]	= @p_dtmForecastEndTime		,	--	@ForecastEndTime datetime,
						[EntryOn]			= @op_dtmEntryOn			,	--	@EntryOn datetime OUTPUT,
						[ForecastQuantity]	= @p_fltForecastQuantity	,	--	@ForecastQuantity float,
						[ProductionRate]	= @p_fltProductionRate		,	--	@ProductionRate float, 
						[AdjustedQuantity]	= @p_fltAdjustedQuantity	,	--	@AdjustedQuantity float, 
						[BlockNumber]		= @p_vchBlockNumber			,	--	@BlockNumber varchar(50),
						[ProcessOrder]		= @p_vchProcessOrder		,	--	@ProcessOrder varchar(50),
						[TransactionTime]	= @dtmTransactionTime		,	--	@TransactionTime datetime,
						[Misc]				= NULL						,	--	@Misc1 int,
						[Misc]				= NULL						,	--	@Misc2 int,
						[Misc]				= NULL						,	--	@Misc3 int,
						[Misc]				= NULL						,	--	@Misc4 int,
						[BOMFormulationId]	= @p_intBOMFormulationId	,	--	@BOMFormulationId bigint = NULL
						[UserGen1]			= NULL						,
						[UserGen2]			= NULL						,
						[UserGen3]			= NULL						,
						[ExtendedInfo]		= NULL												
			END
			-----------------------------------------------------------------------------------------------------------
			--	Otherwise it will excecute the SP directly to affect the DB
			-----------------------------------------------------------------------------------------------------------
			ELSE
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Set Error Section
				-------------------------------------------------------------------------------------------------------
				SELECT	@vchErrorSection	= 'GE UpdProdPlan Call Update B'	,
						@vchNestedObject	= 'dbo.spServer_DBMgrUpdProdPlan'
				BEGIN TRY
					--=================================================================================================
					--	Update a Production Plan record within the database.
					--	TransNum = 97
					--=================================================================================================
					EXEC @intReturnCode	= dbo.spServer_DBMgrUpdProdPlan
						@op_intPPId				OUTPUT	,	--	@PPId int OUTPUT,
						@p_intTransType					,	--	@TransType int,
						@intConstPOStatusTrans			,	--	@TransNum int,
						@p_intPathId					,	--	@PathId int, 
						@p_intCommentId					,	--	@CommentId int,
						@p_intProdId					,	--	@ProdId int,
						@op_intImpliedSequence	OUTPUT	,	--	@ImpliedSequence int OUTPUT,
						@p_intPPStatusId				,	--	@PPStatusId int,
						@p_intPPTypeId					,	--	@PPTypeId int,
						@p_intSourcePPId				,	--	@SourcePPId int,
						@p_intUserId					,	--	@UserId int,
						@p_intParentPPId				,	--	@ParentPPId int,
						@p_intControlType				,	--	@ControlType tinyint,
						@p_dtmForecastStartTime			,	--	@ForecastStartTime datetime,
						@p_dtmForecastEndTime			,	--	@ForecastEndTime datetime,
						@op_dtmEntryOn			OUTPUT	,	--	@EntryOn datetime OUTPUT,
						@p_fltForecastQuantity			,	--	@ForecastQuantity float,
						@p_fltProductionRate			,	--	@ProductionRate float, 
						@p_fltAdjustedQuantity			,	--	@AdjustedQuantity float, 
						@p_vchBlockNumber				,	--	@BlockNumber varchar(50),
						@p_vchProcessOrder				,	--	@ProcessOrder varchar(50),
						@dtmTransactionTime				,	--	@TransactionTime datetime,
						NULL							,	--	@Misc1 int,
						NULL							,	--	@Misc2 int,
						NULL							,	--	@Misc3 int,
						NULL							,	--	@Misc4 int,
						@p_intBOMFormulationId				--	@BOMFormulationId bigint = NULL
					---------------------------------------------------------------------------------------------------
					--	If the SP returns an error, it sets the properly the error message
					---------------------------------------------------------------------------------------------------
					IF	@intReturnCode < 0
					BEGIN
						SELECT	@nvchErrorMessage	= 'The update call to dbo.spServer_DBMgrUpdProdPlan returned an error.'
													+ ' Code = ' + COALESCE(CONVERT(VARCHAR(25), @intReturnCode), '')
						-----------------------------------------------------------------------------------------------
						--	Raise Error
						-----------------------------------------------------------------------------------------------
						RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
					END
				END TRY
				BEGIN CATCH
					--=================================================================================================
					--	Rollback Transaction
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
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	c. Implied Sequence	
		--	Verifies that the fields have values and they are different
		---------------------------------------------------------------------------------------------------------------
		IF		NOT	@intDBImpliedSequence	IS NULL
			AND	NOT	@op_intImpliedSequence	IS NULL
			AND		ISNUMERIC(@op_intImpliedSequence)	= 1
			AND		ISNUMERIC(@intDBImpliedSequence)	= 1
			AND		@intDBImpliedSequence <> @op_intImpliedSequence
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Clean the variable to know how many loops to do
			-----------------------------------------------------------------------------------------------------------
			SELECT		@intImpSeqCount = NULL
			-----------------------------------------------------------------------------------------------------------
			--	Implied Sequence has an order, that way it is possible to know If the record has to be moved up or down.
			--	If @intDBImpliedSequence is less than @op_intImpliedSequence, it will loop using
			--	TransNum 98 - Move Process Order Back
			-----------------------------------------------------------------------------------------------------------
			IF	@intDBImpliedSequence < @op_intImpliedSequence
			BEGIN
				SELECT	@intTransNum = @intConstPOBack
				-------------------------------------------------------------------------------------------------------
				--	Count the Implied Sequence between the one of the DB and the value passed through the SP
				--	only if the first one is less than second one
				-------------------------------------------------------------------------------------------------------
				SELECT		@intImpSeqCount	= COUNT(*)
				FROM		dbo.Production_Plan	WITH (NOLOCK)
				WHERE	(	Path_Id	= @p_intPathId
						OR	(	Path_Id			IS	NULL
							AND	@p_intPathId	IS	NULL
							)
						)
					AND		Implied_Sequence 
					BETWEEN @intDBImpliedSequence
					AND		@op_intImpliedSequence
			END
			-----------------------------------------------------------------------------------------------------------
			--	If @intDBImpliedSequence is greater than @op_intImpliedSequence, it will loop using
			--	TransNum 99 - Move Process Order Forward
			-----------------------------------------------------------------------------------------------------------
			ELSE
			BEGIN
				SELECT	@intTransNum = @intConstPOForward
				-------------------------------------------------------------------------------------------------------
				--	Count the Implied Sequence between the one of the DB and the value passed through the SP
				--	only if the first one is less than second one
				-------------------------------------------------------------------------------------------------------
				SELECT		@intImpSeqCount	= COUNT(*)
				FROM		dbo.Production_Plan	WITH (NOLOCK)
				WHERE	(	Path_Id	= @p_intPathId
						OR	(	Path_Id			IS	NULL
							AND	@p_intPathId	IS	NULL
							)
						)
					AND		Implied_Sequence 
					BETWEEN @op_intImpliedSequence
					AND		@intDBImpliedSequence
			END
			-----------------------------------------------------------------------------------------------------------
			--	Set Error Section
			-----------------------------------------------------------------------------------------------------------
			SELECT	@vchErrorSection	= 'Implied Sequence Validation'	,
					@vchNestedObject	= NULL
			-----------------------------------------------------------------------------------------------------------
			--	Validate the record Count to prevent lots of process trying to reach the implied sequence number
			--	if there were lots of records to move it from @intDBImpliedSequence to @op_intImpliedSequence
			-----------------------------------------------------------------------------------------------------------
			BEGIN TRY
				IF	NOT	@intImpSeqCount	IS NULL
					AND	@intImpSeqCount >= @intConstImpSeqLimit
				BEGIN
					SELECT	@op_vchErrorMessage	=	'Implied Sequence has a problem because the record quantity'
													+	' to move from actual Implied Sequence = ' 
													+	COALESCE(CONVERT(VARCHAR(25), @intDBImpliedSequence),	'BLANK')
													+	' to the new Implied Sequence = '
													+	COALESCE(CONVERT(VARCHAR(25), @op_intImpliedSequence),	'BLANK')
													+	' is greater than the allowed limit. Record Count = ' 
													+	COALESCE(CONVERT(VARCHAR(25), @intImpSeqCount),	'BLANK')
					---------------------------------------------------------------------------------------------------
					--	Raise Error
					---------------------------------------------------------------------------------------------------
					RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
				END
			END TRY
			BEGIN CATCH
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
			--	Prepare the varibles which are goint to be use in the loop
			-----------------------------------------------------------------------------------------------------------
			SELECT	@i	= 1
			--=========================================================================================================
			--	LOOP through the Implied sequence
			--	This loop is necessary because the GE Procedure moves the record 1 row up or down depending on the trans num
			--	and just 1 row for every call, so if we need to move a record 4 places up or down we have to call GE
			--	procedure 4 times
			--=========================================================================================================
			WHILE @i < @intImpSeqCount
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Check @p_bitWriteDirect to see if the user want to write directly on the DB
				-------------------------------------------------------------------------------------------------------
				IF @p_bitWriteDirect = 0
				BEGIN
					---------------------------------------------------------------------------------------------------
					--	Return Production Plan Result Set
					---------------------------------------------------------------------------------------------------
					 SELECT	[RSTId]				= 15						,
							[PreDB]				= 1							,	--	NOT POST DB
							[TransType]			= @p_intTransType			,	--	@TransType int
							[TransNum]			= @intTransNum				,	--	@TransNum int
							[PathId]			= @p_intPathId				,	--	@PathId int 
							[PPId]				= @op_intPPId				,	--	@PPId int OUTPUT		
							[CommentId]			= @p_intCommentId			,	--	@CommentId int
							[ProdId]			= @p_intProdId				,	--	@ProdId int
							[ImpliedSequence]	= @op_intImpliedSequence	,	--	@ImpliedSequence int OUTPUT
							[PPStatusId]		= @p_intPPStatusId			,	--	@PPStatusId int
							[PPTypeId]			= @p_intPPTypeId			,	--	@PPTypeId int
							[SourcePPId]		= @p_intSourcePPId			,	--	@SourcePPId int
							[UserId]			= @p_intUserId				,	--	@UserId int
							[ParentPPId]		= @p_intParentPPId			,	--	@ParentPPId int
							[ControlType]		= @p_intControlType			,	--	@ControlType tinyint
							[ForecastStartTime]	= @p_dtmForecastStartTime	,	--	@ForecastStartTime datetime
							[ForecastEndTime]	= @p_dtmForecastEndTime		,	--	@ForecastEndTime datetime
							[EntryOn]			= @op_dtmEntryOn			,	--	@EntryOn datetime OUTPUT
							[ForecastQuantity]	= @p_fltForecastQuantity	,	--	@ForecastQuantity float
							[ProductionRate]	= @p_fltProductionRate		,	--	@ProductionRate float 
							[AdjustedQuantity]	= @p_fltAdjustedQuantity	,	--	@AdjustedQuantity float 
							[BlockNumber]		= @p_vchBlockNumber			,	--	@BlockNumber varchar(50)
							[ProcessOrder]		= @p_vchProcessOrder		,	--	@ProcessOrder varchar(50)
							[TransactionTime]	= @dtmTransactionTime		,	--	@TransactionTime datetime
							[Misc]				= NULL						,	--	@Misc1 int
							[Misc]				= NULL						,	--	@Misc2 int
							[Misc]				= NULL						,	--	@Misc3 int
							[Misc]				= NULL						,	--	@Misc4 int
							[BOMFormulationId]	= @p_intBOMFormulationId	,	--	@BOMFormulationId bigint = NULL
							[UserGen1]			= NULL						,
							[UserGen2]			= NULL						,
							[UserGen3]			= NULL						,
							[ExtendedInfo]		= NULL						
				END
				-------------------------------------------------------------------------------------------------------
				--	Otherwise it will excecute the SP directly to affect the DB
				-------------------------------------------------------------------------------------------------------
				ELSE
				BEGIN
					---------------------------------------------------------------------------------------------------
					--	Set Error Section
					---------------------------------------------------------------------------------------------------
					SELECT	@vchErrorSection	= 'GE UpdProdPlan Call Update B'	,
							@vchNestedObject	= 'dbo.spServer_DBMgrUpdProdPlan'
					---------------------------------------------------------------------------------------------------
					--	Start a Try And add a transaction clause
					---------------------------------------------------------------------------------------------------
					BEGIN TRY
						--=================================================================================================
						--	Update a Production Plan record within the database.
						--=================================================================================================
						EXEC @intReturnCode = dbo.spServer_DBMgrUpdProdPlan
							@op_intPPId				OUTPUT	,	--	@PPId int OUTPUT
							@p_intTransType					,	--	@TransType int
							@intTransNum					,	--	@TransNum int
							@p_intPathId					,	--	@PathId int 
							@p_intCommentId					,	--	@CommentId int
							@p_intProdId					,	--	@ProdId int
							@op_intImpliedSequence	OUTPUT	,	--	@ImpliedSequence int OUTPUT
							@p_intPPStatusId				,	--	@PPStatusId int
							@p_intPPTypeId					,	--	@PPTypeId int
							@p_intSourcePPId				,	--	@SourcePPId int
							@p_intUserId					,	--	@UserId int
							@p_intParentPPId				,	--	@ParentPPId int
							@p_intControlType				,	--	@ControlType tinyint
							@p_dtmForecastStartTime			,	--	@ForecastStartTime datetime
							@p_dtmForecastEndTime			,	--	@ForecastEndTime datetime
							@op_dtmEntryOn			OUTPUT	,	--	@EntryOn datetime OUTPUT
							@p_fltForecastQuantity			,	--	@ForecastQuantity float
							@p_fltProductionRate			,	--	@ProductionRate float 
							@p_fltAdjustedQuantity			,	--	@AdjustedQuantity float 
							@p_vchBlockNumber				,	--	@BlockNumber varchar(50)
							@p_vchProcessOrder				,	--	@ProcessOrder varchar(50)
							@dtmTransactionTime				,	--	@TransactionTime datetime
							NULL							,	--	@Misc1 int
							NULL							,	--	@Misc2 int
							NULL							,	--	@Misc3 int
							NULL							,	--	@Misc4 int
							@p_intBOMFormulationId				--	@BOMFormulationId bigint = NULL
						-----------------------------------------------------------------------------------------------
						--	If the SP returns an error, it sets the properly the error message
						-----------------------------------------------------------------------------------------------
						IF	@intReturnCode < 0
						BEGIN
							SELECT	@nvchErrorMessage	= 'The update call to dbo.spServer_DBMgrUpdProdPlan returned an error.'
														+ ' Code = "'
														+ COALESCE(CONVERT(VARCHAR(25), @intReturnCode), 'BLANK')
														+ '".'
							-----------------------------------------------------------------------------------------------
							--	Raise Error
							-----------------------------------------------------------------------------------------------
							RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
						END
					END TRY
					BEGIN CATCH
						--=================================================================================================
						--	Rollback Transaction
						--=================================================================================================
						IF	@@TRANCOUNT	>	0
						BEGIN
							ROLLBACK TRANSACTION
						END
						-----------------------------------------------------------------------------------------------
						--	Set error message
						-----------------------------------------------------------------------------------------------
						SELECT	@nvchErrorMessage	= COALESCE(@nvchErrorMessage, ERROR_MESSAGE())
						-----------------------------------------------------------------------------------------------
						--	Raise Error
						-----------------------------------------------------------------------------------------------
						RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
					END CATCH	
				END
				-------------------------------------------------------------------------------------------------------
				--	Increment the counter
				-------------------------------------------------------------------------------------------------------
				SELECT	@i = @i + 1
			END
		END
		---------------------------------------------------------------------------------------------------------------
		--	d.	COALESCE
		--		Meaning some other value needs to be updated on prod Plan Record
		---------------------------------------------------------------------------------------------------------------
		ELSE
		BEGIN
			-----------------------------------------------------------------------------------------------------------
			--	Check @p_bitWriteDirect to see if the user want to write directly on the DB
			-----------------------------------------------------------------------------------------------------------
			IF @p_bitWriteDirect = 0
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Return Production Plan Result Set
				--	Overwrite the required value for Production Plan record using Coalesce Logic
				-------------------------------------------------------------------------------------------------------
				 SELECT	[RSTId]				= 15						,	
						[PreDB]				= 1							,	--	NOT POST DB
						[TransType]			= @p_intTransType			,	--	@TransType int,
						[TransNum]			= @intConstCoalesceUpdate	,	--	@TransNum int,
						[PathId]			= @p_intPathId				,	--	@PathId int, 
						[PPId]				= @op_intPPId				,	--	@PPId int OUTPUT,		
						[CommentId]			= @p_intCommentId			,	--	@CommentId int,
						[ProdId]			= @p_intProdId				,	--	@ProdId int,
						[ImpliedSequence]	= @op_intImpliedSequence	,	--	@ImpliedSequence int OUTPUT,
						[PPStatusId]		= @p_intPPStatusId			,	--	@PPStatusId int,
						[PPTypeId]			= @p_intPPTypeId			,	--	@PPTypeId int,
						[SourcePPId]		= @p_intSourcePPId			,	--	@SourcePPId int,
						[UserId]			= @p_intUserId				,	--	@UserId int,
						[ParentPPId]		= @p_intParentPPId			,	--	@ParentPPId int,
						[ControlType]		= @p_intControlType			,	--	@ControlType tinyint,
						[ForecastStartTime]	= @p_dtmForecastStartTime	,	--	@ForecastStartTime datetime,
						[ForecastEndTime]	= @p_dtmForecastEndTime		,	--	@ForecastEndTime datetime,
						[EntryOn]			= @op_dtmEntryOn			,	--	@EntryOn datetime OUTPUT,
						[ForecastQuantity]	= @p_fltForecastQuantity	,	--	@ForecastQuantity float,
						[ProductionRate]	= @p_fltProductionRate		,	--	@ProductionRate float, 
						[AdjustedQuantity]	= @p_fltAdjustedQuantity	,	--	@AdjustedQuantity float, 
						[BlockNumber]		= @p_vchBlockNumber			,	--	@BlockNumber varchar(50),
						[ProcessOrder]		= @p_vchProcessOrder		,	--	@ProcessOrder varchar(50),
						[TransactionTime]	= @dtmTransactionTime		,	--	@TransactionTime datetime,
						[Misc]				= NULL						,	--	@Misc1 int,
						[Misc]				= NULL						,	--	@Misc2 int,
						[Misc]				= NULL						,	--	@Misc3 int,
						[Misc]				= NULL						,	--	@Misc4 int,
						[BOMFormulationId]	= @p_intBOMFormulationId	,	--	@BOMFormulationId bigint = NULL
						[UserGen1]			= NULL						,
						[UserGen2]			= NULL						,
						[UserGen3]			= NULL						,
						[ExtendedInfo]		= NULL												
			END
			-----------------------------------------------------------------------------------------------------------
			--	Otherwise it will excecute the SP directly to affect the DB
			-----------------------------------------------------------------------------------------------------------
			ELSE
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Set Error Section
				-------------------------------------------------------------------------------------------------------
				SELECT	@vchErrorSection	= 'GE UpdProdPlan Call Update C'	,
						@vchNestedObject	= 'dbo.spServer_DBMgrUpdProdPlan'
				BEGIN TRY
					--=================================================================================================
					--	Update a new Production Plan record within the database.
					--	TransNum = 00
					--=================================================================================================
					EXEC	@intReturnCode	= dbo.spServer_DBMgrUpdProdPlan
						@op_intPPId				OUTPUT	,	--@PPId int OUTPUT,
						@p_intTransType					,	--@TransType int,
						@intConstCoalesceUpdate			,	--@TransNum int,
						@p_intPathId					,	--@PathId int, 
						@p_intCommentId					,	--@CommentId int,
						@p_intProdId					,	--@ProdId int,
						@op_intImpliedSequence	OUTPUT	,	--@ImpliedSequence int OUTPUT,
						@p_intPPStatusId				,	--@PPStatusId int,
						@p_intPPTypeId					,	--@PPTypeId int,
						@p_intSourcePPId				,	--@SourcePPId int,
						@p_intUserId					,	--@UserId int,
						@p_intParentPPId				,	--@ParentPPId int,
						@p_intControlType				,	--@ControlType tinyint,
						@p_dtmForecastStartTime			,	--@ForecastStartTime datetime,
						@p_dtmForecastEndTime			,	--@ForecastEndTime datetime,
						@op_dtmEntryOn			OUTPUT	,	--@EntryOn datetime OUTPUT,
						@p_fltForecastQuantity			,	--@ForecastQuantity float,
						@p_fltProductionRate			,	--@ProductionRate float, 
						@p_fltAdjustedQuantity			,	--@AdjustedQuantity float, 
						@p_vchBlockNumber				,	--@BlockNumber varchar(50),
						@p_vchProcessOrder				,	--@ProcessOrder varchar(50),
						@dtmTransactionTime				,	--@TransactionTime datetime,
						NULL							,	--@Misc1 int,
						NULL							,	--@Misc2 int,
						NULL							,	--@Misc3 int,
						NULL							,	--@Misc4 int,
						@p_intBOMFormulationId				--@BOMFormulationId bigint = NULL
					---------------------------------------------------------------------------------------------------
					--	If the SP returns an error, it sets the properly the error message
					---------------------------------------------------------------------------------------------------
					IF	@intReturnCode < 0
					BEGIN
						SELECT	@op_vchErrorMessage = 'The update call to dbo.spServer_DBMgrUpdProdPlan returned an error.'
														+ ' Code = ' + COALESCE(CONVERT(VARCHAR(25), @intReturnCode), '')
						-----------------------------------------------------------------------------------------------
						--	Raise Error
						-----------------------------------------------------------------------------------------------
						RAISERROR(@nvchErrorMessage, @intErrorSeverity, @intErrorState)
					END
				END TRY
				BEGIN CATCH
					--=================================================================================================
					--	Rollback Transaction
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
			END
		END
	END
	--=================================================================================================================
	--	At this point we can update the General 1 to 3 or Extended_Info for insert or update transactions
	--=================================================================================================================
	IF		@p_intTransType IN	(1,2)
		AND	@op_intPPId	IS NOT NULL
		AND	(	@p_vchUserGeneral1		IS NOT NULL
			OR	@p_vchUserGeneral2		IS NOT NULL
			OR	@p_vchUserGeneral3		IS NOT NULL
			OR	@p_vchExtendedInfo		IS NOT NULL)
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		--	Set Error Section
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchErrorSection	= 'Production Plan Update B'	,
				@vchNestedObject	= 'dbo.Production_Plan'
		BEGIN TRANSACTION
		BEGIN TRY
			-----------------------------------------------------------------------------------------------------------
			--	Update data that it cant be accessed by the GE Procedure
			-----------------------------------------------------------------------------------------------------------
			UPDATE	dbo.Production_Plan
			SET		User_General_1	= @p_vchUserGeneral1	,
					User_General_2	= @p_vchUserGeneral2	,
					User_General_3	= @p_vchUserGeneral3	,
					Extended_Info	= @p_vchExtendedInfo
			WHERE	PP_Id	= @op_intPPId
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
		---------------------------------------------------------------------------------------------------------------
		--	Commit Transaction
		---------------------------------------------------------------------------------------------------------------
		IF	@@TRANCOUNT	>	0
		BEGIN
			COMMIT TRANSACTION
		END
	END
	--=================================================================================================================
	--	If the transaction type is DELETE
	--=================================================================================================================
	IF		@p_intTransType = 3
	BEGIN
		---------------------------------------------------------------------------------------------------------------
		--	Set Error Section
		---------------------------------------------------------------------------------------------------------------
		SELECT	@vchErrorSection	= 'GE UpdProdPlan Call Delete'		,
				@vchNestedObject	= 'dbo.spServer_DBMgrUpdProdPlan'
		BEGIN TRY
			EXEC	@intReturnCode = dbo.spServer_DBMgrUpdProdPlan
				@op_intPPId				OUTPUT	,	--	@PPId int OUTPUT
				@p_intTransType					,	--	@TransType int
				NULL							,	--	@TransNum int
				@p_intPathId					,	--	@PathId int 
				NULL							,	--	@CommentId int
				NULL							,	--	@ProdId int
				@op_intImpliedSequence	OUTPUT	,	--	@ImpliedSequence int OUTPUT
				NULL							,	--	@PPStatusId int
				NULL							,	--	@PPTypeId int
				NULL							,	--	@SourcePPId int
				@p_intUserId					,	--	@UserId int
				NULL							,	--	@ParentPPId int
				NULL							,	--	@ControlType tinyint
				NULL							,	--	@ForecastStartTime datetime
				NULL							,	--	@ForecastEndTime datetime
				@op_dtmEntryOn			OUTPUT	,	--	@EntryOn datetime OUTPUT
				NULL							,	--	@ForecastQuantity float
				NULL							,	--	@ProductionRate float 
				NULL							,	--	@AdjustedQuantity float 
				NULL							,	--	@BlockNumber varchar(50)
				@p_vchProcessOrder				,	--	@ProcessOrder varchar(50)
				NULL							,	--	@TransactionTime datetime
				NULL							,	--	@Misc1 int
				NULL							,	--	@Misc2 int
				NULL							,	--	@Misc3 int
				NULL							,	--	@Misc4 int
				NULL								--	@BOMFormulationId bigint = NULL
			-----------------------------------------------------------------------------------------------------------
			--	If the SP returns an error, it sets the properly the error message
			-----------------------------------------------------------------------------------------------------------
			IF	@intReturnCode < 0
			BEGIN
				-------------------------------------------------------------------------------------------------------
				--	Return the error message
				-------------------------------------------------------------------------------------------------------
				SELECT	@op_vchErrorMessage = 'The delete call to spServer_DBMgrUpdProdPlan returned an error.'
													+ ' Code = ' + COALESCE(CONVERT(VARCHAR(25), @intReturnCode), 'BLANK')
				-------------------------------------------------------------------------------------------------------
				--	Raise Error
				-------------------------------------------------------------------------------------------------------
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
	-------------------------------------------------------------------------------------------------------------------
	--	Log critcal error message and exit.
	-------------------------------------------------------------------------------------------------------------------
	SELECT
		@intReturnCode		= NULL					,
		@intNestingLevel	= @@NESTLEVEL			,
		@vchObjectName		= OBJECT_NAME(@@ProcId)	,
		@nvchErrorMessage	= ERROR_MESSAGE()		,
		@intErrorSeverity	= ERROR_SEVERITY()		,
		@intErrorState		= ERROR_STATE()
	EXECUTE @intReturnCode	= dbo.spLocal_PG_Cmn_LogErrorMessage
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
