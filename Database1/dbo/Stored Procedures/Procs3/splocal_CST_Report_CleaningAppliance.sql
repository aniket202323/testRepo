
/*=====================================================================================================================
Stored Procedure: splocal_CST_Report_CleaningAppliance
=======================================================================================================================
Author				:	U. Lapierre, AutomaTech
Date created			:	2023-03-22
Version 				:	Version <1.0>
SP Type				:	Web
Caller				:	Called by CTS mobile application - Report
Description			:	Wave 2 - get last cleaning activities for all appliance
Editor tab spacing	: 4
==============================================================================

EDIT HISTORY:
==============================================================================
1.0		2023-03-22		U. Lapierre			Initial Release 
1.1		2023-03-31		U.Lapierre			Performance improvement
1.2		2023-04-04		U. Lapierre			Calculate the date of the next cleaning
1.3		2023-04-06		U. Lapierre			sort output by time to next cleaning
1.4		2023-04-17		U. Lapierre			Return last minor cleaning and last major cleaning
1.5		2023-06-27		U. Lapierre			Adapt for Code review
=============================================================================

TEST CODE:

EXECUTE splocal_CST_Report_CleaningAppliance '0908'
===============================================================================*/


CREATE   PROCEDURE [dbo].[splocal_CST_Report_CleaningAppliance]
@SerialString			varchar(100) = NULL

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE		@SPNAME							VARCHAR(100) = 'splocal_CST_Report_CleaningAppliance',
				@DebugFlag						INTEGER,
				@ApplianceTypeTFiD				INTEGER,
				@TableId						INTEGER,
				@estId							INTEGER,
				@CleanedTimerLimitTFid			INTEGER,
				@UsedTimerLimitTFid				INTEGER,
				@Now							DATETIME;

	DECLARE @Appliances TABLE(
	Appliance_event_id			INTEGER,
	Appliance_Timestamp			DATETIME,
	Appliance_type				VARCHAR(50),
	Appliance_serial			VARCHAR(25),
	Appliance_event_num			VARCHAR(50),
	Appliance_status_id			INTEGER,
	Appliance_status_desc		VARCHAR(50),
	Appliance_pu_id				INTEGER,
	Appliance_clean_timer_limit INTEGER,
	Appliance_usage_timer_limit INTEGER
	);

	DECLARE @ApplianceLastUsed	TABLE (
	Appliance_event_id			INT,
	Transition_EVent_Id			INT,
	Component_Id				INT,
	Transition_Time				DATETIME,
	EC_Timestamp				DATETIME
	);

	DECLARE  @Output TABLE(
	udeId					INTEGER,
	puId					INTEGER,
	EventId					INTEGER,
	puDesc					VARCHAR(50),
	Serial					VARCHAR(50),
	ApplianceType			VARCHAR(50),
	eventStatus				INTEGER,
	prodStatusDesc			VARCHAR(60),
	startTime				DATETIME,
	endTime					DATETIME,
	udeDesc					VARCHAR(60),
	cleaningType			VARCHAR(50),
	eventSubtypeDesc		VARCHAR(60),
	commentId				INTEGER,
	signatureId				INTEGER,
	performUser				VARCHAR(50),
	CompleteUser			VARCHAR(50),
	ApproveUser				VARCHAR(50),
	LastUsedTime			DATETIME,
	CleaningLimit			INT,
	TimeSinceLastCleaning	INT,
	UsageLimit				INT,
	TimeSinceLastUsage		INT,
	TimeToNextCleaning		INT,
	TimerExceeded			VARCHAR(50),
	DateNextCleaning		DATETIME,
	AppliancePUID			INT,
	LastMinorCleaning		DATETIME,
	LastMajorCleaning		DATETIME
	);



	/*========================================================
	Get constants from database
	==========================================================*/

	SET @estId					= (SELECT	Event_Subtype_Id 	FROM	dbo.event_subtypes  WITH(NOLOCK)	WHERE	ET_ID = 14 
																												AND event_subtype_desc = 'CTS Appliance Cleaning');
	SET @TableId				= (SELECt	tableId				FROM	dbo.tables			WITH(NOLOCK)	WHERE tableName = 'prod_units');
	SET @ApplianceTypeTFiD		= (SELECT	table_field_id		FROM	dbo.table_fields	WITH(NOLOCK)	WHERE   Table_Field_Desc = 'CTS Appliance type' 
																												AND TableId = @tableId);
	SET @CleanedTimerLimitTFid	= (SELECT	table_field_id		FROM	dbo.table_fields	WITH(NOLOCK)	WHERE   Table_Field_Desc = 'CTS time since last cleaned threshold (hours)' 
																												AND TableId = @tableId);
	SET @UsedTimerLimitTFid		= (SELECT	table_field_id		FROM	dbo.table_fields	WITH(NOLOCK) WHERE   Table_Field_Desc = 'CTS time since last used threshold (hours)' 
																												AND TableId = @tableId);
	SET @Now = GETDATE();
	SET @Now = DATEADD(ms,-1*DATEPART(ms,@Now),@Now);

	/*========================================================
	Get Appliances
	==========================================================*/

	INSERT INTO @Appliances (
				Appliance_event_id,
				Appliance_Timestamp,
				appliance_type,
				Appliance_serial, 
				Appliance_event_num, 
				Appliance_status_id, 
				Appliance_status_desc,
				Appliance_pu_id,
				Appliance_clean_timer_limit ,
				Appliance_usage_timer_limit
				)
	SELECT		E.event_id, 
				e.timestamp,
				TFV1.Value, 
				ED.alternate_event_num,
				E.event_num, 
				PS.ProdStatus_Id, 
				PS.ProdStatus_Desc,
				E.PU_Id,
				TFV2.Value,
				TFV3.Value
	FROM		dbo.events E WITH(NOLOCK)
				JOIN dbo.event_details ED				WITH(NOLOCK)	ON ED.event_id = E.event_id
				JOIN dbo.Prod_Units_Base PUB			WITH(NOLOCK) 	ON PUB.PU_id = E.pu_id
				JOIN dbo.table_fields_values TFV1		WITH(NOLOCK)	ON TFV1.keyId = PUB.pu_id 
																		AND TFV1.table_field_id = @ApplianceTypeTFiD
				JOIN dbo.Production_Status PS			WITH(NOLOCK)	ON PS.ProdStatus_Id = E.Event_Status
				JOIN dbo.Table_Fields_Values TFV2		WITH(NOLOCK)	ON TFV2.keyId = E.pu_id 
																		AND TFV2.TableId = @TableId
																		AND TFV2.Table_Field_Id = @CleanedTimerLimitTFid 
				JOIN dbo.Table_Fields_Values TFV3		WITH(NOLOCK)	ON TFV3.keyId = E.pu_id 
																		AND TFV3.TableId = @TableId
																		AND TFV3.Table_Field_Id = @UsedTimerLimitTFid 
	WHERE		PUB.Equipment_Type = 'CTS Appliance';	



	DELETE @Appliances WHERE Appliance_status_desc NOT IN ('Active');

	IF @SerialString IS NOT NULL
	BEGIN
		DELETE @Appliances WHERE Appliance_serial NOT LIKE @SerialString + '%';
	END
	


	/*========================================================
	Get last cleaning event per appliance
	==========================================================*/
	INSERT INTO @Output
	(
	udeid,
	puId,
	EventId,
	puDesc,
	Serial,
	ApplianceType,
	prodStatusDesc,
	startTime,
	endTime,
	udeDesc,
	commentId,
	performUser		,
	CompleteUser	,
	ApproveUser	,
	CleaningLimit,
	UsageLimit,
	TimeSinceLastCleaning ,
	TimeSinceLastUsage
	)
	SELECT	SUB.udeid, 
			ude.PU_Id, 
			SUB.Appliance_event_id,
			pu.pu_Desc, 
			App.Appliance_serial,
			App.appliance_type,
			ps.ProdStatus_Desc, 
			ude.Start_Time, 
			ude.End_Time, 
			ude.ude_desc,
			ude.COmment_Id,
			u1.Username,
			uc.Username,
			ua.Username,
			app.Appliance_clean_timer_limit ,
			app.Appliance_usage_timer_limit,
			NULL,
			NULL
	FROM dbo.User_Defined_Events ude			WITH(NOLOCK)
	JOIN (	SELECT	MAX(ude.ude_id) as udeId, a.Appliance_event_id
			FROM dbo.User_Defined_Events ude	WITH(NOLOCK)
			JOIN @Appliances a								ON ude.event_id = a.Appliance_event_id
			WHERE ude.Event_Subtype_Id = @estid
			GROUP BY a.Appliance_event_id ) SUB							ON SUB.udeId = ude.ude_id
	JOIN dbo.Production_Status ps				WITH(NOLOCK)	ON ude.Event_Status = ps.prodStatus_id
	JOIN dbo.prod_units_base pu					WITH(NOLOCK)	ON ude.pu_id = pu.pu_id
	JOIN @Appliances app										ON SUB.Appliance_event_id = app.Appliance_event_id
	JOIN dbo.Users_Base u1						WITH(NOLOCK)	ON ude.User_Id = u1.user_id			
	LEFT JOIN esignature esig					WITH(NOLOCK)	ON ude.signature_id = esig.signature_id
	LEFT JOIN dbo.Users_Base uc					WITH(NOLOCK)	ON esig.Perform_User_Id = uc.user_id	
	LEFT JOIN dbo.Users_Base ua					WITH(NOLOCK)	ON esig.Verify_User_Id = ua.user_id;

	/*Get Last Major Cleaning*/
	UPDATE o
	SET LastMajorCleaning = ude.End_Time
	FROM @Output o
	JOIN (	SELECT	MAX(ude.ude_id) as udeId, a.Appliance_event_id as EventId
			FROM dbo.User_Defined_Events ude	WITH(NOLOCK)
			JOIN @Appliances a									ON ude.event_id = a.Appliance_event_id
			JOIN dbo.tests t					WITH(NOLOCK)	ON ude.end_time = t.result_on
			JOIN dbo.variables_Base v			WITH(NOLOCK)	ON v.var_id = t.var_id	
																	AND v.pu_id = ude.pu_id	
																	AND v.Test_Name = 'Type'
			JOIN dbo.pu_groups pug				WITH(NOLOCK)	ON	v.pug_id = pug.pug_id
																	AND pug.pug_desc = 'Appliance Cleaning'
			WHERE ude.Event_Subtype_Id = @estid
				AND t.result = 'Major'
			GROUP BY a.Appliance_event_id ) SUB					ON SUB.EventId = o.EventId
	JOIN dbo.User_Defined_Events ude			WITH(NOLOCK)	ON SUB.udeId = ude.ude_id	;

	/*Get Last Minor Cleaning*/
	UPDATE o
	SET LastMinorCleaning = ude.End_Time
	FROM @Output o
	JOIN (	SELECT	MAX(ude.ude_id) as udeId, a.Appliance_event_id as EventId
			FROM dbo.User_Defined_Events ude	WITH(NOLOCK)
			JOIN @Appliances a									ON ude.event_id = a.Appliance_event_id
			JOIN dbo.tests t					WITH(NOLOCK)	ON ude.end_time = t.result_on
			JOIN dbo.variables_Base v			WITH(NOLOCK)	ON v.var_id = t.var_id	
																	AND v.pu_id = ude.pu_id	
																	AND v.Test_Name = 'Type'
			JOIN dbo.pu_groups pug				WITH(NOLOCK)	ON	v.pug_id = pug.pug_id
																	AND pug.pug_desc = 'Appliance Cleaning'
			WHERE ude.Event_Subtype_Id = @estid
				AND t.result = 'Minor'
			GROUP BY a.Appliance_event_id ) SUB					ON SUB.EventId = o.EventId
	JOIN dbo.User_Defined_Events ude			WITH(NOLOCK)	ON SUB.udeId = ude.ude_id	;

	/*========================================================
	Get cleaning type
	==========================================================*/
	UPDATE o
	SET cleaningType = t.Result
	FROM @Output o
	JOIN dbo.variables_Base v		WITH(NOLOCK) ON v.pu_id = o.puid	
	JOIN dbo.pu_groups pug			WITH(NOLOCK) ON v.pug_id = pug.pug_id AND v.Test_Name = 'Type'
													AND pug.pug_desc = 'Appliance Cleaning'
								
	JOIN dbo.Tests t			WITH(NOLOCK) ON v.Var_Id = t.Var_Id				
												AND t.Result_On = o.endTime;





	/*========================================================
	Get next cleaning & next usage
	==========================================================*/

	UPDATE o
	SET CleaningLimit = Appliance_clean_timer_limit,
		UsageLimit = Appliance_usage_timer_limit,
		TimeSinceLastCleaning	= DATEDIFF(hour,COALESCE(o.endTime, a.appliance_Timestamp),GETDATE())
	FROM @Output o
	JOIN @Appliances a ON o.eventid = a.Appliance_event_id;

 
	INSERT @ApplianceLastUsed	 (
		Appliance_event_id			,
		Transition_EVent_Id			,
		Component_Id				,
		Transition_Time				,
		EC_Timestamp				)
	SELECT SUB.AppId, NULL,SUB.Tot, NULL,NULL
	FROM @Appliances a
	JOIN (	SELECT MAX(ec.Component_id) as Tot,a.Appliance_event_id AS AppId  
			FROM @Appliances a 
			JOIN dbo.event_components ec	WITH(NOLOCK) ON a.appliance_event_id = ec.source_event_id
			GROUP BY a.appliance_event_id
				) SUB ON a.Appliance_event_id = SUB.Appid;


	UPDATE a
	SET Transition_EVent_Id  =e.Event_Id,
		Transition_Time = e.timestamp,
		EC_Timestamp = ec.timestamp
	FROM @ApplianceLastUsed a
	JOIN dbo.event_components ec		WITH(NOLOCK) ON a.Component_Id = ec.Component_Id
	JOIN dbo.events e					WITH(NOLOCK) ON e.event_id = ec.event_id;




	UPDATE o
	SET TimeSinceLastUsage	= DATEDIFF(hour,COALESCE(a.Transition_Time, ap.appliance_Timestamp),GETDATE()),
		LastUsedTime = COALESCE(a.Transition_Time, ap.appliance_Timestamp)
	FROM @Output o
	JOIN @ApplianceLastUsed a	ON o.eventid = a.Appliance_event_id
	JOIN @Appliances ap			ON o.eventid = ap.Appliance_event_id;





	/*========================================================
	Get next cleaning & next usage
	==========================================================*/
	UPDATE @Output
	SET TimerExceeded = ( CASE	WHEN TimeSinceLastCleaning >= CleaningLimit THEN 'CleanTimer'
								WHEN (	TimeSinceLastCleaning < CleaningLimit 
										AND TimeSinceLastCleaning <= TimeSinceLastUsage
										AND TimeSinceLastCleaning > UsageLimit)  THEN 'UseTimer'
								WHEN (	TimeSinceLastCleaning < CleaningLimit 
										AND TimeSinceLastCleaning > TimeSinceLastUsage
										AND TimeSinceLastUsage > UsageLimit)  THEN 'UseTimer'
								ELSE NULL
							END	);



	UPDATE @Output
	SET TimeToNextCleaning = ( CASE	WHEN CleaningLimit-TimeSinceLastCleaning <= 0 THEN 0
									WHEN TimeSinceLastUsage >= TimeSinceLastCleaning AND UsageLimit-TimeSinceLastCleaning <= 0 THEN 0
									WHEN TimeSinceLastUsage >= TimeSinceLastCleaning 
										AND CleaningLimit-TimeSinceLastCleaning <= UsageLimit-TimeSinceLastCleaning THEN CleaningLimit-TimeSinceLastCleaning
									WHEN TimeSinceLastUsage >= TimeSinceLastCleaning 
										AND CleaningLimit-TimeSinceLastCleaning >= UsageLimit-TimeSinceLastCleaning THEN UsageLimit-TimeSinceLastCleaning
									WHEN TimeSinceLastUsage <= TimeSinceLastCleaning 
										AND CleaningLimit-TimeSinceLastCleaning <= UsageLimit-TimeSinceLastUsage THEN CleaningLimit-TimeSinceLastCleaning
									WHEN TimeSinceLastUsage <= TimeSinceLastCleaning 
										AND CleaningLimit-TimeSinceLastCleaning >= UsageLimit-TimeSinceLastUsage THEN UsageLimit-TimeSinceLastUsage
								
							END	);

	UPDATE @Output
	SET DateNextCleaning = DATEADD(HH,TimeToNextCleaning,@Now);



	/*================================
	Return results
	================================*/

	SELECT 	eventid				as 'EVENTID',
			Serial				as 'SERIAL'		,
			ApplianceType		AS 'APPLIANCETYPE'		,
			prodStatusDesc		as 'STATUS',
			startTime			AS 'STARTTIME',
			endTime				AS 'ENDTIME',
			cleaningType		as 'CLEANTYPE',
			pudesc				as 'CLEANINGLOCATION',
			performUser			as 'PERFORMER',
			CompleteUser		as 'COMPLETER',
			ApproveUser			as 'APPROVER',
			LastUsedTime		AS 'LASTUSEDTIME',
			CleaningLimit		as 'CLEANINGLIMIT'		,
			TimeSinceLastCleaning as 'TIMESINCELASTCLEANING'	,
			UsageLimit			AS 'USAGELIMIT',
			TimeSinceLastUsage	as 'TIMESINCELASTUSAGE'	,
			TimeToNextCleaning	as 'TIMETONEXTCLEANING',
			DateNextCleaning	AS 'DATENEXTCLEANING',
			TimerExceeded		as 'TIMEREXCEEDED',
			LastMajorCleaning	as 'LASTMAJORCLEANING',
			LastMinorCleaning	as 'LASTMINORCLEANING'
	FROM @output order by TimeToNextCleaning	;

END
RETURN
