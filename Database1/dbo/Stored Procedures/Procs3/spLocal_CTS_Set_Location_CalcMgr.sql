
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Set_Location_CalcMgr
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-10-27-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Called by CalculationMgr
-- Description			: Set the location of an appliance from PPA
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-10-27		F. Bergeron				Initial Release 

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
	DECLARE 
	@Output VARCHAR(25)
	EXECUTE spLocal_CTS_Set_Location_CalcMgr
	@Output output,
	1035351,
	8454,
	'Accepted',
	'Yes',
	NULL
	SELECT @Output

	SELECT * FROM EVENTS WHERE PU_ID = 8459
	Select * from event_details where pu_id = 8455
	Select * from event_details where event_id  = 986440
SELECT * FROM production_plan WHERE PP_ID = 14979
*/




CREATE PROCEDURE [dbo].[spLocal_CTS_Set_Location_CalcMgr]
	@Output						VARCHAR(25) OUTPUT,
	@ThisEventId				INTEGER,
	@LocationId					INTEGER,
	@MovementValidationResult	VARCHAR(25),
	@ExecuteTransaction			VARCHAR(25),
	@ProcessOrderId				INTEGER



AS
BEGIN
	--=====================================================================================================================
	SET NOCOUNT ON;
	--=====================================================================================================================
	-----------------------------------------------------------------------------------------------------------------------
	-- DECLARE VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@RC									INTEGER,
	@Now								DATETIME,
	@RSUserId							INTEGER,
	@RSStatusId							INTEGER,
	@ApplianceIdTimestamp				DATETIME,
	@MovementvalidationVarId			INTEGER,
	@Movementvalidation					VARCHAR(25),
	@AppliancePuId						INTEGER,
	@CurrentPosition					INTEGER,
	@CurrentPositionPPId				INTEGER,
	@DestinationPPId					INTEGER,
	@CurrentTransitionEventId			INTEGER,
	@CurrentTransitionStatusId			INTEGER,
	@CurrentTransitionStatusDesc		VARCHAR(25),
	@CurrentPositionTimestamp			DATETIME,
	@CurrentTransitionEDPPID			INTEGER,
	@DestTransitionEDPPID				INTEGER,
	@AppliedProductId					INTEGER
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 1 VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@PETransactionType					INTEGER,
	@PEEventId							INTEGER,
	@PEEventNum							VARCHAR(25),
	@PEPUId								INTEGER,
	@PETimestamp						DATETIME,
	@PEAppliedProduct					INTEGER,
	@PESourceEvent						INTEGER,
	@PEEventStatus						INTEGER,
	@PEConfirmed						INTEGER,
	@PEUpdateType						INTEGER,
	@PEConformance						INTEGER,
	@PETestPctComplete					INTEGER,
	@PEStartTime						DATETIME,
	@PETransNum							INTEGER,
	@PETestingStatus					INTEGER,
	@PECommentId						INTEGER,
	@PEEventSubtypeId					INTEGER,
	@PEEntryOn							DATETIME,
	@PEApprovedUserId					INTEGER,
	@PESecondUserID						INTEGER,
	@PEApprovedReasonId					INTEGER,
	@PEUserReasonId						INTEGER,
	@PEUserSignOffId					INTEGER,
	@PEExtendedInfo						VARCHAR(255),
	@PESignatureId						INTEGER


	DECLARE @RSEvents	TABLE  (
	PEId								INTEGER, 
	PETransactionType					INTEGER, 
	PEEventId							INTEGER NULL, 
	PEEventNum							VARCHAR(25), 
	PEPUId								INTEGER, 
	PETimeStamp							DATETIME, 
	PEAppliedProduct					INTEGER Null, 
	PESourceEvent						INTEGER Null, 
	PEEventStatus						INTEGER Null, 
	PEConfirmed							INTEGER Null,
	PEUserId							INTEGER Null,
	PEUpdateType						INTEGER Null,
	PEConformance						INTEGER Null,
	PETestPctComplete					INTEGER Null,
	PEStartTime							DATETIME,
	PETransNum  						INTEGER null,
	PETestingStatus						INTEGER null, 
	PECommentId          				INTEGER null, 
	PEEventSubTypeId    				INTEGER null, 
	PEEntryOn            				DATETIME,
	PEApprovedUserID					INTEGER,
	PESecondUserID						INTEGER,
	PEApprovedReasonID					INTEGER,
	PEUserReasonID						INTEGER,
	PEUserSignOffID						INTEGER,
	PEExtendedInfo						VARCHAR(255),
	PESignature							INTEGER
)

	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 2 VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@VUVarId				INTEGER,
	@VUPUId 				INTEGER,
	@VUUserId				INTEGER,
	@VUCanceled				INTEGER,
	@VUResult				VARCHAR(25),
	@VUResultOn				DATETIME,
	@VUTransactionType		INTEGER,
	@VUPostUpdate			INTEGER
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 2 TABLE
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE @RSVariables TABLE
	(
		VUVarId					INTEGER,
		VUPUId					INTEGER,
		VUUserId				INTEGER,
		VUCanceled				INTEGER,
		VUResult				VARCHAR(25),
		VUResultOn				DATETIME,
		VUTransactionType		INTEGER,
		VUPostUpdate			INTEGER,
		VUSecondUserId			INTEGER,
		VUTransNum				INTEGER,
		VUEventId				INTEGER,
		VUArrayId				INTEGER,
		VUCommentId				INTEGER,
		VUEsignature			INTEGER
	)
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 10 VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@EDUpdateType						INTEGER,
	@EDTransactionType					INTEGER,
	@EDTransactionNumber				INTEGER,
	@EDEventId							INTEGER,
	@EDUnitId							INTEGER,
 	@EDPrimaryEventNumber				VARCHAR(50),
	@EDAlternateEventNumber				VARCHAR(50),
	@EDCommentId						INTEGER,
	@EDEventSubTypeId					INTEGER,
	@EDOriginalProduct					INTEGER,
	@EDAppliedProduct					INTEGER,
	@EDEventStatus						INTEGER,
	@EDTimestamp						DATETIME,
	@EDEntryOn							DATETIME,
	@EDPPSDId							INTEGER,
	@EDOrderId							INTEGER,
	@EDOrderLineId						INTEGER,
	@EDProductionPlanId					INTEGER,
	@EDInitialDimensionX				FLOAT,
	@EDInitialDimensionY				FLOAT,
	@EDInitialDimensionZ				FLOAT,
	@EDInitialDimensionA				FLOAT,
	@EDFinalDimensionX					FLOAT,
	@EDFinalDimensionY					FLOAT,
	@EDFinalDimensionZ					FLOAT,
	@EDFinalDimensionA					FLOAT,
	@EDOrientationX						FLOAT,
	@EDOrientationY						FLOAT,
	@EDOrientationZ						FLOAT,
	@EDOrientationA						FLOAT,
	@EDESignature						INTEGER
		
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 10 TABLE
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE @RSEventDetails TABLE
	(
	ED_Update_Type						INTEGER,
	ED_User_Id							INTEGER,
	ED_Transaction_Type					INTEGER,
	ED_Transaction_Number				INTEGER,
	ED_Event_Id							INTEGER,
	ED_Unit_Id							INTEGER,
 	ED_Primary_Event_Number				VARCHAR(50),
	ED_Alternate_Event_Number			VARCHAR(50),
	ED_Comment_Id						INTEGER,
	ED_Event_Sub_Type_Id				INTEGER,
	ED_Original_Product					INTEGER,
	ED_Applied_Product					INTEGER,
	ED_Event_Status						INTEGER,
	ED_Timestamp						DATETIME,
	ED_Entry_On							DATETIME,
	ED_PP_SD_Id							INTEGER,
	ED_Order_Id							INTEGER,
	ED_Order_Line_Id					INTEGER,
	ED_Production_Plan_Id				INTEGER,
	ED_Initial_Dimension_X				FLOAT,
	ED_Initial_Dimension_Y				FLOAT,
	ED_Initial_Dimension_Z				FLOAT,
	ED_Initial_Dimension_A				FLOAT,
	ED_Final_Dimension_X				FLOAT,
	ED_Final_Dimension_Y				FLOAT,
	ED_Final_Dimension_Z				FLOAT,
	ED_Final_Dimension_A				FLOAT,
	ED_Orientation_X					FLOAT,
	ED_Orientation_Y					FLOAT,
	ED_Orientation_Z					FLOAT,
	ED_Orientation_A					FLOAT,
	ED_ESignature						INTEGER
	)
 
 	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 11 VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@ECPre								INTEGER,
	@ECTransactionType					INTEGER,
	@ECTransactionNumber				INTEGER,
	@ECComponentId						INTEGER,
	@ECEventId							INTEGER,
	@ECSrcEventId						INTEGER,
	@ECDimX								DECIMAL(18,6),
	@ECDimY								FLOAT,
	@ECDimZ								FLOAT,
	@ECDimA								FLOAT,
	@ECStartCoordinateX					FLOAT, 
	@ECStartCoordinateY					FLOAT, 
	@ECStartCoordinateZ					FLOAT, 
	@ECStartCoordinateA					FLOAT,
	@ECStartTime						DATETIME, 
	@ECTimeStamp						DATETIME, 
	@ECPPComponentId					INTEGER, 
	@ECEntryOn							DATETIME, 
	@ECExtendedInfo						VARCHAR(255),
	@ECPEIId							INTEGER,
	@ECReportAsConsumption				INTEGER,
	@ECChildunitId						INTEGER,
	@ECESignatureId						INTEGER
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 11 TABLE
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE @RSEventComponents TABLE(
	ECPre								INTEGER NULL,
	ECUserId							INTEGER NULL,
	ECTransactionType					INTEGER NULL,
	ECTransactionNumber					INTEGER NULL,
	ECComponentId						INTEGER NULL,
	ECEventId							INTEGER NULL,
	ECSrcEventId						INTEGER NULL,
	ECDimX								DECIMAL(18,6) NULL,
	ECDimY								FLOAT NULL,
	ECDimZ								FLOAT NULL,
	ECDimA								FLOAT NULL,
	ECStartCoordinateX					FLOAT NULL, 
	ECStartCoordinateY					FLOAT NULL, 
	ECStartCoordinateZ					FLOAT NULL, 
	ECStartCoordinateA					FLOAT NULL,
	ECStartTime							DATETIME NULL, 
	ECTimeStamp							DATETIME NULL, 
	ECPPComponentId						INTEGER NULL, 
	ECEntryOn							DATETIME NULL, 
	ECExtendedInfo						VARCHAR(255) NULL,
	ECPEIId								INTEGER,
	ECReportAsConsumption				INTEGER,
	ECChildunitId						INTEGER,
	ECESignatureId						INTEGER
	)



	-----------------------------------------------------------------------------------------------------------------------
	-- SP BODY
	-----------------------------------------------------------------------------------------------------------------------

	SET @Output = 'Nothing to do'
	
	SET @Now = GETDATE()
	SET @Now = DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
	-----------------------------------------------------------------------------------------------------------------------
	-- EVALUATE CONDITIONS TO REGISTER THE MOVEMENT
	-----------------------------------------------------------------------------------------------------------------------
	IF (@MovementValidationResult = 'Accepted' AND @ExecuteTransaction = 'Yes') OR (@MovementValidationResult = 'Conditional' AND @ExecuteTransaction = 'Yes')
	BEGIN

		SET @ApplianceIdTimestamp =	(
									SELECT	Timestamp 
									FROM	dbo.events WITH(NOLOCK) 
									WHERE	event_id = @ThisEventId
									)		

		SET @AppliancePUId = (
									SELECT	pu_id 
									FROM	dbo.events WITH(NOLOCK) 
									WHERE	event_id = @ThisEventId
									)	
		-----------------------------------------------------------------------------------------------------------------------
		-- GET CURRENT APPLIANCE INFO
		-----------------------------------------------------------------------------------------------------------------------
		SET @CurrentPosition =				(
											SELECT TOP 1	E.pu_id 
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)

		SET @CurrentPositionTimestamp =				(
											SELECT TOP 1	E.timestamp
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)
		SET @CurrentTransitionEDPPID =		(
											SELECT TOP 1	ED.PP_ID 
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
															JOIN dbo.event_details ED WITH(NOLOCK)
																ON ED.event_id = E.event_id
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)
		SET @CurrentPositionPPId =			(
											SELECT	PP_ID 
											FROM	dbo.production_plan_starts WITH(NOLOCK) 
											WHERE	PU_id = @CurrentPosition 
														AND @CurrentPositionTimestamp > Start_time
														AND (@CurrentPositionTimestamp < end_time OR end_time IS NULL)
											)


		SET @CurrentTransitionEventId =		(
											SELECT TOP 1	E.event_id
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)
		SET @CurrentTransitionStatusId =	(
											SELECT TOP 1	E.Event_Status
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events E WITH(NOLOCK) 
																ON E.event_id = EC.event_id 
											WHERE			EC.Source_event_id = @ThisEventId 
											ORDER BY		EC.Timestamp DESC
											)
		SET @CurrentTransitionStatusDesc = (
											SELECT			ProdStatus_desc 
											FROM			dbo.Production_status WITH(NOLOCK) 
											WHERE			ProdStatus_Id = @CurrentTransitionStatusId
											)


		SET @DestinationPPId =				(
											SELECT	PP_ID 
											FROM	dbo.production_plan_starts WITH(NOLOCK) 
											WHERE	PU_id = @LocationId 
												AND end_time IS NULL
											)		



		IF	COALESCE(@CurrentPosition,0) <> @LocationId		-- AT POSIITON
		BEGIN
			-----------------------------------------------------------------------------------------------------------------------
			-- GET THE USER WHO CHANGED THE LOCATION
			-----------------------------------------------------------------------------------------------------------------------
			SET	@RSUserId =	(
							SELECT	Entry_By 
							FROM	dbo.tests T WITH(NOLOCK)
									JOIN dbo.variables_base VB WITH(NOLOCK) 
									ON VB.var_id = T.var_id 
							WHERE	VB.test_name = 'New location desc'
										AND T.Result_On = @ApplianceIdTimestamp
										AND T.entry_by > 50
							)

			-----------------------------------------------------------------------------------------------------------------------
			-- CREATE PRODUCTION EVENT AT DESTINATION
			-----------------------------------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------------------------------
			-- EVALUATE STATUS
			-----------------------------------------------------------------------------------------------------------------------

			-----------------------------------------------------------------------------------------------------------------------		
			-- CLEAN APPLIANCE MOVED TO MAKING
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentPositionPPId IS NULL AND COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'Clean'  
			BEGIN
				SET @PEEventStatus =	(
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'Clean'
										)
				SET @DestTransitionEDPPID = NULL
				GOTO PROCESS_EVENT
			END

			-----------------------------------------------------------------------------------------------------------------------		
			-- CLEAN APPLIANCE MOVED OUT OF MAKING
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentPositionPPId IS NOT NULL AND COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'Clean'  
			BEGIN
				SET @PEEventStatus =	(
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'In Use'
										)
				SET @DestTransitionEDPPID = @CurrentPositionPPId
				GOTO PROCESS_EVENT
			END
			-----------------------------------------------------------------------------------------------------------------------
			-- BOM COMPONENT MOVED OUT OF MAKING
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentTransitionEDPPID <> @CurrentPositionPPId AND  COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'In use'
			BEGIN
			--SELECT 'A'
				SET @PEEventStatus =	(
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'Dirty'
										)
				SET @DestTransitionEDPPID = @CurrentTransitionEDPPID
				GOTO PROCESS_EVENT
			END
			-----------------------------------------------------------------------------------------------------------------------
			-- GCAS MOVED OUT OF MAKING
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentTransitionEDPPID = @CurrentPositionPPId AND  COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'In use'
			BEGIN
			--SELECT 'A'
				SET @PEEventStatus =	(
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'In use'
										)
				SET @DestTransitionEDPPID = @CurrentTransitionEDPPID
				GOTO PROCESS_EVENT
			END

			-----------------------------------------------------------------------------------------------------------------------
			-- DIRTY APPLIANCE MOVED TO MAKING - IMPOSSIBLE
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentPositionPPId IS NULL AND COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'Dirty'
			BEGIN
				--SELECT 'B'
				SET @PEEventStatus =	(
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'Dirty'
										)
				SET @DestTransitionEDPPID = @CurrentTransitionEDPPID
				GOTO PROCESS_EVENT
			END
			-----------------------------------------------------------------------------------------------------------------------
			-- DIRTY APPLIANCE MOVED OUT OF MAKING
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentPositionPPId IS NOT NULL AND COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'Dirty'
			BEGIN						
				--SELECT 'C'
				SET @PEEventStatus =	(				
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'Dirty'
										)
					SET @DestTransitionEDPPID = @CurrentTransitionEDPPID
					GOTO PROCESS_EVENT
			END

			SET @AppliedProductId =
			(
			SELECT	PROD_ID 
			FROM	dbo.Production_plan WITH(NOLOCK) 
			WHERE	PP_ID = @CurrentTransitionEDPPID
			)
	PROCESS_EVENT:


			SET @PETransactionType				= 1
			SET @PEEventId						= NULL	
			SET @PEEventNum						=	CAST(Datepart(Year,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Month,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Day,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Hour,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Minute,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Second,@Now) AS VARCHAR(10)) 
			SET @PEPUId							= @LocationId
			SET @PETimestamp					= DATEADD(Second,1,@now)
			SET @PETimestamp					= DATEADD(millisecond,-Datepart(millisecond,@Now), @PETimestamp) 
			SET @PEAppliedProduct				= (SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @DestTransitionEDPPID)
			SET @PESourceEvent					= NULL
			--SET @PEEventStatus					= NULL
			SET @PEUpdateType					= 0 --Pre Update, 1 would be post update typically used with hot add
			SET @PEConformance					= 0
			SET @PETestPctComplete				= 0
			SET @PEStartTime					= DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
			SET @PETransNum						= 0 -- Update only non null fields
			SET @PETestingStatus				= NULL
			SET @PECommentId					= NULL
			SET @PEEventSubtypeId				= NULL
			SET @PEEntryOn						= GETDATE()
			SET @PEApprovedUserId				= NULL
			SET @PESecondUserID					= NULL
			SET @PEApprovedReasonId				= NULL
			SET @PEUserReasonId					= NULL
			SET @PEUserSignOffId				= NULL
			SET @PEExtendedInfo					= NULL
			SET @PESignatureId					= NULL
			/*
			INSERT INTO @RSEvents
			(
			PETransactionType, PEEventId, PEEventNum,PEPUId, PETimeStamp, PEAppliedProduct, PESourceEvent, PEEventStatus, PEConfirmed,
			PEUserId, PEUpdateType, PEConformance, PETestPctComplete, PEStartTime, PETransNum, PETestingStatus, PECommentId, PEEventSubtypeId,
			PEEntryOn, PEApprovedUserID, PESecondUserID, PEApprovedReasonID,  PEUserReasonID, PEUserSignOffID, PEExtendedInfo, PESignature
			)
			VALUES
			(
			@PETransactionType, @PEEventId, @PEEventNum, @PEPUId ,@PETimestamp, @PEAppliedProduct, @PESourceEvent, @PEEventStatus, @PEConfirmed, @RSUserId,
			@PEUpdateType, @PEConformance, @PETestPctComplete, @PEStartTime, @PETransNum, @PETestingStatus, @PECommentId, @PEEventSubtypeId, @PEEntryOn, 
			@PEApprovedUserID, @PESecondUserID, @PEApprovedReasonID, @PEUserReasonID, @PEUserSignOffID, @PEExtendedInfo, @PESignatureId
			)
			select * from pendingtasks
			*/
			-----------------------------------------------------------------------------------------------------------------------
			-- CREATE PRODUCTION EVENT AT DESTINATION - HOT ADD
			-----------------------------------------------------------------------------------------------------------------------
	
			EXEC @RC = [dbo].[spServer_DBMgrUpdEvent] 
			@PEEventId OUTPUT, --EVENT_ID
			@PEEventNum,	-- EVENT_NUM
			@PEPUId,		--PU_ID
			@PETimestamp,	--TIMESTAMP
			@AppliedProductId,--APPLIED_PRODUCT
			NULL,			--SOURCE_EVENT
			@PEEventStatus,	--EVENT_STATUS
			1,				--TTYPE
			0,				--TNUM
			@RSUserId,		--USER_ID
			NULL,			--COMMENT_ID
			NULL,			--EVENT_SUBTYPE_ID
			NULL,			--TESTING_STATUS
			@PEStartTime,			--START_TIME
			NULL,			--ENTRY_ON
			0,				--RETURN RESULT SET 
			@PEConformance,			--CONFORMANCE
			@PETestPctComplete,			--TESTPCTCOMPLETE
			NULL,			--SECOND USER ID
			NULL,			--APPROVER USER ID
			NULL,			--USER Reason Id
			NULL,			--USER SIGN OFF ID
			NULL,			--EXTENDED_INFO
			NULL,			--SEND EVENT POST
			0,				--SIGNATURE ID
			NULL,			--LOT INDENTIFIER
			NULL			--FRIENDYOPERATIONNAME

			-- IF PO IS NOT STARTED AT DESTINATION, START IT

			-- GET THE LAST POSITION OF THE APPLIANCE TO CLOSE IT
			DECLARE @lastLocationTransEventId INTEGER
			SET @lastLocationTransEventId =(SELECT top 1	E.event_id 
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events e WITH(NOLOCK)
															ON e.event_id = EC.event_id
											WHERE			EC.source_event_id = @ThisEventId  
															AND E.timestamp < @PEStartTime ORDER By E.timestamp desc
											)
			IF @lastLocationTransEventId IS NOT NULL
			BEGIN
					--SELECT @lastLocationTransEventId,@PEEventNum,@PETimestamp,@AppliedProductId,@PEEventStatus,@RSUserId,@PEStartTime
					SELECT 
					@PEEventNum = event_num,
					@PEPUId= pu_Id,
					@PETimestamp = @PEStartTime,
					@AppliedProductId = Applied_product,
					@PEEventStatus = @PEEventStatus,
					@RSUserId = user_id,
					@PEStartTime = start_time,
					@PEConformance = 0,
					@PETestPctComplete = 0
					FROM dbo.events WITH(NOLOCK) WHERE event_id = @lastLocationTransEventId

					EXEC @RC = [dbo].[spServer_DBMgrUpdEvent] 
					@lastLocationTransEventId OUTPUT, --EVENT_ID
					@PEEventNum, 	-- EVENT_NUM
					@PEPUId,		--PU_ID
					@PETimestamp,	--TIMESTAMP
					@AppliedProductId,--APPLIED_PRODUCT
					NULL,			--SOURCE_EVENT
					@PEEventStatus,	--EVENT_STATUS
					2,				--TTYPE
					0,				--TNUM
					@RSUserId,		--USER_ID
					NULL,			--COMMENT_ID
					NULL,			--EVENT_SUBTYPE_ID
					NULL,			--TESTING_STATUS
					@PEStartTime,			--START_TIME
					NULL,			--ENTRY_ON
					0,				--RETURN RESULT SET 
					@PEConformance,			--CONFORMANCE
					@PETestPctComplete,			--TESTPCTCOMPLETE
					NULL,			--SECOND USER ID
					NULL,			--APPROVER USER ID
					NULL,			--USER Reason Id
					NULL,			--USER SIGN OFF ID
					NULL,			--EXTENDED_INFO
					NULL,			--SEND EVENT POST
					0,				--SIGNATURE ID
					NULL,			--LOT INDENTIFIER
					NULL			--FRIENDYOPERATIONNAME
			END
			
			IF @PEEventId IS NOT NULL AND @ProcessOrderId IS NOT NULL
			BEGIN
				-----------------------------------------------------------------------------------------------------------------------
				--  WRITE IN PRODUCTION PLAN IF NEEDED
				-----------------------------------------------------------------------------------------------------------------------			
				DECLARE 
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
				@PPExtendedInfo  				VARCHAR(255)
		
				SET @ActivePPStatusId =			(
											SELECT	PP_Status_Id 
											FROM	dbo.Production_Plan_Statuses WITH(NOLOCK)
											WHERE	PP_Status_Desc = 'Active'
											)
				SET @CompletePPStatusId =			(
											SELECT	PP_Status_Id 
											FROM	dbo.Production_Plan_Statuses WITH(NOLOCK)
											WHERE	PP_Status_Desc = 'Complete'
											)


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
				@PPUserId						= @RSUserId,
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
				@PPTransactionTime				= @Now,
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
				WHERE	PP_ID = @ProcessOrderId

				IF @DestinationPPId IS NULL AND @PPStatusId NOT IN(@ActivePPStatusId,@CompletePPStatusId)
				BEGIN
					-- ALL UNIT RUN SIMULATANOUSLY, THERE IS NOT NEED TO INSERT IN PRODUCTION_PLAN_STARTS
					EXEC @RC =	[dbo].[spServer_DBMgrUpdProdPlan]
								@PPId ,							
								@PPTransType,												
								@PPTransNum,											
								@Pathid,										
								@PPCommentId,											
								@PPProdId,													
								@PPImpliedSequence,											
								@ActivePPStatusId,									
								@PPTypeId,
								@PPSourcePPId,
								@PPUserId,
								@PPParentPPId,
								@PPControlType,
								@PPForecastStartTime,
								@PPForecastEndTime,
								@PPEntryOn OUTPUT,
								@PPForecastQuantity,
								@PPProductionRate,
								@PPAdjustedQuantity,
								@PPBlockNumber,
								@PPProcessOrder,
								@PPTransactionTime,
								@PPMisc1,
								@PPMisc2,
								@PPMisc3,
								@PPMisc4,
								@PPBOMFormulationId,
								@PPUserGeneral1,
								@PPUserGeneral2,
								@PPUserGeneral3,
								@PPExtendedInfo

				END
				-----------------------------------------------------------------------------------------------------------------------
				-- CREATE EVENT COMPONENT BETWEEN APPLIANCE PE AND TRANSITION PE CREATED ABOVE - HOT ADD
				-----------------------------------------------------------------------------------------------------------------------
				/*IF (
					SELECT TOP 1	E.pu_id 
					FROM			dbo.event_components EC WITH(NOLOCK)
					JOIN			dbo.events E WITH(NOLOCK)
										ON E.event_id = EC.event_id
					WHERE			Source_Event_Id = @ThisEventId
					) <> @LocationId
				BEGIN
*/					EXEC @RC = spServer_DBMgrUpdEventComp
					@RSUserId,						--USER_ID
					@PEEventId,						--EVENT_ID
					@ECComponentId OUTPUT,			--ECID
					@ThisEventId,					--SOURCE_EVENT_ID
					NULL,							-- DIMX	
					NULL,							-- DIMY
					NULL,							-- DIMZ
					NULL,							-- DIMA
					0,								-- TRANSACTION NUMBER	
					1,								-- TRANSACTION TYPE
					NULL,							--CHILUNIT_ID
					NULL,							--START COOR X
					NULL,							--START COOR Y
					NULL,							--START COOR Z
					NULL,							--START COOR a
					NULL,							--START TIME
					@Now,							--TIMESTAMP
					NULL,							--PARENT COMP ID	
					@ECEntryOn	OUTPUT,				--ENTRY ON
					NULL,							--ENTENDED INFO
					NULL,							--PEI ID
					NULL,							--REPORT AS CONS
					NULL,							--SIG ID
					NULL							--RETURN RESULT SET
 			

					INSERT INTO @RSEventComponents(
					ECPre,
					ECUserId,
					ECTransactionType,
					ECTransactionNumber,
					ECComponentId,
					ECEventId,
					ECSrcEventId,
					ECDimX,
					ECDimY,
					ECDimZ,
					ECDimA,
					ECStartCoordinateX, 
					ECStartCoordinateY, 
					ECStartCoordinateZ, 
					ECStartCoordinateA,
					ECStartTime, 
					ECTimeStamp, 
					ECPPComponentId, 
					ECEntryOn, 
					ECExtendedInfo,
					ECPEIId,
					ECReportAsConsumption,
					ECChildunitId,
					ECESignatureId
					)
					VALUES
					(
					0,						--ECPre
					@RSuserId,				--ECUserId
					1,						--ECTransactionType
					0,						--ECTransactionNumber
					NULL,					--ECComponentId
					@PEEventId,				--ECEventId
					@ThisEventId,			--ECSrcEventId
					NULL,					--ECDimX
					NULL,					--ECDimY
					NULL,					--ECDimZ
					NULL,					--ECDimA
					NULL,					--ECStartCoordinateX
					NULL,					--ECStartCoordinateY
					NULL,					--ECStartCoordinateZ 
					NULL,					--ECStartCoordinateA
					NULL,					--ECStartTime
					@Now,					--ECTimeStamp 
					NULL,					--ECPPComponentId 
					@ECEntryOn,				--ECEntryOn
					NULL,					--ECExtendedInfo
					NULL,					--ECPEIId
					NULL,					--ECReportAsConsumption
					NULL,					--ECChildunitId
					NULL					--ECESignatureId
					)
			--	END
				-----------------------------------------------------------------------------------------------------------------------
				-- CREATE EVENT DETAILS					
 				-----------------------------------------------------------------------------------------------------------------------
				IF NOT EXISTS(SELECT event_id FROM dbo.event_details WITH(NOLOCK) WHERE event_id = @PEEventId) 
				BEGIN 
				-- DETERMINE THE PP_ID
				-- IF PP_ID ON CURRENT POSITION IS SET THEEN KEEP IT
				-- IF PP_ID IS NOT SET ON CURRENT POSITION THEN SET IT TO LOCATION'S
				
					SET @EDProductionPlanId = @CurrentTransitionEDPPID
					 
					-----------------------------------------------------------------------------------------------------------------------
 					-- GET EVENT DETAILS INFORMATION
					-----------------------------------------------------------------------------------------------------------------------
		
					SET @PETimestamp = DATEADD(Second,1,@now)

					EXEC @RC = [dbo].[spServer_DBMgrUpdEventDet] 
					@RSUserId,					-- USER_ID
					@PEEventId,					-- EVENT_ID
					@PEPUId,					-- PU_ID
					NULL,						-- FUTURE1
					1,							-- TTYPE
					0,							-- TNUM
					NULL,						-- AEN
					NULL,						-- FUTURE2
					NULL,						-- IDX
					NULL,						-- IDY
					NULL,						-- IDZ
					NULL,						-- IDA
					NULL,						-- FDX
					NULL,						-- FDY
					NULL,						-- FDZ
					NULL,						-- FDA
					NULL,						-- ODX
					NULL,						-- ODY
					NULL,						-- ODZ
					NULL,						-- FUTURE3
					NULL,						-- FUTURE4
					NULL,						-- ORDERID
					NULL,						-- ORDERLINEID
					@CurrentTransitionEDPPID,	-- PPID
					NULL,						-- PPSETUPDETAILID
					NULL,						-- SHIPMENTID
					NULL,						-- COMMENTID
					@Now,						-- ENTRYON
					@PETimestamp,				-- TIMESTANP
					NULL,						-- FUTURE6
					NULL,						-- SIGNATUREID
					NULL						-- PRODUCTDEFID

					-- FOR RESULT SET
					SELECT		@EDEventId =						E.event_id,
								@EDUnitId	=						E.PU_id,
								@EDPrimaryEventNumber =				E.Event_Num,
								@EDAlternateEventNumber =			ED.Alternate_Event_Num,		
								@EDCommentId =						ED.Comment_Id,
								@EDEventSubTypeId =					E.Event_Subtype_Id,
								@EDOriginalProduct =				PPS.Prod_Id,
								@EDAppliedProduct =					(SELECT prod_id FROM dbo.Production_plan WITH(NOLOCK) WHERE PP_ID = @EDProductionPlanId),
								@EDEventStatus =					E.Event_Status,
								@EDTimestamp =						E.TimeStamp,
								@EDEntryOn =						Entry_On,
								@EDPPSDId =							ED.PP_Setup_Detail_Id,
								@EDOrderId =						ED.Order_Id,
								@EDOrderLineId =					ED.Order_Line_Id,
								@EDProductionPlanId =				@EDProductionPlanId,
								@EDInitialDimensionX =				ED.Initial_Dimension_X,
								@EDInitialDimensionY =				ED.Initial_Dimension_Y,
								@EDInitialDimensionZ =				ED.Initial_Dimension_Z,
								@EDInitialDimensionA =				ED.Initial_Dimension_A,
								@EDFinalDimensionX =				ED.Final_Dimension_X,
								@EDFinalDimensionY =				ED.Final_Dimension_Y,	
								@EDFinalDimensionZ =				ED.Final_Dimension_X,
								@EDFinalDimensionA =				ED.Final_Dimension_A,
								@EDOrientationX =					ED.Orientation_X,
								@EDOrientationY =					ED.Orientation_Y,
								@EDOrientationZ =					ED.Orientation_Z,
								@EDOrientationA =					ED.Orientation_A,
								@EDESignature =						ED.Signature_Id
					FROM		dbo.Events E WITH(NOLOCK) 
								LEFT JOIN dbo.event_Details ED WITH(NOLOCK) 
									ON ED.event_id = E.event_id
								LEFT JOIN dbo.production_starts PPS WITH(NOLOCK) 
									ON PPS.pu_id = E.pu_id 
									AND	E.Timestamp >= PPS.start_time 
									AND	(E.timestamp < PPS.end_time OR PPS.end_time IS NULL)
					WHERE		E.event_id = @PEEventId			
					INSERT INTO @RSEventDetails
					(	
						ED_Update_Type,
						ED_User_Id,
						ED_Transaction_Type,
						ED_Transaction_Number,
						ED_Event_Id,
						ED_Unit_Id,
 						ED_Primary_Event_Number,
						ED_Alternate_Event_Number,
						ED_Comment_Id,
						ED_Event_Sub_Type_Id,
						ED_Original_Product,
						ED_Applied_Product,
						ED_Event_Status,
						ED_Timestamp,
						ED_Entry_On,
						ED_PP_SD_Id,
						ED_Order_Id,
						ED_Order_Line_Id,
						ED_Production_Plan_Id,
						ED_Initial_Dimension_X,
						ED_Initial_Dimension_Y,
						ED_Initial_Dimension_Z,
						ED_Initial_Dimension_A,
						ED_Final_Dimension_X,
						ED_Final_Dimension_Y,
						ED_Final_Dimension_Z,
						ED_Final_Dimension_A,
						ED_Orientation_X,
						ED_Orientation_Y,
						ED_Orientation_Z,
						ED_Orientation_A,
						ED_ESignature
					)
					VALUES
					(	
						0,															-- Update_type	
						@RSUserId,													-- User_Id	
						1,															-- ED_Transaction_Type
						0,															-- ED_Transaction_Number
						@EDEventId,													-- ED_Event_Id
						@EDUnitId,													-- PU_ID
						@EDPrimaryEventNumber,										-- Event_num																			
						@EDAlternateEventNumber,									-- AEN
						@EDCommentId,												-- Comment_Id
						@EDEventSubTypeId,											-- Event_Sub_Type_Id
						@EDOriginalProduct,											-- Original_Product
						@EDAppliedProduct,											-- Applied_Product
						@EDEventStatus,												-- Event_Status
						@EDTimestamp,												-- Timestamp
						@EDEntryOn,													-- Entry_On
						@EDPPSDId,													-- Production_Plan_Setup_Detail_Id
						@EDOrderId,													-- Order_Id
						@EDOrderLineId,												-- Order_Line_Id
						@EDProductionPlanId,										-- Production_Plan_Id
						@EDInitialDimensionX,										-- Initial_Dimension_X,
						@EDInitialDimensionY,										-- Initial_Dimension_Y,
						@EDInitialDimensionZ,										-- Initial_Dimension_Z,
						@EDInitialDimensionA,										-- Initial_Dimension_A,
						@EDFinalDimensionX,											-- Final_Dimension_X
						@EDFinalDimensionY,											-- Final_Dimension_Y
						@EDFinalDimensionZ,											-- Final_Dimension_Z
						@EDFinalDimensionA,											-- Final_Dimension_A
						@EDOrientationX,											-- Orientation_X
						@EDOrientationY,											-- Orientation_A
						@EDOrientationZ,											-- Orientation_A
						@EDOrientationA,											-- Orientation_A
						@EDESignature												-- ESignature
					)

				END						-- EVENT DETAILS

				-- WRITE IN VALIDATATION RESULT THE VALUE EXECUTED
				SET @MovementvalidationVarId =
				(SELECT VAR_ID FROM dbo.variables_Base WITH(NOLOCK) WHERE PU_ID = @AppliancePUId AND test_name = 'Movement validation')


				SET @Movementvalidation = 
				(SELECT result FROM dbo.tests WITH(NOLOCK) WHERE var_id = @MovementvalidationVarId AND result_on = @ApplianceIdTimestamp)

				IF @Movementvalidation <> 'Executed'
				BEGIN

					INSERT INTO @RSVariables
					(
						VUVarId,
						VUPUId,
						VUUserId,	
						VUCanceled,	
						VUResult,		
						VUResultOn,			
						VUTransactionType,	
						VUPostUpdate,
						VUSecondUserId,
						VUTransNum,
						VUEventId,
						VUArrayId,
						VUCommentId,
						VUESignature
					)
					VALUES
					(
						@MovementvalidationVarId,
						@AppliancePUId,
						@RSUserId,
						0,
						'Executed',
						@ApplianceIdTimestamp,
						2,
						0,
						NULL,
						0,
						@ThisEventId,
						NULL,
						NULL,
						NULL
					)
				END

	


				IF EXISTS(SELECT 1 FROM @RSEvents) 
					SELECT 1,* FROM @RSEvents
				IF EXISTS(SELECT 1 FROM @RSVariables) 
					SELECT 2,* FROM @RSVariables
				IF EXISTS(SELECT 1 FROM @RSEventDetails) 
					SELECT 10,* FROM @RSEventDetails
				IF EXISTS(SELECT 1 FROM @RSEventComponents) 
					SELECT 11,* FROM @RSEventComponents				
				SET @Output = 'Moved'
				RETURN

			END -- EVEN CREATED





		END 		-- AT POSIITON
		ELSE		-- AT POSIITON
		BEGIN		-- AT POSIITON
			SET @Output = 'Already at position'
		END			-- AT POSIITON




	
	
	END				-- CONDITIONS
			-- CONDITIONS
	
--=====================================================================================================================
	SET NOCOUNT OFF
--=====================================================================================================================


END -- BODY

GRANT EXECUTE ON [dbo].[spLocal_CTS_Set_Location_CalcMgr] TO ctsWebService
GRANT EXECUTE ON [dbo].[spLocal_CTS_Set_Location_CalcMgr] TO comxclient





