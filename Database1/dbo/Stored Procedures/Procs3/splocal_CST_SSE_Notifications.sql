
				

/*======================================================================================================================
Stored Procedure: splocal_CST_SSE_Notifications
======================================================================================================================
Author				: Ugo Lapierre, AutomaTech
Date created		: 2023-05-17
Version 			: Version 1.0
SP Type				: CST web API
Caller				: CST web API
Description			: Return APpliance and Location item that should raised SSE event when changed
Editor tab spacing	: 4
===========================================================================================
HISTORY:

===========================================================================================
1.0		2023-05-17		U. Lapierre				Initial Release


================================================================================================
TEST CODE:


EXEC [dbo].[splocal_CST_SSE_Notifications]

		 

================================================================================================*/

CREATE   PROCEDURE [dbo].[splocal_CST_SSE_Notifications]

		
		
--WITH ENCRYPTION	
AS
SET NOCOUNT ON;

DECLARE	@SPNAME							varchar(50) = 'splocal_CST_SSE_Notifications'

/* UDPs*/
DECLARE	@TableIdProdUnit				int,
		@tfLocationSerial				varchar(50) = 'CTS Location serial number',
		@tfIdLocationSerial				int,
		@TFLocationType					varchar(50) = 'CTS Location type',
		@TFiDLocationType				int

/* Event sub types*/
DECLARE	@evSubtypeLocCleaning			varchar(50) = 'CTS Location Cleaning',	
		@evSubtypeAppCleaning			varchar(50) = 'CTS Appliance Cleaning',
		@evSubtypeMaintenance			varchar(50)	= 'CST Maintenance'

DECLARE @loopId							int,
		@ApplianceTransExtendedInfo		varchar(100)


DECLARE @ApplianceNotifications	TABLE (
	Serial								int,
	Cleaning_status						varchar(50),
	Appliance_Location_Id				int DEFAULT 0,
	Appliance_Status					varchar(50),
	Appliance_PPID_Id					int DEFAULT 0,
	Appliance_Product_Id				int DEFAULT 0,
	Status_Pending_id					int DEFAULT 0
)


DECLARE @LocationNotifications	TABLE (
	Serial								varchar(50),
	Cleaning_status						varchar(50),
	Active_or_inprep_process_order_Id	int DEFAULT 0,
	Number_of_appliances				int DEFAULT 0,
	Location_status						varchar(50),
	Pending_Appliance_Count				int DEFAULT 0
)

DECLARE @Locations				TABLE (
	Puid								int,
	Serial								varchar(50),
	Type								varchar(50)
	--extendedInfo						varchar(50)
)

DECLARE @Appliances				TABLE (
	EventId								int,
	puid								int,
	Serial								varchar(50),
	TransitionEventId					int,
	PuidLocation						int,
	ExtendedInfo						varchar(100),
	AppStatusId							int,
	Status_Pending_Id					int,
	lastUsed							datetime,
	lastClean							datetime
)

DECLARE @AppliancesTransitions	TABLE (
	EventId								int,
	ComponentId							int
)


DECLARE @ActiveOrder			TABLE (
	puid								int,
	ppid								int
)


DECLARE @SplitExtendedInfo TABLE(
	DaString VARCHAR(25),
	DaValue VARCHAR(25)
	)

DECLARE @Appliance_Last_Use TABLE(
	ApplianceId			INTEGER,
	Last_use			DATETIME
)

DECLARE @Appliance_Production TABLE(
	Appliance_event_id			INTEGER,
	Location_event_id			INTEGER,
	PP_ID						INTEGER,
	Prod_id						INTEGER,
	Prod_desc					VARCHAR(50),
	Prod_code					VARCHAR(50),
	Process_order				VARCHAR(50),
	Process_order_status_id		INTEGER,
	Process_order_status_desc	VARCHAR(50)
)

