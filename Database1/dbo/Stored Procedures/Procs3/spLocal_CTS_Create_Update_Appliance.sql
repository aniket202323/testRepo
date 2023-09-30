
--------------------------------------------------------------------------------------------------
-- Table function: spLocal_CTS_Create_Update_Appliance
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2022-02-23
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: SQL
-- Description			: This function retrieves the process order route from a starting process order
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-03-20		F. Bergeron				Initial Release 
-- 1.1		2022-01-12		U. Lapierre				Create appliance as Dirty instead of clean

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

EXECUTE spLocal_CTS_Create_Update_Appliance NULL,'28042022003',104,'28042022003','Kit Utencilios Fabricacion',10416,1596

EXECUTE spLocal_CTS_Create_Update_Appliance 1256597,'IBC120012042022001',118,'12042022001','IBC 1200',10432,1596

Select * from production_status where prodstatus_desc = 'Decommissioned'
Select * from production_status where prodstatus_desc = 'Active'

Select * from users where username = 'bergeron.fe'
*/


CREATE   PROCEDURE [dbo].[spLocal_CTS_Create_Update_Appliance]
(
@Appliance_id			INTEGER = NULL,
@Appliance_name			VARCHAR(25) = NULL ,
@Appliance_status_id	INTEGER = NULL , 
@serial_Number			VARCHAR(25) = NULL,
@Appliance_Type			VARCHAR(50) = NULL,
@Location_Id			INTEGER = NULL,
@User_id				INTEGER
)


