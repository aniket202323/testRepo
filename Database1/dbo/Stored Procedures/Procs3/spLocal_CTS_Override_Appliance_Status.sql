
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Override_Appliance_Status
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-11-18
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Called by Web app
-- Description			: Force the appliance status after a malfunction of the system
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-05-18		F. Bergeron				Initial Release 
-- 1.1		2023-01-26		U. Lapierre				Allow to override to Dirty without a Process Order
-- 1.2		2023-02-17		U. Lapierre				Wave 2 - Save all appliance override into local table
-- 1.3		2023-03-30		U. Lapierre				retieve cleaning type for location where appliance can normally be cleaned
--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*

	DECLARE 	
	@OutputStatus					INTEGER,
	@OutputMessage					VARCHAR(500)
	EXECUTE spLocal_CTS_Override_Appliance_Status	1263185,
													10420,
													'Dirty',
													NULL,			--'Minor',
													NULL,
													NULL,			--'094410002-CTS',
													1600,
													'System down for 3 days',
													@OutputStatus OUTPUT,
													@OutputMessage OUTPUT

SELECT	@OutputStatus OUTPUT,
		@OutputMessage OUTPUT
SELECT * FROM production_plan where process_order = '094410005-CTS'


*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Override_Appliance_Status]
	@ApplianceId					INTEGER,
	@LocationPuId					INTEGER,
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
	--=====================================================================================================================
	SET NOCOUNT ON;
	--=====================================================================================================================

	-----------------------------------------------------------------------------------------------------------------------
	-- DECLARE VARIABLES
	-----------------------------------------------------------------------------------------------------------------------
	DECLARE
	@TableIdProdUnit				INTEGER,
	@ReturnValue					INTEGER,
	@DebugFlag						INTEGER,
	@SPName							VARCHAR(250),

	-- APPLIANCE
	@ApplianceSerial				VARCHAR(25),
	@locationDescription			VARCHAR(50),

	-- ESIG
	@Machine						VARCHAR(50),
	@GenericComment					VARCHAR(250),
	@CommentUserId					INTEGER,

	-- CLEANING
	@ApplianceCleaningTypeVarId		INTEGER,
	@CleaningST						DATETIME,
	@CleaningET						DATETIME,

	-- PROCESS ORDER
	@ActivePPStatusId				INTEGER,
	@PendingPPStatusId				INTEGER,
	@CompletePPStatusId				INTEGER,
	@UpdatePPPUId					INTEGER,
	@UpdatePPId						INTEGER,
	
	-- USER DEFINED EVENT
	@UpdateType						INTEGER,
	@EST_Cleaning					INTEGER,
	@UDEStartTime					DATETIME,
	@UDEEndTime						DATETIME,
	@UDEEventId						INTEGER,
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
	@CommentId2						INTEGER

	-- PRODUCTION EVENT
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

	DECLARE 
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
	@AppliedProductId					INTEGER


	/* V1.2 variable to store value to be written in override table*/
	DECLARE	
	@ovAPplianceId						int,
	@ovOrigin_Location					int,
	@ovOrigin_Status					int,
	@ovOrigin_CleanType					varchar(50),
	@ovOrigin_PPID						int,
	@ovOrigin_ProdId					int,
	@ovNew_Location						int,
	@ovNew_Status						int,
	@ovNew_CleanType					varchar(50),
	@ovNew_PPID							int,
	@ovNew_Prodid						int,
	@ovUserId							int,
	@ovTimestamp						datetime,
	@OvCommentId						int,
	@ovOrigin_Status_Desc				varchar(50)



	----------------------------------------------------------------------------------------
	-- COLLECT INFORMATION
	----------------------------------------------------------------------------------------
	SET @SPName =		'spLocal_CTS_Override_Appliance_Status'
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
				' Appliance EventId: ' + CONVERT(varchar(30), COALESCE(@ApplianceId, 0)) + 
				' Location Puid: ' + CONVERT(varchar(30), COALESCE(@LocationPUId, 0)) + 
				' Process Order: ' + @ProcessOrder + 
				' User Id: ' + CONVERT(varchar(30),COALESCE(@UserId,0)),
				@ApplianceId	)
	END


	/* V1.2 Get new values*/
	SET @ovAPplianceId		= @ApplianceId
	SET @ovNew_Location		= @LocationPuId
	SET @ovNew_Status		= (SELECT ProdStatus_Id FROM dbo.production_Status	WITH(NOLOCK) WHERE prodStatus_Desc = @Status)
	SET @ovNew_CleanType	= @CleaningType
	SET @ovNew_Prodid		= (SELECT prod_id		FROM dbo.products_Base		WITH(NOLOCK) WHERE prod_Code = @ProductCode)
	SET @ovNew_PPID			= (SELECT pp_id			FROM dbo.production_Plan	WITH(NOLOCK) WHERE process_order = @ProcessOrder)
	SET @OvUserId			= @UserId
	SET @ovTimestamp		= (SELECT GETDATE()	)


	

	-- GET THE APPLIANCE CURRENT LOCATION INFORMATION
	SELECT TOP 1	@CurrentTransitionEventId = E.Event_Id,
					@CurrentPositionTimestamp = E.timestamp,
					@CurrentPositionStartTime = E.Start_time,
					@CurrentPosition = E.pu_id,
					@CurrentTransitionEDPPID = ED.PP_Id,
					@CurrentTransitionStatusId	= E.Event_Status,
					@CurrentTransitionStatusDesc = PS.ProdStatus_Desc
	FROM			dbo.event_components EC WITH(NOLOCK) 
					JOIN dbo.events E WITH(NOLOCK) 
						ON E.event_id = EC.event_id 
					JOIN dbo.event_details ED WITH(NOLOCK)
						ON ED.event_id = E.event_id
					JOIN dbo.Production_status PS WITH(NOLOCK) 
						ON PS.ProdStatus_Id = E.Event_Status
	WHERE			EC.Source_event_id = @ApplianceId 
	ORDER BY		EC.Timestamp DESC
	



	/* V1.2 Get initial location*/
	SET @ovOrigin_Location = @CurrentPosition

	SELECT	@ovOrigin_Status_Desc = clean_status,
			@ovOrigin_CleanType  = Clean_type
	FROM fnLocal_CTS_Appliance_Status(@ApplianceId,NULL)

	
	SET @ovOrigin_Status = (SELECT ProdStatus_Id	FROM production_status		WITH(NOLOCK) WHERE prodStatus_Desc = @ovOrigin_Status_Desc)
	SET @ovOrigin_PPID = @CurrentTransitionEDPPID
	SET @ovOrigin_ProdId = (SELECT prod_id			FROM dbo.Production_Plan	WITH(NOLOCK) WHERE PP_Id = @ovOrigin_PPID)


	-------------------------------------------------------
	--GET EVENT_SUBTYPE
	---------------------------------------------------------
	SET @EST_Cleaning = (SELECT event_subtype_id
						FROM dbo.event_subtypes WITH(NOLOCK) 
						WHERE event_subtype_desc = 'CTS appliance cleaning')

	--Get Machine for e-signature
	SET @Machine = (SELECT sp.value
					FROM dbo.site_parameters sp		WITH(NOLOCK)
					JOIN dbo.parameters p			WITH(NOLOCK)	ON sp.parm_id = p.parm_id
					WHERE p.Parm_Name  ='SiteName')

	SET @TableIdProdUnit =		(SELECT tableId 
								FROM	dbo.Tables WITH(NOLOCK) 
								WHERE	TableName = 'Prod_Units'	
								)

	SET @GenericComment =	'Appliance status override' 

	-- GET APPLIANCE SERIAL
	SET @ApplianceSerial = (SELECT alternate_event_num FROM dbo.event_details WITH(NOLOCK) WHERE event_id = @ApplianceId)
	IF @comment IS NULL
		SET @comment = ''
	SET @comment =	@GenericComment 
					+ CHAR(13) 
					+ 'For APPLIANCE -----------------'
					+ @ApplianceSerial
					+ CHAR(13) 
					+  'Performed by ----------------'
					+ (SELECT username FROM dbo.users_base WITH(NOLOCK) WHERE user_id = @UserId)
					+ CHAR(13) 
					+ 'Reason -----------------------'
					+ CHAR(13)
					+ @comment

	SET @Now = GETDATE()

	SET @locationDescription = (SELECT pu_desc FROM dbo.prod_units_base WITH(NOLOCK) WHERE pu_id = @LocationPuId)

	SET @ApplianceCleaningTypeVarId = (SELECT var_id FROM dbo.variables_base WITH(NOLOCK) WHERE pu_id = @locationPUId AND event_subtype_id = @EST_Cleaning AND Test_Name = 'Type')
	IF @ApplianceCleaningTypeVarId IS NULL
	BEGIN
		SET @ApplianceCleaningTypeVarId = (	SELECT var_id 
											FROM dbo.variables_base v	WITH(NOLOCK) 
											JOIN dbo.pu_groups pug		WITH(NOLOCK) ON v.pug_id = pug.pug_id 
																						AND pug.pug_desc = 'Appliance Cleaning'
											WHERE v.pu_id = @locationPUId  AND v.Test_Name = 'Type')
	END

	-- GET CLEANING
	DECLARE @Appliance_cleaning TABLE(
	Status						VARCHAR(25),
	type						VARCHAR(25),
	Location_id					INTEGER,
	Location_desc				VARCHAR(50),
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
	Err_Warn					VARCHAR(500),
	UDE_Id						INTEGER
	)
	INSERT INTO @Appliance_cleaning (
				Status,
				type,
				Location_id,
				Location_desc,
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
				Err_Warn,
				UDE_Id)

	SELECT 		Status,
				type,
				Location_id,
				Location_desc,
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
				Err_Warn,
				UDE_Id
	FROM		dbo.fnLocal_CTS_Appliance_Cleanings(@ApplianceId, NULL, GETDATE())

	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				2,
				'write in local table:'  + 
				' User Id: ' + CONVERT(varchar(30),COALESCE(@UserId,0)),
				@ApplianceId	)
	END


	----------------------------------------------------------------------------------------
	-- CASE 1
	-- @STATUS = In use
	-- Create transition event and set status and PP_ID
	----------------------------------------------------------------------------------------
	IF @Status  = 'In use' AND @ProcessOrder IS NOT NULL
	BEGIN
		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					10,
					'New location = ' + CAST(@LocationPUId AS VARCHAR(25)),
					@ApplianceId)
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					11,
					'Current location = ' + CAST(@CurrentPosition AS VARCHAR(25)),
					@ApplianceId
					)
				
			
		END
		SET @PEEventStatus =	(
								SELECT			ProdStatus_Id
								FROM			dbo.Production_status WITH(NOLOCK) 
								WHERE			ProdStatus_Desc = 'In use'
								)
		-- GET THE PROCESS ORDER CORRESPONDING TO @ProcessOrder AT THE LOCATION
		SELECT	@UpdatePPId   =	PP.PP_Id,
				@UpdatePPPUId = PPU.pu_id 
		FROM	dbo.production_plan PP WITH(NOLOCK)
		JOIN	dbo.PrdExec_Path_Units PPU
					ON PPU.Path_Id = PP.path_id
		WHERE	PP.process_order = @ProcessOrder
								
		-- IF NOT IN PP-- ORDER DOWNLOAD FAILED -- DO NOT ACT
		IF @UpdatePPId IS NULL 
		BEGIN
			SET @OutputMessage = 'Update refused - process order does not exist'
			SET @OutputStatus = 0
			RETURN
		END




		-------------------------------------------------------------------------------------
		-- ACTIONS 1. Reject any open cleaning.  Any open cleaning on appliance is rejected
		-------------------------------------------------------------------------------------
		IF (SELECT status FROM @Appliance_cleaning) NOT IN ('Clean','CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
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
					@UDEStatusId = @UDEStatusId,
					@UDEEventId = Event_id
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Appliance_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	
			--E-SIGNATURE IS MANDATORY WHEN OVERRIDING LOCATION STATUS
			IF @SignatureId IS NULL -- IF CLEANING UDE EXISTS AND SIGNATURE IS NOT PRESENT (CLEANING IS STARTED) - CREATE A SIGNATURE - THE ORDER WILL BE CANCELLED
			BEGIN
			-- CREATE/UPDATE SIGNATURE 
				--Create signature Id
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
			-- ADD COMMENT TO EXISTING COMMENT
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			-- UPDATE EXISTING UDE - CLOSE IT
			EXEC @returnValue = [dbo].[spServer_DBMgrUpdUserEvent]
			0,						--Transnum
			'CTS appliance cleaning',-- Event sub type desc 
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
			@UDEEventId,			--eventId
			NULL,					--parent ude id
			@UDEStatusId,			--event status
			1,						--Testing status
			NULL,					--conformance
			NULL,					--test percent complete
			0	

		END 
		

		-- CREATE EVENT AT LOCATION
		SET @PETransactionType				=	1
		SET @PEEventId						=	NULL	
		SET @PEEventNum						=	'OVR' +
												CAST(Datepart(Year,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Month,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Day,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Hour,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Minute,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Second,@Now) AS VARCHAR(10)) 
		SET @PEPUId							=	@LocationPUId
		SET @PETimestamp					=	DATEADD(Second,1,@now)
		SET @PETimestamp					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @PETimestamp) 
		SET @PEAppliedProduct				=	NULL --(SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @DestTransitionEDPPID)
		SET @PESourceEvent					=	NULL
		--SET @PEEventStatus				=	NULL
		SET @PEUpdateType					=	0 --Pre Update, 1 would be post update typically used with hot add
		SET @PEConformance					=	0
		SET @PETestPctComplete				=	0
		SET @PEStartTime					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
		SET @PETransNum						=	0 -- Update only non null fields
		SET @PETestingStatus				=	NULL
		SET @PECommentId					=	@CommentId2
		SET @PEEventSubtypeId				=	NULL
		SET @PEEntryOn						=	@now
		SET @PEApprovedUserId				=	NULL
		SET @PESecondUserID					=	NULL
		SET @PEApprovedReasonId				=	NULL
		SET @PEUserReasonId					=	NULL
		SET @PEUserSignOffId				=	NULL
		SET @PESignatureId					=	NULL

		-- CREATE A COMMENT
		SET @CommentUserId = @UserId
		EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
		-----------------------------------------------------------------------------------------------------------------------
		-- CREATE PRODUCTION EVENT AT DESTINATION - HOT ADD
		-----------------------------------------------------------------------------------------------------------------------
		EXEC @returnValue = [dbo].[spServer_DBMgrUpdEvent] 
		@PEEventId OUTPUT,		--EVENT_ID
		@PEEventNum,			--EVENT_NUM
		@PEPUId,				--PU_ID
		@PETimestamp,			--TIMESTAMP
		@PEAppliedProduct,		--APPLIED_PRODUCT
		NULL,					--SOURCE_EVENT
		@PEEventStatus,			--EVENT_STATUS
		1,						--TTYPE
		0,						--TNUM
		@UserId,				--USER_ID
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


		-----------------------------------------------------------------------------------------------------------------------
		-- CREATE EVENT DETAILS					
 		-----------------------------------------------------------------------------------------------------------------------
		IF NOT EXISTS(SELECT event_id FROM dbo.event_details WITH(NOLOCK) WHERE event_id = @PEEventId) 
		BEGIN 		
			-----------------------------------------------------------------------------------------------------------------------
 			-- GET EVENT DETAILS INFORMATION
			-----------------------------------------------------------------------------------------------------------------------
			-- GET THE PP_ID 
			EXEC @returnValue = [dbo].[spServer_DBMgrUpdEventDet] 
			@UserId,					-- USER_ID
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
			@UpdatePPId,				-- PPID
			NULL,						-- PPSETUPDETAILID
			NULL,						-- SHIPMENTID
			@CommentId2,				-- COMMENTID
			@Now,						-- ENTRYON
			@PETimestamp,				-- TIMESTANP
			NULL,						-- FUTURE6
			NULL,						-- SIGNATUREID
			NULL						-- PRODUCTDEFID

			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				20,
				'Event Details record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					

				SET @OutputStatus = 0
				SET @OutputMessage =	'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							21,
							'Event_Details record creation succeeded',
							@PEEventId
							)
				END
					
			END

		END	 -- EVENT DETAILS

		-----------------------------------------------------------------------------------------------------------------------
		-- CREATE EVENT COMPONENT BETWEEN APPLIANCE PE AND TRANSITION PE CREATED ABOVE - HOT ADD
		-----------------------------------------------------------------------------------------------------------------------
		IF @PEEventId IS NOT NULL
		BEGIN
			EXEC @returnValue = spServer_DBMgrUpdEventComp
			@UserId,						--USER_ID
			@PEEventId,						--EVENT_ID
			@ECComponentId OUTPUT,			--ECID
			@ApplianceId,					--SOURCE_EVENT_ID
			NULL,							--DIMX	
			NULL,							--DIMY
			NULL,							--DIMZ
			NULL,							--DIMA
			0,								--TRANSACTION NUMBER	
			1,								--TRANSACTION TYPE
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


			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				30,
				'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
				' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					
					
					
				SET @OutputStatus = 0
				SET @OutputMessage =	'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
										' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							31,
							'Event_Components record creation succeeded',
							@ECComponentId
							)

					SELECT	@OutputStatus = 1
					SELECT	@OutputMessage = 'Appliance overriden status = In use, Location = ' + @locationDescription
					GOTO LocalOverride  /* v1.2 */
					RETURN
				END
				ELSE
				BEGIN				
					SELECT	@OutputStatus = 1
					SELECT	@OutputMessage = 'Appliance overriden status = In use, Location = ' + @locationDescription
					GOTO LocalOverride  /* v1.2 */
					RETURN
				END
				
			END
		END

	END

	----------------------------------------------------------------------------------------
	-- CASE 2
	-- @STATUS = Clean And @Type = Minor
	-- Need to minor clean at
	----------------------------------------------------------------------------------------
	IF @Status  = 'Clean' AND @CleaningType = 'Minor' AND @ProcessOrder IS NOT NULL
	BEGIN
		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					100,
					'New location = ' + CAST(@LocationPUId AS VARCHAR(25)),
					@ApplianceId)
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					101,
					'Current location = ' + CAST(@CurrentPosition AS VARCHAR(25)),
					@ApplianceId
					)
				
			
		END

		SET @PEEventStatus =	(
								SELECT			ProdStatus_Id
								FROM			dbo.Production_status WITH(NOLOCK) 
								WHERE			ProdStatus_Desc = 'Clean'
								)
		-- GET THE PROCESS ORDER CORRESPONDING TO @ProcessOrder AT THE LOCATION
		SELECT	@UpdatePPId   =	PP.PP_Id,
				@UpdatePPPUId = PPU.pu_id 
		FROM	dbo.production_plan PP WITH(NOLOCK)
		JOIN	dbo.PrdExec_Path_Units PPU
					ON PPU.Path_Id = PP.path_id
		WHERE	PP.process_order = @ProcessOrder
								
		-- IF NOT IN PP-- ORDER DOWNLOAD FAILED -- DO NOT ACT
		IF @UpdatePPId IS NULL 
		BEGIN
			SET @OutputMessage = 'Update refused - process order does not exist'
			SET @OutputStatus = 0
			RETURN
		END


		--Create signature Id if not existing	
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

		




		-------------------------------------------------------------------------------------
		-- ACTIONS 1. Reject any open cleaning.  Any open cleaning on appliance is rejected 
		-------------------------------------------------------------------------------------
		IF (SELECT status FROM @Appliance_cleaning) NOT IN ('Clean','CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
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
					@UDEStatusId = @UDEStatusId,
					@UDEEventId = Event_id
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Appliance_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	

			SET @CommentUserId = @UserId
			-- ADD COMMENT TO EXISTING COMMENT
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			-- UPDATE EXISTING UDE - CLOSE IT
			EXEC @returnValue = [dbo].[spServer_DBMgrUpdUserEvent]
			0,						--Transnum
			'CTS appliance cleaning',-- Event sub type desc 
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
			@UDEEventId,			--eventId
			NULL,					--parent ude id
			@UDEStatusId,			--event status
			1,						--Testing status
			NULL,					--conformance
			NULL,					--test percent complete
			0	

		END 
		

		-- CREATE EVENT AT LOCATION
		SET @PETransactionType				=	1
		SET @PEEventId						=	NULL	
		SET @PEEventNum						=	'OVR' +
												CAST(Datepart(Year,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Month,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Day,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Hour,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Minute,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Second,@Now) AS VARCHAR(10)) 		
		SET @PEPUId							=	@LocationPUId
		SET @PETimestamp					=	DATEADD(Second,1,@now)
		SET @PETimestamp					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @PETimestamp) 
		SET @PEAppliedProduct				=	NULL --(SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @DestTransitionEDPPID)
		SET @PESourceEvent					=	NULL
		--SET @PEEventStatus				=	NULL
		SET @PEUpdateType					=	0 --Pre Update, 1 would be post update typically used with hot add
		SET @PEConformance					=	0
		SET @PETestPctComplete				=	0
		SET @PEStartTime					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
		SET @PETransNum						=	0 -- Update only non null fields
		SET @PETestingStatus				=	NULL
		SET @PECommentId					=	@CommentId2
		SET @PEEventSubtypeId				=	NULL
		SET @PEEntryOn						=	@now
		SET @PEApprovedUserId				=	NULL
		SET @PESecondUserID					=	NULL
		SET @PEApprovedReasonId				=	NULL
		SET @PEUserReasonId					=	NULL
		SET @PEUserSignOffId				=	NULL
		SET @PESignatureId					=	NULL

		-- CREATE A COMMENT
		SET @CommentUserId = @UserId
		EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 2. CREATE PRODUCTION EVENT AT DESTINATION - HOT ADD Timestamp 1 second after start (@Now)
		-----------------------------------------------------------------------------------------------------------------------
		EXEC @returnValue = [dbo].[spServer_DBMgrUpdEvent] 
		@PEEventId OUTPUT,		--EVENT_ID
		@PEEventNum,			--EVENT_NUM
		@PEPUId,				--PU_ID
		@PETimestamp,			--TIMESTAMP
		@PEAppliedProduct,		--APPLIED_PRODUCT
		NULL,					--SOURCE_EVENT
		@PEEventStatus,			--EVENT_STATUS
		1,						--TTYPE
		0,						--TNUM
		@UserId,				--USER_ID
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


		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 3.  CREATE EVENT DETAILS					
 		-----------------------------------------------------------------------------------------------------------------------
		IF NOT EXISTS(SELECT event_id FROM dbo.event_details WITH(NOLOCK) WHERE event_id = @PEEventId) 
		BEGIN 		
			-----------------------------------------------------------------------------------------------------------------------
 			-- GET EVENT DETAILS INFORMATION
			-----------------------------------------------------------------------------------------------------------------------
			-- GET THE PP_ID 
			EXEC @returnValue = [dbo].[spServer_DBMgrUpdEventDet] 
			@UserId,					-- USER_ID
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
			@UpdatePPId,				-- PPID
			NULL,						-- PPSETUPDETAILID
			NULL,						-- SHIPMENTID
			@CommentId2,				-- COMMENTID
			@Now,						-- ENTRYON
			@PETimestamp,				-- TIMESTANP
			NULL,						-- FUTURE6
			NULL,						-- SIGNATUREID
			NULL						-- PRODUCTDEFID

			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				20,
				'Event Details record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					

				SET @OutputStatus = 0
				SET @OutputMessage =	'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							21,
							'Event_Details record creation succeeded',
							@PEEventId
							)
				END
					
			END

		END	 -- EVENT DETAILS

		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 4. CREATE EVENT COMPONENT BETWEEN APPLIANCE PE AND TRANSITION PE CREATED ABOVE - HOT ADD
		-----------------------------------------------------------------------------------------------------------------------
		IF @PEEventId IS NOT NULL
		BEGIN
			EXEC @returnValue = spServer_DBMgrUpdEventComp
			@UserId,						--USER_ID
			@PEEventId,						--EVENT_ID
			@ECComponentId OUTPUT,			--ECID
			@ApplianceId,					--SOURCE_EVENT_ID
			NULL,							--DIMX	
			NULL,							--DIMY
			NULL,							--DIMZ
			NULL,							--DIMA
			0,								--TRANSACTION NUMBER	
			1,								--TRANSACTION TYPE
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


			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				30,
				'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
				' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					
					
					
				SET @OutputStatus = 0
				SET @OutputMessage =	'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
										' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							31,
							'Event_Components record creation succeeded',
							@ECComponentId
							)
					
				END
				
			END
		END

		-------------------------------------------------------------------------------------
		-- ACTION 5. PERFORM MINOR CLEANING 
		-------------------------------------------------------------------------------------
		SET @CommentUserId = @UserId
		-- ADD COMMENT TO EXISTING
		IF @Comment IS NOt NULL
		BEGIN
			EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
		END
		-- COLLECT UDE INFO			

		SET @UDEDesc = 'OVR-ACL-' + CONVERT(varchar(30), @now)
		SET @UDEStartTime	= Dateadd(Second, 2,@now)
		SET @UDEEndTime	= Dateadd(Second, 1,@UDEStartTime)
		SET @UDEUpdateType = 1
		SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Completed')

		--CREATE UDE
		EXEC @returnValue = [dbo].[spServer_DBMgrUpdUserEvent]
		0, 
		'CTS appliance cleaning', 
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
		@ApplianceId,			--eventId
		NULL,					--parent ude id
		@UDEStatusId,			--event status
		1,						--Testing status
		NULL,					--conformance
		NULL,					--test percent complete
		0
			

		--SELECT @ApplianceCleaningTypeVarId, @UserId,@UDEEndTime,@UDEId,@locationPUId
		-- SET THE CLEANING TYPE
		EXEC dbo.spServer_DBMgrUpdTest2 
			@ApplianceCleaningTypeVarId,	--Var_id
			@UserId	,						--User_id
			0,								--Cancelled
			'Minor',						--New_result
			@UDEEndTime,					--result_on
			NULL,							--Transnum
			NULL,							--Comment_id
			NULL,							--ArrayId
			@UDEId,							--event_id
			@locationPUId,					--Pu_id
			@TestId	OUTPUT,					--testId
			NULL,							--Entry_On
			NULL,
			NULL,
			NULL,
			NULL

		SET @UDEUpdateType = 2
		SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Approved')

		--CREATE UDE
		EXEC @returnValue = [dbo].[spServer_DBMgrUpdUserEvent]
		0, 
		'CTS appliance cleaning', 
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
		@ApplianceId,			--eventId
		NULL,					--parent ude id
		@UDEStatusId,			--event status
		1,						--Testing status
		NULL,					--conformance
		NULL,					--test percent complete
		0
		SELECT	@OutputStatus = 1
		SELECT	@OutputMessage = 'Appliance overriden status = Minor clean, Location = ' + @locationDescription
		GOTO LocalOverride  /* v1.2 */
		RETURN




	


	END


	----------------------------------------------------------------------------------------
	-- CASE 3
	-- @STATUS = Clean Major
	-- ACTIONS  1. Complete any active process order.  2. Reject any open cleaning, 3. Perform major cleaning
	----------------------------------------------------------------------------------------
	IF @Status  = 'Clean' AND @CleaningType = 'Major'
	BEGIN

		/* v1.2  set Process order and product to NULL for the override tble */
		SET @ovNew_Prodid = NULL
		SET @ovNew_PPID = NULL


		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					100,
					'New location = ' + CAST(@LocationPUId AS VARCHAR(25)),
					@ApplianceId)
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					101,
					'Current location = ' + CAST(@CurrentPosition AS VARCHAR(25)),
					@ApplianceId
					)
				
			
		END

		SET @PEEventStatus =	(
								SELECT			ProdStatus_Id
								FROM			dbo.Production_status WITH(NOLOCK) 
								WHERE			ProdStatus_Desc = 'Clean'
								)
	/*	-- GET THE PROCESS ORDER CORRESPONDING TO @ProcessOrder AT THE LOCATION
		SELECT	@UpdatePPId   =	PP.PP_Id,
				@UpdatePPPUId = PPU.pu_id 
		FROM	dbo.production_plan PP WITH(NOLOCK)
		JOIN	dbo.PrdExec_Path_Units PPU
					ON PPU.Path_Id = PP.path_id
		WHERE	PP.process_order = @ProcessOrder
								
		-- IF NOT IN PP-- ORDER DOWNLOAD FAILED -- DO NOT ACT
		IF @UpdatePPId IS NULL 
		BEGIN
			SET @OutputMessage = 'Update refused - process order does not exist'
			SET @OutputStatus = 0
			RETURN
		END*/


		--Create signature Id if not existing	
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

		




		-------------------------------------------------------------------------------------
		-- ACTIONS 1. Reject any open cleaning.  Any open cleaning on appliance is rejected 
		-------------------------------------------------------------------------------------
		IF (SELECT status FROM @Appliance_cleaning) NOT IN ('Clean','CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
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
					@UDEStatusId = @UDEStatusId,
					@UDEEventId = Event_id
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Appliance_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	

			SET @CommentUserId = @UserId
			-- ADD COMMENT TO EXISTING COMMENT
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			-- UPDATE EXISTING UDE - CLOSE IT
			EXEC @returnValue = [dbo].[spServer_DBMgrUpdUserEvent]
			0,						--Transnum
			'CTS appliance cleaning',-- Event sub type desc 
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
			@UDEEventId,			--eventId
			NULL,					--parent ude id
			@UDEStatusId,			--event status
			1,						--Testing status
			NULL,					--conformance
			NULL,					--test percent complete
			0	

		END 
		

		-- CREATE EVENT AT LOCATION
		SET @PETransactionType				=	1
		SET @PEEventId						=	NULL	
		SET @PEEventNum						=	'OVR' +
												CAST(Datepart(Year,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Month,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Day,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Hour,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Minute,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Second,@Now) AS VARCHAR(10)) 
		SET @PEPUId							=	@LocationPUId
		SET @PETimestamp					=	DATEADD(Second,1,@now)
		SET @PETimestamp					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @PETimestamp) 
		SET @PEAppliedProduct				=	NULL --(SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @DestTransitionEDPPID)
		SET @PESourceEvent					=	NULL
		--SET @PEEventStatus				=	NULL
		SET @PEUpdateType					=	0 --Pre Update, 1 would be post update typically used with hot add
		SET @PEConformance					=	0
		SET @PETestPctComplete				=	0
		SET @PEStartTime					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
		SET @PETransNum						=	0 -- Update only non null fields
		SET @PETestingStatus				=	NULL
		SET @PECommentId					=	@CommentId2
		SET @PEEventSubtypeId				=	NULL
		SET @PEEntryOn						=	@now
		SET @PEApprovedUserId				=	NULL
		SET @PESecondUserID					=	NULL
		SET @PEApprovedReasonId				=	NULL
		SET @PEUserReasonId					=	NULL
		SET @PEUserSignOffId				=	NULL
		SET @PESignatureId					=	NULL

		-- CREATE A COMMENT
		SET @CommentUserId = @UserId
		EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 2. CREATE PRODUCTION EVENT AT DESTINATION - HOT ADD Timestamp 1 second after start (@Now)
		-----------------------------------------------------------------------------------------------------------------------
		EXEC @returnValue = [dbo].[spServer_DBMgrUpdEvent] 
		@PEEventId OUTPUT,		--EVENT_ID
		@PEEventNum,			--EVENT_NUM
		@PEPUId,				--PU_ID
		@PETimestamp,			--TIMESTAMP
		NULL,					--APPLIED_PRODUCT
		NULL,					--SOURCE_EVENT
		@PEEventStatus,			--EVENT_STATUS
		1,						--TTYPE
		0,						--TNUM
		@UserId,				--USER_ID
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


		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 3.  CREATE EVENT DETAILS					
 		-----------------------------------------------------------------------------------------------------------------------
		IF NOT EXISTS(SELECT event_id FROM dbo.event_details WITH(NOLOCK) WHERE event_id = @PEEventId) 
		BEGIN 		
			-----------------------------------------------------------------------------------------------------------------------
 			-- GET EVENT DETAILS INFORMATION
			-----------------------------------------------------------------------------------------------------------------------
			-- GET THE PP_ID 
			EXEC @returnValue = [dbo].[spServer_DBMgrUpdEventDet] 
			@UserId,					-- USER_ID
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
			NULL,				-- PPID
			NULL,						-- PPSETUPDETAILID
			NULL,						-- SHIPMENTID
			@CommentId2,				-- COMMENTID
			@Now,						-- ENTRYON
			@PETimestamp,				-- TIMESTANP
			NULL,						-- FUTURE6
			NULL,						-- SIGNATUREID
			NULL						-- PRODUCTDEFID

			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				20,
				'Event Details record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					

				SET @OutputStatus = 0
				SET @OutputMessage =	'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							21,
							'Event_Details record creation succeeded',
							@PEEventId
							)
				END

			END

		END	 -- EVENT DETAILS

		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 4. CREATE EVENT COMPONENT BETWEEN APPLIANCE PE AND TRANSITION PE CREATED ABOVE - HOT ADD
		-----------------------------------------------------------------------------------------------------------------------
		IF @PEEventId IS NOT NULL
		BEGIN
			EXEC @returnValue = spServer_DBMgrUpdEventComp
			@UserId,						--USER_ID
			@PEEventId,						--EVENT_ID
			@ECComponentId OUTPUT,			--ECID
			@ApplianceId,					--SOURCE_EVENT_ID
			NULL,							--DIMX	
			NULL,							--DIMY
			NULL,							--DIMZ
			NULL,							--DIMA
			0,								--TRANSACTION NUMBER	
			1,								--TRANSACTION TYPE
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


			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				30,
				'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
				' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					
					
					
				SET @OutputStatus = 0
				SET @OutputMessage =	'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
										' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							31,
							'Event_Components record creation succeeded',
							@ECComponentId
							)
				END
				
			END
		END

		-------------------------------------------------------------------------------------
		-- ACTION 5. PERFORM MAJOR CLEANING 
		-------------------------------------------------------------------------------------
		SET @CommentUserId = @UserId
		-- ADD COMMENT TO EXISTING
		IF @Comment IS NOt NULL
		BEGIN
			EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
		END
		-- COLLECT UDE INFO			

		SET @UDEDesc = 'OVR-ACL-' + CONVERT(varchar(30), @now)
		SET @UDEStartTime	= Dateadd(Second, 2,@now)
		SET @UDEEndTime	= Dateadd(Second, 1,@UDEStartTime)
		SET @UDEUpdateType = 1
		SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Completed')

		--CREATE UDE
		EXEC @returnValue = [dbo].[spServer_DBMgrUpdUserEvent]
		0, 
		'CTS appliance cleaning', 
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
		@ApplianceId,			--eventId
		NULL,					--parent ude id
		@UDEStatusId,			--event status
		1,						--Testing status
		NULL,					--conformance
		NULL,					--test percent complete
		0	

		-- SET THE CLEANING TYPE
		EXEC dbo.spServer_DBMgrUpdTest2 
			@ApplianceCleaningTypeVarId,	--Var_id
			@UserId	,						--User_id
			0,								--Cancelled
			'Major',						--New_result
			@UDEEndTime,					--result_on
			NULL,							--Transnum
			NULL,							--Comment_id
			NULL,							--ArrayId
			@UDEId,							--event_id
			@locationPUId,					--Pu_id
			@TestId	OUTPUT,					--testId
			NULL,							--Entry_On
			NULL,
			NULL,
			NULL,
			NULL
		SET @UDEUpdateType = 2
		SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Approved')

		--CREATE UDE
		EXEC @returnValue = [dbo].[spServer_DBMgrUpdUserEvent]
		0, 
		'CTS appliance cleaning', 
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
		@ApplianceId,			--eventId
		NULL,					--parent ude id
		@UDEStatusId,			--event status
		1,						--Testing status
		NULL,					--conformance
		NULL,					--test percent complete
		0	
					SELECT	@OutputStatus = 1
					SELECT	@OutputMessage = 'Appliance overriden status = Major clean, Location = ' + @locationDescription
					GOTO LocalOverride  /* v1.2 */
		RETURN
	END
	


	----------------------------------------------------------------------------------------
	-- CASE 4
	-- @STATUS = Dirty.  This means that the process order did not complete.
	-- 1. Reject open cleaning 2. Complete the order passed

	----------------------------------------------------------------------------------------

	IF @Status  = 'Dirty' AND  @ProcessOrder IS NOT NULL
	BEGIN

		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					100,
					'New location = ' + CAST(@LocationPUId AS VARCHAR(25)),
					@ApplianceId)
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					101,
					'Current location = ' + CAST(@CurrentPosition AS VARCHAR(25)),
					@ApplianceId
					)
				
			
		END

		SET @PEEventStatus =	(
								SELECT			ProdStatus_Id
								FROM			dbo.Production_status WITH(NOLOCK) 
								WHERE			ProdStatus_Desc = 'Dirty'
								)
		-- GET THE PROCESS ORDER CORRESPONDING TO @ProcessOrder AT THE LOCATION
		SELECT	@UpdatePPId   =	PP.PP_Id,
				@UpdatePPPUId = PPU.pu_id 
		FROM	dbo.production_plan PP WITH(NOLOCK)
		JOIN	dbo.PrdExec_Path_Units PPU
					ON PPU.Path_Id = PP.path_id
		WHERE	PP.process_order = @ProcessOrder
								
		-- IF NOT IN PP-- ORDER DOWNLOAD FAILED -- DO NOT ACT
		IF @UpdatePPId IS NULL 
		BEGIN
			SET @OutputMessage = 'Update refused - process order does not exist'
			SET @OutputStatus = 0
			RETURN
		END

		--SELECT @UserId RETURN
		--CREATE SIGNATURE ID IF NOT EXISTING	

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




		-------------------------------------------------------------------------------------
		-- ACTIONS 1. Reject any open cleaning.  Any open cleaning on appliance is rejected 
		-------------------------------------------------------------------------------------
		IF (SELECT status FROM @Appliance_cleaning) NOT IN ('Clean','CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
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
					@UDEStatusId = @UDEStatusId,
					@UDEEventId = Event_id
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Appliance_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	

			SET @CommentUserId = @UserId
			-- ADD COMMENT TO EXISTING COMMENT
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			-- UPDATE EXISTING UDE - CLOSE IT
			EXEC @returnValue = [dbo].[spServer_DBMgrUpdUserEvent]
			0,						--Transnum
			'CTS appliance cleaning',-- Event sub type desc 
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
			@UDEEventId,			--eventId
			NULL,					--parent ude id
			@UDEStatusId,			--event status
			1,						--Testing status
			NULL,					--conformance
			NULL,					--test percent complete
			0	


		END 
		

		-- CREATE EVENT AT LOCATION
		SET @PETransactionType				=	1
		SET @PEEventId						=	NULL	
		SET @PEEventNum						=	'OVR' +
												CAST(Datepart(Year,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Month,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Day,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Hour,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Minute,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Second,@Now) AS VARCHAR(10)) 
		SET @PEPUId							=	@LocationPUId
		SET @PETimestamp					=	DATEADD(Second,1,@now)
		SET @PETimestamp					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @PETimestamp) 
		SET @PEAppliedProduct				=	NULL --(SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @DestTransitionEDPPID)
		SET @PESourceEvent					=	NULL
		--SET @PEEventStatus				=	NULL
		SET @PEUpdateType					=	0 --Pre Update, 1 would be post update typically used with hot add
		SET @PEConformance					=	0
		SET @PETestPctComplete				=	0
		SET @PEStartTime					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
		SET @PETransNum						=	0 -- Update only non null fields
		SET @PETestingStatus				=	NULL
		SET @PECommentId					=	@CommentId2
		SET @PEEventSubtypeId				=	NULL
		SET @PEEntryOn						=	@now
		SET @PEApprovedUserId				=	NULL
		SET @PESecondUserID					=	NULL
		SET @PEApprovedReasonId				=	NULL
		SET @PEUserReasonId					=	NULL
		SET @PEUserSignOffId				=	NULL
		SET @PESignatureId					=	NULL

		-- CREATE A COMMENT
		SET @CommentUserId = @UserId
		EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT


		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 2. CREATE PRODUCTION EVENT AT DESTINATION - HOT ADD Timestamp 1 second after start (@Now)
		-----------------------------------------------------------------------------------------------------------------------
		EXEC @returnValue = [dbo].[spServer_DBMgrUpdEvent] 
		@PEEventId OUTPUT,		--EVENT_ID
		@PEEventNum,			--EVENT_NUM
		@PEPUId,				--PU_ID
		@PETimestamp,			--TIMESTAMP
		@PEAppliedProduct,		--APPLIED_PRODUCT
		NULL,					--SOURCE_EVENT
		@PEEventStatus,			--EVENT_STATUS
		1,						--TTYPE
		0,						--TNUM
		@UserId,				--USER_ID
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


		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 3.  CREATE EVENT DETAILS					
 		-----------------------------------------------------------------------------------------------------------------------
		IF NOT EXISTS(SELECT event_id FROM dbo.event_details WITH(NOLOCK) WHERE event_id = @PEEventId) 
		BEGIN 		
			-----------------------------------------------------------------------------------------------------------------------
 			-- GET EVENT DETAILS INFORMATION
			-----------------------------------------------------------------------------------------------------------------------

			EXEC @returnValue = [dbo].[spServer_DBMgrUpdEventDet] 
			@UserId,					-- USER_ID
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
			@UpdatePPId,				-- PPID
			NULL,						-- PPSETUPDETAILID
			NULL,						-- SHIPMENTID
			@CommentId2,				-- COMMENTID
			@Now,						-- ENTRYON
			@PETimestamp,				-- TIMESTANP
			NULL,						-- FUTURE6
			NULL,						-- SIGNATUREID
			NULL						-- PRODUCTDEFID

			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				20,
				'Event Details record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					

				SET @OutputStatus = 0
				SET @OutputMessage =	'Event Details record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							21,
							'Event_Details record creation succeeded',
							@PEEventId
							)
				END
					
		
			END

		END	 -- EVENT DETAILS

		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 4. CREATE EVENT COMPONENT BETWEEN APPLIANCE PE AND TRANSITION PE CREATED ABOVE - HOT ADD
		-----------------------------------------------------------------------------------------------------------------------

		IF @PEEventId IS NOT NULL
		BEGIN
			EXEC @returnValue = spServer_DBMgrUpdEventComp
			@UserId,						--USER_ID
			@PEEventId,						--EVENT_ID
			@ECComponentId OUTPUT,			--ECID
			@ApplianceId,					--SOURCE_EVENT_ID
			NULL,							--DIMX	
			NULL,							--DIMY
			NULL,							--DIMZ
			NULL,							--DIMA
			0,								--TRANSACTION NUMBER	
			1,								--TRANSACTION TYPE
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


			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				30,
				'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
				' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					
					
					
				SET @OutputStatus = 0
				SET @OutputMessage =	'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
										' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							31,
							'Event_Components record creation succeeded',
							@ECComponentId
							)
				END
				
			END
		END

			SELECT	@OutputStatus = 1
			SELECT	@OutputMessage = 'Appliance overriden status = Dirty, Location = ' + @locationDescription
			GOTO LocalOverride  /* v1.2 */
		RETURN

		

	END
	
	----------------------------------------------------------------------------------------
	-- CASE 5
	--New in V1.1  allow PrO to be NULL
	-- @STATUS = Dirty.  
	-- 1. Reject open cleaning 

	----------------------------------------------------------------------------------------
	IF @Status  = 'Dirty' AND  @ProcessOrder IS NULL
	BEGIN

		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					200,
					'New location = ' + CAST(@LocationPUId AS VARCHAR(25)),
					@ApplianceId)
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES(	GETDATE(),
					@SPName,
					201,
					'Current location = ' + CAST(@CurrentPosition AS VARCHAR(25)),
					@ApplianceId
					)
				
			
		END

		SET @PEEventStatus =	(
								SELECT			ProdStatus_Id
								FROM			dbo.Production_status WITH(NOLOCK) 
								WHERE			ProdStatus_Desc = 'Dirty'
								)

								

		--SELECT @UserId RETURN
		--CREATE SIGNATURE ID IF NOT EXISTING	

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

		-------------------------------------------------------------------------------------
		-- ACTIONS 1. Reject any open cleaning.  Any open cleaning on appliance is rejected 
		-------------------------------------------------------------------------------------
		IF (SELECT status FROM @Appliance_cleaning) NOT IN ('Clean','CTS_Cleaning_Rejected','CTS_Cleaning_Approved','CTS_Cleaning_Cancelled')
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
					@UDEStatusId = @UDEStatusId,
					@UDEEventId = Event_id
			FROM	dbo.user_defined_events WITH(NOLOCK) 
			WHERE	ude_id = (SELECT UDE_Id FROM @Appliance_cleaning)
		
			SET @UDEStatusId = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc =  'CTS_Cleaning_Rejected')
	

			SET @CommentUserId = @UserId
			-- ADD COMMENT TO EXISTING COMMENT
			IF @Comment IS NOt NULL
			BEGIN
				EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
			END

			-- UPDATE EXISTING UDE - CLOSE IT
			EXEC @returnValue = [dbo].[spServer_DBMgrUpdUserEvent]
			0,						--Transnum
			'CTS appliance cleaning',-- Event sub type desc 
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
			@UDEEventId,			--eventId
			NULL,					--parent ude id
			@UDEStatusId,			--event status
			1,						--Testing status
			NULL,					--conformance
			NULL,					--test percent complete
			0	


		END 
		

		-- CREATE EVENT AT LOCATION
		SET @PETransactionType				=	1
		SET @PEEventId						=	NULL	
		SET @PEEventNum						=	'OVR' +
												CAST(Datepart(Year,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Month,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Day,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Hour,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Minute,@Now) AS VARCHAR(10)) +
												CAST(Datepart(Second,@Now) AS VARCHAR(10)) 
		SET @PEPUId							=	@LocationPUId
		SET @PETimestamp					=	DATEADD(Second,1,@now)
		SET @PETimestamp					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @PETimestamp) 
		SET @PEAppliedProduct				=	NULL --(SELECT prod_id FROM dbo.production_plan WITH(NOLOCK) WHERE pp_id = @DestTransitionEDPPID)
		SET @PESourceEvent					=	NULL
		--SET @PEEventStatus				=	NULL
		SET @PEUpdateType					=	0 --Pre Update, 1 would be post update typically used with hot add
		SET @PEConformance					=	0
		SET @PETestPctComplete				=	0
		SET @PEStartTime					=	DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
		SET @PETransNum						=	0 -- Update only non null fields
		SET @PETestingStatus				=	NULL
		SET @PECommentId					=	@CommentId2
		SET @PEEventSubtypeId				=	NULL
		SET @PEEntryOn						=	@now
		SET @PEApprovedUserId				=	NULL
		SET @PESecondUserID					=	NULL
		SET @PEApprovedReasonId				=	NULL
		SET @PEUserReasonId					=	NULL
		SET @PEUserSignOffId				=	NULL
		SET @PESignatureId					=	NULL

		-- CREATE A COMMENT
		SET @CommentUserId = @UserId
		EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT


		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 2. CREATE PRODUCTION EVENT AT DESTINATION - HOT ADD Timestamp 1 second after start (@Now)
		-----------------------------------------------------------------------------------------------------------------------
		EXEC @returnValue = [dbo].[spServer_DBMgrUpdEvent] 
		@PEEventId OUTPUT,		--EVENT_ID
		@PEEventNum,			--EVENT_NUM
		@PEPUId,				--PU_ID
		@PETimestamp,			--TIMESTAMP
		@PEAppliedProduct,		--APPLIED_PRODUCT
		NULL,					--SOURCE_EVENT
		@PEEventStatus,			--EVENT_STATUS
		1,						--TTYPE
		0,						--TNUM
		@UserId,				--USER_ID
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


		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 3.  CREATE EVENT DETAILS					
 		-----------------------------------------------------------------------------------------------------------------------
		IF NOT EXISTS(SELECT event_id FROM dbo.event_details WITH(NOLOCK) WHERE event_id = @PEEventId) 
		BEGIN 		
			-----------------------------------------------------------------------------------------------------------------------
 			-- GET EVENT DETAILS INFORMATION
			-----------------------------------------------------------------------------------------------------------------------

			EXEC @returnValue = [dbo].[spServer_DBMgrUpdEventDet] 
			@UserId,					-- USER_ID
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
			NULL,						-- PPID
			NULL,						-- PPSETUPDETAILID
			NULL,						-- SHIPMENTID
			@CommentId2,				-- COMMENTID
			@Now,						-- ENTRYON
			@PETimestamp,				-- TIMESTANP
			NULL,						-- FUTURE6
			NULL,						-- SIGNATUREID
			NULL						-- PRODUCTDEFID

			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				20,
				'Event Details record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					

				SET @OutputStatus = 0
				SET @OutputMessage =	'Event Details record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							21,
							'Event_Details record creation succeeded',
							@PEEventId
							)
				END
					
		
			END

		END	 -- EVENT DETAILS

		-----------------------------------------------------------------------------------------------------------------------
		-- ACTION 4. CREATE EVENT COMPONENT BETWEEN APPLIANCE PE AND TRANSITION PE CREATED ABOVE - HOT ADD
		-----------------------------------------------------------------------------------------------------------------------

		IF @PEEventId IS NOT NULL
		BEGIN
			EXEC @returnValue = spServer_DBMgrUpdEventComp
			@UserId,						--USER_ID
			@PEEventId,						--EVENT_ID
			@ECComponentId OUTPUT,			--ECID
			@ApplianceId,					--SOURCE_EVENT_ID
			NULL,							--DIMX	
			NULL,							--DIMY
			NULL,							--DIMZ
			NULL,							--DIMA
			0,								--TRANSACTION NUMBER	
			1,								--TRANSACTION TYPE
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


			IF @returnValue = -100
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
				@SPName,
				230,
				'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
				' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
				' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
				' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
				' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0)),
				@ApplianceId)

					
					
					
				SET @OutputStatus = 0
				SET @OutputMessage =	'Event component record creation failed: ' + CAST(@returnValue AS VARCHAR(10))  + 
										' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@UserId, 0)) + 
										' @PEEventId: ' + CONVERT(varchar(30), COALESCE(@PEEventId, 0)) + 
										' @ECComponentId: ' + CONVERT(varchar(30),COALESCE(@ECComponentId, 0)) + 
										' @ApplianceEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceId, 0))
				RETURN
						
			END
			ELSE
			BEGIN
				IF @DebugFlag >=2
				BEGIN
					INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
					VALUES	(GETDATE(),
							@SPName,
							231,
							'Event_Components record creation succeeded',
							@ECComponentId
							)
				END
				
			END
		END

			SELECT	@OutputStatus = 1
			SELECT	@OutputMessage = 'Appliance overriden status = Dirty, Location = ' + @locationDescription
			GOTO LocalOverride  /* v1.2 */
		RETURN

		

	END

