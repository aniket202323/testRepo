

--------------------------------------------------------------------------------------------------
-- Table function: spLocal_CTS_Confirm_Appliance_Transition_Status
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2022-04-07
-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: SQL
-- Description			: This function updates the status of appliance transition events
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2022-04-07		F. Bergeron				Initial Release 


--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
select * from production_status
EXECUTE spLocal_CTS_Confirm_Appliance_Transition_Status 1257085,115,1596,'This is a comment'

*/


CREATE   PROCEDURE [dbo].[spLocal_CTS_Confirm_Appliance_Transition_Status]
(
@Appliance_Event_id					INTEGER = NULL,
@Appliance_Transition_new_status_id	INTEGER = NULL , 
@User_id							INTEGER,
@Comment							varchar(5000)
)


AS
BEGIN
	DECLARE
	@ApplianceTransitionEventId			INTEGER,
	@ApplianceTransitionEventNum		VARCHAR(50),
	@ApplianceTransitionRuleStatusId	INTEGER,
	@ApplianceTransitionExtendedInfo	VARCHAR(500),
	@LenExtInfo							INTEGER,
	@ApplianceTransitionRulePPId		INTEGER,
	@ApplianceTransitionPUId			INTEGER,
	@ApplianceEventNum					VARCHAR(50),
	@RC									INTEGER,
	@Now								DATETIME,
	@SPname								VARCHAR(50),
	@DebugFlag							INTEGER,
	@Machine							VARCHAR(3000),
	@SignatureId						INTEGER,					
	@CommentUserId						INTEGER,
	@CommentId							INTEGER,
	@CommentId2							INTEGER

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



	DECLARE @Output TABLE
	(
		OutputStatus	BIT,
		OutputMessage	VARCHAR(500)
	)
	SET @CommentUserId = @User_id

	SET @now = GETDATE()

	--Get Machine for e-signature
	SET @Machine = (SELECT	sp.value
					FROM	dbo.site_parameters sp WITH(NOLOCK)
							JOIN dbo.parameters p WITH(NOLOCK) ON sp.parm_id = p.parm_id
					WHERE	p.Parm_Name  ='SiteName'
					)
	
	SET @SPname = 'spLocal_CTS_Confirm_Appliance_Transition_Status'
	

	SET		@DebugFlag =(
	SELECT	CONVERT(INT,sp.value) 
	FROM	dbo.site_parameters sp WITH(NOLOCK)
			JOIN dbo.parameters p WITH(NOLOCK)		
				ON sp.parm_Id = p.parm_id
	WHERE	p.parm_Name = 'PG_CTS_StoredProcedure_Log_Level')


	IF @DebugFlag IS NULL
		SET @DebugFlag = 0

	--COLLECT BASIC INFORMATION
	SET @ApplianceEventNum =	(SELECT Event_num 
								FROM	dbo.Events WITH(NOLOCK) 
								WHERE	event_id = @Appliance_Event_id
								)



	SELECT TOP 1	@ApplianceTransitionEventId =  E.event_id,
					@ApplianceTransitionEventNum = E.event_num,
					@ApplianceTransitionExtendedInfo = E.Extended_Info,
					@ApplianceTransitionPUId = E.PU_id,
					@CommentId = E.comment_id
	FROM			dbo.events E WITH(NOLOCK)
					JOIN dbo.event_components EC WITH(NOLOCK)
						ON EC.Event_Id = E.event_id
	WHERE			EC.source_event_id = @Appliance_Event_id
	ORDER BY		EC.Timestamp DESC

	DECLARE @SplitExtendedInfo TABLE(
	DaString VARCHAR(25),
	DaValue VARCHAR(25))

	INSERT INTO @SplitExtendedInfo (DaString)
	SELECT value FROM STRING_SPLIT(@ApplianceTransitionExtendedInfo,',')
	UPDATE @SplitExtendedInfo SET DaValue = SUBSTRING(DaString,CHARINDEX('=',DaString,0)+1,Len(DaString)-CHARINDEX('=',DaString,0)+1)
	
	SET @ApplianceTransitionRulePPId = (SELECT CAST(DaValue AS INTEGER) FROM @SplitExtendedInfo WHERE DaString LIKE 'PPID=%')
	SET @ApplianceTransitionRuleStatusId = (SELECT CAST(DaValue AS INTEGER) FROM @SplitExtendedInfo WHERE DaString LIKE 'SID=%')

	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				1,
				'SP Started:'  + 
				' @Appliance_Event_Id: ' + CONVERT(varchar(30), COALESCE(@Appliance_Event_Id, 0)) + 
				' @Appliance_Transition_new_status_id: ' + CONVERT(varchar(30), COALESCE(@Appliance_Transition_new_status_id, 0)) + 
				' @ApplianceEventNum: ' + COALESCE(@ApplianceEventNum,'') + 
				' @ApplianceTransitionEventId: ' + CONVERT(varchar(30),COALESCE(@ApplianceTransitionEventId, 0)) + 
				' @ApplianceTransitionEventNum: ' + COALESCE(@ApplianceTransitionEventNum,'') + 
				' @User_Id: ' + CONVERT(varchar(30),COALESCE(@User_Id,0)),
				@ApplianceTransitionEventId)
	END

	--Create signature Id
	EXEC	[dbo].[spSDK_AU_ESignature]
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
			@User_Id, 
			@Machine, 
			null, 
			null, 
			@Now
		-----------------------------------------------------------------------------------
		--MANAGE COMMENT
		-----------------------------------------------------------------------------------
		IF @Comment IS NOt NULL
		BEGIN
			IF @DebugFlag >=2
			BEGIN
				INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
				VALUES(	GETDATE(),
						@SPName,
						10,
						' Create comments'   ,
						@ApplianceTransitionEventId)
			END
			EXEC [dbo].[spLocal_CTS_CreateComment] @CommentId,@Comment,@CommentUserId,@CommentId2 OUTPUT
		END


	-----------------------------------------------------------------------------------------------
	-- UPDATE TRANSITION STATUS
	-----------------------------------------------------------------------------------------------		
	SELECT	@PETransactionType = 2,
			@PEEventId = @ApplianceTransitionEventId,	
			@PEEventNum	= @ApplianceTransitionEventNum,
			@PEPUId = @ApplianceTransitionPUId,
			@PEAppliedProduct = (SELECT prod_id from dbo.production_plan WITH(NOLOCK) WHERE PP_Id = @ApplianceTransitionRulePPId),
			@PETimestamp = Timestamp, --DATEADD(millisecond,-Datepart(millisecond,@Now), @now), 
			@PEStartTime = start_time,
			@PEEventStatus = @Appliance_Transition_new_status_id,
			@PESourceEvent = Source_event,
			@PEUpdateType = 0, --Pre Update, 1 would be post update typically used with hot add
			@PEConformance = 0,
			@PETestPctComplete = 0,
			@PETransNum	= 2, -- Update all fields
			@PETestingStatus = NULL,
			@PECommentId = @CommentId2,
			@PEEventSubtypeId = Event_subtype_id,
			@PEEntryOn = @now,
			@PEApprovedUserId = NULL,
			@PESecondUserID	= NULL,
			@PEApprovedReasonId = NULL,
			@PEUserReasonId = NULL,
			@PEUserSignOffId = NULL,
			@PEExtendedInfo = NULL,
			@PESignatureId = @SignatureId
	FROM	dbo.events WITH(NOLOCK) 
	WHERE	event_id = @ApplianceTransitionEventId
