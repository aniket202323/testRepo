
/*=====================================================================================================================
Stored Procedure: splocal_CST_Report_LocationActivities
=======================================================================================================================
 Author					:	U. Lapierre, AutomaTech
 Date created			:	2023-02-27
 Version 				:	Version <1.0>
 SP Type				:	Web
 Caller					:	Called by CTS mobile application - Report
 Description			:	Wave 2 - Get location activities for the report


 Editor tab spacing	: 4


 EDIT HISTORY:
  ===========================================================================================
 1.0		2023-02-22		U. Lapierre			Initial Release 
 1.1		2023-03-27		U. Lapierre			Add maintenance activities for Making Location
 1.2		2023-06-27		U. Lapierre			Adapt for Code review
 1.3		2023-08-08		U.Lapierre			limit report to 6 months


================================================================================================


 TEST CODE:
 EXECUTE splocal_CST_Report_LocationActivities  1268670,'1-Feb-2023','1-Mar-2023'



==================================================================================================*/
CREATE   PROCEDURE [dbo].[splocal_CST_Report_LocationActivities]
	@LocationId				int,
	@StartTime				datetime,
	@EndTime				datetime

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE		@SPNAME				varchar(100) = 'splocal_CST_Report_LocationActivities',
				@DebugFlag		int = 0,
				@PuDesc				varchar(50),
				@StartPrO			datetime,
				@EndPrO				datetime,
				@ProcessOrder		varchar(50),
				@Product			varchar(50),
				@Batch				varchar(50),
				@LAID				int,
				@LocationStatus		varchar(50),
				@NextLAID			int,
				@CleaningType		varchar(30),
				@MinorCleanTime		datetime;

	DECLARE @Output TABLE (
	LAId				int		IDENTITY,
	ActivityType		Varchar(50)	,
	Appliance			varchar(50),
	ApplianceStatus		varchar(50),
	Timestamp			datetime	,
	Location			Varchar(50)	,
	ProcessOrder		Varchar(50)	,
	Product				Varchar(50)	,
	LocationStatus		Varchar(100),
	CleaningType		Varchar(50)	,
	CleaningResult		varchar(100),
	StartTime			datetime	,
	EndTime				datetime	,
	Username			Varchar(50)	,
	ApproverName		varchar(50),
	Override			bit,
	eventid				int,
	puid				int,
	Batch				varchar(100)
	);

	DECLARE @OutputOrdered TABLE (
	LAId				int		IDENTITY,
	ActivityType		Varchar(50)	,
	Appliance			varchar(50),
	ApplianceStatus		varchar(50),
	Timestamp			datetime	,
	Location			Varchar(50)	,
	ProcessOrder		Varchar(50)	,
	Product				Varchar(50)	,
	LocationStatus		Varchar(100),
	CleaningType		Varchar(50)	,
	CleaningResult		varchar(100),
	StartTime			datetime	,
	EndTime				datetime	,
	Username			Varchar(50)	,
	ApproverName		varchar(50),
	Override			bit,
	eventid				int,
	puid				int,
	Batch				varchar(100)
	);

	DECLARE @MovementIn TABLE (
	ComponentId			int,
	ActivityType		Varchar(50)	,
	eventId				int,
	SourceEventId		int,
	Appliance			varchar(50) ,
	StartTime			datetime,
	Timestamp			datetime	,
	Status				Varchar(100),
	ProcessOrder		Varchar(50)	,
	Product				varchar(50),
	Username			Varchar(50)	,
	Override			bit,
	Batch				varchar(50)
	);

	DECLARE @MovementOut TABLE (
	ComponentId			int,
	ActivityType		Varchar(50)	,
	eventId				int,
	SourceEventId		int,
	Appliance			varchar(50) ,
	StartTime			datetime,
	Timestamp			datetime	,
	Status				Varchar(100),
	ProcessOrder		Varchar(50)	,
	Product				varchar(50),
	Username			Varchar(50)	,
	Override			bit,
	Batch				varchar(50)
	);

	DECLARE @PrO	TABLE (
	ppId				int,
	ProcessOrder		varchar(30),
	prodId				int,
	ProdCode			varchar(50),
	Batch				varchar(50),
	StartTime			datetime,
	EndTime				datetime
	);

	DECLARE @Cleanings TABLE (
	UDEID				int,
	ActivityType		Varchar(50)	,
	CleaningResult		varchar(50) ,
	StartTime			datetime	,
	EndTime				datetime	,
	Location			Varchar(50)	,
	Status				Varchar(100),
	UserName			Varchar(50)	,
	Approver			Varchar(50),
	Override			bit,
	CleaningType		varchar(50)
	);

	DECLARE @Overrides TABLE (
	ActivityType		Varchar(50)	,
	New_Location		Varchar(50)	,
	New_Status			Varchar(50)	,
	New_CleanType		Varchar(50)	,
	New_ProcessOrder	Varchar(50)	,
	New_ProdCode		Varchar(50)	,
	New_ProdDesc		Varchar(100),
	UserId				int,
	UserName			Varchar(50)	,
	Timestamp			datetime	,
	eventId				int
	);


	DECLARE @Maintenance	TABLE (
	UDEID				INT,
	ActivityType		VARCHAR(50)	,
	StartTime			DATETIME	,
	EndTime				DATETIME	,
	CleaningResult		VARCHAR(50),
	Location			VARCHAR(50)	,
	Status				VARCHAR(100),
	UserName			VARCHAR(50)	,
	CommentId			INT
	);

