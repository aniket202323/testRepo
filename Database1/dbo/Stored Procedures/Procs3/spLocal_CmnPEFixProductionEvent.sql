CREATE PROCEDURE [dbo].[spLocal_CmnPEFixProductionEvent]
		@puid					int,
		@PO						varchar(30),
		@Debug					bit
AS
DECLARE	@OutputValue			varchar(30),

		@Count					int,
		@PPid					int,
		@ppsStartTime			datetime,
		@ppsEndTime				datetime,
		@ePPid					int,
		@eStartTime				datetime,
		@eTimestamp				datetime,

		--Loop
		@EventId				int,
		@ST						datetime,
		@ET						datetime,
		@LoopPPId				int,

		--PRE/Post
		@PrePPID				int,
		@PreTime				datetime,
		@PostPPID				int,
		@PostTime				datetime, 

		--Last In progress event
		@LastEventId			int,
		@LastEventTimestamp		datetime,
		@LastEventStatus		int,
		@InProgressStatus		int,
		@NewEventTime			datetime,
		@eventSubTypeid			int, 
		@EventNum				varchar(50),
		@dbeEntryOn             datetime,
		@dbeConformance         int,
		@dbeTestPctComplete     int


SELECT  @OutputValue = 'No Change'


DECLARE @Events	TABLE (
		EventId					int,
		StartTime				datetime,
		Timestamp				datetime,
		EventStatus				int,
		PPId					int,
		PRE						bit DEFAULT 0,
		post					bit	DEFAULT 0,
		ChangeRequired			int DEFAULT 0 		
		)



