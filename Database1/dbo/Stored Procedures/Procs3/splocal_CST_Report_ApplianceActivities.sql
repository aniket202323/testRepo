
/*=====================================================================================================================
Stored Procedure: splocal_CST_Report_ApplianceActivities
=======================================================================================================================
Author				:	U. Lapierre, AutomaTech
Date created		:	2023-02-22
Version 			:	Version <1.0>
SP Type				:	Web
Caller				:	Called by CTS mobile application - Report
Description			:	Wave 2 - Get appliance activities for the report


Editor tab spacing	: 4

===========================================================================================
EDIT HISTORY:

1.0		2023-02-22		U. Lapierre			Initial Release 
1.1		2023-03-30		U. Lapierre			Fix issue getting cleaning type on unit that usually don't let cleaning
1.2		2023-04-03		U. Lapierre			Add From_location when there is an appliance movement
1.3		2023-06-27		U. Lapierre			Adapt for Code review
1.4		2023-08-08		U.Lapierre			limit report to 6 months
===========================================================================================


===========================================================================================
TEST CODE:
EXECUTE splocal_CST_Report_ApplianceActivities  1268670,'1-Feb-2023','1-Mar-2023'
===========================================================================================

==================================================================================================*/
CREATE   PROCEDURE [dbo].[splocal_CST_Report_ApplianceActivities]
	@ApplianceId			INT,
	@StartTime				DATETIME,
	@EndTime				DATETIME

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SPNAME			VARCHAR(100) = 'splocal_CST_Report_ApplianceActivities',
			@DebugFlag		INT  = 0,
			@ECID			INT,
			@SOURCEEVENTID	INT,
			@FromLocation	VARCHAR(50),
			@Cleaningtime	DATETIME,
			@NotCleantime	DATETIME,
			@CleaningType	VARCHAR(50);

	DECLARE @Output TABLE (
	AAId				INT		IDENTITY,
	ActivityType		VARCHAR(50)	,
	Timestamp			DATETIME	,
	From_Location		VARCHAR(50)	,
	Location			VARCHAR(50)	,
	ProcessOrder		VARCHAR(50)	,
	Batch				VARCHAR(50)	,
	Product				VARCHAR(50)	,
	Status				VARCHAR(100),
	CleaningType		VARCHAR(50)	,
	CleaningResult		VARCHAR(100),
	StartTime			DATETIME	,
	EndTime				DATETIME	,
	Username			VARCHAR(50)	,
	ApproverName		VARCHAR(50),
	Override			BIT,
	eventid				INT
	);



	DECLARE @Movements TABLE (
	ComponentId			INT,
	ActivityType		VARCHAR(50)	,
	eventId				INT,
	ApplianceId			INT,
	EventNum			VARCHAR(50) ,
	From_Location		VARCHAR(50)	,
	Timestamp			DATETIME	,
	Location			VARCHAR(50)	,
	Status				VARCHAR(100),
	ProcessOrder		VARCHAR(50)	,
	Batch				VARCHAR(50),
	Product				VARCHAR(50),
	Username			VARCHAR(50)	,
	Override			BIT
	);

	DECLARE @Cleanings TABLE (
	UDEID				INT,
	ActivityType		VARCHAR(50)	,
	CleaningResult		VARCHAR(50) ,
	StartTime			DATETIME	,
	EndTime				DATETIME	,
	Location			VARCHAR(50)	,
	Status				VARCHAR(100),
	UserName			VARCHAR(50)	,
	Approver			VARCHAR(50),
	Override			BIT,
	CleaningType		VARCHAR(50)
	);

	DECLARE @Overrides TABLE (
	ActivityType		VARCHAR(50)	,
	New_Location		VARCHAR(50)	,
	New_Status			VARCHAR(50)	,
	New_CleanType		VARCHAR(50)	,
	New_ProcessOrder	VARCHAR(50)	,
	New_Batch			VARCHAR(50),
	New_ProdCode		VARCHAR(50)	,
	New_ProdDesc		VARCHAR(100),
	UserId				INT,
	UserName			VARCHAR(50)	,
	Timestamp			DATETIME	,
	eventId				INT
	);


