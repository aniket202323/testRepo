
/*===========================================================================================
 Stored Procedure: spLocal_CTS_Override_Location_Status
=============================================================================================
 Author				: Francois Bergeron, Symasol
 Date created			: 2021-11-18
 Version 				: Version 1.0
 SP Type				: Proficy Plant Applications
 Caller				: Called by Web app
 Description			: Force the location status after a system malfunction 
 Editor tab spacing	: 4
================================================================================================*/
 
/* EDIT HISTORY:
 ===========================================================================================
 1.0		2022-05-18		F. Bergeron				Initial Release 
 1.1		2023-02-20		U. Lapierre				Wave 2 - Save all location overrides into local table 
													+ Allow override to dirty with Complete PrO
													+ Allow dirty without PrO
 1.2		2023-03-29		U. Lapierre				Wave 2 - Support maintenance.  Force close maintenance event
 1.3		2023-04-20		U. Lapierre				fix issue to set minor clean item to Dirty
================================================================================================*/

/*			TEST CODE:

	DECLARE 	
	@OutputStatus					INTEGER,
	@OutputMessage					VARCHAR(500)
	EXECUTE spLocal_CTS_Override_Location_Status	10421,
													'Dirty',
													NULL,  /*   'Major'   */
													NULL,
													NULL,  /*   'G47040001-CTS',  */
													383,
													'System down for 3 days',
													@OutputStatus OUTPUT,
													@OutputMessage OUTPUT

SELECT	@OutputStatus OUTPUT,
		@OutputMessage OUTPUT



*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Override_Location_Status]
	@LocationPUId					INTEGER,
	@Status							VARCHAR(25),
	@CleaningType					VARCHAR(25),
	@ProductCode					VARCHAR(50),
	@ProcessOrder					VARCHAR(50),
	@UserId							INTEGER,
	@Comment						VARCHAR(500),
	@OutputStatus					INTEGER OUTPUT,
	@OutputMessage					VARCHAR(500) OUTPUT