--------------------------------------------------------------
--Fixing a specific PO 
--------------------------------------------------------------
IF @PO IS NOT NULL AND LEN(@PO) = 12
BEGIN

	--get @ppid
	SELECT	@PPid = pp.pp_id,
			@ppsStartTime = pps.start_time,
			@ppsEndTime = pps.end_time
	FROM dbo.production_plan pp			WITH(NOLOCK)
	JOIN dbo.production_plan_starts pps	WITH(NOLOCK)	ON pps.pp_id = pp.pp_id
	WHERE pps.pu_id = @puid
		AND pp.process_order = @PO


	IF @PPid IS NULL
	BEGIN
		SET @OutputValue = 'Invalid PO'
		GOTO TheEnd
	END


	--Get the event just before the PO starts
	INSERT @Events (Eventid, StartTime, timestamp, ppid, PRE)
	SELECT	TOP 1 e.Event_id,
			e.Start_Time, 
			e.timestamp,
			ed.pp_id,
			1
	FROM dbo.events e				WITH(NOLOCK)
	LEFT JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
	WHERE e.pu_id = @puid	AND e.start_time < @ppsStartTime
	ORDER BY Timestamp desc

	--Get all events inside PO time range
	INSERT @Events (Eventid, StartTime, timestamp, ppid)
	SELECT	e.Event_id,
			e.Start_Time, 
			e.timestamp,
			ed.pp_id
	FROM dbo.events e				WITH(NOLOCK)
	LEFT JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
	WHERE e.pu_id = @puid	AND (e.timestamp <= @ppsEndTime OR 	@ppsEndTime IS NULL) AND e.start_time >= @ppsStartTime
	ORDER BY Timestamp desc


	IF @ppsEndTime IS NOT NULL
	BEGIN
		--Get event after the PO
		INSERT @Events (Eventid, StartTime, timestamp, ppid, POST)
		SELECT	TOP 1 e.Event_id,
		e.Start_Time, 
		e.timestamp,
		ed.pp_id,
		1
		FROM dbo.events e				WITH(NOLOCK)
		LEFT JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
		WHERE e.pu_id = @puid	AND e.Timestamp > @ppsEndTime
		ORDER BY Timestamp desc
	END




	-------------------------------------------------------------
	--Validate the event before
	-------------------------------------------------------------
	--The Timestamp must be = to PO start time
	IF (SELECT timestamp FROM @Events WHERE PRE  =1) != @ppsStartTime
	BEGIN
		UPDATE @Events 
		SET timestamp = @ppsStartTime,
			ChangeRequired = 1
		WHERE PRE = 1
	END

	IF (SELECT ppid FROM @Events WHERE PRE  =1) = @ppid
	BEGIN
		--the PPID is Wrong
		SELECT  @preTime = DATEADD(s,-2,@ppsStartTime)
		SET @PrePPID = (	SELECT PP_ID 
							FROM dbo.production_plan_starts 
							WHERE pu_id = @puid
								AND end_time >= @preTime AND Start_time < @preTime)
		UPDATE @Events 
		SET ppid = @PrePPID,
			ChangeRequired = 1
		WHERE PRE = 1
	END



	---------------------------------------------------------------
	--LOOP All event inside the PO time
	-------------------------------------------------------------------
	SET @eventid = (SELECT MIN(eventid) FROM @events WHERE PRE = 0 AND POST = 0)
	WHILE @eventid IS NOT NULL
	BEGIN
		IF @ST IS NULL  --First event of the loop
		BEGIN
			SELECT	@ST = StartTime,
					@ET = Timestamp,
					@LoopPPId = ppid
			FROM @events
			WHERE eventid = @eventid

			--Start_time should be equal to ppsStartTime
			IF @ST <> @ppsStartTime
			BEGIN
				UPDATE @Events
				SET StartTime = @ppsStartTime,
					ChangeRequired = 1
				WHERE eventid = @eventid 
			END
		END
		ELSE
		BEGIN
			IF (SELECT starttime FROM @events WHERE eventid = @eventid) <> @ET
			BEGIN
				UPDATE @Events
				SET StartTime = @ET,
					ChangeRequired = 1
				WHERE eventid = @eventid 
			END

			SELECT	@ST = StartTime,
					@ET = Timestamp,
					@LoopPPId = ppid
			FROM @events
			WHERE eventid = @eventid
		END


		IF @ppsEndTime IS NOT NULL AND @ET>@ppsEndTime  --The timestamp of the event is after the PO endtime
		BEGIN
			SELECT @ET = (SELECT MIN(COALESCE(Starttime, '31-DEC-2999')) FROM @events WHERE StartTime > @st)
			IF @ET > @ppsEndTime
				SET @ET = @ppsEndTime

			UPDATE @Events
			SET timestamp = @ET,
				ChangeRequired = 1
			WHERE eventid = @eventid 
		END
		


		IF @LoopPPId IS NULL
			SET @LoopPPId = 0

		IF @LoopPPId != @ppid
				UPDATE @Events
				SET ppid = @ppid,
					ChangeRequired = 1
				WHERE eventid = @eventid 		


		--next event
		SET @eventid = (SELECT MIN(eventid) FROM @events WHERE PRE = 0 AND POST = 0 AND eventid > @eventid)
	END




	-------------------------------------------------------------
	--Validate the event After
	-------------------------------------------------------------
	--The Timestamp must be = to PO start time
	IF (SELECT starttime FROM @Events WHERE post  =1) != @ppsEndTime
	BEGIN
		UPDATE @Events 
		SET Starttime = @ppsEndTime,
			ChangeRequired = 1
		WHERE post = 1
	END

	IF (SELECT ppid FROM @Events WHERE POST  =1) = @ppid
	BEGIN
		--the PPID is Wrong
		SELECT  @postTime = DATEADD(s,2,@ppsEndTime)
		SET @PostPPID = (	SELECT PP_ID 
							FROM dbo.production_plan_starts 
							WHERE pu_id = @puid
								AND start_time <= @postTime AND (end_time is NULL OR end_time> @postTime) )
		UPDATE @Events 
		SET ppid = @PostPPID,
			ChangeRequired = 1
		WHERE POST = 1
	END


	-------------------------------------------------------------
	--Verify the last event is an In progress event
	-------------------------------------------------------------






	SELECT @po, * FROM @Events

END