/*==========================initialization==========================*/
BEGIN

	SET @DebugFlag =		(SELECT CONVERT(INT,sp.value) 
							FROM	dbo.site_parameters sp		WITH(NOLOCK)
							JOIN	dbo.parameters p			WITH(NOLOCK)		ON sp.parm_Id = p.parm_id
							WHERE p.parm_Name = 'PG_CTS_StoredProcedure_Log_Level');

	IF @DebugFlag IS NULL
		SET @DebugFlag = 0;

	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				1,
				'SP Started' +
				' Start time: ' + CONVERT(varchar(30),@Starttime,120) + 
				' end time: ' + CONVERT(varchar(30),@Endtime,120),
				@LocationId	);
	END

END

/*==========================Limit activities to 6 months ==========================*/
IF DATEDIFF(d,@Starttime,@Endtime) > 180
BEGIN
	SELECT @Starttime = DATEADD(D,-180,@Endtime)
END






/*==========================Get PrO ==========================*/
	BEGIN
		SET @PuDesc = (SELECT pu_desc FROM dbo.prod_units_base WITH(NOLOCK) WHERE pu_id = @LocationId)

		INSERT @PrO (
			ppId				,
			ProcessOrder		,
			prodId				,
			ProdCode			,
			Batch				,
			StartTime			,
			EndTime				)
		SELECT	pps.pp_id,
				pp.process_order,
				pp.prod_id,
				p.prod_code,
				pp.user_General_1,
				pps.start_time,
				pps.end_time
		FROM dbo.production_plan_starts pps		WITH(NOLOCK)
		JOIN dbo.production_plan pp				WITH(NOLOCK)	ON pps.pp_id = pp.pp_id
		JOIN dbo.products_Base p				WITH(NOLOCK)	ON p.prod_id = pp.prod_id
		WHERE pps.pu_id = @locationId
			AND (@EndTime > pps.start_time)
			AND (@Starttime < pps.End_Time OR pps.End_Time IS NULL);


		INSERT @Output	(
			ActivityType		,
			Timestamp			,
			Location			,
			ProcessOrder		,
			Product				,
			puid				,
			Batch	,
			LocationStatus)
		SELECT	'Start of PrO',
				STartTime,
				@Pudesc,
				ProcessOrder,
				prodCode,
				@locationId,
				batch	,
				'In Use'
		FROM @PrO
		WHERE prodcode <> 'CST';


		INSERT @Output	(
			ActivityType		,
			Timestamp			,
			Location			,
			ProcessOrder		,
			Product				,
			puid				,
			Batch				,
			LocationStatus		)
		SELECT	'End of PrO',
				EndTime,
				@Pudesc,
				ProcessOrder,
				prodCode,
				@locationId,
				batch,
				'Dirty'
		FROM @PrO
		WHERE prodcode <> 'CST'
			AND EndTime is NOT NULL;
	END

