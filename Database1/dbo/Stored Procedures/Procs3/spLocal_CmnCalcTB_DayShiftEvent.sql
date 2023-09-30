
--------------------------------------------------------------------------------------------------
-- Author				: Ugo Lapierre
-- Date created			: 11-Oct-2016
-- Version 				: 1.00
-- SP Type				: Calculation
-- Caller				: 
-- Description			: Create production event for DAY and SHift if there is an active order
--							Use cre_schedule for the shift chnage
--							use standard time for day

-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
--================================================================================================
-- 1.0		11-Oct-2016		Ugo Lapierre					Created Stored Procedure

--================================================================================================


CREATE PROCEDURE [dbo].[spLocal_CmnCalcTB_DayShiftEvent]
		@OutputValue				varchar(25) OUTPUT,
		@puid						int,
		@Timestamp					datetime,
		@Username					varchar(50),
		@InProgressId				int,
		@CompleteId					int,
		@DebugFlagOnline			bit


-- ManualDebug
/*
Declare	@OutputValue	nvarchar(25)

Exec spLocal_CmnCalcTB_DayShiftEvent
	@OutputValue				OUTPUT,
	'PESCO00',				
	'Zone1',
	'0',
	'6-Oct-2016 16:53',
	1,
	14720

	
SELECT @OutputValue as OutputValue
*/


AS
SET NOCOUNT ON

DECLARE		@SPNAME							varchar(255),
			@ppid							int,
			@pathid							int,	
			@UserId							int,
			@ThisDay						datetime,
			@LastShift						datetime,
			@MinPuid						int,
			@CurPpid						int,
			@PO_Starttime					datetime,
			@PO_EndTime						datetime,
			@lastEventId					int,
			@LastTimestamp					datetime,
			@LastStartTime					datetime,
			@LastStatus						int,
			@eventSubtypeId					int,
			@hh								varchar(10),
			@Now							datetime

DECLARE		@TblFldIdULIdHeader				int,
			@PUTblId						int,
			@ULIdHeader						varchar(50),
			@MaxEventNum					varchar(50),
			@ULIdSN							varchar(50),
			@ULId							varchar(50),
			@AltEventNum					varchar(50),
			@EventNum						varchar(50)

DECLARE		@UpdateEventId					int,
			@UpdateStatusId					int,
			@UpdateStartTime				datetime,
			@UpdateTimestamp				datetime,
			@UpdateUpdateType				int,
			@NewEventId						int,
			@NewStatusId					int,
			@NewStartTime					datetime,
			@NewTimestamp					datetime,
			@NewEventNum					varchar(50),
			@NewUpdateType					int


DECLARE @PObyUnit	TABLE (
puid				int,
ppid				int
)

DECLARE	@EventUpds	TABLE (		-- ResultSetType = 1
		Id					int			Primary Key Identity,
		TransactionType		int			NULL,
		EventId				int			NULL,
		EventNum			varchar(25) NULL,
		PUId				int			NULL,
		[TimeStamp]			datetime	NULL,
 		AppliedProduct		int			NULL,
		SourceEvent			int			NULL,
		EventStatus			int			NULL,
		Confirmed			int			NULL,
		UserId				int			NULL,
		PostUpdate			int			NULL,
		Conformance			int			NULL,
		TestPctComplete		int			NULL,
		StartTime			datetime	NULL,
		TransNum			int			NULL,
		TestingStatus		int			NULL,
		CommentId			int			NULL,
		EventSubTypeId		int			NULL,
		EntryOn				datetime	NULL,
		ApprovedUserId		int,
		SecondUserId		int,
		ApprovedReasonId	int,
		UserReaonId			int,
		UserSignOffId		int,
		ExtendedInfo		varchar(255))