--------------------------------------------------------------
--ENd of
--Fixing a specific PO 
--------------------------------------------------------------



--------------------------------------------------------------
--Fixing the last event (PO is NULL)
--------------------------------------------------------------
IF @PO IS NULL
BEGIN
	--Get PO is there is anctiave PO
	SELECT 	@PPid			= pp_id,
			@ppsStartTime	= Start_time
	FROM dbo.Production_Plan_Starts	WITH(NOLOCK)
	WHERE end_time is NULL and pu_id = @puid

		SELECT 	@PPid		,
			@ppsStartTime	

	IF @ppid IS NOT NULL
	BEGIN
		--Fix all event since the beginning of the PO

		--Get the event just before the PO starts
		INSERT @Events (Eventid, StartTime, timestamp, ppid, EventStatus, PRE)
		SELECT	TOP 1 e.Event_id,
				e.Start_Time, 
				e.timestamp,
				ed.pp_id,
				e.event_status,
				1
		FROM dbo.events e				WITH(NOLOCK)
		LEFT JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
		WHERE e.pu_id = @puid	AND e.start_time < @ppsStartTime
		ORDER BY Timestamp desc

		--Get all events inside PO time range
		INSERT @Events (Eventid, StartTime, timestamp, ppid, EventStatus)
		SELECT	e.Event_id,
				e.Start_Time, 
				e.timestamp,
				ed.pp_id,
				e.event_status
		FROM dbo.events e				WITH(NOLOCK)
		LEFT JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
		WHERE e.pu_id = @puid	AND e.start_time >= @ppsStartTime
		ORDER BY Timestamp desc



		-------------------------------------------------------------
		--Validate the event before
		-------------------------------------------------------------
		--The Timestamp must be = to PO start time
		IF (SELECT timestamp FROM @Events WHERE PRE  =1) != @ppsStartTime
		BEGIN
			UPDATE @Events 
			SET timestamp = @ppsStartTime,
				ChangeRequired = 1, 
				eventStatus = 5
			WHERE PRE = 1
		END

		IF (SELECT ppid FROM @Events WHERE PRE  =1) = @ppid
		BEGIN
			--the PPID is Wrong
			SELECT  @preTime = DATEADD(s,-2,@ppsStartTime)
			SET @PrePPID = (	SELECT PP_ID 
								FROM dbo.production_plan_starts 
								WHERE pu_id = @puid
									AND end_time >= @preTime AND Start_time < @preTime)
			UPDATE @Events 
			SET ppid = @PrePPID,
				ChangeRequired = 1
			WHERE PRE = 1
		END

		---------------------------------------------------------------
		--LOOP All event inside the PO time
		-------------------------------------------------------------------
		SET @eventid = (SELECT MIN(eventid) FROM @events WHERE PRE = 0 AND POST = 0)
		WHILE @eventid IS NOT NULL
		BEGIN
			IF @ST IS NULL  --First event of the loop
			BEGIN
				SELECT	@ST = StartTime,
						@ET = Timestamp,
						@LoopPPId = ppid
				FROM @events
				WHERE eventid = @eventid

				--Start_time should be equal to ppsStartTime
				IF @ST <> @ppsStartTime
				BEGIN
					UPDATE @Events
					SET StartTime = @ppsStartTime,
						ChangeRequired = 1
					WHERE eventid = @eventid 
				END
			END
			ELSE
			BEGIN
				IF (SELECT starttime FROM @events WHERE eventid = @eventid) <> @ET
				BEGIN
					UPDATE @Events
					SET StartTime = @ET,
						ChangeRequired = 1
					WHERE eventid = @eventid 
				END

				SELECT	@ST = StartTime,
						@ET = Timestamp,
						@LoopPPId = ppid
				FROM @events
				WHERE eventid = @eventid
			END


			IF @ppsEndTime IS NOT NULL AND @ET>@ppsEndTime  --The timestamp of the event is after the PO endtime
			BEGIN
				SELECT @ET = (SELECT MIN(COALESCE(Starttime, '31-DEC-2999')) FROM @events WHERE StartTime > @st)
				IF @ET > @ppsEndTime
					SET @ET = @ppsEndTime

				UPDATE @Events
				SET timestamp = @ET,
					ChangeRequired = 1
				WHERE eventid = @eventid 
			END
		


			IF @LoopPPId IS NULL
				SET @LoopPPId = 0

			IF @LoopPPId != @ppid
					UPDATE @Events
					SET ppid = @ppid,
						ChangeRequired = 1
					WHERE eventid = @eventid 		


			--next event
			SET @eventid = (SELECT MIN(eventid) FROM @events WHERE PRE = 0 AND POST = 0 AND eventid > @eventid)
		END


		----------------------------------------------------------------------
		--Check if there is an In progress event for the latest PP_ID
		----------------------------------------------------------------------
		--Get the last event 
		SELECT	TOP 1
				@LastEventID		= eventid, 
				@lastEventTimestamp = timestamp,
				@LastEventStatus	= eventstatus
		FROM @events 
		ORDER BY timestamp DESC


		SET @InProgressStatus = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'In Progress')

		IF @LastEventStatus IS NOT NULL AND @LastEventStatus != @InProgressStatus
		BEGIN
			SELECT @NewEventTime = GETDATE()
			SET @NewEventTime = DATEADD(ms,-1*DATEPART(ms,@NewEventTime),@NewEventTime)
			--Create a new production event In progress at the end
			INSERT @events (Eventid, StartTime, timestamp,eventStatus,  ppid, ChangeRequired)
			VALUES (NULL, @lastEventTimestamp, @NewEventTime ,@InProgressStatus,@ppid, 2)


		END





	END
	ELSE
	BEGIN
		--PP_ID is NULL, so NO running PO
		--Get the end time fo the last PO
		--Get PO is there is anctiave PO
		SELECT 	TOP 1	@PPid			= pp_id,
						@ppsStartTime	= Start_time,
						@ppsEndTime		= end_time
		FROM dbo.Production_Plan_Starts	WITH(NOLOCK)
		WHERE pu_id = @puid
		ORDER BY end_time DESC 



		--Get the last event of the last PO
		INSERT @Events (Eventid, StartTime, timestamp, ppid,EventStatus, PRE)
		SELECT	TOP 1 e.Event_id,
				e.Start_Time, 
				e.timestamp,
				ed.pp_id,
				e.event_status,
				1
		FROM dbo.events e				WITH(NOLOCK)
		LEFT JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
		WHERE e.pu_id = @puid	AND e.start_time < @ppsEndTime
		ORDER BY Timestamp desc

		--Get all events inside PO time range
		INSERT @Events (Eventid, StartTime, timestamp, ppid, eventstatus)
		SELECT	e.Event_id,
				e.Start_Time, 
				e.timestamp,
				ed.pp_id, 
				e.event_status
		FROM dbo.events e				WITH(NOLOCK)
		LEFT JOIN dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_id
		WHERE e.pu_id = @puid	AND e.start_time >= @ppsEndTime
		ORDER BY Timestamp desc


		
		-------------------------------------------------------------
		--Validate the event before
		-------------------------------------------------------------
		--The Timestamp must be = to PO start time
		IF (SELECT timestamp FROM @Events WHERE PRE  =1) != @ppsEndTime
		BEGIN
			UPDATE @Events 
			SET timestamp = @ppsEndTime,
				ChangeRequired = 1
			WHERE PRE = 1
		END

		IF (SELECT ppid FROM @Events WHERE PRE  =1) != @ppid
		BEGIN
			UPDATE @Events 
			SET ppid = @ppid,
				ChangeRequired = 1
			WHERE PRE = 1
		END


		---------------------------------------------------------------
		--LOOP All event inside the PO time
		-------------------------------------------------------------------
		SET @eventid = (SELECT MIN(eventid) FROM @events WHERE PRE = 0 AND POST = 0)
		WHILE @eventid IS NOT NULL
		BEGIN
			IF @ST IS NULL  --First event of the loop
			BEGIN
				SELECT	@ST = StartTime,
						@ET = Timestamp,
						@LoopPPId = ppid
				FROM @events
				WHERE eventid = @eventid

				--Start_time should be equal to ppsStartTime
				IF @ST <> @ppsEndTime
				BEGIN
					UPDATE @Events
					SET StartTime = @ppsEndTime,
						ChangeRequired = 1
					WHERE eventid = @eventid 
				END
			END
			ELSE
			BEGIN
				IF (SELECT starttime FROM @events WHERE eventid = @eventid) <> @ET
				BEGIN
					UPDATE @Events
					SET StartTime = @ET,
						ChangeRequired = 1
					WHERE eventid = @eventid 
				END

				SELECT	@ST = StartTime,
						@ET = Timestamp,
						@LoopPPId = ppid
				FROM @events
				WHERE eventid = @eventid
			END

		


			IF @LoopPPId IS NOT NULL
					UPDATE @Events
					SET ppid = NULL,
						ChangeRequired = 1
					WHERE eventid = @eventid 		
			

			--next event
			SET @eventid = (SELECT MIN(eventid) FROM @events WHERE PRE = 0 AND POST = 0 AND eventid > @eventid)
		END
		SET @PPID = NULL

	END


	----------------------------------------------------------------------
	--Check for multiple event at same timestamp
	----------------------------------------------------------------------
	INSERT @events (Eventid, StartTime, timestamp, ppid,EventStatus , ChangeRequired)
	SELECT	e.event_id, 
			e.start_time, 
			e.timestamp,
			ed.pp_id,
			e.event_status,
			3
	FROM dbo.events e				WITH(NOLOCK)
	LEFT join dbo.event_details ed	WITH(NOLOCK)	ON e.event_id = ed.event_ID
	JOIN @events	e1								ON e.timestamp = e1.timestamp AND e.pu_id = @puid
	WHERE e.event_id  NOT IN (SELECT eventid FROM @events)


	----------------------------------------------------------------------
	--Insure there is a last event in Progress
	----------------------------------------------------------------------
	--Get the last event 
	SELECT	TOP 1
			@LastEventID		= eventid, 
			@lastEventTimestamp = timestamp,
			@LastEventStatus	= eventstatus
	FROM @events 
	ORDER BY timestamp DESC


	SET @InProgressStatus = (SELECT prodStatus_id FROM dbo.production_status WITH(NOLOCK) WHERE prodStatus_Desc = 'In Progress')

	IF @LastEventStatus IS NOT NULL AND @LastEventStatus != @InProgressStatus
	BEGIN
		SELECT @NewEventTime = GETDATE()
		SET @NewEventTime = DATEADD(ms,-1*DATEPART(ms,@NewEventTime),@NewEventTime)
		--Create a new production event In progress at the end
		INSERT @events (Eventid, StartTime, timestamp,eventStatus,  ppid, ChangeRequired)
		VALUES (NULL, @lastEventTimestamp, @NewEventTime ,@InProgressStatus,@ppid, 2)


	END
		 



	SELECT @po, * FROM @Events