/*==========================Get Movement In==========================*/
	BEGIN

		DECLARE @EventsIn	TABLE (
			ComponentId			int,
			eventId				int,
			sourceeventId		int,
			Appliance			varchar(50),
			StartTime			datetime,
			Timestamp			datetime
								)

		INSERT @EventsIn (
			ComponentId			,
			eventId				,
			SourceEventId		,
			Appliance			,
			StartTime			,
			Timestamp )
		SELECT	ec.Component_id,
				e.event_Id		,
				e1.event_id,
				ed1.alternate_event_num,
				e.start_time,
				e.timestamp
		FROM dbo.Events e					WITH(NOLOCK)
		LEFT JOIN dbo.event_components ec	WITH(NOLOCK)	ON ec.event_id = e.event_id
		LEFT JOIN dbo.Events e1				WITH(NOLOCK)	ON e1.event_id = ec.source_event_id
		LEFT JOIN dbo.event_details ed1		WITH(NOLOCK)	ON e1.event_id = ed1.event_id
		WHERE e.PU_Id = @locationId
			AND e.TimeStamp >= @StartTime
		ORDER BY e.Timestamp ASC;


		INSERT @MovementIn (
			ComponentId			,
			ActivityType		,
			eventId				,
			SourceEventId		,
			Appliance			,
			StartTime			,
			Timestamp			,
			Status				,
			ProcessOrder		,
			Product				,
			Username			,
			Batch				)
		SELECT	ei.ComponentId,
				'Appliance In',
				ei.eventId		,
				ei.sourceeventId,
				ei.appliance,
				ei.starttime,
				ei.timestamp,
				ps.prodStatus_Desc,  
				pp.process_order, 
				p.prod_code,
				u.username,
				pp.user_general_1
		FROM @EventsIn ei
		JOIN	(	SELECT eh.event_id, eh.event_status, eh.user_id, ROW_NUMBER() OVER(PARTITION BY eh.event_id ORDER BY eh.event_history_id ASC) RO
					FROM event_history eh	WITH(NOLOCK)
					JOIN @EventsIn ei						ON eh.event_id = ei.eventId
				) SUB ON ei.eventId = SUB.Event_Id AND RO = 1
		JOIN production_Status ps			WITH(NOLOCK)	ON SUB.Event_Status = ps.ProdStatus_Id
		JOIN dbo.users_base u				WITH(NOLOCK)	ON SUB.User_Id = u.user_id
		JOIN	(	SELECT edh.event_id, edh.pp_id, ROW_NUMBER() OVER(PARTITION BY edh.event_id ORDER BY STARTtime ASC) RO2
					FROM event_detail_history edh	WITH(NOLOCK)
					JOIN @EventsIn ei						ON edh.event_id = ei.eventId
				) SUB2 ON ei.eventId = SUB2.Event_Id AND RO2 = 1
		LEFT JOIN dbo.production_plan pp	WITH(NOLOCK)	ON pp.pp_id = SUB2.pp_id
		LEFT JOIN dbo.products_base p		WITH(NOLOCK)	ON pp.prod_id = p.prod_id;




		INSERT @Output	(
			ActivityType		,
			Timestamp			,
			Appliance			,
			ProcessOrder		,
			Product				,
			ApplianceStatus		,
			Username			,
			Batch			)
		SELECT	'Appliance IN',
				startTime,
				Appliance,
				ProcessOrder,
				Product,
				Status,
				Username,
				Batch
		FROM @MovementIn;
	END

/*========================== Get Movement out ==========================*/
	BEGIN
		INSERT @MovementOut (
			ActivityType		,
			eventId				,
			SourceEventId		,
			Appliance			,
			Timestamp			,
			Status				,
			ProcessOrder		,
			Product				,
			Username,
			Batch)
		SELECT	'Appliance OUT',
				ec.event_id,
				mi.sourceeventid,
				mi.Appliance,
				e.Start_time,
				ps.prodStatus_Desc,
				pp.process_order,
				p.prod_code,
				u.username,
				pp.user_general_1
		FROM @MovementIn mi
		JOIN (	SELECT MIN (Component_id) as Component_id, mi.componentid as C_Id
				FROM @MovementIn MI
				JOIN dbo.event_components ec ON ec.source_event_id = MI.sourceEventid AND ec.timestamp>= MI.Timestamp
				JOIN dbo.events e			ON e.event_id = ec.event_id AND e.pu_id != @locationid
				GROUP BY mi.Componentid
					) as SUB ON mi.componentid = SUB.C_Id
		JOIN dbo.event_components ec		WITH(NOLOCK)	ON ec.component_id = SUB.Component_id
		JOIN dbo.events e					WITH(NOLOCK)	ON ec.event_id = e.event_id
		JOIN dbo.production_status ps		WITH(NOLOCK)	ON e.event_status = ps.prodStatus_id
		JOIN dbo.users_base u				WITH(Nolock)	ON e.user_Id = u.user_id
		LEFT JOIN dbo.event_details ed		WITH(NOLOCK)	ON e.event_id = ed.event_id
		LEFT JOIN dbo.production_plan pp	WITH(NOLOCK)	ON pp.pp_id = ed.pp_id
		LEFT JOIN dbo.products_base p		WITH(NOLOCK)	ON pp.prod_id = p.prod_id;

		INSERT @Output	(
			ActivityType		,
			Timestamp			,
			Appliance			,
			ProcessOrder		,
			Product				,
			ApplianceStatus		,
			Username			,
			Batch		)
		SELECT	'Appliance OUT',
				Timestamp,
				Appliance,
				ProcessOrder,
				Product,
				Status,
				Username, 
				Batch
		FROM @MovementOUT;
	END