DECLARE @Appliance_last_cleaning TABLE(
Appliance_event_id	INTEGER,
Location_pu_id		INTEGER,
Location_pu_desc	VARCHAR(50),
Start_time			DATETIME,
End_time			DATETIME,
Cleaning_status		VARCHAR(50),
Type				VARCHAR(25)
)


/* Get constants*/
SET @TableIdProdUnit		=	(SELECT tableid			FROM dbo.tables			WITH(NOLOCK) WHERE tableName = 'Prod_Units');
SET @tfIdLocationSerial		=	(SELECT Table_field_id	FROM dbo.table_fields	WITH(NOLOCK) WHERE table_field_desc = @tfLocationSerial AND tableid = @TableIdProdUnit);
SET @TFiDLocationType		=	(SELECT Table_field_id	FROM dbo.table_fields	WITH(NOLOCK) WHERE table_field_desc = @TFLocationType AND tableid = @TableIdProdUnit);




/*=========== Get All locations===========*/
INSERT @Locations (	puid, 
					serial,
					Type
					)
SELECT	pu.pu_id,
		tfv.value,
		tfv2.value
FROM dbo.prod_units_base pu			WITH(NOLOCK)
JOIN dbo.table_fields_values tfv	WITH(NOLOCK)	ON tfv.keyid = pu.pu_id
														AND tfv.table_field_id = @tfIdLocationSerial
JOIN dbo.table_fields_values tfv2	WITH(NOLOCK)	ON tfv2.keyid = pu.pu_id
														AND tfv2.table_field_id = @TFiDLocationType
WHERE pu.equipment_type = 'CTS Location';




/* =======Get All Appliances=============*/
INSERT @Appliances (	EventId,
						puid
						--,						Serial
						)
SELECT	e.event_id, 
		e.pu_id
		--,		ed.alternate_event_num
FROM	dbo.events e				WITH(NOLOCK)
--JOIN	dbo.event_details ed		WITH(NOLOCK)	ON ed.event_id = e.event_id
JOIN	dbo.prod_units_base pu		WITH(NOLOCK)	ON e.pu_id = pu.pu_id
--JOIN	dbo.production_status ps	WITH(NOLOCK)	ON e.event_status = ps.prodstatus_id
WHERE	pu.Equipment_Type = 'CTS Appliance'
	--AND ps.prodStatus_desc = 'Active';

--DECLARE @App_Unit TABLE (puid int)

--INSERT @App_Unit (puid)
--SELECT PU_Id FROM dbo.prod_units_base WHERE	Equipment_Type = 'CTS Appliance'

--INSERT @Appliances (	EventId,
--						puid
--						--,						Serial
--						)
--SELECT	e.event_id, 
--		au.puid
--		--,		ed.alternate_event_num 
--FROM	dbo.events e				WITH(NOLOCK)
----JOIN	dbo.event_details ed		WITH(NOLOCK)	ON ed.event_id = e.event_id
--JOIN	@App_Unit au									on e.pu_id = au.puid

--/* ===========Get last location for All Appliances===================*/
INSERT @AppliancesTransitions ( EventId, ComponentId)
SELECT a.EventId , sub.ComponentId
FROM @Appliances a
JOIN (	SELECT MAX(ec.component_id) AS 'ComponentId', a.eventid AS 'Eventid'
		FROM dbo.Event_Components ec	WITH(NOLOCK)
		JOIN @Appliances a								ON ec.Source_Event_Id = a.eventid
		GROUP by a.EventId ) sub ON a.EventId = sub.eventid;




/*=============Get actual event transition for all appliance=========*/
UPDATE a
SET TransitionEventId = ec.Event_Id,
	PuidLocation = e.PU_Id,
	ExtendedInfo = e.extended_info,
	AppStatusId = e.event_Status
FROM @Appliances a
JOIN @AppliancesTransitions t					ON a.EventId		= t.EventId
JOIN dbo.Event_Components ec	WITH(NOLOCK)	ON ec.Component_Id	= t.ComponentId
JOIN dbo.Events e				WITH(NOLOCK)	ON ec.Event_Id		= e.event_id;




