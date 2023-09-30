
/*=====================================================================================================================
Stored Procedure: splocal_CST_Report_CleaningLocation
=======================================================================================================================
Author				:	U. Lapierre, AutomaTech
Date created		:	2023-03-21
Version 			:	Version <1.0>
SP Type				:	Web
Caller				:	Called by CTS mobile application - Report
Description			:	Wave 2 - get last cleaning activities
Editor tab spacing	: 4
=============================================================================================

=============================================================================================

EDIT HISTORY:
 ============================================================================================
1.0			2023-03-31		U. Lapierre			Initial Release 
1.1			2023-04-06		U. Lapierre			sort output by Next cleaning date desc
1.2			2023-04-18		U. Lapierre			Return last minor cleaning and last major cleaning
1.3			2023-06-27		U. Lapierre			Adapt for Code review
=============================================================================================

TEST CODE:
EXECUTE splocal_CST_Report_CleaningLocation 

=============================================================================================*/
CREATE   PROCEDURE [dbo].[splocal_CST_Report_CleaningLocation]

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE		@SPNAME				VARCHAR(100),
				@DebugFlag			INT,
				@NOW				DATETIME,
				@TableIdProdUnit	INT,
				@tfIdLocationType	INT,
				@estId				INT;

	DECLARE @MakingUnits TABLE(
	puid							INT,
	puDesc							VARCHAR(50)
	);


	DECLARE  @Output TABLE(
	eventId							INTEGER,
	puId							INTEGER,
	puDesc							VARCHAR(50),
	eventStatus						INTEGER,
	prodStatusDesc					VARCHAR(60),
	startTime						DATETIME,
	endTime							DATETIME,
	udeDesc							VARCHAR(60),
	cleaningType					VARCHAR(50),
	eventSubtypeDesc				VARCHAR(60),
	commentId						INTEGER,
	signatureId						INTEGER,
	performUser						VARCHAR(50),
	CompleteUser					VARCHAR(50),
	ApproveUser						VARCHAR(50),
	LastUsedTime					DATETIME,
	CleaningLimit					INT,
	TimeSinceLastCleaning			INT,
	TimeToNextCleaning				INT,
	UsageLimit						INT,
	TimeSinceLastUsage				INT,
	DateNextCleaning				DATETIME,
	TimerExceeded					VARCHAR(50),
	LastMinorCleaning				DATETIME,
	LastMajorCleaning				DATETIME
	);



	/*=====================
	Get all making units
	=====================*/
	SET @TableIdProdUnit	=	(	SELECT tableId			FROM dbo.Tables				WITH(NOLOCK) WHERE TableName = 'Prod_Units'	);
	SET @tfIdLocationType	=	(	SELECT table_field_id	FROM dbo.Table_Fields		WITH(NOLOCK) WHERE TableId = @TableIdProdUnit AND Table_Field_Desc = 'CTS location Type');
	SET @estId				=	(	SELECT event_subtype_id	FROM dbo.Event_Subtypes 	WITH(NOLOCK) WHERE Event_Subtype_Desc = 'CTS Location cleaning');

	SET @Now = GETDATE();
	SET @Now = DATEADD(ms,-1*DATEPART(ms,@Now),@Now);

	INSERT @MakingUnits (puid, pudesc)
	SELECT pu.PU_Id, pu.pu_desc
	FROM dbo.Prod_Units_Base pu			WITH(NOLOCK)
	JOIN dbo.table_fields_values tfv	WITH(NOLOCK) ON pu.pu_id = tfv.keyid
	WHERE table_field_id = @tfIdLocationType aND TABLEid = @TableIdProdUnit and value = 'Making';


	/*=====================
	Get the cleaning UDE (latest of each unit)
	=====================*/
	INSERT INTO @Output
	(
	eventId,
	puId,
	puDesc,
	prodStatusDesc,
	startTime,
	endTime,
	udeDesc,
	commentId,
	performUser		,
	CompleteUser	,
	ApproveUser	
	)
	SELECT	SUB.eventId, 
			ude.PU_Id, 
			SUB.puDesc, 
			ps.ProdStatus_Desc, 
			ude.Start_Time, 
			ude.End_Time, 
			ude.ude_desc,
			ude.COmment_Id,
			u1.Username,
			uc.Username,
			ua.Username
	FROM dbo.User_Defined_Events ude			WITH(NOLOCK)
	JOIN (	SELECT	MAX(ude.ude_id) as eventId, pu.pudesc
			FROM dbo.User_Defined_Events ude	WITH(NOLOCK)
			JOIN @MakingUnits pu								ON ude.PU_Id = pu.puid
			WHERE ude.Event_Subtype_Id = @estid
			GROUP BY pu.puDesc ) SUB							ON SUB.eventid = ude.ude_id
	JOIN dbo.Production_Status ps				WITH(NOLOCK)	ON ude.Event_Status = ps.prodStatus_id
	JOIN dbo.Users_Base u1						WITH(NOLOCK)	ON ude.User_Id = u1.user_id			
	LEFT JOIN esignature esig					WITH(NOLOCK)	ON ude.signature_id = esig.signature_id
	LEFT JOIN dbo.Users_Base uc					WITH(NOLOCK)	ON esig.Perform_User_Id = uc.user_id	
	LEFT JOIN dbo.Users_Base ua					WITH(NOLOCK)	ON esig.Verify_User_Id = ua.user_id;


	/*=====================
	Get cleaning Type
	=====================*/
	UPDATE o
	SET cleaningType = t.Result
	FROM @Output o
	JOIN dbo.variables v		WITH(NOLOCK) ON v.pu_id = o.puid	
												AND v.Event_Subtype_Id = @estid 
												AND v.Test_Name = 'Type'
	JOIN dbo.Tests t			WITH(NOLOCK) ON v.Var_Id = t.Var_Id				
												AND t.Result_On = o.endTime;


	/*Get Last Major Cleaning*/
	UPDATE o
	SET LastMajorCleaning = ude.End_Time
	FROM @Output o
	JOIN (	SELECT	MAX(ude.ude_id) as eventId, pu.pudesc
			FROM dbo.User_Defined_Events ude	WITH(NOLOCK)
			JOIN @MakingUnits pu								ON ude.PU_Id = pu.puid
			JOIN dbo.tests t					WITH(NOLOCK)	ON ude.end_time = t.result_on
			JOIN dbo.variables_Base v			WITH(NOLOCK)	ON v.var_id = t.var_id	
																	AND v.pu_id = ude.pu_id	
																	AND v.Test_Name = 'Type'
																	AND t.result = 'Major'
			JOIN dbo.pu_groups pug				WITH(NOLOCK)	ON	v.pug_id = pug.pug_id
																	AND pug.pug_desc = 'Location Cleaning'
			WHERE ude.Event_Subtype_Id = @estid
				
			GROUP BY pu.pudesc ) SUB							ON o.pudesc = SUB.pudesc
	JOIN dbo.User_Defined_Events ude			WITH(NOLOCK)	ON SUB.eventId = ude.ude_id;




	/*Get Last Minor Cleaning*/
	UPDATE o
	SET LastMinorCleaning = ude.End_Time
	FROM @Output o
	JOIN (	SELECT	MAX(ude.ude_id) as eventId, pu.pudesc
			FROM dbo.User_Defined_Events ude	WITH(NOLOCK)
			JOIN @MakingUnits pu								ON ude.PU_Id = pu.puid
			JOIN dbo.tests t					WITH(NOLOCK)	ON ude.end_time = t.result_on
			JOIN dbo.variables_Base v			WITH(NOLOCK)	ON v.var_id = t.var_id	
																	AND v.pu_id = ude.pu_id		
																	AND v.Test_Name = 'Type'
			JOIN dbo.pu_groups pug				WITH(NOLOCK)	ON	v.pug_id = pug.pug_id
																	AND pug.pug_desc = 'Location Cleaning'
			WHERE ude.Event_Subtype_Id = @estid
				AND t.result = 'Minor'
			GROUP BY pu.pudesc ) SUB							ON o.pudesc = SUB.pudesc
	JOIN dbo.User_Defined_Events ude			WITH(NOLOCK)	ON SUB.eventId = ude.ude_id	;

	/*=====================
	Get next cleaning & next usage
	=====================-*/

	UPDATE o
	SET CleaningLimit			= CO.Cleaned_limit_hour,
		TimeSinceLastCleaning	= CO.Cleaned_timer_hour,
		UsageLimit				= Used_limit_hour,
		TimeSinceLastUsage		= Used_timer_hour
	FROM @Output o
	CROSS APPLY (SELECT Cleaned_limit_hour, 
						Cleaned_timer_hour,
						Used_limit_hour,
						Used_timer_hour
				FROM  fnLocal_CTS_Location_Status(o.puid,NULL) ) CO;



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
									WHEN TimeSinceLastUsage > TimeSinceLastCleaning AND UsageLimit-TimeSinceLastCleaning <= 0 THEN 0
									WHEN TimeSinceLastUsage > TimeSinceLastCleaning 
										AND CleaningLimit-TimeSinceLastCleaning < UsageLimit-TimeSinceLastCleaning THEN CleaningLimit-TimeSinceLastCleaning
									WHEN TimeSinceLastUsage > TimeSinceLastCleaning 
										AND CleaningLimit-TimeSinceLastCleaning >= UsageLimit-TimeSinceLastCleaning THEN UsageLimit-TimeSinceLastCleaning
									WHEN TimeSinceLastUsage < TimeSinceLastCleaning 
										AND CleaningLimit-TimeSinceLastCleaning < UsageLimit-TimeSinceLastUsage THEN CleaningLimit-TimeSinceLastCleaning
									WHEN TimeSinceLastUsage < TimeSinceLastCleaning 
										AND CleaningLimit-TimeSinceLastCleaning >= UsageLimit-TimeSinceLastUsage THEN UsageLimit-TimeSinceLastUsage
								
							END	);


	/* Get last used date */
	UPDATE o
	SET LastUsedTime = SUB.LastUsed
	FROM @Output o
	JOIN (	SELECT op.puid, MAX(COALESCE(pps.end_time, start_time)) as LastUsed
			FROM @Output op 
			JOIN dbo.production_plan_starts pps WITH(NOLOCK) ON op.puid = pps.pu_id
			GROUP BY op.puId
			) SUB ON SUB.puId = o.puid;

	UPDATE @Output
	SET DateNextCleaning = DATEADD(HH,TimeToNextCleaning,@Now);
	


	/*=====================
	Return results
	=====================*/

	SELECT 	puDesc				as 'LOCATION',
			puid				as 'PUID',
			prodStatusDesc		as 'STATUS',
			startTime			AS 'STARTTIME',
			endTime				AS 'ENDTIME',
			cleaningType		as 'CLEANTYPE',
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
	FROM @output order by TimeToNextCleaning 	;

END
RETURN