/*        initialization        */
	SET @DebugFlag =		(SELECT CONVERT(INT,sp.value) 
							FROM	dbo.site_parameters sp		WITH(NOLOCK)
							JOIN	dbo.parameters p			WITH(NOLOCK)		ON sp.parm_Id = p.parm_id
							WHERE p.parm_Name = 'PG_CTS_StoredProcedure_Log_Level');


	IF @DebugFlag >=2
	BEGIN
		INSERT INTO dbo.Local_CTS_Debug_Log(Timestamp, CallingSP, LogNumber, Message, GroupingId)
		VALUES(	GETDATE(),
				@SPName,
				1,
				'SP Started' +
				' Start time: ' + CONVERT(VARCHAR(30),@Starttime,120) + 
				' end time: ' + CONVERT(VARCHAR(30),@Endtime,120),
				@ApplianceId	);
	END

	/*==========================Limit activities to 6 months ==========================*/
IF DATEDIFF(d,@Starttime,@Endtime) > 180
BEGIN
	SELECT @Starttime = DATEADD(D,-180,@Endtime)
END

/*=====================Get Movements=====================*/
	INSERT @Movements (
		ComponentId			,
		ActivityType		,
		EventNum			,
		Timestamp			,
		Location			,
		Status				,
		ProcessOrder		,
		Batch				,
		Product				,
		Username			,
		eventId				,
		ApplianceId
		)
	SELECT	ec.component_Id		,
			'Movement'			,
			e.event_num			,
			ec.entry_on			,
			pu.PU_Desc			, 
			ps.prodstatus_desc	,
			pp.process_order	,
			pp.user_general_1	,
			p.prod_code			,
			u.Username			,
			e.event_id			,
			@ApplianceId
	FROM dbo.event_components ec			WITH(NOLOCK) 
	JOIN dbo.Events e						WITH(NOLOCK)  ON ec.Event_Id = e.Event_Id
	JOIN dbo.prod_units_base pu				WITH(NOLOCK)  ON e.pu_id = pu.pu_id
	JOIN dbo.Production_Status ps			WITH(NOLOCK)  ON ps.ProdStatus_Id = e.event_status
	JOIN dbo.Event_Details ed				WITH(NOLOCK)  ON e.Event_Id = ed.event_id
	JOIN dbo.users_base u					WITH(NOLOCK)  ON ec.user_id = u.user_id
	LEFT JOIN dbo.production_plan pp		WITH(NOLOCK)  ON pp.pp_id = ed.pp_id
	LEFT JOIN dbo.products_base p			WITH(NOLOCK)  ON pp.Prod_Id = p.prod_id
	WHERE ec.source_event_id = @ApplianceId
		AND ec.entry_on >= @Starttime
		AND ec.entry_on <= @Endtime
	ORDER BY ec.component_Id;

	UPDATE @movements SET Override = 1 WHERE eventnum LIKE 'OV%';

	/*   Get the previous location  */
	SET @ECID = (	SELECT MIN(ComponentId) FROM @Movements	);
	WHILE @ECID IS NOT NULL
	BEGIN
		SET @FromLocation = (	SELECT TOP 1 pu.pu_desc 
								FROM dbo.event_components ec		WITH(NOLOCK)
								JOIN dbo.events	e					WITH(NOLOCK) ON ec.event_id = e.event_id
								JOIN dbo.prod_Units_base pu			WITH(NOLOCK) ON e.pu_id = pu.PU_Id
								WHERE source_event_id = @ApplianceId AND component_id <@ECID
								ORDER BY component_id DESC);

		UPDATE @movements 
		SET From_Location = @FromLocation
		WHERE componentid = @ECID;

		SET @ECID = (	SELECT MIN(ComponentId) FROM @Movements	WHERE componentId > @ECID);
	END





	INSERT INTO @Output (	
		ActivityType		,
		Timestamp			,
		From_Location		,
		Location			,
		ProcessOrder		,
		Batch				,
		Product				,
		Status				,
		Username			,
		Override			,
		eventid				)

	SELECT 	ActivityType		,
			--EventNum			,
			Timestamp			,
			From_Location		,
			Location			,
			ProcessOrder		,
			batch		,
			Product				,
			Status				,
			Username			,
			Override			,
			eventId
	FROM @Movements ORDER BY timestamp;