/*=============Get pending_status Id for appliance pending=========*/
SET @loopId = (SELECT MIN(TransitionEventId) FROM @Appliances WHERE ExtendedInfo IS NOT NULL)
WHILE @loopId IS NOT NULL
BEGIN

	SET @ApplianceTransExtendedInfo =  (SELECT ExtendedInfo FROM @Appliances WHERE TransitionEventId = @loopid)
		
	INSERT INTO @SplitExtendedInfo (DaString)
	SELECT value FROM STRING_SPLIT(@ApplianceTransExtendedInfo,',')
 
	UPDATE @SplitExtendedInfo SET DaValue = SUBSTRING(DaString,CHARINDEX('=',DaString,0)+1,Len(DaString)-CHARINDEX('=',DaString,0)+1)

	UPDATE @Appliances 
	SET Status_Pending_Id = (SELECT CAST(DaValue AS INTEGER) FROM @SplitExtendedInfo WHERE DaString LIKE '%SID=%')
	WHERE TransitionEventId = @loopid


	SET @loopId = (	SELECT MIN(TransitionEventId) 
					FROM @Appliances 
					WHERE TransitionEventId > @loopId 
						AND ExtendedInfo IS NOT NULL)

	DELETE @SplitExtendedInfo
END



/*=============Get active order =========*/
INSERT @ActiveOrder (puid, ppid)
SELECT l.puid, pps.pp_id
FROM @Locations l
JOIN dbo.production_Plan_starts pps	WITH(NOLOCK) ON l.Puid = pps.PU_Id 
													AND pps.End_Time IS NULL



/*=============Get last Usage =========*/
/*
INSERT INTO @Appliance_Last_Use(	
ApplianceId,
Last_use)

SELECT  MAX(A.EventId),
		MAX(Q.start_time)

FROM	@Appliances A
JOIN event_components EC  WITH(NOLOCK)			ON EC.source_event_id = A.eventid
OUTER APPLY(
SELECT TOP 1	EST.Start_time,PS.prodStatus_desc 
FROM			dbo.Event_Status_Transitions EST	WITH(NOLOCK) 
				JOIN dbo.Production_Status PS		WITH(NOLOCK) 	ON PS.prodStatus_id = EST.Event_Status 
				JOIN dbo.event_details ED			WITH(NOLOCK)	ON ED.event_id = EST.event_id
				JOIN @Locations FAL 								ON FAL.puid = EST.pu_id
WHERE			EST.event_id = ec.event_Id 
				AND PS.prodStatus_desc = 'In Use' 
				AND ED.PP_ID IS NOT NULL
				AND FAL.type = 'Making'
ORDER BY		EST.Start_time DESC)Q
GROUP BY		ec.source_event_id

UPDATE a
SET lastused = COALESCE(alu.Last_use, '10-Jan-2000')
FROM @Appliances a
JOIN @Appliance_Last_Use alu	ON a.EventId = alu.ApplianceId

*/


/*=====================================================================================================================
GET Appliance production
=====================================================================================================================*/
INSERT INTO @Appliance_Production	(
									Appliance_event_id,
									Location_event_id, 
									PP_ID, 
									Prod_id, 
									Prod_desc, 
									Prod_code, 
									Process_order,
									Process_order_status_id,
									Process_order_status_desc
									)
SELECT	ACS.EventId,
		ED.event_id, 
		ED.PP_Id,
		PUB.Prod_Id, 
		PUB.prod_desc,
		PUB.prod_code, 
		PP.Process_Order,
		PPSt.PP_Status_Id, 
		PPSt.PP_Status_Desc