AS
BEGIN

	SET NOCOUNT ON;

	-----------------------------------------------------------------------------------------------------------------------
	-- DECLARE VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@LocationSerial					VARCHAR(25),
	@tfIdLocationSerial				INTEGER,
	@TableIdProdUnit				INTEGER,
	@ReturnValue					INTEGER,
	@Machine						VARCHAR(50),
	@GenericComment					VARCHAR(250),
	@CommentUserId					INTEGER,
	@LocationCleaningTypeVarId		INTEGER,
	@ProductionPlanTransactionTime	DATETIME,
	@ProductionPlanStartsST			DATETIME,
	@ProductionPlanStartsET			DATETIME,
	@CleaningST						DATETIME,
	@CleaningET						DATETIME,
	@DebugFlag						INTEGER,
	@SPName							VARCHAR(250),

	--UDE
	@UpdateType						INTEGER,
	@EST_Cleaning					INTEGER,
	@UDEStartTime					DATETIME,
	@UDEEndTime						DATETIME,
	@UDEUserId						INTEGER,
	@Type							VARCHAR(25),
	@TestId							BIGINT,
	@UDEDESC						VARCHAR(255),
	@UDEID							INTEGER,
	@CommentId						INTEGER,
	@UDEStatusId					INTEGER,
	@LastStatusId					INTEGER,
	@SignatureId					INTEGER,
	@now							DATETIME,
	@StarterId						INTEGER,
	@UDEUpdateType					INTEGER,
	@CommentId2						INTEGER,
	@RoleId							INTEGER,
	@OutputStatusTemp				INTEGER ,
	@OutputMessageTemp				VARCHAR(500) 
	/*  PROCESS ORDER  */
	DECLARE 
	@UpdatePPId						INTEGER,
	@UpdatePPSTatusId				INTEGER,
	@ActivePPId						INTEGER,
	@PPId							INTEGER,
	@PPTransType					INTEGER,
	@PPTransNum						INTEGER,
	@PathId							INTEGER, 
	@PPCommentId					INTEGER,
	@PPProdId						INTEGER,
	@PPImpliedSequence				INTEGER,
	@ActivePPStatusId				INTEGER,
	@PPStatusId						INTEGER,
	@CompletePPStatusId				INTEGER,
	@PendingPPStatusId				INTEGER,
	@PPTypeId						INTEGER,
	@PPSourcePPId					INTEGER,
	@PPUserId						INTEGER,
	@PPParentPPId					INTEGER,
	@PPControlType					TINYINT,
	@PPForecastStartTime			DATETIME,
	@PPForecastEndTime				DATETIME,
	@PPEntryOn						DATETIME,
	@PPForecastQuantity				FLOAT,
	@PPProductionRate				FLOAT, 
	@PPAdjustedQuantity				FLOAT, 
	@PPBlockNumber					NVARCHAR(50),
	@PPProcessOrder					NVARCHAR(50),
	@PPTransactionTime				DATETIME,
	@PPMisc1						INTEGER,
	@PPMisc2						INTEGER,
	@PPMisc3						INTEGER,
	@PPMisc4						INTEGER,
	@PPBOMFormulationId				BIGINT,
	@PPUserGeneral1 				NVARCHAR(255),
	@PPUserGeneral2 				NVARCHAR(255),
	@PPUserGeneral3 				NVARCHAR(255),
	@PPExtendedInfo  				VARCHAR(255),
	@PathCode						varchar(50),
	@ppsStartTime					datetime,
	@ppsEndTime						datetime,
	@PPSTARTId						int

	/* V1.1 variable to store value to be written in override table*/
	DECLARE	
	@ovLocationId						int,
	@ovOrigin_Status					int,
	@ovOrigin_CleanType					varchar(50),
	@ovOrigin_PPID						int,
	@ovOrigin_ProdId					int,
	@ovNew_Status						int,
	@ovNew_CleanType					varchar(50),
	@ovNew_PPID							int,
	@ovNew_Prodid						int,
	@ovUserId							int,
	@ovTimestamp						datetime,
	@OvCommentId						int,
	@ovOrigin_Status_Desc				varchar(50),
	@ovOrigin_ClStatus_Desc				varchar(50),
	@ovOrigin_ProdCode					varchar(50)


	/*=======================================================
	 Generic
	=======================================================*/
	SET @SPName =		'spLocal_CTS_Override_Location_Status'
	SET @DebugFlag =	(SELECT CONVERT(INT,sp.value) 
						FROM	dbo.site_parameters sp WITH(NOLOCK)
								JOIN dbo.parameters p WITH(NOLOCK)		
									ON sp.parm_Id = p.parm_id
						WHERE	p.parm_Name = 'PG_CTS_StoredProcedure_Log_Level')
	IF @DebugFlag IS NULL
		SET @DebugFlag = 0

	/*=======================================================
	 SP BODY
	=======================================================*/	
	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				1,
				'SP Started:'  + 
				' LocationPUId: ' + CONVERT(varchar(30), COALESCE(@LocationPUId, 0)) + 
				' Status: ' + CONVERT(varchar(30), COALESCE(@Status, '-')) + 
				' Process Order: ' + COALESCE(@ProcessOrder,'') + 
				' @ProductCode: ' + COALESCE(@ProductCode, '') + 
				' User Id: ' + CONVERT(varchar(30),COALESCE(@UserId,0)),
				@LocationPUId	)
	END


	/*=======================================================
	 COLLECT INFORMATION
	=======================================================*/


	/* V1.1 Get new values*/
	SET @ovLocationId		=  @LocationPUId
	SET @ovNew_Status		= (SELECT ProdStatus_Id FROM dbo.production_Status	WITH(NOLOCK) WHERE prodStatus_Desc = @Status)
	SET @ovNew_CleanType	= @CleaningType
	SET @ovNew_PPID			= (SELECT pp_id			FROM dbo.production_Plan	WITH(NOLOCK) WHERE process_order = @ProcessOrder)
	SET @OvUserId			= @UserId
	SET @ovTimestamp		= (SELECT GETDATE()	)

	IF @ovNew_PPID IS NOT NULL
	BEGIN
		SET @ovNew_Prodid = (SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @ovNew_PPID)
	END


	/*=======================================================
	GET EVENT_SUBTYPE
	=======================================================*/
	SET @EST_Cleaning = (SELECT event_subtype_id
						FROM dbo.event_subtypes WITH(NOLOCK) 
						WHERE event_subtype_desc = 'CTS location cleaning')

	/*Get Machine for e-signature*/
	SET @Machine = (SELECT sp.value
					FROM dbo.site_parameters sp		WITH(NOLOCK)
					JOIN dbo.parameters p			WITH(NOLOCK)	ON sp.parm_id = p.parm_id
					WHERE p.Parm_Name  ='SiteName')

	SET @TableIdProdUnit =		(SELECT tableId 
								FROM	dbo.Tables WITH(NOLOCK) 
								WHERE	TableName = 'Prod_Units'	
								)
	SET @tfIdLocationSerial =	(SELECT table_field_id 
								FROM	dbo.Table_Fields WITH(NOLOCK) 
								WHERE	TableId = @TableIdProdUnit 
										AND Table_Field_Desc = 'CTS Location serial number'
								)


	SET @ActivePPStatusId =		(
								SELECT	PP_Status_Id 
								FROM	dbo.Production_Plan_Statuses WITH(NOLOCK)
								WHERE	PP_Status_Desc = 'Active'
								)

	SET @CompletePPStatusId =			(
								SELECT	PP_Status_Id 
								FROM	dbo.Production_Plan_Statuses WITH(NOLOCK)
								WHERE	PP_Status_Desc = 'Complete'
								)
	SET @PendingPPStatusId =			(
								SELECT	PP_Status_Id 
								FROM	dbo.Production_Plan_Statuses WITH(NOLOCK)
								WHERE	PP_Status_Desc = 'Pending'
								)

	SET @GenericComment =	'Location status override' 
	

	SET @comment =	@GenericComment 
					+ CHAR(13) 
					+ 'For location -----------------'
					+ (SELECT Pu_Desc FROM dbo.prod_units_base WITH(NOLOCK) WHERE pu_id = @locationPUId)
					+ CHAR(13) 
					+  'Performed by ----------------'
					+ (SELECT username FROM dbo.users_base WITH(NOLOCK) WHERE user_id = @UserId)
					+ CHAR(13) 
					+ 'Reason -----------------------'
					+ CHAR(13)
					+ @comment
	SET @LocationCleaningTypeVarId = (SELECT var_id FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @locationPUId AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Type')



	/* GET CLEANING */
	DECLARE @Location_cleaning TABLE(
		Status						VARCHAR(25),
		type						VARCHAR(25),
		Start_time					DATETIME,
		End_time					DATETIME,
		Start_User_Id				INTEGER,
		Start_Username				VARCHAR(100),
		Start_User_AD				VARCHAR(100),
		Completion_ES_User_Id		INTEGER,
		Completion_ES_Username		VARCHAR(100),
		Completion_ES_User_AD		VARCHAR(100),
		Approver_ES_User_Id			INTEGER,
		Approver_ES_Username		VARCHAR(100),
		Approver_ES_User_AD			VARCHAR(100),
		UDE_Id						INTEGER,
		Err_Warn					VARCHAR(500)
	)
	INSERT INTO @Location_cleaning (
				Status,
				type,
				Start_time,
				End_time,
				Start_User_Id,
				Start_Username,
				Start_User_AD,
				Completion_ES_User_Id,
				Completion_ES_Username,
				Completion_ES_User_AD,
				Approver_ES_User_Id,
				Approver_ES_Username,
				Approver_ES_User_AD,
				UDE_Id,
				Err_Warn)
	SELECT 		Status,
				type,
				Start_time,
				End_time,
				Start_User_Id,
				Start_Username,
				Start_User_AD,
				Completion_ES_User_Id,
				Completion_ES_Username,
				Completion_ES_User_AD,
				Approver_ES_User_Id,
				Approver_ES_Username,
				Approver_ES_User_AD,
				UDE_Id,
				Err_Warn 
	FROM		dbo.fnLocal_CTS_Location_Cleanings(@LocationPUId, NULL, GETDATE())


	/* GET PROCESS ORDER */
	DECLARE @location_process_order TABLE 
		(
		Product_Id						INTEGER,
		Product_code					VARCHAR(50),
		Product_Desc					VARCHAR(50),
		Process_order_Id				INTEGER,
		Process_order_desc				VARCHAR(50),
		Process_order_status_id			VARCHAR(50),
		Process_order_status_desc		VARCHAR(50),
		Planned_Start_time				DATETIME,
		Planned_End_time				DATETIME,
		Actual_Start_time				DATETIME,
		Actual_End_time					DATETIME,
		Location_id						INTEGER,
		Location_desc					VARCHAR(50),
		AllowToSelectInCurrentLocation	BIT
	)
	INSERT INTO	@location_process_order(
				Product_Id,
				Product_code,
				Product_desc,
				Process_order_Id,
				Process_order_desc,
				Process_order_status_id,
				Process_order_status_desc,
				Planned_Start_time,
				Planned_End_time,
				Actual_Start_time,
				Actual_End_time,
				Location_id,
				Location_desc)
	SELECT		Product_Id,
				Product_code,
				Product_desc,
				Process_order_Id,
				Process_order_desc,
				Process_order_status_id,
				Process_order_status_desc,
				Planned_Start_time,
				Planned_End_time,
				Actual_Start_time,
				Actual_End_time,
				Location_id,
				Location_desc 
	FROM		dbo.fnLocal_CTS_Get_Process_Orders_by_criteria(CAST(@LocationPUId AS VARCHAR(50)),NULL,NULL, NULL, NULL, NULL,NULL, 0)


	/* V1.1 Get initial info*/

	SELECT	@ovOrigin_Status_Desc = Location_status,
			@ovOrigin_ClStatus_Desc = Cleaning_Status,
			@ovOrigin_CleanType  = Cleaning_type
	FROM fnLocal_CTS_Location_Status(@LocationPUId,NULL)

	SET @ovOrigin_Status = (SELECT ProdStatus_Id	FROM production_status		WITH(NOLOCK) WHERE prodStatus_Desc = @ovOrigin_Status_Desc)

	/*Get serial*/
	SET @LocationSerial = (SELECT value FROM dbo.table_fields_values WITH(NOLOCK) WHERE table_field_id = @tfIdLocationSerial AND keyid = @ovLocationId)

	SELECT 	@ovOrigin_PPID		= Active_or_inprep_process_order_id 
	FROM fnLocal_CTS_Get_Locations_by_criteria (@LocationSerial,NULL, NULL, NULL, NULL, NULL)

	IF @ovOrigin_PPID IS NOT NULL
	BEGIN
		SET @ovOrigin_ProdId = (SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @ovOrigin_PPID)
	END

	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				50,
				' LocationSerial: ' + COALESCE(@LocationSerial, '0') + 
				' Origin_PPID: ' + CONVERT(varchar(30), COALESCE(@ovOrigin_PPID, 0)) + 
				' Origin_ProdId: ' + CONVERT(varchar(30),COALESCE(@ovOrigin_ProdId,0)),
				@LocationPUId	)
	END



	/* end of V1.1 */
	SET @RoleId = (SELECT user_id FROM dbo.users_base WITH(NOLOCK) WHERE is_role = 1 AND username = 'Super User')



	/* GET PATH_ID OF LOCATION */
	SET @pathId = (SELECT path_id FROM dbo.prdexec_path_Units WHERE pu_id = @locationPUId)
	SET @Now = GETDATE()


	
	/* ================================================================
	 CASE 1
	 @STATUS = In use
	 IF @processorder is complete do nothing
	 IF @processorder is active do nothing
	==================================================================*/
	IF @Status  = 'In use' AND @ProcessOrder IS NOT NULL
	BEGIN

		/* GET THE PROCESS ORDER CORRESPONDING TO @ProcessOrder AT THE LOCATION */
		SELECT @UpdatePPId =	(SELECT	PP_Id 
								FROM	dbo.production_plan PP WITH(NOLOCK)
								JOIN	dbo.PrdExec_Path_Units PPU
											ON PPU.Path_Id = PP.path_id
								WHERE	PPU.PU_Id = @LocationPUId
										AND	PP.process_order = @ProcessOrder
								)
		/* IF NOT IN PP-- ORDER DOWNLOAD FAILED -- DO NOT ACT */
		IF @UpdatePPId IS NULL 
		BEGIN
			SET @OutputMessage = 'Update refused - process order does not exist in CTS'
			SET @OutputStatus = 0
			RETURN
		END

		/*=================================================================	
		ACTIONS 1.a Reject any open cleaning.  Any open cleaning on location is rejected
		==================================================================*/
		IF (SELECT Status FROM @Location_cleaning) NOT IN ('CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
		BEGIN
			/* COLLECT UDE INFO	*/
			SELECT	@UDEDESC = UDE_Desc,
					@UDEId	= UDE_Id,
					@UserId = @UserId,
					@UDEStartTime = Start_time,
					@UDEEndTime = End_time,	
					@UDEUpdateType = 2,
					@CommentId = comment_id,	
					@SignatureId = @SignatureId,
					@UDEStatusId = @UDEStatusId
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Location_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	
			/*	E-SIGNATURE IS MANDATORY WHEN OVERRIDING LOCATION STATUS	*/
			IF @SignatureId IS NULL /* IF CLEANING UDE EXISTS AND SIGNATURE IS NOT PRESENT (CLEANING IS STARTED) - CREATE A SIGNATURE - THE ORDER WILL BE CANCELLED */
			BEGIN

			/* CREATE/UPDATE SIGNATURE 
				Create signature Id	*/

				EXEC  [dbo].[spSDK_AU_ESignature]
							null, 
							@SignatureId OUTPUT, 
							null, 
							null, 
							null, 
							@UserId, 
							@Machine, 
							null, 
							null, 
							null, 
							null, 
							null, 
							null, 
							NULL, 
							NULL, 
							null, 
							null, 
							@Now

			END



			SET @CommentUserId = @UserId
			/* ADD COMMENT TO EXISTING COMMENT */
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			/* UPDATE EXISTING UDE - CLOSE IT  */
			EXEC [dbo].[spServer_DBMgrUpdUserEvent]
			0,						/*Transnum	*/
			'CTS location cleaning',/* Event sub type desc */
			NULL,					/*Action comment Id*/
			NULL,					/*Action 4*/
			NULL, 					/*Action 3*/
			NULL,					/*Action 2*/
			NULL, 					/*Action 1*/
			NULL,					/*Cause comment Id*/
			NULL,					/*Cause 4*/
			NULL, 					/*Cause 3*/
			NULL,					/*Cause 2*/
			NULL, 					/*Cause 1*/
			NULL,					/*Ack by*/
			0,						/*Acked*/
			0,						/*Duration*/
			@EST_Cleaning,			/*event_subTypeId*/
			@LocationPUId,			/*pu_id*/
			@UDEDESC,				/*UDE desc*/
			@UDEId,					/*UDE_ID*/
			@UserId,				/*User_Id*/
			NULL,					/*Acked On*/
			@UDEStartTime,			/*@UDE Starttime,*/ 
			@UDEEndTime,			/*@UDE endtime,  KEEP THE SAME*/
			NULL,					/*Research CommentId*/
			NULL,					/*Research Status id*/
			NULL,					/*Research User id*/
			NULL,					/*Research Open Date*/
			NULL,					/*Research Close date*/
			@UDEUpdateType,			/*Transaction type*/
			@CommentId2,			/*Comment Id*/
			NULL,					/*reason tree*/
			@SignatureId,			/*signature Id*/
			NULL,					/*eventId*/
			NULL,					/*parent ude id*/
			@UDEStatusId,			/*event status*/
			1,						/*Testing status*/
			NULL,					/*conformance*/
			NULL,					/*test percent complete*/
			0	

		END 
		
		/*=================================================================	
		ACTIONS  1.b Reject any open Maintenance	
		==================================================================*/	
		IF (SELECT maintenance_status FROM fnLocal_CTS_Location_Status(@LocationPUId,NULL)) = 'CST_Maintenance_Started'
		BEGIN
			/* udeid of the maintenance event */
			SET @UDEId = (	SELECT TOP 1 ude_id 
							FROM dbo.user_defined_events ude	WITH(NOLOCK)
							JOIN dbo.event_subtypes es			WITH(NOLOCK) ON ude.event_subtype_id = es.event_subtype_id
																				AND es.event_subtype_desc = 'CST Maintenance'
							WHERE pu_id = @LocationPUId
							ORDER BY ude.ude_id DESC	)

			IF @UDEId IS NOT NULL
			BEGIN
				EXEC [dbo].[spLocal_CST_CreateUpdate_Location_Maintenance] 
				@LocationPUId,
				@UDEId,
				@UserId,
				@RoleId,
				'Override',
				@OutPutStatusTemp						 OUTPUT,
				@OutPutMessageTemp						 OUTPUT
			END

		END


		SET @ActivePPId =	
		(SELECT	TOP 1	PP.PP_Id 
		FROM	dbo.production_plan PP WITH(NOLOCK)
		JOIN	dbo.PrdExec_Path_Units PPU
					ON PPU.Path_id = PP.Path_id
		WHERE	PPU.PU_Id = @LocationPUId
				AND PP.PP_status_id = @ActivePPStatusId		)

		

		/*=================================================================
		 SELECTED PP IS ACTIVE
		==================================================================*/
		IF(SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID) IN (@ActivePPStatusId)
		BEGIN
			SELECT	@OutputStatus = 1
			SELECT	@OutputMessage = 'Process order is already active at location'

			GOTO OverrideLog
			RETURN 
		END

		/*=================================================================
		 SELECTED PP IS PENDING
		==================================================================*/
		IF (SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID) IN (@PendingPPStatusId)
		BEGIN
			SET @ProductionPlanTransactionTime = (SELECT DATEADD(second, 1, @now))

			IF @ActivePPId IS NOT NULL
			BEGIN

				/* COMPLETE ORDER @ActivePPId */
				SET @ProductionPlanTransactionTime = (SELECT DATEADD(second, 1, Start_time) FROM dbo.production_plan_starts WITH(NOLOCK) WHERE PP_id = @ActivePPId)
				SELECT 	@PPId							= PP_ID,
						@PPTransType					= 2,
						@PPTransNum						= 97,
						@PathId							= Path_id, 
						@PPCommentId					= comment_id,
						@PPProdId						= Prod_id,
						@PPImpliedSequence				= Implied_Sequence,
						@PPStatusId						= @CompletePPStatusId,
						@PPTypeId						= PP_Type_Id,
						@PPSourcePPId					= Source_PP_ID,
						@PPUserId						= @userId,
						@PPParentPPId					= Parent_PP_ID,
						@PPControlType					= control_type,
						@PPForecastStartTime			= forecast_Start_date,
						@PPForecastEndTime				= forecast_End_date,
						@PPEntryOn						= NULL,
						@PPForecastQuantity				= Forecast_quantity,
						@PPProductionRate				= Production_rate, 
						@PPAdjustedQuantity				= Adjusted_quantity, 
						@PPBlockNumber					= Block_number,
						@PPProcessOrder					= Process_order,
						@PPTransactionTime				= @ProductionPlanTransactionTime, 
						@PPMisc1						= NULL,
						@PPMisc2						= NULL,
						@PPMisc3						= NULL,
						@PPMisc4						= NULL,
						@PPBOMFormulationId				= BOM_Formulation_id,
						@PPUserGeneral1					= User_general_1,
						@PPUserGeneral2					= User_general_2,
						@PPUserGeneral3					= User_general_3,
						@PPExtendedInfo					= Extended_info				
				FROM	dbo.production_plan WITH(NOLOCK) 
				WHERE	PP_ID = @ActivePPId

				IF @Comment IS NOt NULL
				BEGIN
					SET @CommentUserId = @userId
					EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
				END

				EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
						@PPId  ,
						@PPTransType,
						@PPTransNum,
						@Pathid,
						@CommentId2,
						@PPProdId,
						@PPImpliedSequence ,
						@PPStatusId ,
						@PPTypeId ,
						@PPSourcePPId ,
						@PPUserId ,
						@PPParentPPId ,
						@PPControlType ,
						@PPForecastStartTime ,
						@PPForecastEndTime ,
						@PPEntryOn  OUTPUT,
						@PPForecastQuantity ,
						@PPProductionRate ,
						@PPAdjustedQuantity ,
						@PPBlockNumber ,
						@PPProcessOrder ,
						@PPTransactionTime ,
						@PPMisc1 ,
						@PPMisc2 ,
						@PPMisc3 ,
						@PPMisc4 ,
						@PPBOMFormulationId ,
						@PPUserGeneral1 ,
						@PPUserGeneral2 ,
						@PPUserGeneral3 ,
						@PPExtendedInfo-- ,
						--0
				END
				IF @UpdatePPID IS NOT NULL
				BEGIN
					SET @ProductionPlanTransactionTime = Dateadd(Second, 1,@ProductionPlanTransactionTime)
					/* ACTIVATE ORDER @UpdatePPID */
					SELECT 	@PPId							= PP_ID,
							@PPTransType					= 2,
							@PPTransNum						= 97,
							@PathId							= Path_id, 
							@PPCommentId					= comment_id,
							@PPProdId						= Prod_id,
							@PPImpliedSequence				= Implied_Sequence,
							@PPStatusId						= @ActivePPStatusId,
							@PPTypeId						= PP_Type_Id,
							@PPSourcePPId					= Source_PP_ID,
							@PPUserId						= @userId,
							@PPParentPPId					= Parent_PP_ID,
							@PPControlType					= control_type,
							@PPForecastStartTime			= forecast_Start_date,
							@PPForecastEndTime				= forecast_End_date,
							@PPEntryOn						= NULL,
							@PPForecastQuantity				= Forecast_quantity,
							@PPProductionRate				= Production_rate, 
							@PPAdjustedQuantity				= Adjusted_quantity, 
							@PPBlockNumber					= Block_number,
							@PPProcessOrder					= Process_order,
							@PPTransactionTime				= @ProductionPlanTransactionTime, 
							@PPMisc1						= NULL,
							@PPMisc2						= NULL,
							@PPMisc3						= NULL,
							@PPMisc4						= NULL,
							@PPBOMFormulationId				= BOM_Formulation_id,
							@PPUserGeneral1					= User_general_1,
							@PPUserGeneral2					= User_general_2,
							@PPUserGeneral3					= User_general_3,
							@PPExtendedInfo					= Extended_info				
					FROM	dbo.production_plan WITH(NOLOCK) 
					WHERE	PP_ID = @UpdatePPID

					IF @Comment IS NOt NULL
					BEGIN
						SET @CommentUserId = @UserId
						EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
					END

					EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
							@PPId  ,
							@PPTransType,
							@PPTransNum,
							@Pathid,
							@CommentId2,
							@PPProdId,
							@PPImpliedSequence ,
							@PPStatusId ,
							@PPTypeId ,
							@PPSourcePPId ,
							@PPUserId ,
							@PPParentPPId ,
							@PPControlType ,
							@PPForecastStartTime ,
							@PPForecastEndTime ,
							@PPEntryOn  OUTPUT,
							@PPForecastQuantity ,
							@PPProductionRate ,
							@PPAdjustedQuantity ,
							@PPBlockNumber ,
							@PPProcessOrder ,
							@PPTransactionTime ,
							@PPMisc1 ,
							@PPMisc2 ,
							@PPMisc3 ,
							@PPMisc4 ,
							@PPBOMFormulationId ,
							@PPUserGeneral1 ,
							@PPUserGeneral2 ,
							@PPUserGeneral3 ,
							@PPExtendedInfo-- ,
							--0
				
				SELECT	@OutputStatus = 1
				SELECT	@OutputMessage = 'Location overriden to In use'
				GOTO OverrideLog
				RETURN
			END
		END

			SELECT	@OutputStatus = 0
			SELECT	@OutputMessage = 'Location overriden to In use failed'

			RETURN


	END


		/*=================================================================	
		CASE 2
		@STATUS = Clean And @Type = Minor	
		==================================================================*/
	IF @Status  = 'Clean' AND @CleaningType = 'Minor' AND @ProcessOrder IS NOT NULL
	BEGIN

		/* GET THE PROCESS ORDER CORRESPONDING TO @ProcessOrder AT THE LOCATION */
		SELECT @UpdatePPId =	(SELECT	PP_Id 
								FROM	dbo.production_plan PP WITH(NOLOCK)
								JOIN	dbo.PrdExec_Path_Units PPU
											ON PPU.Path_Id = PP.path_id
								WHERE	PPU.PU_Id = @LocationPUId
										AND	PP.process_order = @ProcessOrder
								)


		/* IF NOT IN PP-- ORDER DOWNLOAD FAILED -- DO NOT ACT	*/
		IF @UpdatePPId IS NULL 
		BEGIN
			SET @OutputMessage = 'Update refused - Last process order does not exist in CTS'
			SET @OutputStatus = 0
			RETURN
		END

		/*=================================================================	
		ACTIONS 1.a Reject any open cleaning.  Any open cleaning on location is rejected	
		==================================================================*/

		IF (SELECT Status FROM @Location_cleaning) NOT IN ('CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
		BEGIN

			/* COLLECT UDE INFO  */
			SELECT	@UDEDESC = UDE_Desc,
					@UDEId	= UDE_Id,
					@UserId = @UserId,
					@UDEStartTime = Start_time,
					@UDEEndTime = End_time,	
					@UDEUpdateType = 2,
					@CommentId = comment_id,	
					@SignatureId = @SignatureId,
					@UDEStatusId = @UDEStatusId
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Location_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	
			/*E-SIGNATURE IS MANDATORY WHEN OVERRIDING LOCATION STATUS*/
			IF @SignatureId IS NULL /* IF CLEANING UDE EXISTS AND SIGNATURE IS NOT PRESENT (CLEANING IS STARTED) - CREATE A SIGNATURE - THE ORDER WILL BE CANCELLED */
			BEGIN

			/*	CREATE/UPDATE SIGNATURE 
				Create signature Id			*/

				EXEC  [dbo].[spSDK_AU_ESignature]
							null, 
							@SignatureId OUTPUT, 
							null, 
							null, 
							null, 
							@UserId, 
							@Machine, 
							null, 
							null, 
							null, 
							null, 
							null, 
							null, 
							NULL, 
							NULL, 
							null, 
							null, 
							@Now
			END



			SET @CommentUserId = @UserId
			/* ADD COMMENT TO EXISTING COMMENT */
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			/* UPDATE EXISTING UDE - CLOSE IT */
			EXEC [dbo].[spServer_DBMgrUpdUserEvent]
			0,						--Transnum
			'CTS location cleaning',-- Event sub type desc 
			NULL,					--Action comment Id
			NULL,					--Action 4
			NULL, 					--Action 3
			NULL,					--Action 2
			NULL, 					--Action 1
			NULL,					--Cause comment Id
			NULL,					--Cause 4
			NULL, 					--Cause 3
			NULL,					--Cause 2
			NULL, 					--Cause 1
			NULL,					--Ack by
			0,						--Acked
			0,						--Duration
			@EST_Cleaning,			--event_subTypeId
			@LocationPUId,			--pu_id
			@UDEDESC,				--UDE desc
			@UDEId,					--UDE_ID
			@UserId,				--User_Id
			NULL,					--Acked On
			@UDEStartTime,			--@UDE Starttime, 
			@UDEEndTime,			--@UDE endtime, -- KEEP THE SAME
			NULL,					--Research CommentId
			NULL,					--Research Status id
			NULL,					--Research User id
			NULL,					--Research Open Date
			NULL,					--Research Close date
			@UDEUpdateType,			--Transaction type
			@CommentId2,			--Comment Id
			NULL,					--reason tree
			@SignatureId,			--signature Id
			NULL,					--eventId
			NULL,					--parent ude id
			@UDEStatusId,			--event status
			1,						--Testing status
			NULL,					--conformance
			NULL,					--test percent complete
			0	

		END 
		
		/*=================================================================	
		ACTIONS  1.b Reject any open Maintenance	
		==================================================================*/	
		IF (SELECT maintenance_status FROM fnLocal_CTS_Location_Status(@LocationPUId,NULL)) = 'CST_Maintenance_Started'
		BEGIN
			/* udeid of the maintenance event */
			SET @UDEId = (	SELECT TOP 1 ude_id 
							FROM dbo.user_defined_events ude	WITH(NOLOCK)
							JOIN dbo.event_subtypes es			WITH(NOLOCK) ON ude.event_subtype_id = es.event_subtype_id
																				AND es.event_subtype_desc = 'CST Maintenance'
							WHERE pu_id = @LocationPUId
							ORDER BY ude.ude_id DESC	)

			IF @UDEId IS NOT NULL
			BEGIN
				EXEC [dbo].[spLocal_CST_CreateUpdate_Location_Maintenance] 
				@LocationPUId,
				@UDEId,
				@UserId,
				@RoleId,
				'Override',
				@OutPutStatusTemp						 OUTPUT,
				@OutPutMessageTemp						 OUTPUT
			END

		END

		SET @ActivePPId =	
		(SELECT	TOP 1	PP.PP_Id 
		FROM	dbo.production_plan PP WITH(NOLOCK)
		JOIN	dbo.PrdExec_Path_Units PPU
					ON PPU.Path_id = PP.Path_id
		WHERE	PPU.PU_Id = @LocationPUId
				AND PP.PP_status_id = @ActivePPStatusId
		)

		/*=================================================================	
		SELECTED PP IS ACTIVE	
		==================================================================*/
		IF(SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID) IN (@ActivePPStatusId)
		BEGIN
		
			SET @ProductionPlanTransactionTime = @Now
			/*COMPLETE ORDER*/
			SELECT 	@PPId							= PP_ID,
					@PPTransType					= 2,
					@PPTransNum						= 97,
					@PathId							= Path_id, 
					@PPCommentId					= comment_id,
					@PPProdId						= Prod_id,
					@PPImpliedSequence				= Implied_Sequence,
					@PPStatusId						= @CompletePPStatusId,
					@PPTypeId						= PP_Type_Id,
					@PPSourcePPId					= Source_PP_ID,
					@PPUserId						= @userId,
					@PPParentPPId					= Parent_PP_ID,
					@PPControlType					= control_type,
					@PPForecastStartTime			= forecast_Start_date,
					@PPForecastEndTime				= forecast_End_date,
					@PPEntryOn						= NULL,
					@PPForecastQuantity				= Forecast_quantity,
					@PPProductionRate				= Production_rate, 
					@PPAdjustedQuantity				= Adjusted_quantity, 
					@PPBlockNumber					= Block_number,
					@PPProcessOrder					= Process_order,
					@PPTransactionTime				= @ProductionPlanTransactionTime, 
					@PPMisc1						= NULL,
					@PPMisc2						= NULL,
					@PPMisc3						= NULL,
					@PPMisc4						= NULL,
					@PPBOMFormulationId				= BOM_Formulation_id,
					@PPUserGeneral1					= User_general_1,
					@PPUserGeneral2					= User_general_2,
					@PPUserGeneral3					= User_general_3,
					@PPExtendedInfo					= Extended_info				
			FROM	dbo.production_plan WITH(NOLOCK) 
			WHERE	PP_ID = @UpdatePPID

			IF @Comment IS NOt NULL
			BEGIN
				SET @CommentUserId = @UserId
				EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@PPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo-- ,
					--0

		END

		ELSE IF (SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID) IN (@PendingPPStatusId)
		BEGIN
			/*COMPLETE ORDER @ActivePPId */
			SET @ProductionPlanTransactionTime = (SELECT DATEADD(second, 1, Start_time) FROM dbo.production_plan_starts WITH(NOLOCK) WHERE PP_id = @ActivePPId)
			SELECT 	@PPId							= PP_ID,
					@PPTransType					= 2,
					@PPTransNum						= 97,
					@PathId							= Path_id, 
					@PPCommentId					= comment_id,
					@PPProdId						= Prod_id,
					@PPImpliedSequence				= Implied_Sequence,
					@PPStatusId						= @CompletePPStatusId,
					@PPTypeId						= PP_Type_Id,
					@PPSourcePPId					= Source_PP_ID,
					@PPUserId						= @userId,
					@PPParentPPId					= Parent_PP_ID,
					@PPControlType					= control_type,
					@PPForecastStartTime			= forecast_Start_date,
					@PPForecastEndTime				= forecast_End_date,
					@PPEntryOn						= NULL,
					@PPForecastQuantity				= Forecast_quantity,
					@PPProductionRate				= Production_rate, 
					@PPAdjustedQuantity				= Adjusted_quantity, 
					@PPBlockNumber					= Block_number,
					@PPProcessOrder					= Process_order,
					@PPTransactionTime				= @ProductionPlanTransactionTime, 
					@PPMisc1						= NULL,
					@PPMisc2						= NULL,
					@PPMisc3						= NULL,
					@PPMisc4						= NULL,
					@PPBOMFormulationId				= BOM_Formulation_id,
					@PPUserGeneral1					= User_general_1,
					@PPUserGeneral2					= User_general_2,
					@PPUserGeneral3					= User_general_3,
					@PPExtendedInfo					= Extended_info				
			FROM	dbo.production_plan WITH(NOLOCK) 
			WHERE	PP_ID = @ActivePPId

			IF @Comment IS NOt NULL
			BEGIN
				SET @CommentUserId = @UserId
				EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@PPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo-- ,
					--0

				SET @ProductionPlanTransactionTime = Dateadd(Second, 1,@ProductionPlanTransactionTime)
				/*ACTIVATE ORDER @UpdatePPID */
				SELECT 	@PPId							= PP_ID,
						@PPTransType					= 2,
						@PPTransNum						= 97,
						@PathId							= Path_id, 
						@PPCommentId					= comment_id,
						@PPProdId						= Prod_id,
						@PPImpliedSequence				= Implied_Sequence,
						@PPStatusId						= @ActivePPStatusId,
						@PPTypeId						= PP_Type_Id,
						@PPSourcePPId					= Source_PP_ID,
						@PPUserId						= @userId,
						@PPParentPPId					= Parent_PP_ID,
						@PPControlType					= control_type,
						@PPForecastStartTime			= forecast_Start_date,
						@PPForecastEndTime				= forecast_End_date,
						@PPEntryOn						= NULL,
						@PPForecastQuantity				= Forecast_quantity,
						@PPProductionRate				= Production_rate, 
						@PPAdjustedQuantity				= Adjusted_quantity, 
						@PPBlockNumber					= Block_number,
						@PPProcessOrder					= Process_order,
						@PPTransactionTime				= @ProductionPlanTransactionTime, 
						@PPMisc1						= NULL,
						@PPMisc2						= NULL,
						@PPMisc3						= NULL,
						@PPMisc4						= NULL,
						@PPBOMFormulationId				= BOM_Formulation_id,
						@PPUserGeneral1					= User_general_1,
						@PPUserGeneral2					= User_general_2,
						@PPUserGeneral3					= User_general_3,
						@PPExtendedInfo					= Extended_info				
				FROM	dbo.production_plan WITH(NOLOCK) 
				WHERE	PP_ID = @UpdatePPID

			IF @Comment IS NOt NULL
			BEGIN
				SET @CommentUserId = @UserId
				EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END
			SELECT @CommentId2

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@PPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo-- ,
					--0
			/*COMPLETE ORDER @UpdatePPID */
			SET @ProductionPlanTransactionTime = Dateadd(Second, 1,@ProductionPlanTransactionTime)
			SELECT 	@PPId							= PP_ID,
					@PPTransType					= 2,
					@PPTransNum						= 97,
					@PathId							= Path_id, 
					@PPCommentId					= comment_id,
					@PPProdId						= Prod_id,
					@PPImpliedSequence				= Implied_Sequence,
					@PPStatusId						= @CompletePPStatusId,
					@PPTypeId						= PP_Type_Id,
					@PPSourcePPId					= Source_PP_ID,
					@PPUserId						= @userId,
					@PPParentPPId					= Parent_PP_ID,
					@PPControlType					= control_type,
					@PPForecastStartTime			= forecast_Start_date,
					@PPForecastEndTime				= forecast_End_date,
					@PPEntryOn						= NULL,
					@PPForecastQuantity				= Forecast_quantity,
					@PPProductionRate				= Production_rate, 
					@PPAdjustedQuantity				= Adjusted_quantity, 
					@PPBlockNumber					= Block_number,
					@PPProcessOrder					= Process_order,
					@PPTransactionTime				= @ProductionPlanTransactionTime, 
					@PPMisc1						= NULL,
					@PPMisc2						= NULL,
					@PPMisc3						= NULL,
					@PPMisc4						= NULL,
					@PPBOMFormulationId				= BOM_Formulation_id,
					@PPUserGeneral1					= User_general_1,
					@PPUserGeneral2					= User_general_2,
					@PPUserGeneral3					= User_general_3,
					@PPExtendedInfo					= Extended_info				
			FROM	dbo.production_plan WITH(NOLOCK) 
			WHERE	PP_ID = @UpdatePPID

	

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@PPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo-- ,
					--0

		END
		ELSE IF (SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID) IN (@CompletePPStatusId)
		BEGIN
			/* LOOK IF LAST ENTRY IN PPS	*/
			IF	(SELECT TOP 1	PPS.pp_id 
				FROM			dbo.production_plan_starts PPS WITH(NOLOCK)
								JOIN dbo.production_plan PP WITH(NOLOCK)
									ON PP.PP_Id = PPS.PP_Id 
				WHERE			PP.path_id = @PathId
				ORDER BY		PPS.start_time desc
				) != @UpdatePPID
			BEGIN
				SELECT	@OutputStatus = 0
				SELECT	@OutputMessage = 'Selected process order is commplete and it is not the last one active at the location'
				RETURN
			END
			

		END


		/*=================================================================	
		ACTION -  Perform minor cleaning	
		==================================================================*/
		/*Create signature Id if not existing*/
		
		IF @SignatureId IS NULL
		BEGIN
			EXEC  [dbo].[spSDK_AU_ESignature]
			null, 
			@SignatureId OUTPUT, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			null, 
			@UserId, 
			@Machine, 
			null, 
			null, 
			@Now
		END

		
		SET @CommentUserId = @UserId
		/* Add comment to existing  */
		IF @Comment IS NOt NULL
		BEGIN
			EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
		END
		/* COLLECT UDE INFO */
			
		SET @UDEUpdateType = 1
		SET @UDEDesc = 'LCL-' + CONVERT(varchar(30), @now)
		SET @UDEStartTime	= Dateadd(Second, 1,@now)
		SET @UDEEndTime	= Dateadd(Second, 1,@UDEStartTime)
		SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Completed')


		/* Approve the cleaning to lock it */

		EXEC [dbo].[spServer_DBMgrUpdUserEvent]
		0, 
		'CTS location cleaning', 
		NULL,					--Action comment Id
		NULL,					--Action 4
		NULL, 					--Action 3
		NULL,					--Action 2
		NULL, 					--Action 1
		NULL,					--Cause comment Id
		NULL,					--Cause 4
		NULL, 					--Cause 3
		NULL,					--Cause 2
		NULL, 					--Cause 1
		NULL,					--Ack by
		0,						--Acked
		0,						--Duration
		@EST_Cleaning,			--event_subTypeId
		@LocationPUId,			--pu_id
		@UDEDESC,				--UDE desc
		@UDEId OUTPUT,			--UDE_ID
		@UserId,				--User_Id
		NULL,					--Acked On
		@UDEStartTime,			--@UDE Starttime, 
		@UDEEndTime,			--@UDE endtime, 
		NULL,					--Research CommentId
		NULL,					--Research Status id
		NULL,					--Research User id
		NULL,					--Research Open Date
		NULL,					--Research Close date
		@UDEUpdateType,			--Transaction type
		@CommentId2,			--Comment Id
		NULL,					--reason tree
		@SignatureId,			--signature Id
		NULL,					--eventId
		NULL,					--parent ude id
		@UDEStatusId,			--event status
		1,						--Testing status
		NULL,					--conformance
		NULL,					--test percent complete
		0	

		-- SET THE CLEANING TYPE
		EXEC dbo.spServer_DBMgrUpdTest2 
			@LocationCleaningTypeVarId,	/*Var_id*/
			@UserId	,					/*User_id*/
			0,							/*Cancelled*/
			'Minor',					/*New_result*/
			@UDEEndTime,				/*result_on*/
			NULL,						/*Transnum*/
			NULL,						/*Comment_id*/
			NULL,						/*ArrayId*/
			@UDEId,						/*event_id*/
			@locationPUId,				/*Pu_id*/
			@TestId	OUTPUT,				/*testId*/
			NULL,						/*Entry_On*/
			NULL,
			NULL,
			NULL,
			NULL
		SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Approved')
		SET @UDEUpdateType = 2

		EXEC [dbo].[spServer_DBMgrUpdUserEvent]
		0, 
		'CTS location cleaning', 
		NULL,					--Action comment Id
		NULL,					--Action 4
		NULL, 					--Action 3
		NULL,					--Action 2
		NULL, 					--Action 1
		NULL,					--Cause comment Id
		NULL,					--Cause 4
		NULL, 					--Cause 3
		NULL,					--Cause 2
		NULL, 					--Cause 1
		NULL,					--Ack by
		0,						--Acked
		0,						--Duration
		@EST_Cleaning,			--event_subTypeId
		@LocationPUId,			--pu_id
		@UDEDESC,				--UDE desc
		@UDEId,					--UDE_ID
		@UserId,				--User_Id
		NULL,					--Acked On
		@UDEStartTime,			--@UDE Starttime, 
		@UDEEndTime,			--@UDE endtime, 
		NULL,					--Research CommentId
		NULL,					--Research Status id
		NULL,					--Research User id
		NULL,					--Research Open Date
		NULL,					--Research Close date
		@UDEUpdateType,			--Transaction type
		@CommentId2,			--Comment Id
		NULL,					--reason tree
		@SignatureId,			--signature Id
		NULL,					--eventId
		NULL,					--parent ude id
		@UDEStatusId,			--event status
		1,						--Testing status
		NULL,					--conformance
		NULL,					--test percent complete
		0	
		SELECT	@OutputStatus = 1
		SELECT	@OutputMessage = 'Location overriden to Clean Minor'
		GOTO OverrideLog
		RETURN

	END

	/*=================================================================	
	CASE 3
	@STATUS = Clean Major
	ACTIONS  1. Complete any active process order.  2. Reject any open cleaning, 3. Perform major cleaning  	
	==================================================================*/
	IF @Status  = 'Clean'  AND @CleaningType  = 'Major' 
	BEGIN

		/*=================================================================	
		ACTIONS  1. Complete any active process order.  	
		==================================================================*/
		SELECT	@ActivePPId = PPS.PP_Id
		FROM	dbo.production_plan_starts PPS
		WHERE	PU_id = @LocationPUId 
				AND End_Time IS NULL

		IF @ActivePPId IS NOT NULL
		BEGIN
			SELECT 	
					@PPId							= PP_ID,
					@PPTransType					= 2,
					@PPTransNum						= 97,
					@PathId							= Path_id, 
					@PPCommentId					= comment_id,
					@PPProdId						= Prod_id,
					@PPImpliedSequence				= Implied_Sequence,
					@PPStatusId						= PP_Status_id,
					@PPTypeId						= PP_Type_Id,
					@PPSourcePPId					= Source_PP_ID,
					@PPUserId						= @userId,
					@PPParentPPId					= Parent_PP_ID,
					@PPControlType					= control_type,
					@PPForecastStartTime			= forecast_Start_date,
					@PPForecastEndTime				= forecast_End_date,
					@PPEntryOn						= NULL,
					@PPForecastQuantity				= Forecast_quantity,
					@PPProductionRate				= Production_rate, 
					@PPAdjustedQuantity				= Adjusted_quantity, 
					@PPBlockNumber					= Block_number,
					@PPProcessOrder					= Process_order,
					@PPTransactionTime				= DATEADD(Second,-1,@now), --Close at a second before now
					@PPMisc1						= NULL,
					@PPMisc2						= NULL,
					@PPMisc3						= NULL,
					@PPMisc4						= NULL,
					@PPBOMFormulationId				= BOM_Formulation_id,
					@PPUserGeneral1					= User_general_1,
					@PPUserGeneral2					= User_general_2,
					@PPUserGeneral3					= User_general_3,
					@PPExtendedInfo					= Extended_info				
			FROM	dbo.production_plan WITH(NOLOCK) 
			WHERE	PP_ID = @activePPId

			IF @Comment IS NOt NULL
			BEGIN
				SET @CommentUserId = @UserId
				EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@CompletePPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo-- ,
					--0
		END


		/*=================================================================	
		ACTIONS  2.a Reject any open cleaning	
		==================================================================*/
		IF (SELECT Status FROM @Location_cleaning) NOT IN ('CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
		BEGIN
			-- COLLECT UDE INFO
			SELECT	@UDEDESC = UDE_Desc,
					@UDEId	= UDE_Id,
					@UDEStartTime = Start_time,
					@UDEEndTime = End_time,	
					@UDEUpdateType = 2,
					@CommentId = comment_id,	
					@SignatureId = @SignatureId,
					@UDEStatusId = @UDEStatusId
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Location_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	
			/*E-SIGNATURE IS MANDATORY WHEN OVERRIDING LOCATION STATUS*/
			IF @SignatureId IS NULL /* IF CLEANING UDE EXISTS AND SIGNATURE IS NOT PRESENT (CLEANING IS STARTED) - CREATE A SIGNATURE - THE ORDER WILL BE CANCELLED*/
			BEGIN

			/* CREATE/UPDATE SIGNATURE */
				SET @Now = GETDATE()
				/*Create signature Id*/

				EXEC  [dbo].[spSDK_AU_ESignature]
							null, 
							@SignatureId OUTPUT, 
							null, 
							null, 
							null, 
							@UserId, 
							@Machine, 
							null, 
							null, 
							null, 
							null, 
							null, 
							null, 
							@UserId, 
							@Machine, 
							null, 
							null, 
							@Now
			END
			ELSE 
			BEGIN
				UPDATE	dbo.esignature 
				SET		verify_user_id = @UserId, 
						Verify_Node = @Machine, 
						Verify_Time = @Now 
				WHERE	[Signature_Id] = @SignatureId
			END

			SET @CommentUserId = @UserId
			/* ADD COMMENT TO EXISTING COMMENT */
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			/* UPDATE EXISTING UDE - CLOSE IT */
			EXEC [dbo].[spServer_DBMgrUpdUserEvent]
			0,						--Transnum
			'CTS location cleaning',-- Event sub type desc 
			NULL,					--Action comment Id
			NULL,					--Action 4
			NULL, 					--Action 3
			NULL,					--Action 2
			NULL, 					--Action 1
			NULL,					--Cause comment Id
			NULL,					--Cause 4
			NULL, 					--Cause 3
			NULL,					--Cause 2
			NULL, 					--Cause 1
			NULL,					--Ack by
			0,						--Acked
			0,						--Duration
			@EST_Cleaning,			--event_subTypeId
			@LocationPUId,			--pu_id
			@UDEDESC,				--UDE desc
			@UDEId,					--UDE_ID
			@UserId,				--User_Id
			NULL,					--Acked On
			@UDEStartTime,			--@UDE Starttime, 
			@UDEEndTime,			--@UDE endtime, -- KEEP THE SAME
			NULL,					--Research CommentId
			NULL,					--Research Status id
			NULL,					--Research User id
			NULL,					--Research Open Date
			NULL,					--Research Close date
			@UpdateType,			--Transaction type
			@CommentId2,			--Comment Id
			NULL,					--reason tree
			@SignatureId,			--signature Id
			NULL,					--eventId
			NULL,					--parent ude id
			@UDEStatusId,			--event status
			1,						--Testing status
			NULL,					--conformance
			NULL,					--test percent complete
			0	
		END 
	
	
		/*=================================================================	
		ACTIONS  2.b Reject any open Maintenance	
		==================================================================*/	
		IF (SELECT maintenance_status FROM fnLocal_CTS_Location_Status(@LocationPUId,NULL)) = 'CST_Maintenance_Started'
		BEGIN
			/* udeid of the maintenance event */
			SET @UDEId = (	SELECT TOP 1 ude_id 
							FROM dbo.user_defined_events ude	WITH(NOLOCK)
							JOIN dbo.event_subtypes es			WITH(NOLOCK) ON ude.event_subtype_id = es.event_subtype_id
																				AND es.event_subtype_desc = 'CST Maintenance'
							WHERE pu_id = @LocationPUId
							ORDER BY ude.ude_id DESC	)

			IF @UDEId IS NOT NULL
			BEGIN
				EXEC [dbo].[spLocal_CST_CreateUpdate_Location_Maintenance] 
				@LocationPUId,
				@UDEId,
				@UserId,
				@RoleId,
				'Override',
				@OutPutStatusTemp						 OUTPUT,
				@OutPutMessageTemp						 OUTPUT
			END

		END

		/*=================================================================	
		ACTIONS 3. Perform major cleaning	
		==================================================================*/	
		SET @Now = GETDATE()
		SET @UDEUpdateType = 1
		SET @CommentId2 = NULL
		SET @UDEDesc = 'LCL-' + CONVERT(varchar(30), @now)

		SET @UDEStartTime = @Now
		SET @UDEEndTime = DATEADD(Second,1,@Now)


		/*Create signature Id if not existing*/
		IF @SignatureId IS NULL
		BEGIN
			EXEC  [dbo].[spSDK_AU_ESignature]
					null, 
					@SignatureId OUTPUT, 
					null, 
					null, 
					null, 
					@UserId, 
					@Machine, 
					null, 
					null, 
					null, 
					null, 
					null, 
					null, 
					@UserId, 
					@Machine, 
					null, 
					null, 
					@Now
		END

		
		SET @CommentUserId = @UserId
		/* Add comment to existing */
		IF @Comment IS NOt NULL
		BEGIN
			EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
		END
		/* CREATE UDE complete */
		SET @UDEUpdateType = 1
		SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Completed')
		EXEC [dbo].[spServer_DBMgrUpdUserEvent]
		0, 
		'CTS location cleaning', 
		NULL,					--Action comment Id
		NULL,					--Action 4
		NULL, 					--Action 3
		NULL,					--Action 2
		NULL, 					--Action 1
		NULL,					--Cause comment Id
		NULL,					--Cause 4
		NULL, 					--Cause 3
		NULL,					--Cause 2
		NULL, 					--Cause 1
		NULL,					--Ack by
		0,						--Acked
		0,						--Duration
		@EST_Cleaning,			--event_subTypeId
		@LocationPUId,			--pu_id
		@UDEDESC,				--UDE desc
		@UDEId OUTPUT,			--UDE_ID
		@userId,				--User_Id
		NULL,					--Acked On
		@UDEStartTime,			--@UDE Starttime, 
		@UDEEndTime,			--@UDE endtime, 
		NULL,					--Research CommentId
		NULL,					--Research Status id
		NULL,					--Research User id
		NULL,					--Research Open Date
		NULL,					--Research Close date
		@UDEUpdateType,			--Transaction type
		@CommentId2,			--Comment Id
		NULL,					--reason tree
		@SignatureId,			--signature Id
		NULL,					--eventId
		NULL,					--parent ude id
		@UDEStatusId,			--event status
		1,						--Testing status
		NULL,					--conformance
		NULL,					--test percent complete
		0	
		
		/* SET THE CLEANING TYPE */
		EXEC dbo.spServer_DBMgrUpdTest2 
			@LocationCleaningTypeVarId,	--Var_id
			@UserId	,					--User_id
			0,							--Cancelled
			'Major',					--New_result
			@UDEEndTime,						--result_on
			NULL,						--Transnum
			NULL,						--Comment_id
			NULL,						--ArrayId
			@UDEId,						--event_id
			@locationPUId,				--Pu_id
			@TestId	OUTPUT,				--testId
			NULL,						--Entry_On
			NULL,
			NULL,
			NULL,
			NULL
		/* UPDATE UDE to Approved */
		SET @UDEUpdateType = 2
		SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Approved')
		/* CREATE UDE */
		EXEC [dbo].[spServer_DBMgrUpdUserEvent]
		0, 
		'CTS location cleaning', 
		NULL,					--Action comment Id
		NULL,					--Action 4
		NULL, 					--Action 3
		NULL,					--Action 2
		NULL, 					--Action 1
		NULL,					--Cause comment Id
		NULL,					--Cause 4
		NULL, 					--Cause 3
		NULL,					--Cause 2
		NULL, 					--Cause 1
		NULL,					--Ack by
		0,						--Acked
		0,						--Duration
		@EST_Cleaning,			--event_subTypeId
		@LocationPUId,			--pu_id
		@UDEDESC,				--UDE desc
		@UDEId,					--UDE_ID
		@userId,				--User_Id
		NULL,					--Acked On
		@UDEStartTime,			--@UDE Starttime, 
		@UDEEndTime,			--@UDE endtime, 
		NULL,					--Research CommentId
		NULL,					--Research Status id
		NULL,					--Research User id
		NULL,					--Research Open Date
		NULL,					--Research Close date
		@UDEUpdateType,			--Transaction type
		@CommentId2,			--Comment Id
		NULL,					--reason tree
		@SignatureId,			--signature Id
		NULL,					--eventId
		NULL,					--parent ude id
		@UDEStatusId,			--event status
		1,						--Testing status
		NULL,					--conformance
		NULL,					--test percent complete
		0	
		
	

		SELECT	@OutputStatus = 1
		SELECT	@OutputMessage = 'Location overriden to Clean Major'

		SET @ovNew_PPID =NULL
		SET @ovNew_ProdId = NULL
		GOTO OverrideLog
		RETURN
	END





	/*=================================================================	
	CASE 4
	 @STATUS = Dirty.  This means that the process order did not complete.
	 1. Reject open cleaning 2. Complete the order passed if not completed	
	==================================================================*/
	IF @Status  = 'Dirty' AND @ProcessOrder IS NOT NULL
	BEGIN

		/* GET THE PROCESS ORDER CORRESPONDING TO @ProcessOrder AT THE LOCATION */
		SELECT @UpdatePPId =	(SELECT	PP_Id 
								FROM	dbo.production_plan PP WITH(NOLOCK)
								JOIN	dbo.PrdExec_Path_Units PPU
											ON PPU.Path_Id = PP.path_id
								WHERE	PPU.PU_Id = @LocationPUId
										AND	PP.process_order = @ProcessOrder
								)
		/* IF NOT IN PP-- ORDER DOWNLOAD FAILED -- DO NOT ACT */
		IF @UpdatePPId IS NULL 
		BEGIN
			SET @OutputMessage = 'Update refused - Last process order does not exist in CTS'
			SET @OutputStatus = 0
			RETURN
		END


		/*=================================================================	
		ACTIONS 1.a Reject any open cleaning.  Any open cleaning on location is rejected	
		==================================================================*/
		IF (SELECT Status FROM @Location_cleaning) NOT IN ('CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
		BEGIN
			-- COLLECT UDE INFO
			SELECT	@UDEDESC = UDE_Desc,
					@UDEId	= UDE_Id,
					@UserId = @UserId,
					@UDEStartTime = Start_time,
					@UDEEndTime = End_time,	
					@UDEUpdateType = 2,
					@CommentId = comment_id,	
					@SignatureId = @SignatureId,
					@UDEStatusId = @UDEStatusId
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Location_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	
			/* E-SIGNATURE IS MANDATORY WHEN OVERRIDING LOCATION STATUS */
			IF @SignatureId IS NULL /* IF CLEANING UDE EXISTS AND SIGNATURE IS NOT PRESENT (CLEANING IS STARTED) - CREATE A SIGNATURE - THE ORDER WILL BE CANCELLED */
			BEGIN

			/* CREATE/UPDATE SIGNATURE  */
				SET @Now = GETDATE()
				/* Create signature Id */

				EXEC  [dbo].[spSDK_AU_ESignature]
							null, 
							@SignatureId OUTPUT, 
							null, 
							null, 
							null, 
							@UserId, 
							@Machine, 
							null, 
							null, 
							null, 
							null, 
							null, 
							null, 
							NULL, 
							NULL, 
							null, 
							null, 
							@Now

			END



			SET @CommentUserId = @UserId
			/* ADD COMMENT TO EXISTING COMMENT */
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			/* UPDATE EXISTING UDE - CLOSE IT */
			EXEC [dbo].[spServer_DBMgrUpdUserEvent]
			0,						--Transnum
			'CTS location cleaning',-- Event sub type desc 
			NULL,					--Action comment Id
			NULL,					--Action 4
			NULL, 					--Action 3
			NULL,					--Action 2
			NULL, 					--Action 1
			NULL,					--Cause comment Id
			NULL,					--Cause 4
			NULL, 					--Cause 3
			NULL,					--Cause 2
			NULL, 					--Cause 1
			NULL,					--Ack by
			0,						--Acked
			0,						--Duration
			@EST_Cleaning,			--event_subTypeId
			@LocationPUId,			--pu_id
			@UDEDESC,				--UDE desc
			@UDEId,					--UDE_ID
			@UserId,				--User_Id
			NULL,					--Acked On
			@UDEStartTime,			--@UDE Starttime, 
			@UDEEndTime,			--@UDE endtime, -- KEEP THE SAME
			NULL,					--Research CommentId
			NULL,					--Research Status id
			NULL,					--Research User id
			NULL,					--Research Open Date
			NULL,					--Research Close date
			@UDEUpdateType,			--Transaction type
			@CommentId2,			--Comment Id
			NULL,					--reason tree
			@SignatureId,			--signature Id
			NULL,					--eventId
			NULL,					--parent ude id
			@UDEStatusId,			--event status
			1,						--Testing status
			NULL,					--conformance
			NULL,					--test percent complete
			0	

		END 
		
		/*=================================================================	
		ACTIONS  1.b Reject any open Maintenance	
		==================================================================*/	
		IF (SELECT maintenance_status FROM fnLocal_CTS_Location_Status(@LocationPUId,NULL)) = 'CST_Maintenance_Started'
		BEGIN
			/* udeid of the maintenance event */
			SET @UDEId = (	SELECT TOP 1 ude_id 
							FROM dbo.user_defined_events ude	WITH(NOLOCK)
							JOIN dbo.event_subtypes es			WITH(NOLOCK) ON ude.event_subtype_id = es.event_subtype_id
																				AND es.event_subtype_desc = 'CST Maintenance'
							WHERE pu_id = @LocationPUId
							ORDER BY ude.ude_id DESC	)

			IF @UDEId IS NOT NULL
			BEGIN
				EXEC [dbo].[spLocal_CST_CreateUpdate_Location_Maintenance] 
				@LocationPUId,
				@UDEId,
				@UserId,
				@RoleId,
				'Override',
				@OutPutStatusTemp						 OUTPUT,
				@OutPutMessageTemp						 OUTPUT
			END

		END


		/* COMPLETE THE PROCESS ORDER - SET AN ENTRY IN PRODUCTION_PLAN_STARTS */
		/* LOOK IF THE ENTRY EXISTS IN PPS */

		SET @ActivePPId =	
		(SELECT	TOP 1	PP.PP_Id 
		FROM	dbo.production_plan PP WITH(NOLOCK)
		JOIN	dbo.PrdExec_Path_Units PPU
					ON PPU.Path_id = PP.Path_id
		WHERE	PPU.PU_Id = @LocationPUId
				AND PP.PP_status_id = @ActivePPStatusId
		)


		
		/* SELECTED PP ALREADY COMPLETED */
		/* IF(SELECT end_time FROM dbo.production_plan_starts WITH(NOLOCK) WHERE PP_id = @UpdatePPID) IS NOT NULL */

		SET @UpdatePPSTatusId = (SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID)
		/*===========================================================================================================
		SELECTED PP IS ACTIVE
		=============================================================================================================*/
		--IF(SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID) IN (@ActivePPStatusId)
		IF @UpdatePPSTatusId = @ActivePPStatusId
		BEGIN
		
			SET @ProductionPlanTransactionTime = @Now
			/* COMPLETGE ORDER */
			SELECT 	@PPId							= PP_ID,
					@PPTransType					= 2,
					@PPTransNum						= 97,
					@PathId							= Path_id, 
					@PPCommentId					= comment_id,
					@PPProdId						= Prod_id,
					@PPImpliedSequence				= Implied_Sequence,
					@PPStatusId						= @CompletePPStatusId,
					@PPTypeId						= PP_Type_Id,
					@PPSourcePPId					= Source_PP_ID,
					@PPUserId						= @userId,
					@PPParentPPId					= Parent_PP_ID,
					@PPControlType					= control_type,
					@PPForecastStartTime			= forecast_Start_date,
					@PPForecastEndTime				= forecast_End_date,
					@PPEntryOn						= NULL,
					@PPForecastQuantity				= Forecast_quantity,
					@PPProductionRate				= Production_rate, 
					@PPAdjustedQuantity				= Adjusted_quantity, 
					@PPBlockNumber					= Block_number,
					@PPProcessOrder					= Process_order,
					@PPTransactionTime				= @ProductionPlanTransactionTime, 
					@PPMisc1						= NULL,
					@PPMisc2						= NULL,
					@PPMisc3						= NULL,
					@PPMisc4						= NULL,
					@PPBOMFormulationId				= BOM_Formulation_id,
					@PPUserGeneral1					= User_general_1,
					@PPUserGeneral2					= User_general_2,
					@PPUserGeneral3					= User_general_3,
					@PPExtendedInfo					= Extended_info				
			FROM	dbo.production_plan WITH(NOLOCK) 
			WHERE	PP_ID = @UpdatePPID

			IF @Comment IS NOt NULL
			BEGIN
				SET @CommentUserId = @UserId
				EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@PPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo /* ,
					0 */

			END

		--ELSE IF (SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID) IN (@PendingPPStatusId)
		IF @UpdatePPSTatusId = @PendingPPStatusId
		BEGIN
		

			/* COMPLETE ORDER @ActivePPId */
			SET @ProductionPlanTransactionTime = (SELECT DATEADD(second, 1, Start_time) FROM dbo.production_plan_starts WITH(NOLOCK) WHERE PP_id = @ActivePPId)
			SELECT 	@PPId							= PP_ID,
					@PPTransType					= 2,
					@PPTransNum						= 97,
					@PathId							= Path_id, 
					@PPCommentId					= comment_id,
					@PPProdId						= Prod_id,
					@PPImpliedSequence				= Implied_Sequence,
					@PPStatusId						= @CompletePPStatusId,
					@PPTypeId						= PP_Type_Id,
					@PPSourcePPId					= Source_PP_ID,
					@PPUserId						= @userId,
					@PPParentPPId					= Parent_PP_ID,
					@PPControlType					= control_type,
					@PPForecastStartTime			= forecast_Start_date,
					@PPForecastEndTime				= forecast_End_date,
					@PPEntryOn						= NULL,
					@PPForecastQuantity				= Forecast_quantity,
					@PPProductionRate				= Production_rate, 
					@PPAdjustedQuantity				= Adjusted_quantity, 
					@PPBlockNumber					= Block_number,
					@PPProcessOrder					= Process_order,
					@PPTransactionTime				= @ProductionPlanTransactionTime, 
					@PPMisc1						= NULL,
					@PPMisc2						= NULL,
					@PPMisc3						= NULL,
					@PPMisc4						= NULL,
					@PPBOMFormulationId				= BOM_Formulation_id,
					@PPUserGeneral1					= User_general_1,
					@PPUserGeneral2					= User_general_2,
					@PPUserGeneral3					= User_general_3,
					@PPExtendedInfo					= Extended_info				
			FROM	dbo.production_plan WITH(NOLOCK) 
			WHERE	PP_ID = @ActivePPId

			IF @Comment IS NOt NULL
			BEGIN
				SET @CommentUserId = @UserId
				EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@PPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo /* ,
					0 */

				SET @ProductionPlanTransactionTime = Dateadd(Second, 1,@ProductionPlanTransactionTime)
				/* ACTIVATE ORDER @UpdatePPID */
				SELECT 	@PPId							= PP_ID,
						@PPTransType					= 2,
						@PPTransNum						= 97,
						@PathId							= Path_id, 
						@PPCommentId					= comment_id,
						@PPProdId						= Prod_id,
						@PPImpliedSequence				= Implied_Sequence,
						@PPStatusId						= @ActivePPStatusId,
						@PPTypeId						= PP_Type_Id,
						@PPSourcePPId					= Source_PP_ID,
						@PPUserId						= @userId,
						@PPParentPPId					= Parent_PP_ID,
						@PPControlType					= control_type,
						@PPForecastStartTime			= forecast_Start_date,
						@PPForecastEndTime				= forecast_End_date,
						@PPEntryOn						= NULL,
						@PPForecastQuantity				= Forecast_quantity,
						@PPProductionRate				= Production_rate, 
						@PPAdjustedQuantity				= Adjusted_quantity, 
						@PPBlockNumber					= Block_number,
						@PPProcessOrder					= Process_order,
						@PPTransactionTime				= @ProductionPlanTransactionTime, 
						@PPMisc1						= NULL,
						@PPMisc2						= NULL,
						@PPMisc3						= NULL,
						@PPMisc4						= NULL,
						@PPBOMFormulationId				= BOM_Formulation_id,
						@PPUserGeneral1					= User_general_1,
						@PPUserGeneral2					= User_general_2,
						@PPUserGeneral3					= User_general_3,
						@PPExtendedInfo					= Extended_info				
				FROM	dbo.production_plan WITH(NOLOCK) 
				WHERE	PP_ID = @UpdatePPID

			IF @Comment IS NOt NULL
			BEGIN
				SET @CommentUserId = @UserId
				EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@PPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo-- ,
					--0
			/* COMPLETE ORDER @UpdatePPID */
			SET @ProductionPlanTransactionTime = Dateadd(Second, 1,@ProductionPlanTransactionTime)
			SELECT 	@PPId							= PP_ID,
					@PPTransType					= 2,
					@PPTransNum						= 97,
					@PathId							= Path_id, 
					@PPCommentId					= comment_id,
					@PPProdId						= Prod_id,
					@PPImpliedSequence				= Implied_Sequence,
					@PPStatusId						= @CompletePPStatusId,
					@PPTypeId						= PP_Type_Id,
					@PPSourcePPId					= Source_PP_ID,
					@PPUserId						= @userId,
					@PPParentPPId					= Parent_PP_ID,
					@PPControlType					= control_type,
					@PPForecastStartTime			= forecast_Start_date,
					@PPForecastEndTime				= forecast_End_date,
					@PPEntryOn						= NULL,
					@PPForecastQuantity				= Forecast_quantity,
					@PPProductionRate				= Production_rate, 
					@PPAdjustedQuantity				= Adjusted_quantity, 
					@PPBlockNumber					= Block_number,
					@PPProcessOrder					= Process_order,
					@PPTransactionTime				= @ProductionPlanTransactionTime, 
					@PPMisc1						= NULL,
					@PPMisc2						= NULL,
					@PPMisc3						= NULL,
					@PPMisc4						= NULL,
					@PPBOMFormulationId				= BOM_Formulation_id,
					@PPUserGeneral1					= User_general_1,
					@PPUserGeneral2					= User_general_2,
					@PPUserGeneral3					= User_general_3,
					@PPExtendedInfo					= Extended_info				
			FROM	dbo.production_plan WITH(NOLOCK) 
			WHERE	PP_ID = @UpdatePPID

	

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@PPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo-- ,
					--0

		END
		
		IF @UpdatePPSTatusId = @CompletePPStatusId
		BEGIN
			SET @ActivePPId =	
			(SELECT	TOP 1	PP.PP_Id 
			FROM	dbo.production_plan PP WITH(NOLOCK)
			JOIN	dbo.PrdExec_Path_Units PPU
						ON PPU.Path_id = PP.Path_id
			WHERE	PPU.PU_Id = @LocationPUId
					AND PP.PP_status_id = @ActivePPStatusId
			)


			-----------------------------------------------------------------------------------------------------------
			-- SELECTED PP IS ACTIVE
			-----------------------------------------------------------------------------------------------------------
	--		IF(SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID) IN (@ActivePPStatusId)
			IF @ActivePPId IS NOT NULL
			BEGIN
		
				SET @ProductionPlanTransactionTime = @Now
				--COMPLETGE ORDER
				SELECT 	@PPId							= PP_ID,
						@PPTransType					= 2,
						@PPTransNum						= 97,
						@PathId							= Path_id, 
						@PPCommentId					= comment_id,
						@PPProdId						= Prod_id,
						@PPImpliedSequence				= Implied_Sequence,
						@PPStatusId						= @CompletePPStatusId,
						@PPTypeId						= PP_Type_Id,
						@PPSourcePPId					= Source_PP_ID,
						@PPUserId						= @userId,
						@PPParentPPId					= Parent_PP_ID,
						@PPControlType					= control_type,
						@PPForecastStartTime			= forecast_Start_date,
						@PPForecastEndTime				= forecast_End_date,
						@PPEntryOn						= NULL,
						@PPForecastQuantity				= Forecast_quantity,
						@PPProductionRate				= Production_rate, 
						@PPAdjustedQuantity				= Adjusted_quantity, 
						@PPBlockNumber					= Block_number,
						@PPProcessOrder					= Process_order,
						@PPTransactionTime				= @ProductionPlanTransactionTime, 
						@PPMisc1						= NULL,
						@PPMisc2						= NULL,
						@PPMisc3						= NULL,
						@PPMisc4						= NULL,
						@PPBOMFormulationId				= BOM_Formulation_id,
						@PPUserGeneral1					= User_general_1,
						@PPUserGeneral2					= User_general_2,
						@PPUserGeneral3					= User_general_3,
						@PPExtendedInfo					= Extended_info				
				FROM	dbo.production_plan WITH(NOLOCK) 
				WHERE	PP_ID = @ActivePPId

				IF @Comment IS NOt NULL
				BEGIN
					SET @CommentUserId = @UserId
					EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
				END

				EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
						@PPId  ,
						@PPTransType,
						@PPTransNum,
						@Pathid,
						@CommentId2,
						@PPProdId,
						@PPImpliedSequence ,
						@PPStatusId ,
						@PPTypeId ,
						@PPSourcePPId ,
						@PPUserId ,
						@PPParentPPId ,
						@PPControlType ,
						@PPForecastStartTime ,
						@PPForecastEndTime ,
						@PPEntryOn  OUTPUT,
						@PPForecastQuantity ,
						@PPProductionRate ,
						@PPAdjustedQuantity ,
						@PPBlockNumber ,
						@PPProcessOrder ,
						@PPTransactionTime ,
						@PPMisc1 ,
						@PPMisc2 ,
						@PPMisc3 ,
						@PPMisc4 ,
						@PPBOMFormulationId ,
						@PPUserGeneral1 ,
						@PPUserGeneral2 ,
						@PPUserGeneral3 ,
						@PPExtendedInfo-- ,
						--0

			END

			--Use Dummy PrO run
			SET @PathId = (SELECT TOP 1 path_id FROM dbo.prdExec_path_units WHERE pu_id = @LocationPUId)
			SET @PathCode = (	SELECT pl.pl_desc
								FROM dbo.prod_units_Base pu		WITH(NOLOCK)
								JOIN dbo.prod_Lines_Base pl		WITH(NOLOCK) ON pu.pl_id = pl.pl_id
								WHERE pu.pu_id = @LocationPUId
								)

			SET @UpdatePPID = (SELECT TOP 1 pp_id FROM dbo.production_plan WHERE path_id = @PathId AND Process_order = 'Override'+@PathCode)

			IF @UpdatePPID IS NULL
			BEGIN
				SET @OutputMessage = 'Update refused - Override process order does not exist in CTS'
				SET @OutputStatus = 0
				RETURN
			END

			SELECT @ppsEndtime = GETDATE()
			SET @PPSSTartTime = DateAdd(ss,-2,@ppsEndtime)



			EXEC [dbo].[spServer_DBMgrUpdProdPlanStarts]
			@PPSTARTId,
			1,						--TransType
			NULL,					--TransNUm
			@LocationPUId,			--pu_id
			@PPSSTartTime,
			@ppsEndtime,
			@UpdatePPID,
			NULL,
			NULL,
			@UserId,
			1,
			NULL
		END
		
		SET @ovNew_CleanType = NULL
		SELECT	@OutputStatus = 1
		SELECT	@OutputMessage = 'Location status overriden to Dirty'
		GOTO OverrideLog
		RETURN
	END

	/*=================================================================	
	CASE 5
	@STATUS = Dirty.  Process order is NULL
	==================================================================*/
	IF @Status  = 'Dirty' AND @ProcessOrder IS NULL
	BEGIN

		/*=================================================================	
		ACTIONS 1. Reject any open cleaning.  Any open cleaning on location is rejected	
		==================================================================*/
		IF (SELECT Status FROM @Location_cleaning) NOT IN ('CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
		BEGIN
			-- COLLECT UDE INFO
			SELECT	@UDEDESC = UDE_Desc,
					@UDEId	= UDE_Id,
					@UserId = @UserId,
					@UDEStartTime = Start_time,
					@UDEEndTime = End_time,	
					@UDEUpdateType = 2,
					@CommentId = comment_id,	
					@SignatureId = @SignatureId,
					@UDEStatusId = @UDEStatusId
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Location_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	
			/* E-SIGNATURE IS MANDATORY WHEN OVERRIDING LOCATION STATUS */
			IF @SignatureId IS NULL /* IF CLEANING UDE EXISTS AND SIGNATURE IS NOT PRESENT (CLEANING IS STARTED) - CREATE A SIGNATURE - THE ORDER WILL BE CANCELLED */
			BEGIN

			/* CREATE/UPDATE SIGNATURE */
				SET @Now = GETDATE()
				/* Create signature Id */

				EXEC  [dbo].[spSDK_AU_ESignature]
							null, 
							@SignatureId OUTPUT, 
							null, 
							null, 
							null, 
							@UserId, 
							@Machine, 
							null, 
							null, 
							null, 
							null, 
							null, 
							null, 
							NULL, 
							NULL, 
							null, 
							null, 
							@Now

			END



			SET @CommentUserId = @UserId
			/* ADD COMMENT TO EXISTING COMMENT */
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			/* UPDATE EXISTING UDE - CLOSE IT */
			EXEC [dbo].[spServer_DBMgrUpdUserEvent]
			0,						--Transnum
			'CTS location cleaning',-- Event sub type desc 
			NULL,					--Action comment Id
			NULL,					--Action 4
			NULL, 					--Action 3
			NULL,					--Action 2
			NULL, 					--Action 1
			NULL,					--Cause comment Id
			NULL,					--Cause 4
			NULL, 					--Cause 3
			NULL,					--Cause 2
			NULL, 					--Cause 1
			NULL,					--Ack by
			0,						--Acked
			0,						--Duration
			@EST_Cleaning,			--event_subTypeId
			@LocationPUId,			--pu_id
			@UDEDESC,				--UDE desc
			@UDEId,					--UDE_ID
			@UserId,				--User_Id
			NULL,					--Acked On
			@UDEStartTime,			--@UDE Starttime, 
			@UDEEndTime,			--@UDE endtime, -- KEEP THE SAME
			NULL,					--Research CommentId
			NULL,					--Research Status id
			NULL,					--Research User id
			NULL,					--Research Open Date
			NULL,					--Research Close date
			@UDEUpdateType,			--Transaction type
			@CommentId2,			--Comment Id
			NULL,					--reason tree
			@SignatureId,			--signature Id
			NULL,					--eventId
			NULL,					--parent ude id
			@UDEStatusId,			--event status
			1,						--Testing status
			NULL,					--conformance
			NULL,					--test percent complete
			0	

		END 
		
		/*=================================================================	
		ACTIONS  2.b Reject any open Maintenance	
		==================================================================*/	
		IF (SELECT maintenance_status FROM fnLocal_CTS_Location_Status(@LocationPUId,NULL)) = 'CST_Maintenance_Started'
		BEGIN
			/* udeid of the maintenance event */
			SET @UDEId = (	SELECT TOP 1 ude_id 
							FROM dbo.user_defined_events ude	WITH(NOLOCK)
							JOIN dbo.event_subtypes es			WITH(NOLOCK) ON ude.event_subtype_id = es.event_subtype_id
																				AND es.event_subtype_desc = 'CST Maintenance'
							WHERE pu_id = @LocationPUId
							ORDER BY ude.ude_id DESC	)

			IF @UDEId IS NOT NULL
			BEGIN
				EXEC [dbo].[spLocal_CST_CreateUpdate_Location_Maintenance] 
				@LocationPUId,
				@UDEId,
				@UserId,
				@RoleId,
				'Override',
				@OutPutStatusTemp						 OUTPUT,
				@OutPutMessageTemp						 OUTPUT
			END

		END

		-- COMPLETE THE PROCESS ORDER - SET AN ENTRY IN PRODUCTION_PLAN_STARTS
		-- LOOK IF THE ENTRY EXISTS IN PPS

		SET @ActivePPId =	
		(SELECT	TOP 1	PP.PP_Id 
		FROM	dbo.production_plan PP WITH(NOLOCK)
		JOIN	dbo.PrdExec_Path_Units PPU
					ON PPU.Path_id = PP.Path_id
		WHERE	PPU.PU_Id = @LocationPUId
				AND PP.PP_status_id = @ActivePPStatusId
		)


		-----------------------------------------------------------------------------------------------------------
		-- SELECTED PP IS ACTIVE
		-----------------------------------------------------------------------------------------------------------
--		IF(SELECT PP_status_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @UpdatePPID) IN (@ActivePPStatusId)
		IF @ActivePPId IS NOT NULL
		BEGIN
		
			SET @ProductionPlanTransactionTime = @Now
			--COMPLETGE ORDER
			SELECT 	@PPId							= PP_ID,
					@PPTransType					= 2,
					@PPTransNum						= 97,
					@PathId							= Path_id, 
					@PPCommentId					= comment_id,
					@PPProdId						= Prod_id,
					@PPImpliedSequence				= Implied_Sequence,
					@PPStatusId						= @CompletePPStatusId,
					@PPTypeId						= PP_Type_Id,
					@PPSourcePPId					= Source_PP_ID,
					@PPUserId						= @userId,
					@PPParentPPId					= Parent_PP_ID,
					@PPControlType					= control_type,
					@PPForecastStartTime			= forecast_Start_date,
					@PPForecastEndTime				= forecast_End_date,
					@PPEntryOn						= NULL,
					@PPForecastQuantity				= Forecast_quantity,
					@PPProductionRate				= Production_rate, 
					@PPAdjustedQuantity				= Adjusted_quantity, 
					@PPBlockNumber					= Block_number,
					@PPProcessOrder					= Process_order,
					@PPTransactionTime				= @ProductionPlanTransactionTime, 
					@PPMisc1						= NULL,
					@PPMisc2						= NULL,
					@PPMisc3						= NULL,
					@PPMisc4						= NULL,
					@PPBOMFormulationId				= BOM_Formulation_id,
					@PPUserGeneral1					= User_general_1,
					@PPUserGeneral2					= User_general_2,
					@PPUserGeneral3					= User_general_3,
					@PPExtendedInfo					= Extended_info				
			FROM	dbo.production_plan WITH(NOLOCK) 
			WHERE	PP_ID = @ActivePPId

			IF @Comment IS NOt NULL
			BEGIN
				SET @CommentUserId = @UserId
				EXEC [dbo].[spLocal_CTS_CreateComment] @PPCommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			EXEC	@returnValue = [dbo].[spServer_DBMgrUpdProdPlan]
					@PPId  ,
					@PPTransType,
					@PPTransNum,
					@Pathid,
					@CommentId2,
					@PPProdId,
					@PPImpliedSequence ,
					@PPStatusId ,
					@PPTypeId ,
					@PPSourcePPId ,
					@PPUserId ,
					@PPParentPPId ,
					@PPControlType ,
					@PPForecastStartTime ,
					@PPForecastEndTime ,
					@PPEntryOn  OUTPUT,
					@PPForecastQuantity ,
					@PPProductionRate ,
					@PPAdjustedQuantity ,
					@PPBlockNumber ,
					@PPProcessOrder ,
					@PPTransactionTime ,
					@PPMisc1 ,
					@PPMisc2 ,
					@PPMisc3 ,
					@PPMisc4 ,
					@PPBOMFormulationId ,
					@PPUserGeneral1 ,
					@PPUserGeneral2 ,
					@PPUserGeneral3 ,
					@PPExtendedInfo-- ,
					--0

		END

		--Use Dummy PrO run
		SET @PathId = (SELECT TOP 1 path_id FROM dbo.prdExec_path_units WHERE pu_id = @LocationPUId)
		SET @PathCode = (	SELECT pl.pl_desc
							FROM dbo.prod_units_Base pu		WITH(NOLOCK)
							JOIN dbo.prod_Lines_Base pl		WITH(NOLOCK) ON pu.pl_id = pl.pl_id
							WHERE pu.pu_id = @LocationPUId
							)

		SET @UpdatePPID = (SELECT TOP 1 pp_id FROM dbo.production_plan WHERE path_id = @PathId AND Process_order = 'Override'+@PathCode)

		IF @UpdatePPID IS NULL
		BEGIN
			SET @OutputMessage = 'Update refused - Override process order does not exist in CTS'
			SET @OutputStatus = 0
			RETURN
		END

		SELECT @ppsEndtime = GETDATE()
		SET @PPSSTartTime = DateAdd(ss,-2,@ppsEndtime)



		EXEC [dbo].[spServer_DBMgrUpdProdPlanStarts]
		@PPSTARTId,
		1,						--TransType
		NULL,					--TransNUm
		@LocationPUId,			--pu_id
		@PPSSTartTime,
		@ppsEndtime,
		@UpdatePPID,
		NULL,
		NULL,
		@UserId,
		1,
		NULL

		SET @ovNew_CleanType = NULL
		SELECT	@OutputStatus = 1
		SELECT	@OutputMessage = 'Location status overriden to Dirty'
		GOTO OverrideLog
		RETURN
	END

RETURN

 OverrideLog:
 INSERT Local_CST_LocationOverrides (
	LocationId			,
	Origin_Status		,
	Origin_CleanType	,
	Origin_PPID			,
	Origin_Prod_Id		,
	New_Status			,
	New_CleanType		,
	New_PPID			,
	New_Prod_Id			,
	UserId				,
	Timestamp			,
	CommentId
)
VALUES (
	@ovLocationId						,
	@ovOrigin_Status					,
	@ovOrigin_CleanType					,
	@ovOrigin_PPID						,
	@ovOrigin_ProdId					,
	@ovNew_Status						,
	@ovNew_CleanType					,
	@ovNew_PPID							,
	@ovNew_Prodid						,
	@ovUserId							,
	@ovTimestamp						,
	@CommentId2
)
	

END