END


--------------------------------------------------------------
--End of
--Fixing the last event (PO is NULL)
--------------------------------------------------------------



--Events Update
SET @count = (SELECT  COUNT(changeRequired) FROM @events WHERE changeRequired = 1)
IF @count>0 AND @debug = 0
BEGIN
	--------------------------------------------------------------
	--Make event update
	--------------------------------------------------------------
	UPDATE e
	SET	Start_time = ev.starttime,
		timestamp = ev.timestamp
	FROM dbo.events e 
	JOIN @events ev ON e.event_id = ev.eventid
	WHERE ev.ChangeRequired = 1


	--------------------------------------------------------------
	--Make event_details update
	--------------------------------------------------------------
	UPDATE ed
	SET	pp_id = ev.ppid
	FROM dbo.event_details ed
	JOIN @events ev ON ed.event_id = ev.eventid
	WHERE ev.ChangeRequired = 1

	SELECT @OutputValue = CONVERT(varchar(10),@Count) + ' Event updated'

END


--Event deletion
SET @count = (SELECT  COUNT(changeRequired) FROM @events WHERE changeRequired = 3)
IF @count>0 AND @debug = 0
BEGIN
	IF @count > 3  --We want to avoid catastrophy
		GOTO TheEnd

	--------------------------------------------------------------
	--Delete events
	--------------------------------------------------------------
	DELETE dbo.event_details
	WHERE event_id IN (SELECT eventid FROM @events WHERE ChangeRequired = 3)

	DELETE dbo.events
	WHERE event_id IN (SELECT eventid FROM @events WHERE ChangeRequired = 3)

	SELECT @OutputValue = CONVERT(varchar(10),@Count) + ' Event deleted'

