
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Set_Location
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-11-18
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Called by Web app
-- Description			: Set the location of an appliance from Web app
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-11-18		F. Bergeron				Initial Release 
-- 1.1		2022-02-18		F. Bergeron				Modify event time for consistency 
--													PE created WITH Start_time = GETDATE - MS and TIMESTAMP = START_TIME + 1 second 
--													EC TIMESTAMP IS SET TO PE START_TIME
--													ED TIMESTAMP IS SET TO PE TIMESTAMP
--													PPS START_TIME IS SET TO PE STARTIME
-- 1.2		2022-02-21		F. Bergeron				Set the start time of the previous CTS Location Transition event (For reporting purposes)
-- 1.3		2022-03-18		F. Bergeron				Add validation if record already exists in production plan starts
-- 1.4		2022-04-06		F. Bergeron				Status update staging
-- 1.5		2023-01-31		U. Lapierre				Include process order change in transition staging
-- 1.6		2023-07-13		U.Lapierre				CONF-34253.  FIx issue when we move PPW material out of Making and no PPID id assign (trap NULL)
-- 1.7		2023-08--4		K. Michel				Module Desc changed from CTS to CST
--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
DECLARE 
	@OutputStatus				INTEGER,
	@OutputMessage				VARCHAR(500)
EXECUTE spLocal_CTS_Set_Location
	1304645,
	10415,
	16268,
	1596,
	@OutputStatus OUTPUT,
	@OutputMessage  OUTPUT
	SELECT @OutputStatus
	SELECT @OutputMessage