/*==========================Get Cleanings==========================*/
	BEGIN
		INSERT @Cleanings  (
			UDEID				,
			ActivityType		,
			CleaningResult		,
			StartTime			,
			EndTime				,
			Status				,
			UserName			,
			Approver			,
			CleaningType		
		)
		SELECT	ude.ude_id,
				'Cleaning',
				ps.prodstatus_desc,
				ude.Start_Time, 
				ude.end_time,
				CASE
					WHEN ps.prodstatus_desc ='CTS_Cleaning_Approved' THEN 'Clean'
					ELSE 'Dirty'
				END,
				u1.username, 
				u2.username,
				t.Result
		FROM dbo.user_defined_events ude		WITH(NOLOCK)
		LEFT JOIN dbo.production_status ps		WITH(NOLOCK)	ON ude.event_status = ps.prodStatus_id
		JOIN dbo.Event_Subtypes es				WITH(NOLOCK)	ON es.Event_Subtype_Id = ude.Event_Subtype_Id
		LEFT JOIN dbo.esignature esig			WITH(NOLOCK)	ON ude.signature_id = esig.signature_id
		LEFT JOIN dbo.users_Base u1				WITH(NOLOCK)	ON esig.perform_user_id = u1.user_id
		LEFT JOIN dbo.users_Base u2				WITH(NOLOCK)	ON esig.verify_user_id = u2.user_id
		JOIN dbo.Variables_Base v			WITH(NOLOCK)	ON v.PU_Id = @LocationId AND v.Test_Name = 'type' AND v.event_subtype_id = ude.Event_Subtype_Id
		JOIN dbo.Tests t					WITH(NOLOCK)	ON v.Var_Id = t.Var_Id AND t.Result_On = ude.end_time
		WHERE es.Event_Subtype_Desc = 'CTS Location cleaning'
			AND ude.pu_id = @LocationId
			AND ude.end_time>= @Starttime
			AND UDE.Start_time < @EndTime;

		INSERT @Cleanings  (
			UDEID				,
			ActivityType		,
			CleaningResult		,
			StartTime			,
			EndTime				,
			Status				,
			UserName			,
			Approver			,
			CleaningType		
		)
		SELECT	TOP 1 ude.ude_id,
				'Cleaning',
				ps.prodstatus_desc,
				ude.Start_Time, 
				ude.end_time,
				CASE
					WHEN ps.prodstatus_desc ='CTS_Cleaning_Approved' THEN 'Clean'
					ELSE 'Dirty'
				END,
				u1.username, 
				u2.username,
				t.Result
		FROM dbo.user_defined_events ude		WITH(NOLOCK)
		LEFT JOIN dbo.production_status ps		WITH(NOLOCK)	ON ude.event_status = ps.prodStatus_id
		JOIN dbo.Event_Subtypes es				WITH(NOLOCK)	ON es.Event_Subtype_Id = ude.Event_Subtype_Id
		LEFT JOIN dbo.esignature esig			WITH(NOLOCK)	ON ude.signature_id = esig.signature_id
		LEFT JOIN dbo.users_Base u1				WITH(NOLOCK)	ON esig.perform_user_id = u1.user_id
		LEFT JOIN dbo.users_Base u2				WITH(NOLOCK)	ON esig.verify_user_id = u2.user_id
		JOIN dbo.Variables_Base v			WITH(NOLOCK)	ON v.PU_Id = @LocationId AND v.Test_Name = 'type' AND v.event_subtype_id = ude.Event_Subtype_Id
		JOIN dbo.Tests t					WITH(NOLOCK)	ON v.Var_Id = t.Var_Id AND t.Result_On = ude.end_time
		WHERE es.Event_Subtype_Desc = 'CTS Location cleaning'
			AND ude.pu_id = @LocationId
			AND UDE.End_Time < @Starttime
		ORDER BY ude.End_Time DESC;


		INSERT @Output (
			ActivityType		,
			Timestamp			,
			CleaningResult		,
			LocationStatus		,
			CleaningType		,
			StartTime			,
			EndTime				,
			Username			,
			ApproverName	)	
		SELECT 	ActivityType		,
				EndTime				,
				CleaningResult		,	
				Status				,
				CleaningType		,
				StartTime			,	
				EndTime				,
				UserName			,
				Approver	
		FROM @Cleanings;


	END