/*Removed in V1.1 
	IF @Status IN ('Dirty','In Use') AND  @ProcessOrder IS NULL
	BEGIN
			
		SELECT	@OutputStatus = 0
		SELECT	@OutputMessage = 'Process order cannot be null'
		RETURN
	END
*/

	IF @Status IN ('Clean') AND @Type = 'Minor' AND @ProcessOrder IS NULL
	BEGIN
		SELECT	@OutputStatus = 0
		SELECT	@OutputMessage = 'Process order cannot be null'
		RETURN
	END

RETURN

LocalOverride:

INSERT Local_CST_ApplianceOverrides (
	ApplianceId			,
	Origin_Location		,
	Origin_Status		,
	Origin_CleanType	,
	Origin_PPID			,
	Origin_Prod_Id		,
	New_Location		,
	New_Status			,
	New_CleanType		,
	New_PPID			,
	New_Prod_Id			,
	UserId				,
	Timestamp			,
	CommentId			,
	EventId
)
VALUES (
	@ovAPplianceId						,
	@ovOrigin_Location					,
	@ovOrigin_Status					,
	@ovOrigin_CleanType					,
	@ovOrigin_PPID						,
	@ovOrigin_ProdId					,
	@ovNew_Location						,
	@ovNew_Status						,
	@ovNew_CleanType					,
	@ovNew_PPID							,
	@ovNew_Prodid						,
	@ovUserId							,
	@ovTimestamp						,
	@CommentId2							,
	@PeEventId
)
		

	





END