/*Get Cleanings */
	INSERT @Cleanings  (
		UDEID				,
		ActivityType		,
		CleaningResult		,
		StartTime			,	
		EndTime				,
		Location			,
		Status				,
		UserName			,
		Approver		,
		Cleaningtype
		)
	SELECT	ude.ude_id,
			'Cleaning',
			ps.prodstatus_desc,
			ude.Start_Time, 
			ude.end_time,
			pu.pu_desc,
			CASE
				WHEN ps.prodstatus_desc ='CTS_Cleaning_Approved' THEN 'Clean'
				ELSE 'Dirty'
			END,
			u1.username, 
			u2.username,
			t.Result
	FROM dbo.user_defined_events ude		WITH(NOLOCK)
	LEFT JOIN dbo.production_status ps		WITH(NOLOCK)	ON ude.event_status = ps.prodStatus_id
	JOIN dbo.prod_units_Base PU				WITH(NOLOCK)	ON ude.pu_id = pu.pu_id
	JOIN dbo.Event_Subtypes es				WITH(NOLOCK)	ON es.Event_Subtype_Id = ude.Event_Subtype_Id
	LEFT JOIN dbo.esignature esig			WITH(NOLOCK)	ON ude.signature_id = esig.signature_id
	LEFT JOIN dbo.users_Base u1				WITH(NOLOCK)	ON esig.perform_user_id = u1.user_id
	LEFT JOIN dbo.users_Base u2				WITH(NOLOCK)	ON esig.verify_user_id = u2.user_id
	LEFT JOIN dbo.Variables_Base v			WITH(NOLOCK)	ON v.PU_Id = ude.PU_Id AND v.Test_Name = 'type'
	JOIN dbo.pu_groups pug					WITH(NOLOCK) ON v.pug_id = pug.pug_id 
															AND pug.pug_desc = 'Appliance Cleaning' 
	LEFT JOIN dbo.Tests t					WITH(NOLOCK)	ON v.Var_Id = t.Var_Id AND t.Result_On = ude.end_time
	WHERE es.Event_Subtype_Desc = 'CTS Appliance cleaning'
		AND ude.event_id = @ApplianceId
		AND ude.end_time>= @Starttime
		AND UDE.Start_time < @EndTime;

	INSERT @Cleanings  (
		UDEID				,
		ActivityType		,
		CleaningResult		,
		StartTime			,	
		EndTime				,
		Location			,
		Status				,
		UserName			,
		Approver		,
		Cleaningtype
		)
	SELECT	TOP 1 ude.ude_id,
			'Cleaning',
			ps.prodstatus_desc,
			ude.Start_Time, 
			ude.end_time,
			pu.pu_desc,
			CASE
				WHEN ps.prodstatus_desc ='CTS_Cleaning_Approved' THEN 'Clean'
				ELSE 'Dirty'
			END,
			u1.username, 
			u2.username,
			t.Result
	FROM dbo.user_defined_events ude		WITH(NOLOCK)
	LEFT JOIN dbo.production_status ps		WITH(NOLOCK)	ON ude.event_status = ps.prodStatus_id
	JOIN dbo.prod_units_Base PU				WITH(NOLOCK)	ON ude.pu_id = pu.pu_id
	JOIN dbo.Event_Subtypes es				WITH(NOLOCK)	ON es.Event_Subtype_Id = ude.Event_Subtype_Id
	LEFT JOIN dbo.esignature esig			WITH(NOLOCK)	ON ude.signature_id = esig.signature_id
	LEFT JOIN dbo.users_Base u1				WITH(NOLOCK)	ON esig.perform_user_id = u1.user_id
	LEFT JOIN dbo.users_Base u2				WITH(NOLOCK)	ON esig.verify_user_id = u2.user_id
	LEFT JOIN dbo.Variables_Base v			WITH(NOLOCK)	ON v.PU_Id = ude.PU_Id AND v.Test_Name = 'type'
	JOIN dbo.pu_groups pug					WITH(NOLOCK) ON v.pug_id = pug.pug_id 	LEFT JOIN dbo.Tests t					WITH(NOLOCK)	ON v.Var_Id = t.Var_Id AND t.Result_On = ude.end_time
	WHERE es.Event_Subtype_Desc = 'CTS Appliance cleaning'
		AND ude.event_id = @ApplianceId
		AND UDE.End_Time < @Starttime
	ORDER BY ude.End_Time DESC;


	INSERT INTO @Output (	
		ActivityType		,
		Timestamp			,
		Location			,
		CleaningResult		,
		Status				,
		CleaningType		,
		StartTime			,
		EndTime				,
		Username			,
		ApproverName		
			)
	SELECT 	ActivityType		,
			EndTime				,
			Location			,
			CleaningResult		,	
			Status				,
			CleaningType		,
			StartTime			,	
			EndTime				,
			UserName			,
			Approver	
	FROM @Cleanings;