/*
	SET @PETransactionType				= 2
	SET @PEEventId						= @ApplianceTransitionEventId	
	SET @PEEventNum						= @ApplianceTransitionEventNum
	SET @PEPUId							= @ApplianceTransitionPUId
	SET @PETimestamp					= DATEADD(millisecond,-Datepart(millisecond,@Now), @now) 
	SET @PEStartTime
	SET @PEEventStatus					= @Appliance_Transition_new_status_id
	SET @PESourceEvent					= NULL
	SET @PEUpdateType					= 0 --Pre Update, 1 would be post update typically used with hot add
	SET @PEConformance					= 0
	SET @PETestPctComplete				= 0
	SET @PETransNum						= 0 -- Update only non null fields
	SET @PETestingStatus				= NULL
	SET @PECommentId					= @CommentId2
	SET @PEEventSubtypeId				= (SELECt event_subtype_id FROM dbo.events WITH(NOLOCK) WHERE event_id = @ApplianceTransitionEventId)
	SET @PEEntryOn						= @now
	SET @PEApprovedUserId				= NULL
	SET @PESecondUserID					= NULL
	SET @PEApprovedReasonId				= NULL
	SET @PEUserReasonId					= NULL
	SET @PEUserSignOffId				= NULL
	SET @PEExtendedInfo					= NULL
	SET @PESignatureId					= @SignatureId
	*/		
	-----------------------------------------------------------------------------------------------------------------------
	-- CREATE PRODUCTION EVENT OF THE NEW APPLIANCE
	-----------------------------------------------------------------------------------------------------------------------

	EXEC @RC = [dbo].[spServer_DBMgrUpdEvent] 
	@PEEventId,				--EVENT_ID
	@PEEventNum,			--EVENT_NUM
	@PEPUId,				--PU_ID
	@PETimestamp,			--TIMESTAMP
	@PEAppliedProduct,		--APPLIED_PRODUCT
	@PESourceEvent,			--SOURCE_EVENT
	@PEEventStatus,			--EVENT_STATUS
	@PETransactionType,		--TTYPE
	@PETransNum,			--TNUM
	@User_id,				--USER_ID
	@PECommentId,			--COMMENT_ID
	@PEEventSubtypeId,		--EVENT_SUBTYPE_ID
	@PETestingStatus,		--TESTING_STATUS
	@PEStartTime,			--START_TIME
	@now,					--ENTRY_ON
	0,						--RETURN RESULT SET 
	@PEConformance,			--CONFORMANCE
	@PETestPctComplete,		--TESTPCTCOMPLETE
	@PESecondUserID,		--SECOND USER ID
	@PEApprovedUserId,		--APPROVER USER ID
	@PEUserReasonId,		--USER Reason Id
	@PEUserSignOffId,		--USER SIGN OFF ID
	@PEExtendedInfo,		--EXTENDED_INFO
	NULL,					--SEND EVENT POST
	@PESignatureId/*,		-- SIGNATURE ID
	NULL,					--LOT INDENTIFIER
	NULL					--FRIENDYOPERATIONNAME 
	*/

	IF @RC = -100
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
			@SPName,
			20,
			'Appliance transition status update failed: ' + CAST(@RC AS VARCHAR(10)),
			@PEEventId)
				
		INSERT INTO @output
		(
			OutputStatus,
			OutputMessage
		)
		VALUES
		(
			0,
			'Appliance transition status update failed: ' + CAST(@RC AS VARCHAR(10))
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
						51,
						'Appliance transition status update succeeded for: ' +
						'@ApplianceTransitionEventId : ' + CAST(@PEEventId AS VARCHAR(30)) ,
						@PEEventId	
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
			'Appliance transition status update succeeded' 
		)
	END

	-----------------------------------------------------------------------------------------------------------------------
 	-- GET EVENT DETAILS INFORMATION
	-----------------------------------------------------------------------------------------------------------------------
	EXEC @RC = [dbo].[spServer_DBMgrUpdEventDet] 
	@User_id,						-- USER_ID
	@PEEventId,						-- EVENT_ID
	@PEPUId,						-- PU_ID
	NULL,							-- FUTURE1
	2,								-- TTYPE
	0,								-- TNUM
	NULL,							-- AEN
	NULL,							-- FUTURE2
	NULL,							-- IDX
	NULL,							-- IDY
	NULL,							-- IDZ
	NULL,							-- IDA
	NULL,							-- FDX
	NULL,							-- FDY
	NULL,							-- FDZ
	NULL,							-- FDA
	NULL,							-- ODX
	NULL,							-- ODY
	NULL,							-- ODZ
	NULL,							-- FUTURE3
	NULL,							-- FUTURE4
	NULL,							-- ORDERID
	NULL,							-- ORDERLINEID
	@ApplianceTransitionRulePPId,	-- PPID
	NULL,							-- PPSETUPDETAILID
	NULL,							-- SHIPMENTID
	NULL,							-- COMMENTID
	@Now,							-- ENTRYON
	@PETimestamp,					-- TIMESTANP
	NULL,							-- FUTURE6
	NULL,							-- SIGNATUREID
	NULL							-- PRODUCTDEFID

	IF @RC = -100
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
		@SPName,
		70,
		'Event Details record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
		' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@User_id, 0)) + 
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
			'Event component record creation failed: ' + CAST(@RC AS VARCHAR(10))  + 
			' @RSUserId: ' + CONVERT(varchar(30), COALESCE(@User_id, 0)) + 
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
		IF @DebugFlag >=2
		BEGIN
			INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
			VALUES	(GETDATE(),
					@SPName,
					71,
					'Event_Details record creation succeeded',
					@PEEventId
					)

			INSERT INTO @output
			(
				OutputStatus,
				OutputMessage
			)
			VALUES
			(
				1,
				''
			)
			SELECT 
			OutputStatus,
			OutputMessage
			FROM @output

			RETURN
		END
	END


	SELECT	OutputStatus,
			OutputMessage
	FROM	@output

END