AS
BEGIN
	DECLARE
	@RC									INTEGER,
	@Now								DATETIME,
	@ApplianceTypePUId					INTEGER,
	@SPname								VARCHAR(50),
	@DebugFlag							INTEGER,
	@ExistEventNum						VARCHAR(50),
	@ExistsApplianceType				VARCHAR(50),
	@ExistsLocation						VARCHAR(50),
	@LocationTransitionCleanStatusId	INTEGER,
	@locationPUDesc						VARCHAR(50)
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 1 VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@PETransactionType					INTEGER,
	@PEEventId							INTEGER,
	@PEEventIdTrans						INTEGER,	
	@PEEventNumTrans					VARCHAR(25),
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
	-----------------------------------------------------------------------------------------------------------------------
	-- RESULT SET 1 TABLE
	-----------------------------------------------------------------------------------------------------------------------
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


	DECLARE @Output TABLE
	(
		OutputStatus	BIT,
		OutputMessage	VARCHAR(500)
	)

	SET @now = GETDATE()

	SET @SPname = 'spLocal_CTS_Create_Update_Appliance'
	
	SET		@DebugFlag =(
	SELECT	CONVERT(INT,sp.value) 
	FROM	dbo.site_parameters sp WITH(NOLOCK)
			JOIN dbo.parameters p WITH(NOLOCK)		
				ON sp.parm_Id = p.parm_id
	WHERE	p.parm_Name = 'PG_CTS_StoredProcedure_Log_Level')


	IF @DebugFlag IS NULL
		SET @DebugFlag = 0
	------------------------------
	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				1,
				'SP Started:'  + 
				' @Appliance_id: ' + CONVERT(varchar(30), COALESCE(@Appliance_id, 0)) + 
				' @Appliance_name: ' + COALESCE(@Appliance_name,'') + 
				' @Appliance_status_id: ' + CONVERT(varchar(30),COALESCE(@Appliance_status_id, 0)) + 
				' @serial_Number: ' + COALESCE(@serial_Number,'') + 
				' @Appliance_Type: ' + COALESCE(@Appliance_Type,'') + 
				' @User_Id: ' + CONVERT(varchar(30),COALESCE(@User_Id,0)),
				NULL)
	END

	-----------------------------------------------------------------------------------------------
	-- CREATE A NEW APPLIANCE
	-----------------------------------------------------------------------------------------------------------------------------
	IF @Appliance_id IS NULL
	BEGIN
		IF @serial_Number IS NULL
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
				@SPName,
				10,
				'Serial number cannot be null',
				NULL	)
				
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Serial number cannot be null'
			)
			SELECT 
			OutputStatus,
			OutputMessage
			FROM @output
			RETURN
		END
		-- LOOK IF SERIAL EXISTS AMONG APPLIANCE
		IF (SELECT COUNT(1) FROM dbo.event_details WITH(NOLOCK) WHERE Alternate_Event_Num = @serial_Number) > 0 
		BEGIN
			SELECT	@ExistEventNum = E.event_num,
					@ExistsApplianceType = PUB.equipment_type
			FROM	dbo.events E WITH(NOLOCK) 
					JOIN dbo.event_details ED WITH(NOLOCK)
						ON E.event_id = ED.event_id  
					JOIN dbo.prod_units_base PUB WITH(NOLOCK)
						ON PUB.pu_id = E.pu_id
			WHERE	Alternate_Event_Num = @serial_Number

			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Serial number: ' + CAST(@serial_Number AS VARCHAR(10)) + 'is aleady exists on Appliance number ' + 
				@ExistEventNum + ' of type ' + @ExistsApplianceType

			)
			SELECT  OutputStatus,
					OutputMessage
			FROM	@output
			RETURN		
		END

		-- LOOK IF SERIAL EXISTS AMONG LOCATIONS
		IF @serial_Number IN	(SELECT	TFV.value 
								FROM	dbo.prod_units_base PUB WITH(NOLOCK) 
										JOIN dbo.table_fields_values TFV WITH(NOLOCK)
											ON TFV.keyId = PUB.Pu_Id
										JOIN dbo.table_fields TF WITH(NOLOCK) 
											ON TF.Table_field_id = TFV.table_field_Id
										JOIN dbo.tables T WITH(NOLOCK)
											ON T.tableId = TF.tableId
								WHERE	T.TableName = 'Prod_units' 
										AND TF.Table_Field_Desc = 'CTS Location serial number'
								)
		BEGIN

			SET @locationPUDesc=	(SELECT	PUB.pu_desc
									FROM	dbo.prod_units_base PUB WITH(NOLOCK) 
											JOIN dbo.table_fields_values TFV WITH(NOLOCK)
												ON TFV.keyId = PUB.Pu_Id
											JOIN dbo.table_fields TF WITH(NOLOCK) 
												ON TF.Table_field_id = TFV.table_field_Id
											JOIN dbo.tables T WITH(NOLOCK)
												ON T.tableId = TF.tableId
									WHERE	T.TableName = 'Prod_units' 
											AND TF.Table_Field_Desc = 'CTS Location serial number'
											AND TFV.value = @serial_Number)
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Serial number: ' + @serial_Number + ' is aleady used for location ' + @locationPUDesc

			)
			SELECT  OutputStatus,
					OutputMessage
			FROM	@output
			RETURN		
		END

		-- BUILD THE EVENT_NUM IF NULL
		IF @Appliance_name IS NULL
		BEGIN
			SET @PEEventNum =	CAST(Datepart(Year,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Month,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Day,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Hour,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Minute,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Second,@Now) AS VARCHAR(10)) 
		END
		ELSE 
			SET @PEEventNum = @Appliance_name

		-- GET THE PU_ID OF THE APPLIANCE TYPE
		SET		@ApplianceTypePUId =
		(SELECT	PUB.pu_id 
		FROM	dbo.prod_units_base PUB WITH(NOLOCK) 
				JOIN dbo.table_fields_values TFV WITH(NOLOCK)
					ON TFV.keyId = PUB.Pu_Id
				JOIN dbo.table_fields TF WITH(NOLOCK) 
					ON TF.Table_field_id = TFV.table_field_Id
				JOIN dbo.tables T WITH(NOLOCK)
					ON T.tableId = TF.tableId
		WHERE	T.TableName = 'Prod_units' 
				AND TF.Table_Field_Desc = 'CTS Appliance type'
				AND TFV.value = @Appliance_Type)
		
		
		SET @PETransactionType				= 1
		SET @PEEventId						= NULL	
		SET @PEPUId							= @ApplianceTypePUId
		SET @PETimestamp					= DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
		SET @PEEventStatus					= @Appliance_status_id
		SET @PESourceEvent					= NULL
		SET @PEUpdateType					= 0 --Pre Update, 1 would be post update typically used with hot add
		SET @PEConformance					= 0
		SET @PETestPctComplete				= 0
		SET @PETransNum						= 0 -- Update only non null fields
		SET @PETestingStatus				= NULL
		SET @PECommentId					= NULL
		SET @PEEventSubtypeId				= NULL
		SET @PEEntryOn						= @now
		SET @PEApprovedUserId				= NULL
		SET @PESecondUserID					= NULL
		SET @PEApprovedReasonId				= NULL
		SET @PEUserReasonId					= NULL
		SET @PEUserSignOffId				= NULL
		SET @PEExtendedInfo					= NULL
		SET @PESignatureId					= NULL
			
		-----------------------------------------------------------------------------------------------------------------------
		-- CREATE PRODUCTION EVENT OF THE NEW APPLIANCE
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
		@User_id,				--USER_ID
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
		NULL,					--USER Reason Id
		NULL,					--USER SIGN OFF ID
		NULL,					--EXTENDED_INFO
		NULL,					--SEND EVENT POST
		NULL--,					--SIGNATURE ID
		--NULL,					--LOT INDENTIFIER
		--NULL					--FRIENDYOPERATIONNAME

		IF @PEEventId IS NULL
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
				@SPName,
				50,
				'Appliance event creation failed: ' + CAST(@RC AS VARCHAR(10)),
				@serial_Number	)
				
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Appliance event creation failed: ' + CAST(@RC AS VARCHAR(10))
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
				IF @PEEventId IS NOT NULL
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(	
							GETDATE(),
							@SPName,
							51,
							'Appliance event is created' +
							'@PEEventId : ' + CAST(@PEEventId AS VARCHAR(30)) ,
							NULL	
							)
				END
			END
		END

		-- SET THE SERIAL NUMBER - HOT ADD
		EXEC @RC = [dbo].[spServer_DBMgrUpdEventDet] 
				@User_id,					-- USER_ID
				@PEEventId,					-- EVENT_ID
				@ApplianceTypePUId,			-- PU_ID
				NULL,						-- FUTURE1
				1,							-- TTYPE
				0,							-- TNUM
				@serial_Number,				-- AEN
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
				NULL,						-- PPID
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
			60,
			'Event Details record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
			' @User_Id: ' + CONVERT(varchar(30), COALESCE(@User_Id, 0)) + 
			' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@PEEventId, 0)),
			@PEEventId)

			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Event Details record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
				' @User_Id: ' + CONVERT(varchar(30), COALESCE(@User_Id, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@PEEventId, 0))
			)
			SELECT 
			OutputStatus,
			OutputMessage
			FROM @output
			RETURN
						
		END
		ELSE
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES	(GETDATE(),
					@SPName,
					61,
					'Event_Details record creation succeeded',
					@PEEventId
					)
		END

		-- CREATE THE TRANSITION PRODUCTION EVENT
		SET @PEEventNumTrans =	CAST(Datepart(Year,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Month,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Day,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Hour,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Minute,@Now) AS VARCHAR(10)) +
								CAST(Datepart(Second,@Now) AS VARCHAR(10)) 

		SET @PEStartTime = DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
		SET @PETimestamp = DATEADD(Second,1,@now)
		SET @PETimestamp = DATEADD(millisecond,-Datepart(millisecond,@Now), @PETimestamp) 
		--SET @LocationTransitionCleanStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_desc = 'Clean')
		SET @LocationTransitionCleanStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_desc = 'Dirty')
		
		EXEC @RC = [dbo].[spServer_DBMgrUpdEvent] 
		@PEEventIdTrans OUTPUT,		--EVENT_ID
		@PEEventNumTrans,			--EVENT_NUM
		@Location_Id,				--PU_ID
		@PETimestamp,				--TIMESTAMP
		@PEAppliedProduct,			--APPLIED_PRODUCT
		NULL,						--SOURCE_EVENT
		@LocationTransitionCleanStatusId,				--EVENT_STATUS
		1,							--TTYPE
		0,							--TNUM
		@User_id,					--USER_ID
		NULL,						--COMMENT_ID
		NULL,						--EVENT_SUBTYPE_ID
		NULL,						--TESTING_STATUS
		@PEStartTime,				--START_TIME
		@now,						--ENTRY_ON
		0,							--RETURN RESULT SET 
		@PEConformance,				--CONFORMANCE
		@PETestPctComplete,			--TESTPCTCOMPLETE
		NULL,						--SECOND USER ID
		NULL,						--APPROVER USER ID
		NULL,						--USER Reason Id
		NULL,						--USER SIGN OFF ID
		NULL,						--EXTENDED_INFO
		NULL,						--SEND EVENT POST
		NULL--,						--SIGNATURE ID
		--NULL,						--LOT INDENTIFIER
		--NULL						--FRIENDYOPERATIONNAME

		IF @PEEventIdTrans IS NULL
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
				@SPName,
				80,
				'Location transition event creation failed: ' + CAST(@RC AS VARCHAR(10)),
				NULL	)
				
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Location transition event creation failed: ' + CAST(@RC AS VARCHAR(10))
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
				IF @PEEventIdTrans IS NOT NULL
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(	
							GETDATE(),
							@SPName,
							81,
							'Location transition event is created' +
							'@PEEventId : ' + CAST(@PEEventIdTrans AS VARCHAR(30)) ,
							NULL	
							)
				END
			END
		END
		-- CREATE EVENT COMPONENTS RECORD				
		EXEC @RC = spServer_DBMgrUpdEventComp
		@User_id,						--USER_ID
		@PEEventIdTrans,				--EVENT_ID
		@ECComponentId OUTPUT,			--ECID
		@PEEventId,						--SOURCE_EVENT_ID
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
		@PEStartTime,						--TIMESTAMP
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
			90,
			'Event component record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
			' @User_Id: ' + CONVERT(varchar(30), COALESCE(@User_id, 0)) + 
			' @PEEventIdTrans: ' + CONVERT(varchar(30), COALESCE(@PEEventIdTrans, 0)) + 
			' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
			' @PEEventId: ' + CONVERT(varchar(30),COALESCE(@PEEventId, 0)),
			@PEEventId)

			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Event component record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
				' @User_Id: ' + CONVERT(varchar(30), COALESCE(@User_id, 0)) + 
				' @PEEventIdTrans: ' + CONVERT(varchar(30), COALESCE(@PEEventIdTrans, 0)) + 
				' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
				' @PEEventId: ' + CONVERT(varchar(30),COALESCE(@PEEventId, 0))
			)
			SELECT 
			OutputStatus,
			OutputMessage
			FROM @output
			RETURN
						
		END
		ELSE
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES	(GETDATE(),
					@SPName,
					91,
					'Event_Components record creation succeeded',
					@ECComponentId
					)
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				1,
				'Appliance created'
			)
		END
	END

	ELSE --IF @Appliance_id IS NOT NULL
	BEGIN

	


		SELECT	@PEEventNum = event_num,
				@PETimestamp = Timestamp,
				@PEPUId = PU_Id
		FROM	dbo.events WITH(NOLOCK) 
		WHERE	event_id = @Appliance_Id


		
		SET @PETransactionType				= 2
		SET @PEEventId						= @Appliance_Id	
		SET @PESourceEvent					= NULL
		SET @PEEventStatus					= @Appliance_status_id
		SET @PEUpdateType					= 0 --Pre Update, 1 would be post update typically used with hot add
		SET @PEConformance					= 0
		SET @PETestPctComplete				= 0
		SET @PETransNum						= 0 -- Update only non null fields
		SET @PETestingStatus				= NULL
		SET @PECommentId					= NULL
		SET @PEEventSubtypeId				= NULL
		SET @PEEntryOn						= @now
		SET @PEApprovedUserId				= NULL
		SET @PESecondUserID					= NULL
		SET @PEApprovedReasonId				= NULL
		SET @PEUserReasonId					= NULL
		SET @PEUserSignOffId				= NULL
		SET @PEExtendedInfo					= NULL
		SET @PESignatureId					= NULL

		-----------------------------------------------------------------------------------------------------------------------
		-- CREATE PRODUCTION EVENT AT DESTINATION - HOT ADD
		-----------------------------------------------------------------------------------------------------------------------
		EXEC @RC = [dbo].[spServer_DBMgrUpdEvent] 
		@PEEventId,				--EVENT_ID
		@PEEventNum,			--EVENT_NUM
		@PEPUId,				--PU_ID
		@PETimestamp,			--TIMESTAMP
		NULL,					--APPLIED_PRODUCT
		NULL,					--SOURCE_EVENT
		@PEEventStatus,			--EVENT_STATUS
		@PETransactionType,		--TTYPE
		0,						--TNUM
		@User_id,				--USER_ID
		NULL,					--COMMENT_ID
		NULL,					--EVENT_SUBTYPE_ID
		NULL,					--TESTING_STATUS
		NULL,					--START_TIME
		@now,					--ENTRY_ON
		0,						--RETURN RESULT SET 
		@PEConformance,			--CONFORMANCE
		@PETestPctComplete,		--TESTPCTCOMPLETE
		NULL,					--SECOND USER ID
		NULL,					--APPROVER USER ID
		NULL,					--APPROVER Reason Id
		NULL,					--USER Reason Id
		NULL,					--USER SIGN OFF ID
		NULL,					--EXTENDED_INFO
		NULL,					--SEND EVENT POST
		NULL--,					--SIGNATURE ID
		--NULL,					--LOT INDENTIFIER
		--NULL					--FRIENDYOPERATIONNAME


		IF @RC = -100
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
				@SPName,
				100,
				'Appliance event update failed: ' + CAST(@RC AS VARCHAR(10)),
				NULL	)
				
			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				0,
				'Appliance event update failed: ' + CAST(@RC AS VARCHAR(10))
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
				IF @PEEventId IS NOT NULL
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(	
							GETDATE(),
							@SPName,
							101,
							'Appliance event is updated' +
							'@PEEventId : ' + CAST(@PEEventId AS VARCHAR(30)) ,
							NULL	
							)
					
				END

				-- SET THE SERIAL NUMBER - HOT ADD
				EXEC @RC = [dbo].[spServer_DBMgrUpdEventDet] 
				@User_id,					-- USER_ID
				@PEEventId,					-- EVENT_ID
				@ApplianceTypePUId,			-- PU_ID
				NULL,						-- FUTURE1
				2,							-- TTYPE
				0,							-- TNUM
				@serial_Number,				-- AEN
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
				NULL,						-- PPID
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
					102,
					'Event Details record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
					' @User_Id: ' + CONVERT(varchar(30), COALESCE(@User_Id, 0)) + 
					' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@PEEventId, 0)),
					@PEEventId)

					INSERT INTO @output
					(
						OutputStatus,
						OutputMessage
					)
					VALUES
					(
						0,
						'Event Details record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
						' @User_Id: ' + CONVERT(varchar(30), COALESCE(@User_Id, 0)) + 
						' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@PEEventId, 0))
					)
					SELECT 
					OutputStatus,
					OutputMessage
					FROM @output
					RETURN
						
				END
				ELSE
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							103,
							'Event_Details record creation succeeded',
							@PEEventId
							)
				END

			END
				INSERT INTO @output
				(
					OutputStatus,
					OutputMessage
				)
				VALUES
				(
					1,
					'Appliance event is updated'
				)
	END


	END
	SELECT	OutputStatus,
			OutputMessage
	FROM	@output
	END