/*====================== END of Cleanings ===================*/






/*====================== Get Overrides ===================*/

	INSERT @Overrides  (
	ActivityType		,
	New_Location		,
	New_Status			,
	New_CleanType		,
	New_ProcessOrder	,
	New_Batch			,
	New_ProdCode		,
	New_ProdDesc		,
	UserId				,
	UserName			,
	Timestamp		,
	eventid
	)
	SELECT	'Override',
			pun.pu_desc,
			psn.prodstatus_desc,
			o.New_CleanType,
			ppn.process_order,
			ppn.user_general_1,
			pn.prod_code, 
			pn.prod_desc,
			o.userId,
			u.username,
			o.timestamp,
			o.eventid
	FROM dbo.Local_CST_ApplianceOverrides	o	WITH(NOLOCK)
	JOIN dbo.event_details ed					WITH(NOLOCK)	ON o.applianceId = ed.event_id
	JOIN dbo.prod_units_Base pun				WITH(NOLOCK)	ON o.New_Location = pun.pu_id
	JOIN dbo.production_status	psn				WITH(NOLOCK)	ON o.New_Status = psn.prodStatus_id
	LEFT JOIN dbo.production_plan ppn			WITH(NOLOCK)	ON o.New_PPID = ppn.pp_id
	LEFT JOIN dbo.products_base pn				WITH(NOLOCK)	ON o.New_Prod_Id = pn.prod_id
	JOIN dbo.users_base u						WITH(NOLOCK)	ON o.userid = u.user_id
	WHERE o.applianceId = @ApplianceId
		AND o.timestamp > @starttime
		AND o.timestamp <=@endtime
	ORDER BY timestamp ASC;


	/*1 try to update the existing overrides)*/
	UPDATE op
	SET ActivityType = 'Override',
		Status = ov.New_Status,
		ProcessOrder = ov.New_ProcessOrder,
		batch = ov.new_batch,
		Product = ov.New_ProdCode, 
		CleaningType = ov.New_CleanType
	FROM @output op
	JOIN @Overrides ov		ON op.eventid = ov.eventid AND op.override = 1
	WHERE ov.eventid IS NOT NULL;


/*2 add other overrides)*/
	INSERT INTO @Output (	
		ActivityType		,
		Timestamp			,
		Location			,
		Status				,
		CleaningType		,
		ProcessOrder		,
		Batch				,
		Product				,
		Username			
			)
	SELECT 	ActivityType		,
			Timestamp		,
			New_Location		,
			New_Status			,
			New_CleanType		,
			New_ProcessOrder	,
			New_Batch			,
			New_ProdCode		,
			UserName			
	FROM @Overrides
	WHERE eventId IS NULL;

/*====================== END of Overrides ===================*/



/*====================== Get Cleaning Type ===================*/


	SET @Cleaningtime = (SELECT MIN(Timestamp) FROM @Output WHERE ActivityType = 'Cleaning' AND Status = 'Clean');

	WHILE @Cleaningtime IS NOT NULL
	BEGIN
		SET @NotCleantime = (	SELECT MIN(Timestamp) 
								FROM @Output 
								WHERE (Status <> 'Clean' AND Timestamp > @Cleaningtime) 
										OR (ActivityType = 'Cleaning'AND Timestamp > @Cleaningtime)
								);
		IF @NotCleantime IS NULL
			SET @NotCleantime = (SELECT GETDATE() );
		SET @CleaningType = (SELECT CleaningType FROM @Output WHERE ActivityType = 'Cleaning' AND Timestamp = @Cleaningtime);
		UPDATE @Output SET CleaningType = @CleaningType WHERE Status = 'Clean' AND timestamp> @Cleaningtime AND Timestamp < @NotCleantime;

		SET @Cleaningtime = (SELECT MIN(Timestamp) FROM @Output WHERE ActivityType = 'Cleaning' AND Status = 'Clean' AND Timestamp > @Cleaningtime);
	END



	/*return the list of activities*/
	SELECT 	ActivityType,
			Timestamp,
			From_Location,
			Location,
			Status,
			CleaningType,
			ProcessOrder,
			Batch	,
			Product,
			CleaningResult,
			StartTime,
			EndTime,
			Username,
			ApproverName
	FROM @Output
	WHERE Timestamp >= @StartTime
	ORDER BY timestamp ;

END
RETURN