*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Set_Location]
	@ApplianceEventId			INTEGER,
	@LocationId					INTEGER,
	@ProcessOrderId				INTEGER,
	@UserId						INTEGER,
	@OutputStatus				INTEGER OUTPUT,
	@OutputMessage				VARCHAR(500) OUTPUT




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
	@Movementvalidation					VARCHAR(50),
	@AppliancePuId						INTEGER,
	@CurrentPosition					INTEGER,
	@CurrentPositionPPId				INTEGER,
	@DestinationPPId					INTEGER,
	@CurrentTransitionEventId			INTEGER,
	@CurrentTransitionStatusId			INTEGER,
	@CurrentTransitionStatusDesc		VARCHAR(25),
	@CurrentPositionTimestamp			DATETIME,
	@CurrentPositionStartTime			DATETIME,
	@CurrentTransitionEDPPID			INTEGER,
	@DestTransitionEDPPID				INTEGER,
	@CurrentTransitionReuse				INTEGER,
	@AppliedProductId					INTEGER,
	@DebugFlag							INTEGER,
	@SPName								VARCHAR(250),
	@LastLocationTransEventId			INTEGER,
	@CTSApplianceHoldsMaterialId		INTEGER,
	@ProdUnitsTableId					INTEGER,
	@ApplianceHoldMaterial				INTEGER,
	@CTSApplianceTypeId					INTEGER,
	@ApplianceType						VARCHAR(50)
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
	@PEExtendedInfo						NVARCHAR(255),
	@PESignatureId						INTEGER


	DECLARE
	@LastPETransactionType					INTEGER,
	@LastPEEventId							INTEGER,
	@LastPEEventNum							VARCHAR(25),
	@LastPEPUId								INTEGER,
	@LastPETimestamp						DATETIME,
	@LastPEAppliedProduct					INTEGER,
	@LastPESourceEvent						INTEGER,
	@LastPEEventStatus						INTEGER,
	@LastPEConfirmed						INTEGER,
	@LastPEUpdateType						INTEGER,
	@LastPEConformance						INTEGER,
	@LastPETestPctComplete					INTEGER,
	@LastPEStartTime						DATETIME,
	@LastPETransNum							INTEGER,
	@LastPETestingStatus					INTEGER,
	@LastPECommentId						INTEGER,
	@LastPEEventSubtypeId					INTEGER,
	@LastPEEntryOn							DATETIME,
	@LastPEApprovedUserId					INTEGER,
	@LastPESecondUserID						INTEGER,
	@LastPEApprovedReasonId					INTEGER,
	@LastPEUserReasonId						INTEGER,
	@LastPEUserSignOffId					INTEGER,
	@LastPEExtendedInfo						VARCHAR(255),
	@LastPESignatureId						INTEGER,
	@LastPEUserId							INTEGER

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


	DECLARE @MoveEval TABLE 
	(
		O_Status	INTEGER, -- -1 (REJECTED), 0(ACTION REQUIRED), 1 (ACCEPTED)
		O_Message	VARCHAR(500)
	)


	SET @SPName =		'spLocal_CTS_Set_Location'
	SET @DebugFlag =	(SELECT CONVERT(INT,sp.value) 
						FROM	dbo.site_parameters sp WITH(NOLOCK)
								JOIN dbo.parameters p WITH(NOLOCK)		
									ON sp.parm_Id = p.parm_id
						WHERE	p.parm_Name = 'PG_CTS_StoredProcedure_Log_Level')
	IF @DebugFlag IS NULL
		SET @DebugFlag = 0
	-----------------------------------------------------------------------------------------------------------------------
	-- SP BODY
	-----------------------------------------------------------------------------------------------------------------------
	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				1,
				'SP Started:'  + 
				' Appliance EventId: ' + CONVERT(varchar(30), COALESCE(@ApplianceEventId, 0)) + 
				' Location Puid: ' + CONVERT(varchar(30), COALESCE(@LocationId, 0)) + 
				' ProcessOrderId: ' + CONVERT(varchar(30),COALESCE(@ProcessOrderId, 0)) + 
				' User Id: ' + CONVERT(varchar(30),COALESCE(@UserId,0)),
				@ApplianceEventId	)
	END
	-------------------------------------------------------------------------------
	-- GET TABLE FIELDS
	-------------------------------------------------------------------------------
	SET @ProdUnitsTableId	= (SELECT tableId FROM dbo.tables WITH(NOLOCK) WHERE tableName = 'Prod_units')	
	SET @CTSApplianceHoldsMaterialId = (SELECT table_field_id FROM dbo.table_fields WITH(NOLOCK) WHERE tableID = @ProdUnitsTableId AND Table_field_desc = 'CTS appliance holds material')
	SET @CTSApplianceTypeId = (SELECT table_field_id FROM dbo.table_fields WITH(NOLOCK) WHERE tableID = @ProdUnitsTableId AND Table_field_desc = 'CTS appliance type')
	-----------------------------------------------------------------------------------------------------------------------
	-- RUN EVALUATION BEFORE MOVE
	-----------------------------------------------------------------------------------------------------------------------													
	
	INSERT INTO @MoveEval
	(
	O_Status,
	O_Message
	)
	EXECUTE spLocal_CTS_Evaluate_Appliance_Movement	@ApplianceEventId,
													@locationId,
													@ProcessOrderId,
													@UserId



	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				2,
				'Move evaluation status = ' + CAST((SELECT O_status FROM @MoveEval) AS VARCHAR(25)),
				@ApplianceEventId)
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				3,
				'Move evaluation message = ' + (SELECT O_message FROM @MoveEval),
				@ApplianceEventId)
	END

	-----------------------------------------------------------------------------------------------------------------------
	IF (SELECT O_Status FROM @MoveEval) = 1 	-- EVALUATION IF
	-----------------------------------------------------------------------------------------------------------------------
	BEGIN

		SET @Now = GETDATE()
	
		-----------------------------------------------------------------------------------------------------------------------
		-- EVALUATE CONDITIONS TO REGISTER THE MOVEMENT
		-----------------------------------------------------------------------------------------------------------------------
		SET @ApplianceIdTimestamp =		(
										SELECT	Timestamp 
										FROM	dbo.events WITH(NOLOCK) 
										WHERE	event_id = @ApplianceEventId
										)		

		SET @AppliancePUId =			(
										SELECT	pu_id 
										FROM	dbo.events WITH(NOLOCK) 
										WHERE	event_id = @ApplianceEventId
										)	

		SET @ApplianceHoldMaterial =	(
										SELECT	tfv.value 
										FROM	dbo.Table_Fields_Values TFV WITH(NOLOCK)
												JOIN dbo.prod_units_base PUB WITH(NOLOCK)
												ON PUB.pu_id = TFV.KeyId
										WHERE	TFV.TableId = @ProdUnitsTableId 
												AND TFV.Table_Field_Id = @CTSApplianceHoldsMaterialId
												AND PUB.pu_id = @AppliancePUId
										)

		SET @ApplianceType =			(
										SELECT	tfv.value 
										FROM	dbo.Table_Fields_Values TFV WITH(NOLOCK)
												JOIN dbo.prod_units_base PUB WITH(NOLOCK)
												ON PUB.pu_id = TFV.KeyId
										WHERE	TFV.TableId = @ProdUnitsTableId 
												AND TFV.Table_Field_Id = @CTSApplianceTypeId
												AND PUB.pu_id = @AppliancePUId
										)
			

		-----------------------------------------------------------------------------------------------------------------------
		-- GET CURRENT APPLIANCE TRANSITION INFO
		-----------------------------------------------------------------------------------------------------------------------
		SELECT TOP 1	@CurrentTransitionEventId = E.Event_Id,
						@CurrentPositionTimestamp = E.timestamp,
						@CurrentPositionStartTime = E.Start_time,
						@CurrentPosition = E.pu_id,
						@CurrentTransitionEDPPID = ED.PP_Id,
						@CurrentTransitionStatusId	= E.Event_Status,
						@CurrentTransitionStatusDesc = PS.ProdStatus_Desc,
						@CurrentTransitionReuse = TFV.value
		FROM			dbo.event_components EC WITH(NOLOCK) 
						JOIN dbo.events E WITH(NOLOCK) 
							ON E.event_id = EC.event_id 
						LEFT JOIN dbo.event_details ED WITH(NOLOCK)
							ON ED.event_id = E.event_id
						JOIN dbo.Production_status PS WITH(NOLOCK) 
							ON PS.ProdStatus_Id = E.Event_Status
						LEFT JOIN dbo.Table_Fields_Values TFV WITH(NOLOCK)	
							ON TFV.KeyId = E.PU_Id AND TFV.tableID = @ProdUnitsTableId 
						AND  TFV.Table_Field_Id = (SELECT Table_Field_Id FROM dbo.table_fields WHERE tableID = 43 and Table_Field_Desc ='CTS Reuse appliance - '+ @ApplianceType)
		WHERE			EC.Source_event_id = @ApplianceEventId 
		ORDER BY		EC.Timestamp DESC

		-----------------------------------------------------------------------------------------------------------------------
		-- GET CURRENT APPLIANCE TRANSITION LOCATION INFO @CurrentPosition
		-----------------------------------------------------------------------------------------------------------------------	
		-- PPID (PPSTARTS) AT THE POSITION WHERE THE APPLIANCE IS INITIALLY LOCATED
		-- MUST GET THE PO WAS ACTIVE AT THE LOCATION WHEN THE APPLIANCE WAS MOVED IN OR STARTED AFTER IT WAS MOVED IN

		-- MUST GET THE PREVIOUS CLOSEST AND NEXT CLOSEST PO AT LOCATION
		
		--PROCESS ORDER ACTIVE WHEN THE APPLIANCE AT THE LOCATION OR ACTIVATED WHILE THE APPLIANCE WHAS IN THE LOCATION
		SET @CurrentPositionPPId =			(
											SELECT TOP 1	PP_ID 
											FROM			dbo.production_plan_starts WITH(NOLOCK) 
											WHERE			PU_id = @CurrentPosition 
															AND (Start_Time <= @CurrentPositionTimestamp) 
															AND (COALESCE(End_time,GETDATE()) >= @CurrentPositionStartTime)
															ORDER BY Start_Time DESC)
											


		SET @DestinationPPId =				(
											SELECT			PP_ID 
											FROM			dbo.production_plan_starts WITH(NOLOCK) 
											WHERE			PU_id = @LocationId 
															AND end_time IS NULL
											)		
		SET @AppliedProductId =				(
											SELECT			PROD_ID 
											FROM			dbo.Production_plan WITH(NOLOCK) 
											WHERE			PP_ID = @CurrentTransitionEDPPID
											)


		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					4,
					'Parameters:'  + 
					' @CurrentPosition: ' + CONVERT(varchar(30), COALESCE(@CurrentPosition, 0)) + 
					' @CurrentPositionTimestamp: ' + CONVERT(varchar(30), @CurrentPositionTimestamp,120) + 
					' @CurrentTransitionEDPPID: ' + CONVERT(varchar(30),COALESCE(@CurrentTransitionEDPPID, 0)) + 
					' @CurrentPositionPPId: ' + CONVERT(varchar(30),COALESCE(@CurrentPositionPPId, 0)),
					@ApplianceEventId)

			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					5,
					'Parameters:' + 
					' @CurrentTransitionEventId: ' + CONVERT(varchar(30),COALESCE(@CurrentTransitionEventId, 0)) + 
					' @CurrentTransitionStatusId: ' + CONVERT(varchar(30),COALESCE(@CurrentTransitionStatusId, 0)) + 
					' @CurrentTransitionStatusDesc: ' + COALESCE(@CurrentTransitionStatusDesc, '') + 
					' @DestinationPPId: ' + CONVERT(varchar(30),COALESCE(@DestinationPPId, 0)) + 
					' @AppliedProductId: ' + CONVERT(varchar(30),COALESCE(@AppliedProductId, 0)),
					@ApplianceEventId)
		END
		-----------------------------------------------------------------------------------------------------------------------
		IF	COALESCE(@CurrentPosition,0) <> @LocationId		-- LOCATION HAS CHANGED
		-----------------------------------------------------------------------------------------------------------------------
		BEGIN
			IF @DebugFlag >=2
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
						@SPName,
						10,
						'New location = ' + CAST(@LocationId AS VARCHAR(25)),
						@ApplianceEventId)
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
						@SPName,
						11,
						'Current location = ' + CAST(@CurrentPosition AS VARCHAR(25)),
						@ApplianceEventId
						)
				
			
			END
			-----------------------------------------------------------------------------------------------------------------------
			-- GET THE USER WHO CHANGED THE LOCATION
			-----------------------------------------------------------------------------------------------------------------------
			SET	@RSUserId =	@UserId

			-----------------------------------------------------------------------------------------------------------------------
			-- DETERMINE STATUS AND PP_ID OF NEW LOCATION TRANSITION TO CREATE
			-----------------------------------------------------------------------------------------------------------------------			
			-----------------------------------------------------------------------------------------------------------------------
			-- APPLIANCE IS INITIALLY LOCATED IN A NON MAKING LOCATION (@CurrentPositionPPId IS NULL) AND THE APPLIANCE WAS CLEAN
			-- NEW STATUS REMAINS WHAT IT WAS 
			-----------------------------------------------------------------------------------------------------------------------	
			IF @CurrentPositionPPId IS NULL AND COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'Clean'  
			BEGIN
				SET @PEEventStatus =	(
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'Clean'
										)
				SET @DestTransitionEDPPID = NULL




				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
						@SPName,
						40,
						'Appliance status is [Clean] and current position is not making' ,
						@ApplianceEventId	)
				END
	
				GOTO PROCESS_EVENT
			END

			-----------------------------------------------------------------------------------------------------------------------		
			-- CLEAN APPLIANCE MOVED OUT OF MAKING
			-- CHANGE STATUS TO IN USE
			-- SET PP_ID OF THE NEW LOCATION TRANSITION TO THE PP_ID OF THE CURRENTY LOCATION OF THE APPLIANCE (THIS SHOULD NOT MATTER)
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentPositionPPId IS NOT NULL AND COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'Clean'  
			BEGIN
				IF @ApplianceHoldMaterial = 1
				BEGIN
					SET @PEEventStatus =	(
											SELECT			ProdStatus_Id
											FROM			dbo.Production_status WITH(NOLOCK) 
											WHERE			ProdStatus_Desc = 'In Use'
											)
					SET @DestTransitionEDPPID = @CurrentPositionPPId -- SHOULD BE NULL
				END
				ELSE
				BEGIN
					SET @PEEventStatus =	(
											SELECT			ProdStatus_Id
											FROM			dbo.Production_status WITH(NOLOCK) 
											WHERE			ProdStatus_Desc = 'Dirty'
											)
					SET @DestTransitionEDPPID = @CurrentPositionPPId -- SHOULD BE NULL
				END


				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
						@SPName,
						41,
						'Appliance status is [Clean] and current position is making, new status is [In use]' ,
						@ApplianceEventId	)
				END

				GOTO PROCESS_EVENT
			END
			-----------------------------------------------------------------------------------------------------------------------
			-- BOM COMPONENT MOVED OUT OF MAKING PP_ID OF LOCATION TRANSITION IS DIFFERENT THAN PP_ID OF LOCATION
			-- STATUS OF NEXT LOCATION TRANSITION IS DIRTY
			-- PP_ID IS KEPT (FOLLOWS FROM THE LAST TRANSITION TO THE NEW ONE)
			-----------------------------------------------------------------------------------------------------------------------
			IF COALESCE(@CurrentTransitionEDPPID,0) <> @CurrentPositionPPId AND  COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'In use'   --1.6
			BEGIN
				IF @CurrentTransitionReuse !=1
				BEGIN
					SET @PEEventStatus =	(
											SELECT			ProdStatus_Id
											FROM			dbo.Production_status WITH(NOLOCK) 
											WHERE			ProdStatus_Desc = 'Dirty'
											)
					SET @DestTransitionEDPPID = @CurrentTransitionEDPPID
				END
				ELSE
				BEGIN
					SET @PEEventStatus =	(
											SELECT			ProdStatus_Id
											FROM			dbo.Production_status WITH(NOLOCK) 
											WHERE			ProdStatus_Desc = 'In use'
											)
					SET @DestTransitionEDPPID = @CurrentPositionPPId
				END
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
						@SPName,
						42,
						'Appliance status is [In Use] and current position and BOM component is moved in ' + CONVERT(varchar(30),COALESCE(@PEEventStatus,0)),
						@ApplianceEventId	)
				END
				GOTO PROCESS_EVENT
			END
			-----------------------------------------------------------------------------------------------------------------------
			-- GCAS MOVED OUT OF MAKING.  THE APPLIANCE HAS THE SAME PP_ID THAN THE LOCATION WHERE IT IS LOCATED
			-- STATUS OF NEXT LOCATION TRANSITION IS IN UISE
			-- PP_ID IS KEPT (FOLLOWS FROM THE LAST TRANSITION TO THE NEW ONE)
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
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
						@SPName,
						43,
						'Appliance status is [In Use] and GCAS is moved out',
						@ApplianceEventId	)
				END

				GOTO PROCESS_EVENT
			END

			-----------------------------------------------------------------------------------------------------------------------
			-- DIRTY APPLIANCE MOVED FROM NON MAKING
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentPositionPPId IS NULL AND COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'Dirty'
			BEGIN
				SET @PEEventStatus =	(
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'Dirty'
										)
				SET @DestTransitionEDPPID = @CurrentTransitionEDPPID
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
						@SPName,
						44,
						'Appliance status is [Diry] moved from NON MAKING',
						@ApplianceEventId	)
				END

				GOTO PROCESS_EVENT
			END
			-----------------------------------------------------------------------------------------------------------------------
			-- DIRTY APPLIANCE MOVED OUT OF MAKING
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentPositionPPId IS NOT NULL AND COALESCE(@CurrentTransitionStatusDesc,'Clean') = 'Dirty'
			BEGIN						
				SET @PEEventStatus =	(				
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'Dirty'
										)
				SET @DestTransitionEDPPID = @CurrentTransitionEDPPID
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
						@SPName,
						45,
						'Appliance status is [Diry] moved from Out of making',
						@ApplianceEventId	)
				END

					GOTO PROCESS_EVENT
			END

			-----------------------------------------------------------------------------------------------------------------------		
			-- NON MAKING MOVEMENT
			-----------------------------------------------------------------------------------------------------------------------
			IF @CurrentPositionPPId IS NULL  
			BEGIN
				SET @PEEventStatus =	@CurrentTransitionStatusId
				SET @DestTransitionEDPPID = @CurrentTransitionEDPPID
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
						@SPName,
						46,
						'Appliance moved from non making' ,
						@ApplianceEventId	)
				END

				GOTO PROCESS_EVENT
			END

			IF @DebugFlag >=2
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
					@SPName,
					47,
					'Untreated situation ' ,
					@ApplianceEventId	)
			END
			
			
			RETURN
			
			PROCESS_EVENT:


			IF @DebugFlag >=2
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
					@SPName,
					49,
					'Beginning processing event',
					@ApplianceEventId	)
			END

			SET @PEStartTime					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
			SET @lastLocationTransEventId = (SELECT top 1	E.event_id 
											FROM			dbo.event_components EC WITH(NOLOCK) 
															JOIN dbo.events e WITH(NOLOCK)
															ON e.event_id = EC.event_id
											WHERE			EC.source_event_id = @ApplianceEventId  
															AND E.timestamp < @PEStartTime ORDER By E.timestamp desc
											)


			-- GET THE LAST POSITION OF THE APPLIANCE TO CLOSE IT											
			IF @lastLocationTransEventId IS NOT NULL
			BEGIN
				SELECT 
				@LastPEEventNum = event_num,
				@LastPEPUId= pu_Id,
				@LastPETimestamp = @PEStartTime,
				@LastPEAppliedProduct = Applied_product,
				@LastPEEventStatus = Event_Status,
				@LastPEUserId = user_id,
				@LastPEStartTime = start_time,
				@LastPEConformance = 0,
				@LastPETestPctComplete = 0,
				@PEExtendedInfo = Extended_Info,
				@PESignatureId	= Signature_id
				FROM dbo.events WITH(NOLOCK) WHERE event_id = @lastLocationTransEventId
					
			
				EXEC @RC = [dbo].[spServer_DBMgrUpdEvent] 
				@lastLocationTransEventId OUTPUT, --EVENT_ID
				@LastPEEventNum, 				-- EVENT_NUM
				@LastPEPUId,					--PU_ID
				@LastPETimestamp,				--TIMESTAMP
				@LastPEAppliedProduct,			--APPLIED_PRODUCT
				NULL,							--SOURCE_EVENT
				@LastPEEventStatus,				--EVENT_STATUS
				2,								--TTYPE
				0,								--TNUM
				@LastPEUserId,					--USER_ID
				NULL,							--COMMENT_ID
				NULL,							--EVENT_SUBTYPE_ID
				NULL,							--TESTING_STATUS
				@LastPEStartTime,				--START_TIME
				NULL,							--ENTRY_ON
				0,								--RETURN RESULT SET 
				@LastPEConformance,				--CONFORMANCE
				@LastPETestPctComplete,			--TESTPCTCOMPLETE
				NULL,							--SECOND USER ID
				NULL,							--APPROVER USER ID
				NULL,							--USER Reason Id
				NULL,							--USER SIGN OFF ID
				@PEExtendedInfo,				--EXTENDED_INFO
				NULL,							--SEND EVENT POST
				@PESignatureId--,				--SIGNATURE ID
				--NULL,							--LOT INDENTIFIER
				--NULL							--FRIENDYOPERATIONNAME
				
				IF @RC =-100
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
						@SPName,
						51,
						'Failed to update Last location transition event: ' + CAST(@RC AS VARCHAR(10)),
						@ApplianceEventId	)
					

					SET @OutputStatus = 0
					SET @OutputMessage = 'Failed to update Last location transition event: ' + CAST(@RC AS VARCHAR(10))

				
					RETURN
				END
				IF @DebugFlag >=2
				BEGIN
					IF @RC !=-100
					BEGIN
						INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
						VALUES	(	
								GETDATE(),
								@SPName,
								52,
								'Last location transition event update :' +
								'@PEEventId : ' + CAST(@lastLocationTransEventId AS VARCHAR(30)) ,
								@ApplianceEventId	
								)
					END
				END
			END




				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES	(	
						GETDATE(),
						@SPName,
						53,
						'@CurrentTransitionStatusId = ' + CONVERT(varchar(30),COALESCE(@CurrentTransitionStatusId,0)) + 
						'@PEEventStatus = ' + CONVERT(varchar(30),COALESCE(@PEEventStatus,0)) +
						'@CurrentPositionPPId = ' + CONVERT(varchar(30),COALESCE(@CurrentPositionPPId,0)) +
						'@DestTransitionEDPPID = ' + CONVERT(varchar(30),COALESCE(@DestTransitionEDPPID,0)) 	,
						@ApplianceEventId	
								)



			-- EVALUATE IF STATUS MUST BE SET IMMEDIATELY OR STAGED
			IF @CurrentTransitionStatusId != @PEEventStatus OR 
			(COALESCE(@DestTransitionEDPPID,0) != COALESCE(@CurrentTransitionEDPPID,0) AND COALESCE(@CurrentPositionPPId,0) > 0) /*  V1.5  31-Jan-2023*/
			BEGIN
			
				SET @PEExtendedInfo = 'SID=' + CAST(@PEEventStatus AS VARCHAR(25))+',PPID=' + CAST(COALESCE(@DestTransitionEDPPID,0) AS VARCHAR(25)) -- Bergeron.fe 19-apr-2022
				SET @PEEventStatus = @CurrentTransitionStatusId

				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES	(	
						GETDATE(),
						@SPName,
						53,
						'@PEExtendedInfo = ' + @PEExtendedInfo + 
						'@PEEventStatus = ' + CONVERT(varchar(30),COALESCE(@PEEventStatus,0)) ,  
						@ApplianceEventId	
								)
				--SET @PEAppliedProduct = (SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE PP_ID = @DestTransitionEDPPID)
			END



			SET @PETransactionType				=	1
			SET @PEEventId						=	NULL	
			SET @PEEventNum						=	CAST(Datepart(Year,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Month,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Day,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Hour,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Minute,@Now) AS VARCHAR(10)) +
													CAST(Datepart(Second,@Now) AS VARCHAR(10)) 
			SET @PEPUId							=	@LocationId
			SET @PETimestamp					=	DATEADD(Second,1,@now)
			SET @PETimestamp					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @PETimestamp) 
			SET @PEAppliedProduct				=	@LastPEAppliedProduct --(SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @DestTransitionEDPPID)
			SET @PESourceEvent					=	NULL
			--SET @PEEventStatus				=	NULL
			SET @PEUpdateType					=	0 --Pre Update, 1 would be post update typically used with hot add
			SET @PEConformance					=	0
			SET @PETestPctComplete				=	0
			SET @PEStartTime					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
			SET @PETransNum						=	0 -- Update only non null fields
			SET @PETestingStatus				=	NULL
			SET @PECommentId					=	NULL
			SET @PEEventSubtypeId				=	NULL
			SET @PEEntryOn						=	@now
			SET @PEApprovedUserId				=	NULL
			SET @PESecondUserID					=	NULL
			SET @PEApprovedReasonId				=	NULL
			SET @PEUserReasonId					=	NULL
			SET @PEUserSignOffId				=	NULL
			SET @PESignatureId					=	NULL

			
			-----------------------------------------------------------------------------------------------------------------------
			-- CREATE PRODUCTION EVENT AT DESTINATION - HOT ADD
			-----------------------------------------------------------------------------------------------------------------------
			EXEC @RC = [dbo].[spServer_DBMgrUpdEvent] 
			@PEEventId OUTPUT,		--EVENT_ID
			@PEEventNum,			--EVENT_NUM
			@PEPUId,				--PU_ID
			@PETimestamp,			--TIMESTAMP
			@PEAppliedProduct,		--APPLIED_PRODUCT
			NULL,					--SOURCE_EVENT
			@PEEventStatus,			--EVENT_STATUS
			1,						--TTYPE
			0,						--TNUM
			@RSUserId,				--USER_ID
			NULL,					--COMMENT_ID
			NULL,					--EVENT_SUBTYPE_ID
			NULL,					--TESTING_STATUS
			@PEStartTime,			--START_TIME
			@now,					--ENTRY_ON
			0,						--RETURN RESULT SET 
			@PEConformance,			--CONFORMANCE
			@PETestPctComplete,		--TESTPCTCOMPLETE
			NULL,					--SECOND USER ID
			NULL,					--APPROVER USER ID
			NULL,					--APPROVER Reason Id
			NULL,					--USER Reason Id
			NULL,					--USER SIGN OFF ID
			@PEExtendedInfo,		--EXTENDED_INFO
			NULL,					--SEND EVENT POST
			@PESignatureId--,		--SIGNATURE ID
			--NULL,					--LOT INDENTIFIER
			--NULL					--FRIENDYOPERATIONNAME
	
			IF @PEEventId IS NULL
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
					@SPName,
					53,
					'Location transition event creation failed: ' + CAST(@RC AS VARCHAR(10)),
					@ApplianceEventId	)

				SET @OutputStatus = 0
				SET @OutputMessage = 'Location transition event creation failed: ' + CAST(@RC AS VARCHAR(10))

				RETURN
			END

			IF @DebugFlag >=2
			BEGIN
				IF @PEEventId IS NOT NULL
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(	
							GETDATE(),
							@SPName,
							54,
							'Location  transition event is Created' +
							'@PEEventId : ' + CAST(@PEEventId AS VARCHAR(30)) ,
							@ApplianceEventId	
							)
				END
			END
		
		



			-----------------------------------------------------------------------------------------------------------------------
			IF @PEEventId IS NOT NULL AND @ProcessOrderId IS NOT NULL -- IF PO IS NOT STARTED AT DESTINATION, START IT
			-----------------------------------------------------------------------------------------------------------------------
			BEGIN --1
				--  WRITE IN PRODUCTION PLAN IF NEEDED
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
				@PPTransactionTime				= @PEStartTime,
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

				-----------------------------------------------------------------------------------------------------------------------------------------
				IF @DestinationPPId IS NULL AND @PPStatusId NOT IN(@ActivePPStatusId,@CompletePPStatusId) -- NO ACTIVE PP ID IN PRODUCTION PLAN 
				-----------------------------------------------------------------------------------------------------------------------------------------
				BEGIN --2

					-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
					IF (SELECT COUNT(PP_Start_id) FROM dbo.production_plan_starts WITH(NOLOCK) WHERE PP_ID = @ProcessOrderId) = 0 -- IF RECORDS EXISTS IN PRODUCTION PLAN START DO NOTHING
					-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
					BEGIN --3
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

						IF @RC = -100
						BEGIN --4
							INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
							VALUES	(	
									GETDATE(),
									@SPName,
									55,
									'Process order activation failed: ' + CAST(@RC AS VARCHAR(10)),
									@ApplianceEventId	
									)

									
							SET @OutputStatus = 0
							SET @OutputMessage = 'Process order activation failed: ' + CAST(@RC AS VARCHAR(10))

							RETURN
					
						END --4
						ELSE
						BEGIN --4
							IF @DebugFlag >=2
							BEGIN --5
								INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
								VALUES	(GETDATE(),
										@SPName,
										56,
										'Process order activation succeeded',
										@PPId
										)
							END --5
						END -- END OF RESULT SET EVALUATION --4
					-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
					END  -- IF RECORDS EXISTS IN PRODUCTION PLAN START DO NOTHING --3
					ELSE
					-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
					BEGIN --3
						IF @DebugFlag >=2
						BEGIN
							INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
							VALUES	(	
									GETDATE(),
									@SPName,
									57,
									'Process order ' + CAST(@PPId AS VARCHAR(25)) + 'was activated',
									@ApplianceEventId	
									)
						END
								
					-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
					END   -- IF RECORDS EXISTS IN PRODUCTION PLAN START DO NOTHING --3
					-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
				-----------------------------------------------------------------------------------------------------------------------------------------
				END -- NO ACTIVE PP ID IN PRODUCTION PLAN --2 
				-----------------------------------------------------------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------------------------------------
			END -- IF PO IS NOT STARTED AT DESTINATION, START IT --1
			-----------------------------------------------------------------------------------------------------------------------
			
			-----------------------------------------------------------------------------------------------------------------------
			-- CREATE EVENT COMPONENT BETWEEN APPLIANCE PE AND TRANSITION PE CREATED ABOVE - HOT ADD
			-----------------------------------------------------------------------------------------------------------------------
			IF @PEEventId IS NOT NULL
			BEGIN
				EXEC @RC = spServer_DBMgrUpdEventComp
				@RSUserId,						--USER_ID
				@PEEventId,						--EVENT_ID
				@ECComponentId OUTPUT,			--ECID
				@ApplianceEventId,				--SOURCE_EVENT_ID
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
				@PEStartTime,					--TIMESTAMP
				NULL,							--PARENT COMP ID	
				@ECEntryOn	OUTPUT,				--ENTRY ON
				NULL,							--ENTENDED INFO
				NULL,							--PEI ID
				NULL,							--REPORT AS CONS
				NULL,							--SIG ID
				NULL							--RETURN RESULT SET


				IF @RC = -100
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
					@SPName,
					60,
					'Event component record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
					' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@RSUserId, 0)) + 
					' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
					' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
					' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceEventId, 0)),
					@ApplianceEventId)

					
					
					
					SET @OutputStatus = 0
					SET @OutputMessage =	'Event component record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
											' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@RSUserId, 0)) + 
											' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
											' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
											' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceEventId, 0))
					RETURN
						
				END
				ELSE
				BEGIN
					IF @DebugFlag >=2
					BEGIN
						INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
						VALUES	(GETDATE(),
								@SPName,
								61,
								'Event_Components record creation succeeded',
								@ECComponentId
								)
					END
				
				END
			END


			-----------------------------------------------------------------------------------------------------------------------
			-- CREATE EVENT DETAILS					
 			-----------------------------------------------------------------------------------------------------------------------
			IF NOT EXISTS(SELECT event_id FROM dbo.event_details WITH(NOLOCK) WHERE event_id = @PEEventId) 
			BEGIN 
				-- DETERMINE THE PP_ID
				-- IF PP_ID ON CURRENT POSITION IS SET THEN KEEP IT
				-- IF PP_ID IS NOT SET ON CURRENT POSITION THEN SET IT TO LOCATION'S
				-- @CurrentTransitionEDPPID,@CurrentPositionPPId,@DestinationPPId
				IF @CurrentTransitionEDPPID IS NOT NULL
					SET @EDProductionPlanId = @CurrentTransitionEDPPID
				--ELSE -- Bergeron.fe 19-apr-2022
				--	SET @EDProductionPlanId = @DestinationPPId
					 
				-----------------------------------------------------------------------------------------------------------------------
 				-- GET EVENT DETAILS INFORMATION
				-----------------------------------------------------------------------------------------------------------------------
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
				@EDProductionPlanId,		-- PPID
				NULL,						-- PPSETUPDETAILID
				NULL,						-- SHIPMENTID
				NULL,						-- COMMENTID
				@Now,						-- ENTRYON
				@PETimestamp,				-- TIMESTANP
				NULL,						-- FUTURE6
				NULL,						-- SIGNATUREID
				NULL						-- PRODUCTDEFID

				IF @RC = -100
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
					@SPName,
					70,
					'Event Details record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
					' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@RSUserId, 0)) + 
					' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceEventId, 0)),
					@ApplianceEventId)

					

					SET @OutputStatus = 0
					SET @OutputMessage =	'Event details record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
											' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@RSUserId, 0)) + 
											' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceEventId, 0))
					RETURN
						
				END
				ELSE
				BEGIN
					IF @DebugFlag >=2
					BEGIN
						INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
						VALUES	(GETDATE(),
								@SPName,
								71,
								'Event_Details record creation succeeded',
								@PEEventId
								)
					END
					
					SET @OutputStatus = 1
					SET @OutputMessage = ''
					RETURN
				END

			END	 /*EVENT DETAILS ADD*/
			ELSE 
			BEGIN /*EVENT DETAILS UPDATE*/
				/*
				DETERMINE THE PP_ID
				IF PP_ID ON CURRENT POSITION IS SET THEN KEEP IT
				IF PP_ID IS NOT SET ON CURRENT POSITION THEN SET IT TO LOCATION'S
				*/
				IF @CurrentTransitionEDPPID IS NOT NULL
					SET @EDProductionPlanId = @CurrentTransitionEDPPID

					 
				-----------------------------------------------------------------------------------------------------------------------
 				-- GET EVENT DETAILS INFORMATION
				-----------------------------------------------------------------------------------------------------------------------
				EXEC @RC = [dbo].[spServer_DBMgrUpdEventDet] 
				@RSUserId,					-- USER_ID
				@PEEventId,					-- EVENT_ID
				@PEPUId,					-- PU_ID
				NULL,						-- FUTURE1
				2,							-- TTYPE
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
				@EDProductionPlanId,		-- PPID
				NULL,						-- PPSETUPDETAILID
				NULL,						-- SHIPMENTID
				NULL,						-- COMMENTID
				@Now,						-- ENTRYON
				@PETimestamp,				-- TIMESTANP
				NULL,						-- FUTURE6
				NULL,						-- SIGNATUREID
				NULL						-- PRODUCTDEFID

				IF @RC = -100
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES(	GETDATE(),
					@SPName,
					72,
					'Event Details record upddate failed: ' + CAST(@RC AS VARCHAR(10))  + 
					' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@RSUserId, 0)) + 
					' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceEventId, 0)),
					@ApplianceEventId)

					

					SET @OutputStatus = 0
					SET @OutputMessage =	'Event details record upddate failed: ' + CAST(@RC AS VARCHAR(10))  + 
											' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@RSUserId, 0)) + 
											' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceEventId, 0))
					RETURN
						
				END
				ELSE
				BEGIN
					IF @DebugFlag >=2
					BEGIN
						INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
						VALUES	(GETDATE(),
								@SPName,
								73,
								'Event_Details record upddate succeeded',
								@PEEventId
								)
					END
					
					SET @OutputStatus = 1
					SET @OutputMessage = ''
					RETURN
				END
			END

			
		-----------------------------------------------------------------------------------------------------------------------
		END 	-- LOCATION HAS CHANGED	
		ELSE
		-----------------------------------------------------------------------------------------------------------------------
		BEGIN		

			IF @DebugFlag >=2
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
						@SPName,
						245,
						'Already at location' ,
						@ApplianceEventId	)
			END
			
			SET @OutputStatus = 0
			SET @OutputMessage = 'Already at location'
			RETURN
		-----------------------------------------------------------------------------------------------------------------------
		END	-- LOCATION HAS CHANGED
		-----------------------------------------------------------------------------------------------------------------------
		
		

	
	-----------------------------------------------------------------------------------------------------------------------
	END --EVALUATION IF
	ELSE 
	-----------------------------------------------------------------------------------------------------------------------
	BEGIN
		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					250,
					'Evaluation failed' ,
					@ApplianceEventId	)
		END
		
		SET @OutputStatus = (SELECT O_Status FROM @moveEval)
		SET @OutputMessage = (SELECT O_Message FROM @moveEval)
		RETURN
	-----------------------------------------------------------------------------------------------------------------------
	END --EVALUATION IF
	-----------------------------------------------------------------------------------------------------------------------
	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				999,
				'Abnormal conclusion of procedure' ,
				@ApplianceEventId	)
	END


	SET @OutputStatus = 0
	SET @OutputMessage = 'Abnormal conclusion of procedure'
--=====================================================================================================================
	SET NOCOUNT OFF
--=====================================================================================================================


END -- BODY
