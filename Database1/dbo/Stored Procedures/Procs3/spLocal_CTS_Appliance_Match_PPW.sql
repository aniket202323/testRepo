


--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Appliance_Match_PPW
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-08-12
-- Version 				: Version 1.0
-- SP Type				: WEB
-- Caller				: WEB SERVICE
-- Description			: the purpose of this SP is to set the PPW product on a container
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-01-28		F. Bergeron				Initial Release
-- 1.1		2022-02-18		F. Bergeron				Early validation with  fnLocal_CTS_Evaluate_Appliance_Movement 
--													to prevent PPW match without reservation
--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXECUTE [spLocal_CTS_Appliance_Match_PPW] 1042326,'180322001-CTS','90039231',1580
SELECT prod_id FROM dbo.products_base WITH(NOLOCK) WHERE prod_code = '90271684'
SELECT * FROM events where event_id = 1031408
SELECT * FROM event_details WHERE event_id = 997982
*/

CREATE   PROCEDURE [dbo].[spLocal_CTS_Appliance_Match_PPW]
	@ApplianceEventId				INTEGER,
	@DestinationPPId				INTEGER	= NULL,
	@ProductCode					VARCHAR(50),
	@UserId							INTEGER

AS
BEGIN
	SET NOCOUNT ON;
	-- SP Variables

	DECLARE 
	@SPName							VARCHAR(25),
	@DebugFlag						INTEGER,
	@CurrentPosition				INTEGER,
	@CurrentTransitionEventId		INTEGER,
	@RC								INTEGER,
	@DestinationLocationId			INTEGER,
	@Now							DATETIME,
	@C_User							VARCHAR(50),
	@ProductId						INTEGER,
	@ProcessOrder					VARCHAR(50)
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
	

	DECLARE @Output TABLE
	(
		OutputStatus	BIT,
		OutputMessage	VARCHAR(500)
	)

	SET @C_User = (SELECT username FROM dbo.users_base WHERE user_id = @UserId )
	SET @SPname = 'spLocal_CTS_Appliance_Match_PPW'
	SET @DebugFlag =	(SELECT CONVERT(INT,sp.value) 
						FROM	dbo.site_parameters sp WITH(NOLOCK)
								JOIN dbo.parameters p WITH(NOLOCK)		
									ON sp.parm_Id = p.parm_id
						WHERE	p.parm_Name = 'PG_CTS_StoredProcedure_Log_Level')
	IF @DebugFlag IS NULL
		SET @DebugFlag = 0

	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				1,
				'SP Started:'  + 
				' Appliance EventId: ' + CONVERT(varchar(30), COALESCE(@ApplianceEventId, 0)) + 
				' Product code: ' + + COALESCE(@Productcode, 'Missing')+ 
				' Process Order: ' + COALESCE(@ProcessOrder, 'Missing') + 
				' User id: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)),
				@ApplianceEventId	)
	END
	SET @Now = GETDATE()
	-----------------------------------------------------------------------------------------------------------------------
	-- FIND THE LOCATION TRANSITION EVENT
	-----------------------------------------------------------------------------------------------------------------------
	SET @CurrentPosition =				(
										SELECT TOP 1	E.pu_id 
										FROM			dbo.event_components EC WITH(NOLOCK) 
														JOIN dbo.events E WITH(NOLOCK) 
															ON E.event_id = EC.event_id 
										WHERE			EC.Source_event_id = @ApplianceEventId 
										ORDER BY		EC.Timestamp DESC
										)

	SET @CurrentTransitionEventId =		(
										SELECT TOP 1	E.event_id
										FROM			dbo.event_components EC WITH(NOLOCK) 
														JOIN dbo.events E WITH(NOLOCK) 
															ON E.event_id = EC.event_id 
										WHERE			EC.Source_event_id = @ApplianceEventId 
										ORDER BY		EC.Timestamp DESC
										)
	SET @PEEventStatus =				(
										SELECT			ProdStatus_Id
										FROM			dbo.Production_status WITH(NOLOCK) 
										WHERE			ProdStatus_Desc = 'In Use'
										)

	SET @ProductId	=					(
										SELECT			prod_id 
										FROM			dbo.products_base WITH(NOLOCK) 
										WHERE			prod_code = @ProductCode
										)

	-----------------------------------------------------------------------------------------------------------------------
	-- VALIDATE IF @ProductCode EXISTS
	-----------------------------------------------------------------------------------------------------------------------
	IF @ProductId IS NULL
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
			@SPName,
			5,
			'Product code : ' + @ProductCode + ' not found',
			@ApplianceEventId	)
				
		INSERT INTO @output
		(
			OutputStatus,
			OutputMessage
		)
		VALUES
		(
			0,
			'Product code : ' + @ProductCode + ' not found'
		)
		SELECT 
		OutputStatus,
		OutputMessage
		FROM @output
		RETURN
		
	END
	-----------------------------------------------------------------------------------------------------------------------
	-- VALIDATE APPLIANCE IS IN PPW LOCATION
	-----------------------------------------------------------------------------------------------------------------------
	IF EXISTS(	
				SELECT 1 
				FROM	dbo.prod_units_base PUB 
						JOIN dbo.Table_Fields_Values TFV
							ON TFV.keyId = PUB.PU_id
						JOIN dbo.table_fields TF
							ON TF.Table_Field_Id = TFV.Table_Field_Id
						JOIN dbo.Tables T 
							ON t.tableid = TF.tableId
							AND T.tableName = 'Prod_Units'
				WHERE   Table_Field_Desc = 'CTS Location type' 
						AND TFV.Value = 'PPW'
						AND PUB.pu_Id = @CurrentPosition
			)
	BEGIN

	-----------------------------------------------------------------------------------------------------------------------
	-- GET PO LOCATION
	-----------------------------------------------------------------------------------------------------------------------
	SET @DestinationLocationId = NULL
	IF @DestinationPPId IS NOT NULL
	BEGIN
		SELECT  @DestinationLocationId = PPU.Pu_id,
				@processOrder = PP.Process_order
		FROM	dbo.production_plan PP WITH(NOLOCK) 
				JOIN dbo.prdexec_path_units PPU 
					ON ppu.path_id = PP.path_Id
		WHERE	PPU.is_schedule_point = 1
			AND PP.PP_Id = @DestinationPPId
	
		IF @DestinationLocationId IS NULL
		BEGIN
			
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
					@SPName,
					10,
					'Process order ' + @processOrder + ' not found on any CTS making location',
					@ApplianceEventId	)
				
				INSERT INTO @output
				(
					OutputStatus,
					OutputMessage
				)
				VALUES
				(
					0,
					'Process order ' + @processOrder + ' not found on any CTS making location'
				)
				SELECT 
				OutputStatus,
				OutputMessage
				FROM @output
				RETURN
		END

		-- LOOK IF THE PRODUCT IS IN THE PO BOM		
		IF 		@ProductId NOT IN (	SELECT		COALESCE(boms.prod_id,BOMFI.Prod_Id) 
									FROM		dbo.Bill_Of_Material_Formulation BOMF 
												JOIN dbo.production_plan PP WITH(NOLOCK)
													ON PP.BOM_Formulation_Id = BOMF.BOM_Formulation_Id 
												JOIN dbo.Bill_Of_Material_Formulation_Item BOMFI  WITH(NOLOCK) 
													ON BOMFI.BOM_Formulation_Id = BOMF.BOM_Formulation_Id
												LEFT JOIN dbo.Bill_Of_Material_Substitution boms WITH(NOLOCK)	
												ON bomfi.BOM_Formulation_Item_Id = boms.BOM_Formulation_Item_Id
									WHERE		PP.PP_Id = @DestinationPPId)
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
				@SPName,
				11,
				'Product ' + @ProductCode +  ' not in process order BOM' ,
				@ApplianceEventId	)
				
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Product ' + @ProductCode + ' not in process order BOM' 
			)
			SELECT 
			OutputStatus,
			OutputMessage
			FROM @output
			RETURN
		END
	END