FROM	event_details ED 
		JOIN @Appliances ACS									ON ACS.TransitionEventId	= ED.Event_Id
		JOIN dbo.production_plan PP				WITH(NOLOCK) 	ON PP.pp_id					= ED.pp_id
		JOIN dbo.Production_Plan_Statuses PPSt	WITH(NOLOCK)	ON PPSt.PP_Status_Id		= PP.PP_Status_Id
		JOIN dbo.products_base PUB								ON PUB.Prod_Id				= PP.Prod_Id





/*=====================================================================================================================
GET All cleanings
=====================================================================================================================*/

	
	
INSERT INTO	@Appliance_last_cleaning(
			Appliance_event_id,
			Location_pu_id,
			Location_pu_desc,
			Start_time,
			End_time,
			Cleaning_status,
			Type
			)
SELECT		A.eventid,
			Q1.Location_id,
			Q1.location_desc,
			Q1.Start_time,
			Q1.End_time,
			Q1.Status,
			Q1.Type				
FROM		@Appliances	A 
			CROSS APPLY (	SELECT 
							Status,
							type,
							Location_id,
							Location_desc,
							Start_time,
							End_time
							FROM	[dbo].[fnLocal_CTS_Appliance_Cleanings](A.eventid , NULL, NULL)
						) Q1




/*
UPDATE a
SET lastclean = COALESCE(alc.End_time, '1-Jan-2000')
FROM @Appliances a
JOIN @Appliance_last_cleaning alc	ON a.EventId = alc.Appliance_event_id AND Cleaning_status = 'Clean'
*/


/*============= set Location Notifications =========*/
INSERT @LocationNotifications	 (
	Serial								,
	Cleaning_status						,
	Active_or_inprep_process_order_Id	,
	Number_of_appliances				,
	Location_status						,
	Pending_Appliance_Count				)
SELECT	l.Serial,
		COALESCE(f.cleaning_status, f.maintenance_Status) ,
		COALESCE(o.ppid,0),
		COALESCE(s1.NumberApp,0),
		f.Location_status,
		COALESCE(s2.PendingAppCnt,0)
FROM @Locations l
LEFT JOIN (	SELECT COUNT(a.TransitionEventId) as 'PendingAppCnt', l.puid as 'puid'
			FROM @Appliances a
			JOIN @Locations l ON a.PuidLocation = l.puid
			WHERE a.extendedInfo IS NOT NULL
			GROUP BY l.Puid) s2											ON l.Puid = s2.puid
LEFT JOIN (	SELECT COUNT(a.EventId) as 'NumberApp', l.puid as 'puid'
			FROM @Appliances a
			JOIN @Locations l ON a.PuidLocation = l.puid
			GROUP BY l.Puid) s1											ON l.Puid = s1.puid
LEFT JOIN @ActiveOrder o												ON o.puid = l.puid
CROSS APPLY dbo.fnLocal_CTS_Location_Status(l.puid,NULL) f




/*============= set Appliance Notifications =========*/
INSERT @ApplianceNotifications (
	Serial							,
	Cleaning_status					,
	Appliance_Location_Id			,
	Appliance_Status				,
	Appliance_PPID_Id				,
	Appliance_Product_Id			,
	Status_Pending_id
)
SELECT	a.EventId,
		alc.Cleaning_status,
		COALESCE(a.PuidLocation,0),
		COALESCE(ps.prodStatus_Desc, 'Dirty-Sale'),
		COALESCE(ap.PP_ID,0),
		COALESCE(ap.Prod_id,0),
		COALESCE(a.Status_Pending_id,0)
FROM @Appliances a
LEFT JOIN @Appliance_last_cleaning alc	ON a.eventid = alc.Appliance_event_id AND alc.Cleaning_status <> 'Clean'
LEFT JOIN @Appliance_Production ap		ON a.eventid = ap.Appliance_event_id
join production_status ps				ON a.AppStatusId = ps.prodStatus_id


SELECT * FROM @LocationNotifications
select * from @ApplianceNotifications
	

SET NOCOUNT OFF

RETURN