END


--Event Creation
SET @count = (SELECT  COUNT(changeRequired) FROM @events WHERE changeRequired = 2)
IF @count>0 AND @debug = 0
BEGIN
	SELECT	@lastEventId	= NULL,
			@LastEventTimeStamp = NULL,
			@NewEventTime = NULL

	SELECT	@LastEventTimeStamp = starttime,
			@NewEventTime = timestamp
	FROM	@events WHERE changeRequired = 2

	SELECT @eventSubTypeid (SELECT event_subtype_id FROM dbo.event_configuration WITH(NOLOCK) WHERE et_id = 1 AND pu_id = @puid)
	SELECT @EventNum = CONVERT(varchar(10), @puid) + '-' +  CONVERT(varchar(30), @NewEventTime)

	--------------------------------------------------------------
	--Create events
	--------------------------------------------------------------
EXECUTE			dbo.spServer_DBMgrUpdEvent
				@lastEventId OUTPUT,
				@EventNum,
				@PUID,
				@NewEventTime,
				NULL,
				NULL,
				@InProgressStatus,
				1,
				NULL,
				1,
				NULL,
				@eventSubTypeid,
				NULL,
				@LastEventTimeStamp,
				@dbeEntryOn             OUTPUT,
				1,
				@dbeConformance         OUTPUT,
				@dbeTestPctComplete     OUTPUT,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL

				EXECUTE		spServer_DBMgrUpdEventDet
		 		1,		--@ParamUserId int,
				@lastEventId,		--@ParamEventId int,
				@PUID,			--@ParamPUId int,
				@EventNum,			--@ParamEventNum varchar(25),
				1,			--@ParamTransType int,
				NULL,				--@ParamTransNum int,
				NULL,				--@ParamAltEventNum varchar(25),
				@InProgressStatus,		--@ParamEventStatus int,
				NULL,					--@ParamInitialDimX float,
				NULL,				--@ParamInitialDimY float,
				NULL,				--@ParamInitialDimZ float,
				NULL,				--@ParamInitialDimA float,
				NULL,					--@ParamFinalDimX float,
				NULL,				--@ParamFinalDimY float,
				NULL,				--@ParamFinalDimZ float,
				NULL,				--@ParamFinalDimA float,
				0,					--@ParamOrientationX float,
				NULL,				--@ParamOrientationY float,
				NULL,				--@ParamOrientationZ float,
				NULL,				--@ParamProdId int,
				NULL,				--@ParamAppProdId int,
				NULL,				--@ParamOrderId int,
				NULL,				--@ParamOrderLineId int,
				@PPID,				--@ParamPPId int,
				NULL,				--@ParamPPElementId int,
				NULL,				--@ParamShipmentId int,
				NULL,				--@ParamCommentId int,
				NULL,				--@ParamEntryOn datetime,
				@NewEventTime,			--@ParamTimeStamp datetime,
				1					--@ParamEventType int


	SELECT @OutputValue = CONVERT(varchar(10),@Count) + ' Created deleted'

END





TheEnd:

SELECT @OutputValue