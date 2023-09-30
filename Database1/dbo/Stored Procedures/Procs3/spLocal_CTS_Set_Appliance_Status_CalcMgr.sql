
--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CTS_Set_Appliance_Status_CalcMgr
--------------------------------------------------------------------------------------------------
-- Author				: Francois Bergeron, Symasol
-- Date created			: 2021-10-27-- Version 				: Version 1.0
-- SP Type				: Proficy Plant Applications
-- Caller				: Called by CalculationMgr
-- Description			: Set the status of the appliance transition event
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ===========================================================================================
-- 1.0		2021-11-04		F. Bergeron				Initial Release 

--================================================================================================
--
--------------------------------------------------------------------------------------------------
-- TEST CODE:
--------------------------------------------------------------------------------------------------
/*
	DECLARE 
	@Output VARCHAR(25)
	EXECUTE spLocal_CTS_Set_Appliance_Status_CalcMgr
	@Output output,
	995678
	SELECT @Output

	SELECT * FROM EVENTS WHERE PU_ID = 8459
	Select * from event_details where pu_id = 8455
	Select * from event_details where event_id  = 986440

*/


CREATE PROCEDURE [dbo].[spLocal_CTS_Set_Appliance_Status_CalcMgr]
	@Output						VARCHAR(25) OUTPUT,
	@ThisEventId				INTEGER



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
	@RSStatusDesc						VARCHAR(25),
	@ApplianceEventId					INTEGER
	

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




	SET @ApplianceEventId =	(
							SELECT	source_event_id 
							FROM	dbo.event_components WITH(NOLOCK) 
							WHERE	event_id = @ThisEventId
							)
	SET @RSStatusDesc =		(
							SELECT	Clean_status 
							FROM	fnLocal_CTS_Appliance_Status(@ApplianceEventId)
							)

						
	SET @RSStatusId =		(
							SELECT	ProdStatus_id 
							FROM	dbo.production_status WITH(NOLOCK) 
							WHERE	ProdStatus_desc = @RSStatusDesc
							)

	SET @RSUserId =			(
							SELECT	user_id
							FROM	dbo.users_base WITH(NOLOCK) 
							WHERE	username = 'CTS'
							)
	-----------------------------------------------------------------------------------------------------------------------
	-- SP BODY
	-----------------------------------------------------------------------------------------------------------------------

	SET @Output = 'OK'
	RETURN
	SET @Now = GETDATE()


	-----------------------------------------------------------------------------------------------------------------------
	-- CREATE PRODUCTION EVENT AT DESTINATION
	-----------------------------------------------------------------------------------------------------------------------
	SELECT 		
			@PETransactionType				= 2,
			@PEEventId						= Event_id,	
			@PEEventNum						= Event_num,
			@PEPUId							= pu_id,
			@PETimestamp					= timestamp,
			@PEAppliedProduct				= Applied_product,
			@PESourceEvent					= Source_event,
			@PEEventStatus					= @RSStatusId,
			@PEUpdateType					= 0, --Pre Update, 1 would be post update typically used with hot add
			@PEConformance					= 0,
			@PETestPctComplete				= 0,
			@PEStartTime					= Start_time,
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
	WHERE	event_id = @ThisEventId

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

	/*
	-----------------------------------------------------------------------------------------------------------------------
	-- CREATE PRODUCTION EVENT AT DESTINATION - HOT ADD
	-----------------------------------------------------------------------------------------------------------------------

	EXEC @RC = [dbo].[spServer_DBMgrUpdEvent] 
	@PEEventId OUTPUT, --EVENT_ID
	@PEEventNum, -- EVENT_NUM
	@PEPUId,		--PU_ID
	@PETimestamp,	--TIMESTAMP
	NULL,			--APPLIED_PRODUCT
	NULL,			--SOURCE_EVENT
	@PEEventStatus,	--EVENT_STATUS
	1,				--TTYPE
	0,				--TNUM
	@RSUserId,		--USER_ID
	NULL,			--COMMENT_ID
	NULL,			--EVENT_SUBTYPE_ID
	NULL,			--TESTING_STATUS
	NULL,			--START_TIME
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

	*/


	


	IF EXISTS(SELECT 1 FROM @RSEvents) 
		SELECT 1,* FROM @RSEvents
				

	SET @Output = 'OK'
		
	
--=====================================================================================================================
	SET NOCOUNT OFF
--=====================================================================================================================


END -- BODY

GRANT EXECUTE ON [dbo].[spLocal_CTS_Set_Appliance_Status_CalcMgr] TO ctsWebService
GRANT EXECUTE ON [dbo].[spLocal_CTS_Set_Appliance_Status_CalcMgr] TO comxclient