/*========================== Get Maintenance ==========================*/
	BEGIN
		INSERT @Maintenance (
			UDEID				,
			ActivityType			,
			StartTime				,
			EndTime					,
			CleaningResult			,
			status					,
			UserName				,
			CommentId	)
			SELECT	ude.ude_id,
					'Maintenance',
					ude.Start_Time, 
					ude.end_time,
					ps.prodstatus_desc,
					'Dirty',
					u1.username, 
					ude.comment_id
			FROM dbo.user_defined_events ude		WITH(NOLOCK)
			JOIN dbo.production_status ps		WITH(NOLOCK)	ON ude.event_status = ps.prodStatus_id
			JOIN dbo.Event_Subtypes es				WITH(NOLOCK)	ON es.Event_Subtype_Id = ude.Event_Subtype_Id
			JOIN dbo.users_Base u1					WITH(NOLOCK)	ON ude.user_id = u1.user_id
			WHERE es.Event_Subtype_Desc = 'CST Maintenance'
				AND ude.pu_id = @LocationId
				AND ude.end_time>= @Starttime
				AND UDE.Start_time < @EndTime	;	


			INSERT @Output (
				ActivityType		,
				Timestamp			,
				LocationStatus		,
				CleaningResult		,
				StartTime			,
				EndTime				,
				Username			
		)	
			SELECT 	ActivityType		,
					EndTime				,
					Status				,
					CleaningResult		,
					StartTime			,	
					EndTime				,
					UserName			
			FROM @Maintenance;

	END



/*========================== Get Overrides ==========================*/
	BEGIN
		INSERT @Overrides  (
		ActivityType		,
		New_Status			,
		New_CleanType		,
		New_ProcessOrder	,
		New_ProdCode		,
		New_ProdDesc		,
		UserId				,
		UserName			,
		Timestamp		
		)
		SELECT	'Override',
				psn.prodstatus_desc,
				o.New_CleanType,
				ppn.process_order,
				pn.prod_code, 
				pn.prod_desc,
				o.userId,
				u.username,
				o.timestamp
		FROM dbo.Local_CST_LocationOverrides	o	WITH(NOLOCK)
		JOIN dbo.production_status	psn				WITH(NOLOCK)	ON o.New_Status = psn.prodStatus_id
		LEFT JOIN dbo.production_plan ppn			WITH(NOLOCK)	ON o.New_PPID = ppn.pp_id
		LEFT JOIN dbo.products_base pn				WITH(NOLOCK)	ON o.New_Prod_Id = pn.prod_id
		JOIN dbo.users_base u						WITH(NOLOCK)	ON o.userid = u.user_id
		WHERE o.LocationId = @LocationId
			AND o.timestamp > @starttime
			AND o.timestamp <=@endtime
		ORDER BY timestamp ASC;




	/*2 add other overrides)*/
		INSERT INTO @Output (	
			ActivityType		,
			Timestamp			,
			LocationStatus		,
			CleaningType		,
			ProcessOrder		,
			Product				,
			Username			
				)
		SELECT 	ActivityType		,
				Timestamp			,
				New_Status			,
				New_CleanType		,
				New_ProcessOrder	,
				New_ProdCode		,
				UserName			
		FROM @Overrides
		WHERE eventId IS NULL;

	END


/* ========================== Fill holes ==========================*/

	BEGIN
		INSERT @OutputOrdered (	ActivityType,
				Timestamp,
				LocationStatus,
				ProcessOrder,
				Product,
				Batch,
				CleaningType,
				CleaningResult,
				StartTime,
				EndTime,
				Appliance,
				ApplianceStatus,
				Username,
				ApproverName)
		SELECT 	ActivityType,
				Timestamp,
				LocationStatus,
				ProcessOrder,
				Product,
				Batch,
				CleaningType,
				CleaningResult,
				StartTime,
				EndTime,
				Appliance,
				ApplianceStatus,
				Username,
				ApproverName
		FROM @Output
		ORDER BY timestamp ;