/*
		IF (SELECT O_Status FROM fnLocal_CTS_Evaluate_Appliance_Movement(@ApplianceEventId,@DestinationLocationId,@DestinationPPId,@UserId)) != 1
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
				@SPName,
				20,
				(SELECT O_Message FROM fnLocal_CTS_Evaluate_Appliance_Movement(@ApplianceEventId,@DestinationLocationId,@DestinationPPId,@UserId)),
				@ApplianceEventId	)
				
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				(SELECT O_Status FROM fnLocal_CTS_Evaluate_Appliance_Movement(@ApplianceEventId,@DestinationLocationId,@DestinationPPId,@UserId))
			)
			SELECT 
			OutputStatus,
			OutputMessage
			FROM @output
			RETURN

		END
		*/

		SET @PETimestamp = @Now
		SET @PETimestamp = DATEADD(millisecond,-Datepart(millisecond,@Now), @PETimestamp) 
		--SET @PEStartTime					
		SELECT	@PETransactionType				= 2,
				@PEEventId						= event_id,
				@PEEventNum						= event_num,
				@PEPUId							= pu_id,
				--@PETimestamp					= Timestamp, 
				@PEAppliedProduct				= (SELECT prod_id FROM dbo.products_base WITH(NOLOCK) WHERE prod_code = @ProductCode),
				@PESourceEvent					= NULL,
				--@PEEventStatus					= Event_Status,
				@PEUpdateType					= 0, --Pre Update, 1 would be post update typically used with hot add
				@PEConformance					= 0,
				@PETestPctComplete				= 0,
				@PEStartTime					= start_time,
				@PETransNum						= 0, -- Update only non null fields
				@PETestingStatus				= NULL,
				@PECommentId					= NULL,
				@PEEventSubtypeId				= NULL,
				@PEEntryOn						= GETDATE(),
				@PEApprovedUserId				= NULL,
				@PESecondUserID					= NULL,
				@PEApprovedReasonId				= NULL,
				@PEUserReasonId					= NULL,
				@PEUserSignOffId				= NULL,
				@PEExtendedInfo					= NULL,
				@PESignatureId					= NULL
		FROM	dbo.events WITH(NOLOCK) 
		WHERE	event_id = @CurrentTransitionEventId

		-----------------------------------------------------------------------------------------------------------------------
		-- WRITE THE APPLIED PRODUCT ON THE EVENT
		-----------------------------------------------------------------------------------------------------------------------
		EXEC	@RC = [dbo].[spServer_DBMgrUpdEvent] 
				@PEEventId OUTPUT,			--EVENT_ID
				@PEEventNum,				--EVENT_NUM
				@PEPUId,					--PU_ID
				@PETimestamp,				--TIMESTAMP
				@PEAppliedProduct,			--APPLIED_PRODUCT
				NULL,						--SOURCE_EVENT
				@PEEventStatus,				--EVENT_STATUS
				2,							--TTYPE
				0,							--TNUM
				@UserId,					--USER_ID
				NULL,						--COMMENT_ID
				NULL,						--EVENT_SUBTYPE_ID
				NULL,						--TESTING_STATUS
				@PEStartTime,				--START_TIME
				NULL,						--ENTRY_ON
				0,							--RETURN RESULT SET 
				@PEConformance,				--CONFORMANCE
				@PETestPctComplete,			--TESTPCTCOMPLETE
				NULL,						--SECOND USER ID
				NULL,						--APPROVER USER ID
				NULL,						--USER Reason Id
				NULL,						--USER SIGN OFF ID
				NULL,						--EXTENDED_INFO
				NULL,						--SEND EVENT POST
				@PESignatureId--,			--SIGNATURE ID
				--NULL,						--LOT INDENTIFIER
				--NULL						--FRIENDYOPERATIONNAME

			IF @RC = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
					@SPName,
					50,
					'PPW Match event update failed: ' + CAST(@RC AS VARCHAR(10)),
					@ApplianceEventId	)
				
				INSERT INTO @output
				(
					OutputStatus,
					OutputMessage
				)
				VALUES
				(
					0,
					'PPW Match event update failed: ' + CAST(@RC AS VARCHAR(10))
				)
				SELECT 
				OutputStatus,
				OutputMessage
				FROM @output
				RETURN
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(	
							GETDATE(),
							@SPName,
							50,
							'PPW Match event update succeeded' +
							'@PEEventId : ' + CAST(@PEEventId AS VARCHAR(30)) ,
							@ApplianceEventId	
							)
				END
					INSERT INTO @output
				(
					OutputStatus,
					OutputMessage
				)
				VALUES
				(
					1,
					'Appliances is matched to Preweigh Product ' + @ProductCode  + ' and destination process ordrer ' + @ProcessOrder
				)

				SELECT 
				OutputStatus,
				OutputMessage
				FROM @output
				RETURN
			END

	END
	ELSE
	BEGIN
		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES	(	
					GETDATE(),
					@SPName,
					51,
					'Appliance not in PPW location' +
					'@PEEventId : ' + CAST(@PEEventId AS VARCHAR(30)) ,
					@ApplianceEventId	
					)
				INSERT INTO @output
				(
					OutputStatus,
					OutputMessage
				)
				VALUES
				(
					0,
					'Appliance not in PPW location'
				)
				SELECT 
				OutputStatus,
				OutputMessage
				FROM @output
				RETURN
		END
	END


	-----------------------------------------------------------------------------------------------------------------------
	-- MAKE RESERVATION ON THE LOCATION RUNNING THE INPUT PO
	-----------------------------------------------------------------------------------------------------------------------
	IF @ProcessOrder IS NOT NULL
	BEGIN
		DECLARE 
		@OutPutStatus	INTEGER,
		@OutPutMessage	VARCHAR(50)
		EXEC [dbo].[spLocal_CTS_MakeReservation] @ApplianceEventId, @DestinationLocationId, @DestinationPPId, 'Hard', @C_User, @OutPutStatus OUTPUT, @OutPutMessage OUTPUT
		IF @OutPutStatus = 0
		BEGIN

			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
				@SPName,
				50,
				'PPW reservation failed: ' + @OutputMessage,
				@ApplianceEventId	)
				
				INSERT INTO @output
				(
					OutputStatus,
					OutputMessage
				)
				VALUES
				(
					0,
					'PPW reservation failed: ' + @OutputMessage
				)
				SELECT 
				OutputStatus,
				OutputMessage
				FROM @output
				RETURN
		END
	END

END