DECLARE @EventDetailUpds TABLE(	-- ResultSetType = 10
		Pre					int NULL, 
		UserId				int NULL,
		TransType			int NULL,
		TransNum			int NULL,
		EventId				int NULL,
		PUId				int NULL,
		PriEventNum			varchar(25) NULL,
		AltEventNum			varchar(25) NULL,
		CommentId			int NULL,
		EventType			int NULL,
		OriginalProduct		int NULL,
		AppliedProduct		int NULL,
		EventStatus			int NULL,
		[TimeStamp]			datetime NULL,
		EntryOn				datetime NULL,
		PPSetupDetailId		int NULL,
		ShipmentItemId		int NULL,
		OrderId				int NULL,
		OrderLineId			int NULL,
		PPId				int NULL,
		InitialDimensionX	float NULL,
		InitialDimensionY	float NULL,
		InitialDimensionZ	float NULL,
		InitialDimensionA	float NULL,
		FinalDimensionX		float NULL,
		FinalDimensionY		float NULL,
		FinalDimensionZ		float NULL,
		FinalDimensionA		float NULL,
		OrientationX		float NULL,
		OrientationY		float NULL,
		OrientationZ		float NULL )



			
---------------------------------------------------------------------------
--SET SP name and initiate the SP
---------------------------------------------------------------------------
SET @SPNAME  = 'spLocal_CmnCalcTB_DayShiftEvent'
SELECT @Now = GETDATE()

IF @DebugFlagOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1000 - SP started for time: '+ CONVERT(varchar(30),@Timestamp,20),
				@puid
			)
END


SET @OutputValue = 'No Action'

---------------------------------------------------------------------------
--SET SP name and initiate the SP
---------------------------------------------------------------------------
SET @UserId = (SELECT user_id FROM dbo.users_base WITH(NOLOCK) WHERE username =  @Username)

IF @userid IS NULL
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1100 - Invalid User: ' + @Username,
				@puid
			)
END

IF @DebugFlagOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1150 - username: '+ @Username + 
				' user_id: ' + CONVERT(varchar(30), @userid),
				@puid
			)
END



---------------------------------------------------------------------------
--check for active order on all unit of the path
---------------------------------------------------------------------------
--Get path
SET @pathid = (SELECT top 1 path_id FROM dbo.prdexec_path_units WITH(NOLOCK) WHERE pu_id = @puid)

INSERT @PObyUnit (puid)
SELECT	pepu.pu_id
FROM	dbo.prdexec_path_units pepu		WITH(NOLOCK)	
WHERE path_id = @pathid


IF @DebugFlagOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	SELECT @SPNAME, GETDATE(), '1200 -  pu_id: ' + CONVERT(varchar(30), @puid), @puid
END



---------------------------------------------------------------------------
--Get constant	
---------------------------------------------------------------------------
SELECT	@PUTblId = TableId
FROM	dbo.[Tables] WITH(NOLOCK)
WHERE	TableName = 'Prod_Units'		
			
SELECT	@TblFldIdULIdHeader = Table_Field_Id
FROM	dbo.Table_Fields WITH(NOLOCK)
WHERE	Table_Field_Desc = 'ULId_Header'


---------------------------------------------------------------------------
--Get Day and shift time	
---------------------------------------------------------------------------
--Day
--SELECT @ThisDay = (SELECT DATEADD(HH,-1*datepart(HH,@timestamp), @timestamp))
--SELECT @ThisDay = (SELECT DATEADD(Mi,-1*datepart(Mi,@timestamp), @ThisDay))
--SELECT @ThisDay = (SELECT DATEADD(ss,-1*datepart(ss,@timestamp), @ThisDay))


SELECT @hh =	CONVERT(NVARCHAR(20),Value) 
 				FROM dbo.Property_Equipment_EquipmentClass pp WITH(NOLOCK)
 				JOIN dbo.Equipment e WITH(NOLOCK) ON e.EquipmentId = pp.EquipmentId 
 				WHERE pp.Name = 'PGDayStart' 
 				AND Class = 'Site Common Element'
 				AND e.Type = 'Site'

SELECT @ThisDay =CAST(GETDATE() As date )
SELECT @ThisDay = CAST(CONVERT(varchar(30),@ThisDay,06) + ' ' + @hh as datetime)

IF @DebugFlagOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1300 - This day time: '+ CONVERT(varchar(30),@ThisDay,20),
				@puid
			)
END

--Shift
SET @LastShift = (SELECT MIN(Start_time) FROM dbo.crew_schedule WITH(NOLOCK) WHERE pu_id = @puid AND end_time> @timestamp)

IF @DebugFlagOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
				GETDATE(),
				'1310 - Last shift time: '+ COALESCE(CONVERT(varchar(30),@LastShift,20),'--'),
				@puid
			)
END