/*========================== Cleaning Holes ==========================*/

		SET @NextLAID = (SELECT MIN(LAID) FROM @OutputOrdered WHERE LocationStatus IS NULL);

		WHILE @NextLAID IS NOT NULL
		BEGIN
			SET @LAID = (SELECT MAX(LAID) FROM @OutputOrdered WHERE LAID < @NextLAID AND LocationStatus IS NOT NULL);

			SELECT	@LocationStatus = LocationStatus, 
					@CleaningType	= CleaningType
			FROM @OutputOrdered
			WHERE LAID = @LAID;


			UPDATE @OutputOrdered
			SET LocationStatus = @LocationStatus,
				CleaningType = @CleaningType
			WHERE LAID > @LAID
				AND LAID <= @NEXTLAID;

			SET @NextLAID = (SELECT MIN(LAID) FROM @OutputOrdered WHERE LocationStatus IS NULL AND LAID > @NextLAID);
		END

		UPDATE @OutputOrdered SET @CleaningType = NULL WHERE LocationStatus IN ('In Use', 'Dirty');



/* ========================== PrO holes Holes ==========================*/

		SET @StartPrO = (SELECT MIN(timestamp) FROM @OutputOrdered WHERE ActivityType = 'Start of PrO');
		WHILE @StartPrO IS NOT NULL
		BEGIN
			SELECT	@ProcessOrder = NULL,
					@product = NULL,
					@Batch = NULL;
			SET @EndPrO = (	SELECT MIN(timestamp) 
							FROM @OutputOrdered 
							WHERE ActivityType = 'End of PrO' 
								AND timestamp > @StartPrO);
			IF @EndPrO IS NULL
				SET @EndPrO = GETDATE();

			SELECT	@ProcessOrder = processorder,
					@product = product,
					@Batch = batch
			FROM @OutputOrdered 
			WHERE ActivityType = 'Start of PrO' AND timestamp = @StartPrO;

			UPDATE @OutputOrdered
			SET processorder = @ProcessOrder,
				product = @product,
				batch = @Batch
			WHERE timestamp >= @StartPrO
				AND timestamp <= @EndPrO
				AND processorder IS NULL
				AND (CleaningType IS NULL OR CleaningType <> 'Major');

			SET @StartPrO = (SELECT MIN(timestamp) FROM @OutputOrdered WHERE ActivityType = 'Start of PrO' AND timestamp > @StartPrO);
		END
		
		SET @MinorCleanTime = (	SELECT MIN(Timestamp) 
								FROM @OutputOrdered 
								WHERE ActivityType = 'Cleaning' 
									AND CLEANINGType = 'Minor');
		WHILE @MinorCleanTime IS NOT NULL
		BEGIN
			SELECT	@ProcessOrder = NULL,
					@product = NULL,
					@Batch = NULL;


			SET @EndPrO = (	SELECT MAX(timestamp) 
							FROM @OutputOrdered 
							WHERE ActivityType = 'End of PrO' 
								AND timestamp < @MinorCleanTime);

			SELECT	@ProcessOrder = processorder,
					@product = product,
					@Batch = batch
			FROM @OutputOrdered 
			WHERE ActivityType = 'End of PrO' AND timestamp = @EndPrO;

			UPDATE @OutputOrdered
			SET processorder	= @ProcessOrder,
				product			= @product,
				batch			= @Batch
			WHERE timestamp = @MinorCleanTime
				 AND CleaningType = 'Minor';


			SET @MinorCleanTime = (	SELECT MIN(Timestamp) 
									FROM @OutputOrdered 
									WHERE ActivityType = 'Cleaning' 
										AND CLEANINGType = 'Minor'
										AND timestamp > @MinorCleanTime);
		END


		/*Remove entry prior start date*/
		DELETE @OutputOrdered WHERE timestamp <@STartTime;

	END


/*========================== Return result ==========================*/
		SELECT 	ActivityType,
				Timestamp,
				LocationStatus,
				CleaningType,
				Appliance,
				ApplianceStatus,	
				ProcessOrder,
				Product,
				Batch,
				CleaningResult,
				StartTime,
				EndTime,
				Username,
				ApproverName
		FROM @OutputOrdered;

	

END
RETURN