---------------------------------------------------------------------------
--Create Missing events	for each units
---------------------------------------------------------------------------
SET @minPuid = (SELECT MIN(puid) FROM @PObyUnit)
WHILE @minPuid IS NOT NULL
BEGIN
	IF @DebugFlagOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
					GETDATE(),
					'1390 -Looped Puid: '+ COALESCE(CONVERT(varchar(30),@minPuid),'0'),
					@puid
				)
	END
	SET		@UpdateEventId					=NULL
	SET		@UpdateStatusId					=NULL
	SET		@UpdateStartTime				=NULL
	SET		@UpdateTimestamp				=NULL
	SET		@NewEventId						=NULL
	SET		@NewStatusId					=NULL
	SET		@NewStartTime					=NULL
	SET		@NewTimestamp					=NULL
	SET		@NewEventNum					=NULL


	--Get ULID header to build an event num
	SET @ULIdHeader = (	SELECT	tfv.Value
						FROM	dbo.Table_Fields_Values tfv	WITH(NOLOCK)
						JOIN dbo.Table_Fields tf		WITH(NOLOCK) ON (tf.Table_Field_Id = tfv.Table_Field_Id)
						JOIN dbo.[Tables] t				WITH(NOLOCK) ON (tf.TableId = t.TableId)
						WHERE	t.TableId = @PUTblId
						AND tfv.Table_Field_Id = @TblFldIdULIdHeader
						AND tfv.KeyId = @minPuid)

	-------------------------------------------------------------------------------
	-- Construct a ULId
	-------------------------------------------------------------------------------
	SET @MaxEventNum = (SELECT max(substring(Event_Num, 1, 19))
						FROM dbo.[Events] WITH(NOLOCK)
						WHERE PU_Id = @minPuid
							AND Event_Num LIKE @ULIdHeader + '%')
				
	SET	@ULIdSN = substring(@MaxEventNum, 10, 19)		

	IF	isnumeric(@ULIdSN) <> 1
	BEGIN
		SET	@ULIdSN = '000000000'
	END
			
	/* Build ULID */
	SET	@ULIdSN = right('000000000' + convert(varchar(25), 1 + convert(int, @ULIdSN)), 9)
		
	EXECUTE [dbo].spLocal_CmnCreateULID 
			@ULID OUTPUT, 
			@ULIDHeader, 
			@ULIdSN	

	SELECT	@NewEventNum = @ULId,
			@AltEventNum = @ULId
	------------------------------------------------------------------------------------



	------------------------------------------------------------------------------------------------------
	--Check for day---------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------
	SET @ppid = NULL
	SET @PO_Starttime = NULL
	SET @PO_EndTime = NULL

	SELECT	@ppid			= pp_id,
			@PO_Starttime	= Start_time,
			@PO_EndTime		= end_time
	FROM dbo.production_plan_starts WITH(NOLOCK) 
	WHERE pu_id = @minPuid
		AND start_time<=@ThisDay
		AND (End_time >@ThisDay OR End_time IS NULL)
						

	IF @DebugFlagOnline = 1
	BEGIN
		INSERT local_debug (CallingSP,timestamp, message, msg)
		VALUES (	@SPNAME,
				GETDATE(),
				'1400 - Day event PO verification' + 
				' @minPuid: '+ COALESCE(CONVERT(varchar(30),@minPuid),'0') +
				' @ppid : ' +CONVERT(varchar(30),  COALESCE(@ppid,0)) + 
				' @PO_Starttime : ' + CONVERT(varchar(30), COALESCE(@PO_Starttime,'01-01-2000'),20) ,
				@puid
			)
	END


	IF @ppid IS NOT NULL AND @ThisDay < @Now
	BEGIN
		IF NOT EXISTS(SELECT event_id FROM dbo.events WHERE pu_id = @minPuid AND STart_time = @ThisDay)
		BEGIN

			--An event must be created
			IF @DebugFlagOnline = 1
			BEGIN
				INSERT local_debug (CallingSP,timestamp, message, msg)
				VALUES (	@SPNAME,
							GETDATE(),
							'1500 - A new Day event needs to be created' + 
							' @minPuid: ' + CONVERT(varchar(30), @minPuid),
							@puid
						)
			END


			--Get last event on the unit
			SET @lastEventId	= NULL
			SET @LastTimestamp	= NULL
			SET @LastStartTime	= NULL
			SET @LastStatus		= NULL


			SELECT	Top 1
					@lastEventId		= event_id,
					@LastTimestamp		= timestamp,
					@LastStartTime		= start_time,
					@LastStatus 		= event_status,
					@eventSubtypeId		= event_subtype_id,
					@EventNum			= event_num
			FROM dbo.events WITH(NOLOCK)
			WHERE pu_id = @minPUid AND start_time>= @PO_Starttime
			ORDER BY TIMESTAMP DESC
		

			--This is the In progress event.  it started before the 
			IF @LastStatus = @InProgressId AND @LastStartTime<@ThisDay
			BEGIN
				--Update end_time of existing event to ThisDay time
				--Set status complete

				SET		@UpdateEventId					=	@lastEventId
				SET		@UpdateStatusId					=	@CompleteId
				SET		@UpdateStartTime				=	@LastStartTime
				SET		@UpdateTimestamp				=	@thisday
				SET		@UpdateUpdateType				=   2


				--Create a new event with status in Progress
				SET		@NewEventId		=	NULL
				SET		@NewStatusId	=	@InProgressId
				SET		@NewStartTime	=	@thisday
				IF @LastTimestamp > @thisday
					SET	@NewTimestamp	=	@LastTimestamp
				ELSE
					SET	@NewTimestamp	=	(SELECT DATEADD(ss,1,@thisday))
				SET		@NewEventNum	=	@ULId
				SET		@NewUpdatetype	=	1
			END



			--This is the In Complete event.  it started before the 
			IF @LastStatus = @CompleteId AND @LastStartTime<@ThisDay AND @LastTimestamp > @thisday
			BEGIN
				-- We need to set update the event to stop at 0:00 and find the following In Progress event and update its time stamp
				SET		@UpdateEventId					=	@lastEventId
				SET		@UpdateStatusId					=	@CompleteId
				SET		@UpdateStartTime				=	@LastStartTime
				SET		@UpdateTimestamp				=	@thisday
				SET		@UpdateUpdateType				=   2


				--Create a new event with status in Progress

				SET		@NewEventId		=	NULL
				SET		@NewStatusId	=	@CompleteId
				SET		@NewStartTime	=	@thisday
				SET		@NewTimestamp	=	@LastTimestamp
				SET		@NewEventNum	=	@ULId
				SET		@NewUpdatetype	=	1
			END
		END

		--EXECUTE actions
		IF @UpdateEventId IS NOT NULL
		BEGIN
			SET @OutputValue = 'New Day '
			--Direct Update.  This is needed to get the latest data when evaluating SHIFT
			EXEC	spServer_DBMgrUpdEvent
						@UpdateEventId OUTPUT,		--@ParamEventId		int OUTPUT,
						@EventNum,					--@ParamEventNum	nvarchar(25),
						@minPUid,					--@ParamPUId		int,
						@UpdateTimestamp,			--@ParamTimeStamp	datetime,
						NULL,						--@ParamAppliedProduct	int,
						NULL,						--@ParamSourceEvent	int,
						@UpdateStatusId,			--@ParamEventStatus	int,
						@UpdateUpdateType,			--@ParamTransactionType	int,
						0,							--@ParamTransNum	int,
						@UserId,					--@ParamUserId		int,
						NULL,						--@ParamCommentId	int,
						@eventSubtypeId,			--@ParamEventSubTypeId	int,
						0,							--@ParamTestingStatus	int,
						@UpdateStartTime,			--@ParamPropStartTime	datetime,
						NULL,						--@ParamPropEntryOn	datetime,
						NULL						--@ParamReturnResultSet	int	


			INSERT	@EventUpds (
				TransactionType, 
				EventId, 
				EventNum, 
				PUId, 
				[TimeStamp],       
				AppliedProduct, 
				SourceEvent, 
				EventStatus, 
				Confirmed, 
				UserId, 
				PostUpdate,
				Conformance, 
				TestPctComplete, 
				StartTime, 
				TransNum, 
				TestingStatus, 
				CommentId,
				EventSubTypeId, 
				EntryOn,
				ApprovedUserId,
				SecondUserId,
				ApprovedReasonId,
				UserReaonId,
				UserSignOffId,
				ExtendedInfo)
			VALUES(	
				@UpdateUpdateType, 
				@UpdateEventId, 
				@EventNum, 
				@minPUid, 
				@UpdateTimestamp,
				NULL, 
				NULL, 
				@UpdateStatusId, 
				NULL, 
				@UserId, 
				1,
				NULL, 
				NULL, 
				@UpdateStartTime, 
				0, 
				0, 
				NULL, 
				@eventSubtypeId, 
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL)
		END

		IF @NewEventNum IS NOT NULL
		BEGIN
			EXEC	spServer_DBMgrUpdEvent
						@NewEventId OUTPUT,		--@ParamEventId		int OUTPUT,
						@NewEventNum,				--@ParamEventNum	nvarchar(25),
						@minPUid,					--@ParamPUId		int,
						@NewTimestamp,				--@ParamTimeStamp	datetime,
						NULL,						--@ParamAppliedProduct	int,
						NULL,						--@ParamSourceEvent	int,
						@NewStatusId,				--@ParamEventStatus	int,
						@NewUpdatetype,				--@ParamTransactionType	int,
						0,							--@ParamTransNum	int,
						@UserId,					--@ParamUserId		int,
						NULL,						--@ParamCommentId	int,
						@eventSubtypeId,			--@ParamEventSubTypeId	int,
						0,							--@ParamTestingStatus	int,
						@NewStartTime,				--@ParamPropStartTime	datetime,
						NULL,						--@ParamPropEntryOn	datetime,
						NULL						--@ParamReturnResultSet	int	


			INSERT	@EventUpds (
				TransactionType, 
				EventId, 
				EventNum, 
				PUId, 
				[TimeStamp],       
				AppliedProduct, 
				SourceEvent, 
				EventStatus, 
				Confirmed, 
				UserId, 
				PostUpdate,
				Conformance, 
				TestPctComplete, 
				StartTime, 
				TransNum, 
				TestingStatus, 
				CommentId,
				EventSubTypeId, 
				EntryOn,
				ApprovedUserId,
				SecondUserId,
				ApprovedReasonId,
				UserReaonId,
				UserSignOffId,
				ExtendedInfo)
			VALUES(	
				@NewUpdateType, 
				@NewEventId, 
				@NewEventNum, 
				@minPUid, 
				@NewTimestamp,
				NULL, 
				NULL, 
				@NewStatusId, 
				NULL, 
				@UserId, 
				1,
				NULL, 
				NULL, 
				@NewStartTime, 
				0, 
				0, 
				NULL, 
				@eventSubtypeId, 
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL)

			-------------------------------------------------------------------------------
			-- Add a new record to the Event_Details table.
			-------------------------------------------------------------------------------
			EXEC	spServer_DBMgrUpdEventDet
					@UserId,				--@ParamUserId int,
					@NewEventId,			--@ParamEventId int,
					@minPUid,				--@ParamPUId int,
					@NewEventNum,			--@ParamEventNum varchar(25),
					@NewUpdatetype,			--@ParamTransType int,
					NULL,					--@ParamTransNum int,
					@NewEventNum,			--@ParamAltEventNum varchar(25),
					@NewStatusId,			--@ParamEventStatus int,
					0,						--@ParamInitialDimX float,
					NULL,					--@ParamInitialDimY float,
					NULL,					--@ParamInitialDimZ float,
					NULL,					--@ParamInitialDimA float,
					0,						--@ParamFinalDimX float,
					NULL,					--@ParamFinalDimY float,
					NULL,					--@ParamFinalDimZ float,
					NULL,					--@ParamFinalDimA float,
					NULL,					--@ParamOrientationX float,
					NULL,					--@ParamOrientationY float,
					NULL,					--@ParamOrientationZ float,
					NULL,					--@ParamProdId int,
					NULL,					--@ParamAppProdId int,
					NULL,					--@ParamOrderId int,
					NULL,					--@ParamOrderLineId int,
					@PPId,					--@ParamPPId int,
					NULL,					--@ParamPPElementId int,
					NULL,					--@ParamShipmentId int,
					NULL,					--@ParamCommentId int,
					NULL,					--@ParamEntryOn datetime,
					@NewTimestamp,			--@ParamTimeStamp datetime,
					@eventSubtypeId			--@ParamEventType int	

		END

	END			--End of Day check


	------------------------------------------------------------------------
	--Verify last shift (if different than @ThisDay)
	------------------------------------------------------------------------
	IF @lastShift IS NOT NULL
	BEGIN
		IF @lastShift <> @ThisDay
		BEGIN
			SET @ppid = NULL
			SET @PO_Starttime = NULL
			SET @PO_EndTime = NULL

			SELECT	@ppid			= pp_id,
					@PO_Starttime	= Start_time,
					@PO_EndTime		= end_time
			FROM dbo.production_plan_starts WITH(NOLOCK) 
			WHERE pu_id = @minPuid
				AND start_time<=@lastShift
				AND (End_time >@lastShift OR End_time IS NULL)

			IF @DebugFlagOnline = 1
			BEGIN
				INSERT local_debug (CallingSP,timestamp, message, msg)
				VALUES (	@SPNAME,
						GETDATE(),
						'1600 - Shift event PO verification' + 
						' @minPuid: '+ COALESCE(CONVERT(varchar(30),@minPuid),'0') +
						' @ppid : ' + COALESCE(CONVERT(varchar(30), @ppid),'0') + 
						' @PO_Starttime : ' + CONVERT(varchar(30),COALESCE(@PO_Starttime,'01-01-2000'),20) ,
						@puid
					)
			END


			IF @ppid IS NOT NULL
			BEGIN
				IF NOT EXISTS(SELECT event_id FROM dbo.events WHERE pu_id = @minPuid AND STart_time = @lastShift)
				BEGIN
					--An event must be created
					IF @DebugFlagOnline = 1
					BEGIN
						INSERT local_debug (CallingSP,timestamp, message, msg)
						VALUES (	@SPNAME,
								GETDATE(),
								'1620 - A new Shift event needs to be created' + 
								' @minPuid: ' + CONVERT(varchar(30), @minPuid),
								@puid
							)
					END


						--Get last event on the unit
					SET @lastEventId	= NULL
					SET @LastTimestamp	= NULL
					SET @LastStartTime	= NULL
					SET @LastStatus		= NULL


					SELECT	Top 1
							@lastEventId		= event_id,
							@LastTimestamp		= timestamp,
							@LastStartTime		= start_time,
							@LastStatus 		= event_status,
							@eventSubtypeId		= event_subtype_id,
							@EventNum			= event_num
					FROM dbo.events WITH(NOLOCK)
					WHERE pu_id = @minPUid AND start_time>= @PO_Starttime
					ORDER BY TIMESTAMP DESC

		
		
					IF @DebugFlagOnline = 1
					BEGIN
						INSERT local_debug (CallingSP,timestamp, message, msg)
						VALUES (	@SPNAME,
								GETDATE(),
								'1640 - Last Status ID: ' + CONVERT(varchar(30), COALESCE(@LastStatus,0)) +
								' @LastStartTime : ' + CONVERT(varchar(30),COALESCE(@LastStartTime,'01-01-2000'),20)							,
								@puid
							)
					END




					--This is the In progress event.  it started before the 
					IF @LastStatus = @InProgressId AND @LastStartTime<@lastShift
					BEGIN

						IF @DebugFlagOnline = 1
						BEGIN
							INSERT local_debug (CallingSP,timestamp, message, msg)
							VALUES (	@SPNAME,
									GETDATE(),
									'1650 - THIS IS THE UPDATE PART',
									@puid
								)
						END

						--Update end_time of existing event to ThisDay time
						--Set status complete

						SET		@UpdateEventId					=	@lastEventId
						SET		@UpdateStatusId					=	@CompleteId
						SET		@UpdateStartTime				=	@LastStartTime
						SET		@UpdateTimestamp				=	@lastShift
						SET		@UpdateUpdateType				=   2


						--Create a new event with status in Progress
						SET		@NewEventId		=	NULL
						SET		@NewStatusId	=	@InProgressId
						SET		@NewStartTime	=	@lastShift
						IF @LastTimestamp > @lastShift
							SET	@NewTimestamp	=	@LastTimestamp
						ELSE
							SET	@NewTimestamp	=	(SELECT DATEADD(ss,1,@lastShift))
						SET		@NewEventNum	=	@ULId
						SET		@NewUpdatetype	=	1
					END


					--This is the In Complete event.  it started before the 
					IF @LastStatus = @CompleteId AND @LastStartTime<@lastShift AND @LastTimestamp > @lastShift
					BEGIN
						-- We need to set update the event to stop at 0:00 and find the following In Progress event and update its time stamp
						SET		@UpdateEventId					=	@lastEventId
						SET		@UpdateStatusId					=	@CompleteId
						SET		@UpdateStartTime				=	@LastStartTime
						SET		@UpdateTimestamp				=	@lastShift
						SET		@UpdateUpdateType				=   2


						--Create a new event with status in Progress

						SET		@NewEventId		=	NULL
						SET		@NewStatusId	=	@CompleteId
						SET		@NewStartTime	=	@lastShift
						SET		@NewTimestamp	=	@LastTimestamp
						SET		@NewEventNum	=	@ULId
						SET		@NewUpdatetype	=	1
					END
					
				
					--EXECUTE actions
					IF @UpdateEventId IS NOT NULL
					BEGIN	
						SET @OutputValue = 'New Shift'

						IF @DebugFlagOnline = 1
						BEGIN
							INSERT local_debug (CallingSP,timestamp, message, msg)
							VALUES (	@SPNAME,
									GETDATE(),
									'1670 - Just before sp server',
									@puid
								)
						END

						--Direct Update.  This is needed to get the latest data when evaluating SHIFT
						EXEC	spServer_DBMgrUpdEvent
									@UpdateEventId OUTPUT,		--@ParamEventId		int OUTPUT,
									@EventNum,					--@ParamEventNum	nvarchar(25),
									@minPUid,					--@ParamPUId		int,
									@UpdateTimestamp,			--@ParamTimeStamp	datetime,
									NULL,						--@ParamAppliedProduct	int,
									NULL,						--@ParamSourceEvent	int,
									@UpdateStatusId,			--@ParamEventStatus	int,
									@UpdateUpdateType,			--@ParamTransactionType	int,
									0,							--@ParamTransNum	int,
									@UserId,					--@ParamUserId		int,
									NULL,						--@ParamCommentId	int,
									@eventSubtypeId,			--@ParamEventSubTypeId	int,
									0,							--@ParamTestingStatus	int,
									@UpdateStartTime,			--@ParamPropStartTime	datetime,
									NULL,						--@ParamPropEntryOn	datetime,
									NULL						--@ParamReturnResultSet	int	


						INSERT	@EventUpds (
							TransactionType, 
							EventId, 
							EventNum, 
							PUId, 
							[TimeStamp],       
							AppliedProduct, 
							SourceEvent, 
							EventStatus, 
							Confirmed, 
							UserId, 
							PostUpdate,
							Conformance, 
							TestPctComplete, 
							StartTime, 
							TransNum, 
							TestingStatus, 
							CommentId,
							EventSubTypeId, 
							EntryOn,
							ApprovedUserId,
							SecondUserId,
							ApprovedReasonId,
							UserReaonId,
							UserSignOffId,
							ExtendedInfo)
						VALUES(	
							@UpdateUpdateType, 
							@UpdateEventId, 
							@EventNum, 
							@minPUid, 
							@UpdateTimestamp,
							NULL, 
							NULL, 
							@UpdateStatusId, 
							NULL, 
							@UserId, 
							1,
							NULL, 
							NULL, 
							@UpdateStartTime, 
							0, 
							0, 
							NULL, 
							@eventSubtypeId, 
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL)
						
					END

					IF @NewEventNum IS NOT NULL
					BEGIN	


						IF @DebugFlagOnline = 1
						BEGIN
							INSERT local_debug (CallingSP,timestamp, message, msg)
							VALUES (	@SPNAME,
									GETDATE(),
									'1670 - Just before sp server to add an event',
									@puid
								)
						END
						EXEC	spServer_DBMgrUpdEvent
									@NewEventId OUTPUT,		--@ParamEventId		int OUTPUT,
									@NewEventNum,				--@ParamEventNum	nvarchar(25),
									@minPUid,					--@ParamPUId		int,
									@NewTimestamp,				--@ParamTimeStamp	datetime,
									NULL,						--@ParamAppliedProduct	int,
									NULL,						--@ParamSourceEvent	int,
									@NewStatusId,				--@ParamEventStatus	int,
									@NewUpdatetype,				--@ParamTransactionType	int,
									0,							--@ParamTransNum	int,
									@UserId,					--@ParamUserId		int,
									NULL,						--@ParamCommentId	int,
									@eventSubtypeId,			--@ParamEventSubTypeId	int,
									0,							--@ParamTestingStatus	int,
									@NewStartTime,				--@ParamPropStartTime	datetime,
									NULL,						--@ParamPropEntryOn	datetime,
									NULL						--@ParamReturnResultSet	int	


						INSERT	@EventUpds (
							TransactionType, 
							EventId, 
							EventNum, 
							PUId, 
							[TimeStamp],       
							AppliedProduct, 
							SourceEvent, 
							EventStatus, 
							Confirmed, 
							UserId, 
							PostUpdate,
							Conformance, 
							TestPctComplete, 
							StartTime, 
							TransNum, 
							TestingStatus, 
							CommentId,
							EventSubTypeId, 
							EntryOn,
							ApprovedUserId,
							SecondUserId,
							ApprovedReasonId,
							UserReaonId,
							UserSignOffId,
							ExtendedInfo)
						VALUES(	
							@NewUpdateType, 
							@NewEventId, 
							@NewEventNum, 
							@minPUid, 
							@NewTimestamp,
							NULL, 
							NULL, 
							@NewStatusId, 
							NULL, 
							@UserId, 
							1,
							NULL, 
							NULL, 
							@NewStartTime, 
							0, 
							0, 
							NULL, 
							@eventSubtypeId, 
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL,
							NULL)

						-------------------------------------------------------------------------------
						-- Add a new record to the Event_Details table.
						-------------------------------------------------------------------------------
						EXEC	spServer_DBMgrUpdEventDet
								@UserId,				--@ParamUserId int,
								@NewEventId,			--@ParamEventId int,
								@minPUid,				--@ParamPUId int,
								@NewEventNum,			--@ParamEventNum varchar(25),
								@NewUpdatetype,			--@ParamTransType int,
								NULL,					--@ParamTransNum int,
								@NewEventNum,			--@ParamAltEventNum varchar(25),
								@NewStatusId,			--@ParamEventStatus int,
								0,						--@ParamInitialDimX float,
								NULL,					--@ParamInitialDimY float,
								NULL,					--@ParamInitialDimZ float,
								NULL,					--@ParamInitialDimA float,
								0,						--@ParamFinalDimX float,
								NULL,					--@ParamFinalDimY float,
								NULL,					--@ParamFinalDimZ float,
								NULL,					--@ParamFinalDimA float,
								NULL,					--@ParamOrientationX float,
								NULL,					--@ParamOrientationY float,
								NULL,					--@ParamOrientationZ float,
								NULL,					--@ParamProdId int,
								NULL,					--@ParamAppProdId int,
								NULL,					--@ParamOrderId int,
								NULL,					--@ParamOrderLineId int,
								@PPId,					--@ParamPPId int,
								NULL,					--@ParamPPElementId int,
								NULL,					--@ParamShipmentId int,
								NULL,					--@ParamCommentId int,
								NULL,					--@ParamEntryOn datetime,
								@NewTimestamp,			--@ParamTimeStamp datetime,
								@eventSubtypeId			--@ParamEventType int	

					END
				END  --End of event doesn't exist
			END
		END
	END

	SET @minPuid = (SELECT MIN(puid) FROM @PObyUnit WHERE puid>@minPuid)
END


--Push Result Sets

-------------------------------------------------------------------------------
-- Send ResultSets - Events and Event Detail
-------------------------------------------------------------------------------
SELECT	
	1 ResultType, 
	Id, 
	TransactionType, 
	EventId, 
	EventNum, 
	PUId,
	convert(nvarchar(25), [TimeStamp], 120) [TimeStamp], 
	AppliedProduct,
	SourceEvent, 
	EventStatus, 
	Confirmed, 
	UserId, 
	PostUpdate, 
	Conformance,
	TestPctComplete, 
	StartTime, 
	TransNum, 
	TestingStatus, 
	CommentId,
	EventSubTypeId, 
	EntryOn,
	ApprovedUserId,
	SecondUserId,
	ApprovedReasonId,
	UserReaonId,
	UserSignOffId,
	ExtendedInfo
FROM	@EventUpds




--An event must be created
IF @DebugFlagOnline = 1
BEGIN
	INSERT local_debug (CallingSP,timestamp, message, msg)
	VALUES (	@SPNAME,
			GETDATE(),
			'2000- End of Stored proc: ' + @OutputValue ,
			@puid
		)
END


SELECT	@OutputValue = @OutputValue
RETURN



