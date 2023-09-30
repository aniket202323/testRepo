
-----------------------------------------------------------------------------------------------------------------------
-- Stored Procedure: o la produccion plan start
-----------------------------------------------------------------------------------------------------------------------
-- Author				: Arido Software
-- Date created			: 2017-03-13
-- Version 				: 1.0
-- SP Type				: Report Stored Procedure
-- Caller				: Report
-- Description			: This stored procedure provides the data for UDE Events.
-- Editor tab spacing	: 4 
-- --------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:

-- --------------------------------------------------------------------------------------------------------------------
-- ========	====	  				 ====					=====
-- 1.0		2017-03-13			     Initial Release        FO-02760
-- 1.1		2017-04-11				 Fernando Rio			'EventByScheduleTime' when Parent Event is UDE then not working properly.
--															Review the rest of the EventBy services.
-- 1.2		2017-04-13				 Fernando Rio			Changed the way to look for Size changes
-- 1.3		2017-04-13				 Fernando Rio			Changed the BatchId comparison for Previous and Current.
--															Fix the IF Condition to create the Event.
-- 1.4		2017-04-18				 Daniela Giraudi        Added Log file Message.
-- 1.5		2017-06-07				 Daniela Giraudi        Changed property name from TURB006 Line Factors to RE_Product Information.
-- 1.6		2017-06-13               Daniela Giraudi        Solved issue with log file in  TBS event where was missing else condition in if PO is running.
-- 1.7		2017-06-13				 Daniela Giraudi		Added two parameters in @output table for Process Order event with ScheludeMinutes Qualifier.
-- 1.8		2017-07-03				 Daniela Giraudi		Fixed issue with qualifiers in ShiftChange event type and @monitoringEvent in UnitsProduced.
-- 1.9      2017-07-03               Daniela Giraudi		Added Weekly event type.
-- 1.10		2017-07-06				 Juan Pisani			Add multiple day trigger functionality for Time-Monthly UDEs
-- 1.11		2017-07-18				 Daniela Giraudi		Fixed issue with ShiftChange event type.
-- 1.12		2017-08-02				 Daniela Giraudi		Fixed issue with End_TIme in Weekly trigger type.
-- 1.13		2017-08-02				 Daniela Giraudi        Added ShiftChangeOnce trigger type and changed Shiftchange trigger type to ShiftChange Multi.
-- 1.14		2017-08-09				 Daniela Giraudi		Fix end time.Now the Qualifier Time Check is the End_Time of the event for all trigger type that use 
--															Qualifiers(Calendar Minutes, Schedule Minutes, Downtime Minutes,Uptime Minutes).
-- 1.15		2017-08-17				 Daniela Giraudi		Added new Trigger Type : Formula Change
-- 1.16		2017-10-20				 Daniela Giraudi		Change QualifierOffset to QualifierValue in ShiftChangeOnce trigger
-- 1.17		2017-10-23				 Daniela Giraudi		Added new Trigger Type TimeByUptimeOnly
-- 1.18		2018-03-08				 Daniela Giraudi		Modified Datatype for @BN and @PreviousBN values from integer to varchar
-- 1.19     2018-05-07				 Daniela Giraudi		Fixed issue with Brand Change TriggerType when there aren't PO open on the Unit
-- 1.20     2018-05-25				 Daniela GIraudi		FO-03438 Allow  more that one configuration of same trigger in the same unit
-- 1.21     2018-06-18				 Daniela GIraudi		FO-03438 Allow  more that one configuration of same trigger in the same unit (modified Event Name)
-- 1.22		2018-07-20				 Fernando Rio			FO-03535 Fixed issue with Weekly events if that is the unique event configured for a Production Unit.
-- 1.23		2020-05-06				 Daniela GIraudi		FO-04455 UDE Listener ShiftChangeOnce bugfix
-- 1.24		2021-11-18				 Daniela GIraudi		Fixed Daily trigger  because it doesn't work when the year changes
-- 1.25		2022-03-03				 Daniela GIraudi		Fixed wEEKLY trigger  because it doesn't work correctly.
-- 1.26		2022-10-27				 Daniela GIraudi		Remove with ENCRYPTION.
-- 1.27		2022-10-30				 Daniela GIraudi		Solve performance issues.
-- ---- EXEC spLocal_UDE_MonitorService '','			'
--====================================================================================================================

CREATE PROCEDURE [dbo].[spLocal_UDE_MonitorService]


--WITH ENCRYPTION 
AS
SET NOCOUNT ON	
----------------------------------------------------------------------------------------------------------------------
-- VARIABLES UDEOnPOStatus
----------------------------------------------------------------------------------------------------------------------
DECLARE              

		@ecid		   				INT				,	
		@EventSubType				INT				,		-- ec_id UDE Monitoring
		@STLPUId   					INT				,
		-----
		@intUserId   				INT				,
		@SpecPropertyID				INT				,
		@SizeSpecId					INT				,
		@FormulaSpecId				INT				,
		@PPID						INT				,
		@Previous_PPID				INT				,
		@ProdID						INT				,
		@PreviousProdId             INT				,
		@Prod_Size					FLOAT			,
		@Prod_Size_Varchar			VARCHAR(25)		,
		@PreviousProd_Size			FLOAT			,
		@PreviousProd_Size_Varchar	VARCHAR(25)		,
		@Prod_Formula				NVARCHAR(50)	,
		@PreviousProd_Formula		NVARCHAR(50)	,
		@BN							NVARCHAR(50)	,
		@PreviousBN					NVARCHAR(50)	,
		@POStatusId					INT				,
		@PONumber					NVARCHAR(50)	,
		@EventTime 					DATETIME		,
		@EventStartTime 			DATETIME		,
		@POStartTime 				DATETIME		,
		@POEndTime					DATETIME		,
		@spEndTime					DATETIME		,
		@Last5Minutes				DATETIME		,
		@spEndTimeOnTime			DATETIME		,

		
		@thisPUId					INT				,
		@dteLastShiftTime			DATETIME		,
	--	@EventSubType					INT				,  -- Sub-Event used for UDE generation 1. PE-UDE 2. CIL 3. CL 4. QA
		@strEventNum 				VARCHAR(30)		,	
		@lastEvent					DATETIME		,	
		@MonitoredEvent				DATETIME		,
		@CalendarMinutes			INT				,
		@DowntimeMinutes			INT				,
		@UptimeMinutes				INT				,
		@ScheduleMinutes			INT				,
	--	@LastDay					INT				,
		@MinQuantity				INT				,
		@VarQuantity				NVARCHAR(50)	,
		@EVENT						DATETIME		,
		@Production					FLOAT			,	
		@StopStart					DATETIME		,
		@ParentSubType				VARCHAR(50)		,
		@CountMin					INT				,
		@CountMAX					INT				,
		@year						NVARCHAR(4)		,
		@month						NVARCHAR(4)		,
		@day						NVARCHAR(4)		,
		@UDECount					NVARCHAR(50)	,
		@EndOfWeek					INT				,
		@1st_day_ofweek				INT				,

	    @str						VARCHAR(255)	,
        @ind						INT				,
	    @input						VARCHAR(50)		,
----------------------------------------------------------------------------------------------------------------------
-- VARIABLES Script
----------------------------------------------------------------------------------------------------------------------

		  @i						INT				,



----------------------------------------------------------------------------------------------------------------------
-- VARIABLES New Production Hourly
----------------------------------------------------------------------------------------------------------------------
		@dteLastHourlyEvent			DATETIME		,
		@dteNextTime				DATETIME		,
		@intEvent_id				INT				,
		@RS_User_id					INT				,
		@AppVersion					VARCHAR(30)		,	-- Used to retrieve the Proficy database Version
		@NbrRows					INT				,
		@intType					INT
		
----------------------------------------------------------------------------------------------------------------------
-- VARIABLE TABLES
----------------------------------------------------------------------------------------------------------------------
DECLARE @POList TABLE	( 
		RcdIdx						INT IDENTITY	,
		PPId						INT				, 
		ProcessOrder				NVARCHAR(50)	,  
		POStatusId					INT				,
		PUId						INT				,
		AStartTime					DATETIME		,
		AEndTime					DATETIME		)


DECLARE @tblListenerConf TABLE
                           (      ECId            INT					 ,                                 
                                  PUId            INT					 ,
                           		  TriggerType	  NVARCHAR(50)			 ,
								  TriggerValue	  NVARCHAR(50)			 ,
								  Qualifier		  NVARCHAR(50)			 ,
								  QuantityVar	  NVARCHAR(50)			 ,
			    				  QualifierValue  NVARCHAR(50)					 ,
								  QualifierOffset INT					 ,
								  ParentEvent     NVARCHAR(50)			 ,
								  Flag            INT 
								  )

  
  DECLARE    @tblGetUpDownMinutes TABLE
                           (      UPDOWNFLAG			INT                  ,                                 
                                  DOWNTIMEMIN			INT                  ,
                                  UPTIMEMIN				INT					 ,
								  SCHEDULEMIN			INT                  ,
								  PreviousReason		NVARCHAR(50)		 ,
								  ActualReason          NVARCHAR(50)		 ,
								  StartTime				DATETIME
								  )

 
  DECLARE    @tblGetQuantity TABLE
                           (      MinQuantity          INT    ,
								  PercQuantity         FLOAT  ,
								  ActualQuantity       FLOAT  ,
								  RemainingQuantity    FLOAT                                              
                                  )
  
  
  DECLARE    @EC_ID TABLE
                           (       ID				   INT IDENTITY,
						           ECID				   INT		   ,
								   SUBTYPE			   INT         ,
								   PUID				   INT
								                                    
                                  )
DECLARE @Output TABLE (
		Event_Id					INT				,
		Event_Num					VARCHAR (100)	,
		PU_ID						INT				,
		Time_Stamp					DATETIME		,
		Event_Status                INT				, 
		Transaction_Type			INT				,
		User_Id						INT				,
		Start_Time                  DATETIME		,
		Prod_Id						INT				,
		Event_Subtype				INT				,
		ReturnStatus				INT				,
		ReturnMessage				VARCHAR(255)	)

DECLARE  @Result TABLE(
		Value NVARCHAR(50))
----------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------
--	Get System utility User_Id
----------------------------------------------------------------------------------------------------------------------
SET @intUserId = (	SELECT User_id
	FROM dbo.Users WITH(NOLOCK)
	WHERE UserName = 'ReliabilitySystem'	)
---------------------------------------------------------------------------------------------------------------------

IF @intUserId IS NULL
BEGIN
				INSERT INTO @Output( ReturnStatus,
									ReturnMessage )
			
				VALUES			 ( 0,
								'Reliability System is not present ...')


				SELECT
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage
				FROM @OUTPUT

	SET NOCOUNT OFF
	RETURN
END
--------------------------------------------------------------------------------------------------------------------- 
SET @spEndTime=GETDATE()
SET @Last5Minutes = DATEADD(mi,-5,@spEndTime) --FIND EC_ID
 ---------------------------------------------------------------
 --FIND EC_ID
 ---------------------------------------------------------------

INSERT INTO @EC_ID (ECID,Subtype,PUId)
SELECT ec.EC_id, ec.EVENT_Subtype_ID ,ec.PU_Id
FROM dbo.Event_Configuration ec WITH(NOLOCK)
WHERE	PU_Id in (SELECT KeyId
					FROM Table_Fields_Values 
					WHERE Table_Field_Id = (SELECT TABLE_fIELD_ID 
											FROM Table_Fields 
											WHERE Table_Field_Desc ='EventListener' AND TABLEID =(	SELECT  TableId 
																									FROM dbo.Tables WITH(NOLOCK) 
																									WHERE  TableName = 'Prod_Units') ))
 AND Ec_Desc like '%UDE Monitoring%'
 
---------------------------------------------------------------------------------------------------------------------
IF (SELECT COUNT(*) FROM @EC_ID) = 0
BEGIN
				INSERT INTO @Output( ReturnStatus,
									 ReturnMessage )
			
				VALUES			 ( 0,
								 'No Event Models configured to use UDE Monitoring ...')

			
				SELECT
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage
				FROM @OUTPUT
	SET NOCOUNT OFF			
	RETURN
END
--------------------------------------------------------------------------------------------------------------------- 


 
SET @CountMin=1
SELECT @CountMAX=MAX(ID) FROM @EC_ID
WHILE  @CountMin < = @CountMAX
BEGIN
SELECT  @ecid=ECId FROM  @EC_Id WHERE ID = @CountMin
-----------------------------------------------------------------
--Fill @tblListenerConf from Model configured
-----------------------------------------------------------------
INSERT INTO @tblListenerConf 
                           (      ECId          			 ,                                 
                                  PUId           		
							)
SELECT                     ec.EC_Id                   
                           ,ec.PU_Id  
						                   
                              
                   
FROM dbo.Event_Configuration ec WITH(NOLOCK)
WHERE	ec.EC_id=@ecid


UPDATE TLC
SET TriggerType	=  ecp.VALUE
FROM @tblListenerConf TLC
JOIN  dbo.Event_Configuration_Properties  ecp WITH(NOLOCK) ON  ecp.ec_id=TLC.ECID 
JOIN  dbo.ED_Field_Properties efp WITH(NOLOCK) ON  ecp.ED_Field_PROP_ID= efp.ED_Field_PROP_ID
WHERE  efp.Field_Desc ='TriggerType'  

UPDATE TLC
SET Qualifier	=  CASE WHEN ecp.VALUE = '-' THEN NULL ELSE  ecp.VALUE  END
FROM @tblListenerConf TLC
JOIN  dbo.Event_Configuration_Properties  ecp WITH(NOLOCK) ON  ecp.ec_id=TLC.ECID  
JOIN  dbo.ED_Field_Properties efp WITH(NOLOCK) ON  ecp.ED_Field_PROP_ID= efp.ED_Field_PROP_ID
WHERE  efp.Field_Desc ='Qualifier'

UPDATE TLC
SET QualifierValue	=  ecp.VALUE
FROM @tblListenerConf TLC
JOIN  dbo.Event_Configuration_Properties  ecp WITH(NOLOCK) ON  ecp.ec_id=TLC.ECID  
JOIN  dbo.ED_Field_Properties efp WITH(NOLOCK) ON  ecp.ED_Field_PROP_ID= efp.ED_Field_PROP_ID
WHERE  efp.Field_Desc ='QualifierValue'

UPDATE TLC
SET QuantityVar=  ecp.VALUE
FROM @tblListenerConf TLC
JOIN  dbo.Event_Configuration_Properties  ecp WITH(NOLOCK) ON  ecp.ec_id=TLC.ECID 
JOIN  dbo.ED_Field_Properties efp WITH(NOLOCK) ON  ecp.ED_Field_PROP_ID= efp.ED_Field_PROP_ID
WHERE  efp.Field_Desc ='QuantityVariable'

UPDATE TLC
SET QualifierOffset	=  ecp.VALUE
FROM @tblListenerConf TLC
JOIN  dbo.Event_Configuration_Properties  ecp WITH(NOLOCK) ON  ecp.ec_id=TLC.ECID  
JOIN  dbo.ED_Field_Properties efp WITH(NOLOCK) ON  ecp.ED_Field_PROP_ID= efp.ED_Field_PROP_ID
WHERE  efp.Field_Desc ='QualifierOffset'

UPDATE TLC
SET TriggerValue	=  ecp.VALUE
FROM @tblListenerConf TLC
JOIN  dbo.Event_Configuration_Properties  ecp WITH(NOLOCK) ON  ecp.ec_id=TLC.ECID  
JOIN  dbo.ED_Field_Properties efp WITH(NOLOCK) ON  ecp.ED_Field_PROP_ID= efp.ED_Field_PROP_ID
WHERE  efp.Field_Desc ='TriggerValue'


UPDATE TLC
SET	  ParentEvent	=  CASE WHEN ecp.VALUE = '-' THEN NULL ELSE  ecp.VALUE  END
FROM @tblListenerConf TLC
JOIN  dbo.Event_Configuration_Properties  ecp WITH(NOLOCK) ON  ecp.ec_id=TLC.ECID  
JOIN  dbo.ED_Field_Properties efp WITH(NOLOCK) ON  ecp.ED_Field_PROP_ID= efp.ED_Field_PROP_ID
WHERE  efp.Field_Desc ='ParentEvent'

SET @CountMin= @CountMin +1
END




SET @CountMin=1
SELECT @CountMAX=MAX(ID) FROM @EC_ID

WHILE  @CountMin < = @CountMAX
BEGIN
SELECT  @ecid=ECId,  @EventSubType=Subtype, @thisPUId= PUID FROM  @EC_Id WHERE ID = @CountMin

--Change needed to solve issue with Weekly --------------------

DELETE FROM @Result
----------------------------------------------------------------
--Find PU for Crew Schedule
----------------------------------------------------------------
--SELECT	@stlsPUId =	CASE
--						 WHEN	(CharIndex	('STLS=', Extended_Info, 1)) > 0
--						   THEN	Substring	(Extended_Info, (CharIndex	('STLS=', Extended_Info, 1) + 5),
--						CASE
--						  WHEN 	(CharIndex(';', Extended_Info, CharIndex('STLS=', Extended_Info, 1))) > 0
--						   THEN (CharIndex(';', Extended_Info, CharIndex('STLS=', Extended_Info, 1)) - (CharIndex('STLS=', Extended_Info, 1) + 5)) 
--						ELSE Len(Extended_Info)
--						END )
--								END
--FROM		dbo.Prod_Units WITH(NOLOCK)
--WHERE		PU_ID = @thisPUId 

---------------------------------------------------------------------------------------------------------------------
IF (@thisPUId is null)
BEGIN
				INSERT INTO @Output( ReturnStatus,
									 ReturnMessage )
			
				VALUES				( 0,
									 'No entry in Crew_schedule for unit...')

END
--------------------------------------------------------------------------------------------------------------------- 
SELECT  @ParentSubType = NULL,
		@VarQuantity= NULL
		
 ---------------------------------------------------------------
 --FIND EVENT_SUBTYPE FOR PARENT
 ---------------------------------------------------------------
 
 SELECT @ParentSubType=Event_Subtype_Id
 FROM dbo.Event_Subtypes  WITH(NOLOCK)
 WHERE	Event_Subtype_desc = (SELECT ParentEvent FROM @tblListenerConf WHERE ECID=@ECID)
--------------------------------------------------------------------------------------------------------------------
--Set Event Start Time 
---------------------------------------------------------------------------------------------------------------------

--SET @spEndTime = GETDATE()
--SET @Last5Minutes = DATEADD(mi,-5,GETDATE())


---------------------------------------------------------------------------------------------------------------------
-- @tblGetUpDownMinutes and @tlGetQuantity
---------------------------------------------------------------------------------------------------------------------

SELECT @VarQuantity = QuantityVar FROM @tblListenerConf  WHERE ECID=@ECID

 ---------------------------------------------------------------------------------------------------------------------

 -- PP_Id , Product, Size and Batch Id  Information
 ---------------------------------------------------------------------------------------------------------------------
 -- debug
 -- SELECT * FROM @tblListenerConf

SELECT	@PPID =NULL,
		@ProdId=NULL,
		@PreviousProdId=NULL,
		@Previous_PPID=NULL,
		@PreviousProd_Size =NULL,
		@PreviousProd_Size_Varchar =NULL,
		@Prod_Size = NULL,
		@Prod_Size_Varchar = NULL,
		@Prod_Formula =NULL,
		@PreviousProd_Formula = NULL,
		@BN = NULL,
		@PreviousBN = NULL
----------------------------------------------------------------------------------------------------------------------
--Product and PP_ID
----------------------------------------------------------------------------------------------------------------------
 SELECT @PPID	= pps.PP_Id ,
		@ProdId	= pp.Prod_Id
 FROM dbo.Production_Plan_Starts	pps WITH(NOLOCK) 
 JOIN dbo.Production_Plan			pp	WITH(NOLOCK) ON pps.PP_Id = pp.PP_Id
 WHERE pps.PU_Id = @thisPUId
	AND pps.Start_Time <= @spEndTime
	AND (pps.End_Time IS NULL  )

	
 SELECT @PreviousProdId = pp.Prod_Id,
		@Previous_PPID = pp.PP_Id
 FROM dbo.Production_Plan pp  WITH(NOLOCK) 
 WHERE pp.PP_Id =(	SELECT pps.PP_Id
					FROM dbo.Production_Plan_Starts  pps WITH(NOLOCK)
					WHERE End_Time  = (	SELECT MAX(End_Time) 
											FROM  dbo.Production_Plan_Starts WITH(NOLOCK) 
											WHERE pu_id=@thisPUId 
											AND End_Time < @spEndTime ) 
						AND PU_Id = @thisPUId )


----------------------------------------------------------------------------------------------------------------------
--Size: change the way to get the Size as now it will come from the Spec vs from a Product Group
-- Leave it as a Specific Line - Line Factor for now, than change it to 'RE_Product Information'
----------------------------------------------------------------------------------------------------------------------

-- Get the Property
SELECT @SpecPropertyId = PROP_ID
		FROM dbo.Product_Properties WITH(NOLOCK)
		WHERE Prop_Desc = 'RE_Product Information'
		
-- Get the Specifications
SELECT @SizeSpecId = Spec_Id
		FROM dbo.Specifications WITH(NOLOCK)
		WHERE Spec_Desc like 'Size' 
				and Prop_Id = @SpecPropertyID

-- Get the Specifications for Formula
SELECT @FormulaSpecId = Spec_Id
		FROM dbo.Specifications WITH(NOLOCK)
		WHERE Spec_Desc like 'Formula Group' 
				and Prop_Id = @SpecPropertyID		
--SELECT * FROM dbo.Products WHERE Prod_Id = @ProdId

SELECT @Prod_Size_Varchar = Target
FROM dbo.Products p WITH(NOLOCK)
LEFT JOIN dbo.Characteristics c WITH(NOLOCK) ON (c.Char_Desc_Local Like '%' + p.Prod_Code + '%'
												 OR c.Char_Desc_Local = p.Prod_Desc)
							and c.Prop_Id = @SpecPropertyId
LEFT JOIN Active_Specs ass WITH(NOLOCK) On c.char_id = ass.char_id
WHERE ass.Expiration_Date Is Null 
AND ass.Spec_Id = @SizeSpecId
AND p.Prod_Id = @ProdId

SET @Prod_Size = CONVERT(FLOAT, @Prod_Size_Varchar)

SELECT @PreviousProd_Size_Varchar = Target
FROM dbo.Products p WITH(NOLOCK)
LEFT JOIN dbo.Characteristics c WITH(NOLOCK) ON (c.Char_Desc_Local Like '%' + p.Prod_Code + '%'
												 OR c.Char_Desc_Local = p.Prod_Desc)
							and c.Prop_Id = @SpecPropertyId
LEFT JOIN Active_Specs ass WITH(NOLOCK) On c.char_id = ass.char_id
WHERE ass.Expiration_Date Is Null 
AND ass.Spec_Id = @SizeSpecId
AND p.Prod_Id = @PreviousProdId


SET @PreviousProd_Size = CONVERT(FLOAT, @PreviousProd_Size_Varchar)

--SELECT @Prod_Size = Product_Grp_Id 
--FROM   dbo.Product_Group_Data (NOLOCK)  
--WHERE Prod_Id= @ProdId
	
--SELECT @PreviousProd_Size = Product_Grp_Id 
--FROM   dbo.Product_Group_Data (NOLOCK)  
--WHERE Prod_Id= @PreviousProdId

SELECT @Prod_Formula = Target
FROM dbo.Products p WITH(NOLOCK)
LEFT JOIN dbo.Characteristics c WITH(NOLOCK) ON (c.Char_Desc Like '%' + p.Prod_Code + '%'
												 OR c.Char_Desc = p.Prod_Desc)
							and c.Prop_Id = @SpecPropertyId
LEFT JOIN Active_Specs ass WITH(NOLOCK) On c.char_id = ass.char_id
WHERE ass.Expiration_Date Is Null 
AND ass.Spec_Id = @FormulaSpecId
AND p.Prod_Id = @ProdId

SELECT @PreviousProd_Formula = Target
FROM dbo.Products p WITH(NOLOCK)
LEFT JOIN dbo.Characteristics c WITH(NOLOCK) ON (c.Char_Desc Like '%' + p.Prod_Code + '%'
												 OR c.Char_Desc = p.Prod_Desc)
							and c.Prop_Id = @SpecPropertyId
LEFT JOIN Active_Specs ass WITH(NOLOCK) On c.char_id = ass.char_id
WHERE ass.Expiration_Date Is Null 
AND ass.Spec_Id = @FormulaSpecId
AND p.Prod_Id = @PreviousProdId

----------------------------------------------------------------------------------------------------------------------
--Batch Id
----------------------------------------------------------------------------------------------------------------------

SELECT @BN =User_General_1 FROM dbo.Production_Plan WITH(NOLOCK) WHERE PP_Id = @PPID
SELECT @PreviousBN =User_General_1 FROM dbo.Production_Plan WITH(NOLOCK) WHERE PP_Id = @Previous_PPID

--SELECT	@BN =Pattern_Code 
--FROM		dbo.Production_Setup WITH(NOLOCK)
--WHERE		PP_Id = @PPID 
----------------------------------------------------------------------------------------------------------------------
--UDE Configuration
----------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------
--  1. Time By Uptime
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid ) ='TimeByUptime'
	BEGIN

	SELECT  @MonitoredEvent  = Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)						


	SELECT @lastEvent=MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
	SET @lastEvent = ISNULL(@lastEvent,@MonitoredEvent)

	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@lastEvent

	INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN , UPTIMEMIN, SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
	EXEC spLocal_GetUpDownMinutes  @lastEvent,@thisPUId, @spEndTime

	IF  (@MonitoredEvent IS NOT NULL)
	 BEGIN 
	  --SET @spEndTime   =@spEndTime

	  SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
	  IF  @UptimeMinutes > = (SELECT TriggerValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
	  BEGIN
		IF  (SELECT QUALIFIER FROM @tblListenerConf WHERE ECID=@ECID) ='Min Quantity'
		 BEGIN
		    IF (SELECT QuantityVar FROM @tblListenerConf WHERE ECID=@ECID) IS NOT NULL
			 BEGIN
			     
				-- SET @spEndTime   =@spEndTime
			   	     
				IF (SELECT MinQuantity FROM  @tblGetQuantity) >= (SELECT QualifierValue FROM @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
				 SET @strEventNum =  'TBU-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
			
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage)	
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTime,120)					,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'

				END --@MinQuantity >= (SELECT QualifierValue FROM @tblListenerConf) 
			 END--QuantityVar
			 ELSE
				BEGIN
					INSERT INTO @Output( ReturnStatus,
										ReturnMessage )
			
					VALUES				( 0,
										CONVERT(VARCHAR(10),@ecid) + '-TBU:Quantity Var is NULL')
				
				END

		 END--Min Quantity'
		 ELSE
		 BEGIN
			INSERT INTO @Output( ReturnStatus,
								ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) + '-TBU:Invalid Qualifier')
				
		END
	  END-- @CalendarMinutes > = (SELECT QualifierValue from @tblListenerConf )
	END --@MonitoredEvent not null and not event created yet
	ELSE
	BEGIN
			INSERT INTO @Output( ReturnStatus,
								ReturnMessage )		
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) + '-TBU:No PO Runnning')
				
	END
END -- ='TimeByCalendar

----------------------------------------------------------------------------------------------------------------------
--  2. Time by Schedule Time

----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='TimeByScheduleTime'
	BEGIN
	
	SELECT  @MonitoredEvent  = Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)						
	SELECT @lastEvent=MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
	SET @lastEvent = ISNULL(@lastEvent,@MonitoredEvent)

	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@lastEvent

	INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN , UPTIMEMIN   ,SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
	EXEC spLocal_GetUpDownMinutes  @lastEvent,@thisPUId, @spEndTime

	IF  (@MonitoredEvent IS NOT NULL) 
	 BEGIN 
	 -- SET @spEndTime   =@spEndTime
	  
	  SELECT @ScheduleMinutes= DATEDIFF(mi,@lastEvent,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
	 -- SELECT @ScheduleMinutes = ScheduleMIN FROM @tblGetUpDownMinutes

	  IF  @ScheduleMinutes > = (SELECT TriggerValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
	  BEGIN
		IF  (SELECT QUALIFIER FROM @tblListenerConf WHERE ECID=@ECID ) ='Min Quantity'
		 BEGIN
		    IF (SELECT QuantityVar FROM @tblListenerConf WHERE ECID=@ECID) IS NOT NULL
			 BEGIN
			     
				 --SET @spEndTime   =@spEndTime
			   	     
				IF (SELECT MinQuantity FROM  @tblGetQuantity) >= (SELECT QualifierValue FROM @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
				 SET @strEventNum =  'TBS-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
				------------------------------------------------------------------------------
				--UD Event Result Set 8
				------------------------------------------------------------------------------
				-- BEGIN
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTime,120)					,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'
				END --@MinQuantity >= (SELECT QualifierValue FROM @tblListenerConf) 
			 END--QuantityVar
			 ELSE
			 BEGIN
					INSERT INTO @Output( ReturnStatus,
										ReturnMessage )
			
					VALUES				( 0,
										CONVERT(VARCHAR(10),@ecid) + '-TBS: Quantity Var is NULL')
				
			END
		 END--Min Quantity'
		 ELSE
		 BEGIN
			INSERT INTO @Output( ReturnStatus,
								ReturnMessage )
			
			Values			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'-TBS:Invalid Qualifier')
					
		END
	  END-- @CalendarMinutes > = (SELECT QualifierValue from @tblListenerConf )

	END --@MonitoredEvent not null
	ELSE
	BEGIN
			INSERT INTO @Output( ReturnStatus,
								ReturnMessage )
			
		   Values			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'-TBS:No PO Runnning')
	END
END -- ='TimeByCalendar

----------------------------------------------------------------------------------------------------------------------
--  3. Time By Calendar Time
--  Debug
--IF @ecid = 66
--BEGIN
--	SELECT @thisPUId,* FROM @tblListenerConf WHERE ECID = @ecid
--END
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid ) ='TimeByCalendarTime'
	BEGIN
	SELECT  @MonitoredEvent  = MAX (End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)

	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@MonitoredEvent

	IF  @MonitoredEvent IS NULL
	BEGIN
	  SET @strEventNum =  'TBC-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
			
			------------------------------------------------------------------------------
			--UD Event Result Set 8
			------------------------------------------------------------------------------
			-- BEGIN
				INSERT INTO @Output(
				Event_Id										,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage				)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTime,120)					,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'

	END --@MonitoredEvent null
	ELSE
	BEGIN  
	  --SET @spEndTime   =@spEndTime
	  SET @CalendarMinutes = datediff(mi,@MonitoredEvent,@spEndTime)

	  IF  @CalendarMinutes > = (SELECT TriggerValue from @tblListenerConf  WHERE ecid=@ecid)

	  BEGIN
		IF  (SELECT QUALIFIER FROM @tblListenerConf  WHERE ecid=@ecid) ='Min Quantity'
		 BEGIN
		    IF (SELECT QuantityVar FROM @tblListenerConf  WHERE ecid=@ecid ) IS NOT NULL AND (@MonitoredEvent < @spEndTime)
			 BEGIN
			     
				 --SET @spEndTime   =@spEndTime
	
			   	     
				IF (SELECT MinQuantity FROM  @tblGetQuantity) >= (SELECT QualifierValue FROM @tblListenerConf  WHERE ecid=@ecid) 
				BEGIN
				 SET @strEventNum =  'TBC-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)

				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTime,120)					,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'
				END --@MinQuantity >= (SELECT QualifierValue FROM @tblListenerConf) 
			 END--QuantityVar
			 ELSE
			 BEGIN
			 IF (SELECT QuantityVar FROM @tblListenerConf  WHERE ecid=@ecid)  IS NULL
				 BEGIN
						INSERT INTO @Output( ReturnStatus,
											ReturnMessage )
			
						 VALUES				( 0,
											CONVERT(VARCHAR(10),@ecid) + '-TBC:Quantity Var is NULL')
				 END
			 END
		 END--Min Quantity'
	     ELSE
		 BEGIN
 			INSERT INTO @Output( ReturnStatus,
								ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-TBC:Invalid Qualifier')

		END
	
	  END-- @CalendarMinutes > = (SELECT QualifierValue from @tblListenerConf )
	END
END -- ='TimeByCalendar

----------------------------------------------------------------------------------------------------------------------
--  4. TIME MONTHLY
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='Time-Monthly'
BEGIN

		--	Retrieve trigger value from listener configuration
		SELECT @input = TriggerValue from @tblListenerConf WHERE ECId = @ecid
	  
		--	Split trigger values and insert them into @Result table
		IF(@input is not null)
		BEGIN
		      SET @ind = CharIndex(',',@input)
		      WHILE @ind > 0
		      BEGIN
		            SET @str = SUBSTRING(@input,1,@ind-1)
		            SET @input = SUBSTRING(@input,@ind+1,LEN(@input)-@ind)
		            INSERT INTO @Result values (@str)
		            SET @ind = CharIndex(',',@input)
		      END
		      SET @str = @input
		      INSERT INTO @Result values (@str)
		END

		SELECT @year= datepart(yy,@spEndTime)
		SELECT @month= datepart(mm, @spEndTime)
		SELECT @day= datepart(dd, @spEndTime)

	SELECT  @MonitoredEvent = MAX(End_Time) FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
	IF  @MonitoredEvent IS NULL
	BEGIN
	   IF @day IN (SELECT Value FROM @Result) AND (CONVERT(NVARCHAR(5), @spEndTime, 108) >= (SELECT QualifierValue from @tblListenerConf WHERE ECId = @ecid)) AND (CONVERT(NVARCHAR(5), @Last5Minutes, 108) < (SELECT QualifierValue from @tblListenerConf WHERE ECId = @ecid))
	   BEGIN
	   
			IF NOT EXISTS(SELECT UDE_Id FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.End_Time = @spEndTime) AND (ude.Event_Subtype_Id=@EventSubType))
				
			SELECT @spEndTimeOnTime=  CONVERT(DATETIME,(CONVERT(NVARCHAR(4),@year)+ '-' + CONVERT(NVARCHAR(2),@month)+ '-' + CONVERT(NVARCHAR(2),@day) + ' ' + (SELECT QualifierValue from @tblListenerConf WHERE ecid=@ecid )))
			SET @strEventNum =  'MON-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)

			INSERT INTO @Output(
			Event_Id				,
			Event_Num				,
			PU_Id					,
			Time_Stamp				,
			Event_Status			,
			Transaction_Type		,
			User_Id					,
			Start_Time				,
			Event_Subtype			,
			ReturnStatus			,
			ReturnMessage	)
			SELECT
			0													,
			@strEventNum										,	-- Event_Num
			@thisPUId											,	-- PU_Id
			convert(varchar(30),@spEndTimeOnTime,120) 			,	-- TimeStamp
			0													,
			1													,	-- Transact
			@intUserId											,
			isnull (convert(varchar(30),@MonitoredEvent,120),
			convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,													
			@EventSubType										,
			1													,
			'Success'
	   END
	END
	ELSE
		BEGIN
	    
		IF @day IN (SELECT Value FROM @Result) AND (CONVERT(NVARCHAR(5), @spEndTime, 108) >= (SELECT QualifierValue from @tblListenerConf WHERE ECId = @ecid)) AND (CONVERT(NVARCHAR(5), @Last5Minutes, 108) < (SELECT QualifierValue from @tblListenerConf WHERE ECId = @ecid))
		BEGIN
		
			IF NOT EXISTS(SELECT UDE_Id FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.End_Time = @spEndTime) AND (ude.Event_Subtype_Id=@EventSubType))
			BEGIN
			
				SELECT @spEndTimeOnTime=  CONVERT(DATETIME,(CONVERT(NVARCHAR(4),@year)+ '-' + CONVERT(NVARCHAR(2),@month)+ '-' + CONVERT(NVARCHAR(2),@day) + ' ' + (SELECT QualifierValue from @tblListenerConf WHERE ecid = @ecid)))
				SET @strEventNum =  'MON-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)

				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTimeOnTime,120) 			,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,													 
				@EventSubType										,
				1													,
				'Success'
		   END
		END
		--ELSE 
		--BEGIN
		--	--	What do we say to the Time-Monthly UDE execution? ... Not today
		--END
END

END-- END Time Monthly
----------------------------------------------------------------------------------------------------------------------
--  5. TIME DAILY
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='Time-Daily'
BEGIN
    SELECT @year= datepart(yy,@spEndTime)
	SELECT @month= datepart(mm, @spEndTime)
	SELECT @day= datepart(dd, @spEndTime)

	SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
	
	IF  @MonitoredEvent IS NULL
	BEGIN
		--SET @spEndTime=	@spEndTime
	   IF (CONVERT(NVARCHAR(5), @spEndTime, 108)  >=  (SELECT TriggerValue from @tblListenerConf WHERE ecid=@ecid ) AND  (CONVERT(NVARCHAR(5), @Last5Minutes, 108)  <  (SELECT TriggerValue from @tblListenerConf WHERE ecid=@ecid )))
	   BEGIN
	        SELECT @spEndTimeOnTime=  CONVERT(DATETIME,(CONVERT(NVARCHAR(4),@year)+ '-' + CONVERT(NVARCHAR(2),@month)+ '-' + CONVERT(NVARCHAR(2),@day) + ' ' + (SELECT TriggerValue from @tblListenerConf WHERE ecid=@ecid )))
			SET @strEventNum =  'Daily-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
			

				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,													 
				@EventSubType										,
				1													,
				'Success'
	   END--END DATE

	END--@MonitoredEvent IS NULL
	ELSE
	BEGIN
	  -- SET @spEndTime=@spEndTime
	   SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)

	   IF ((DATEPART (dd,@MonitoredEvent) < DATEPART(dd,@spEndTime) )OR(DATEPART (mm,@MonitoredEvent) < DATEPART(mm,@spEndTime) ) OR (DATEPART (yy,@MonitoredEvent) < DATEPART(yy,@spEndTime) )) AND   (CONVERT(NVARCHAR(5), @spEndTime, 108)  >=  (SELECT TriggerValue from @tblListenerConf WHERE ecid=@ecid) AND (CONVERT(NVARCHAR(5), @Last5Minutes, 108)  <  (SELECT TriggerValue from @tblListenerConf WHERE ecid=@ecid) ))
		BEGIN
		    SELECT @spEndTimeOnTime=  CONVERT(DATETIME,(CONVERT(NVARCHAR(4),@year)+ '-' + CONVERT(NVARCHAR(2),@month)+ '-' + CONVERT(NVARCHAR(2),@day) + ' ' + (SELECT TriggerValue from @tblListenerConf WHERE ecid=@ecid )))
			SET @strEventNum =  'Daily-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)
			
			------------------------------------------------------------------------------
			--UD Event Result Set 8
			------------------------------------------------------------------------------
			-- BEGIN
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
			SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
				@EventSubType										,
				1													,
				'Success'
					
	   END--END DATE
	END --@MonitoredEvent IS NOT NULL
END--END Time Daily

----------------------------------------------------------------------------------------------------------------------
--  6.Time SHIFT CHANGE EVENT
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='TimeShiftChange'
BEGIN

-----------------------------------------------------------------------------------------------------------------------
--Verify for shift change
--find last shift end time.
-----------------------------------------------------------------------------------------------------------------------

SET @MonitoredEvent = (SELECT MAX(end_time) FROM dbo.crew_schedule WITH(NOLOCK) WHERE (pu_id = @thisPUId) AND (end_time <@spEndTime))

IF @MonitoredEvent IS NOT NULL --There is Shift change
BEGIN
	SET @MonitoredEvent=DATEADD(mi,((SELECT TriggerValue FROM @tblListenerConf WHERE ECID=@ECID) + (SELECT QualifierOffset FROM @tblListenerConf WHERE ECID=@ECID)),@MonitoredEvent )
-----------------------------------------------------------------------------------------------------------------------
--Verify if there is already an event at end of shift time + trigger value + offset value
-----------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT UDE_Id FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.End_Time = @MonitoredEvent) AND (ude.Event_Subtype_Id=@EventSubType)) AND (@MonitoredEvent <= @spEndTime)
	BEGIN

		SET @LastEvent= (SELECT MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType))
		

		SET @strEventNum =  'CS-' + CONVERT(VARCHAR(30),@MonitoredEvent,20)  + '-'  + convert (VARCHAR(5), @EventSubType)
		--Set @spEndTime=	@MonitoredEvent 
		------------------------------------------------------------------------------
		--UD Event Result Set 8
		------------------------------------------------------------------------------
		-- BEGIN
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
			SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@MonitoredEvent,120) 				,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@LastEvent,120),
				convert(varchar(30),dateadd(s,-60,@MonitoredEvent),120)) ,											
				@EventSubType										,
				1													,
				'Success'	

	END

END--@MonitoredEvent IS NOT NULL 
ELSE
BEGIN

 			INSERT INTO @Output( ReturnStatus,
								ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-CS:No Crew Schedule programmed')
			
END
END-- Time Shift change

----------------------------------------------------------------------------------------------------------------------
--  7.a. ShiftChangeMulti
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf  WHERE ecid=@ecid ) ='ShiftChangeMulti'
BEGIN

-----------------------------------------------------------------------------------------------------------------------
--Verify for shift change
--find last shift end time.
-----------------------------------------------------------------------------------------------------------------------

SET @MonitoredEvent = (SELECT MAX(end_time) FROM dbo.crew_schedule WHERE (pu_id = @thisPUId) AND (end_time <@spEndTime))

IF @MonitoredEvent IS NOT NULL --There is Shift change
BEGIN
	SET @MonitoredEvent=DATEADD(mi,((SELECT TriggerValue FROM @tblListenerConf WHERE ECID=@ECID) + (SELECT QualifierOffset FROM @tblListenerConf WHERE ECID=@ECID)),@MonitoredEvent )
	SET @LastEvent= (SELECT MAX(End_Time) FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType))
-----------------------------------------------------------------------------------------------------------------------
--Verify if there is already an event at end of shift time + trigger value + offset value
-----------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT UDE_Id FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.End_Time = @MonitoredEvent) AND (ude.Event_Subtype_Id=@EventSubType)) AND (@MonitoredEvent <= @spEndTime)
	BEGIN
		--Yes we can create an event.
		--Build event @spEndTime
		
		

		SET @strEventNum =  'CSM-' + CONVERT(VARCHAR(30),@MonitoredEvent,20)  + '-' + convert (VARCHAR(5), @EventSubType)
		--Set @spEndTime=	@MonitoredEvent 
		------------------------------------------------------------------------------
		--UD Event Result Set 8
		------------------------------------------------------------------------------
		-- BEGIN
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
			SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@MonitoredEvent,120) 				,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@LastEvent,120),
				convert(varchar(30),dateadd(s,-60,@MonitoredEvent),120)) ,											
				@EventSubType										,
				1													,
				'Success'

	END
	ELSE
	BEGIN
	IF (SELECT Qualifier from @tblListenerConf WHERE ECID=@ECID ) IS NOT NULL
		BEGIN
		    SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)

			INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN , UPTIMEMIN   ,SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
		    EXEC spLocal_GetUpDownMinutes  @MonitoredEvent,@thisPUId, @spEndTime


			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='CalendarMinutes'
			BEGIN
			    
			    --SET @spEndTime   =@spEndTime
				SET @CalendarMinutes = datediff(mi,@MonitoredEvent,@spEndTime)
				IF  @CalendarMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)
				BEGIN
					
					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),@MonitoredEvent)
					SET @strEventNum =  'CSM-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType) --replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage)
				SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@LastEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

				END--DATEDIFF
			END--END CalendarMinutes
			ELSE
			BEGIN
				IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='DowntimeMinutes'
				BEGIN
			    --SET @spEndTime   =@spEndTime

				IF (SELECT StartTime FROM @tblGetUpDownMinutes) IS NOT NULL
					SELECT @DowntimeMinutes =DATEDIFF(mi, (SELECT StartTime FROM @tblGetUpDownMinutes),@spEndTime)
				ELSE                    
					SELECT @DowntimeMinutes=0

				IF  @DowntimeMinutes > = (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=0)
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),ISNULL((SELECT StartTime FROM @tblGetUpDownMinutes),@MonitoredEvent))
					SET @strEventNum =  'CSM-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-' + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					


					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	
					)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@LastEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'
										


				END--DATEDIFF
			END--END DowntimeMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID ) ='UptimeMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
				                     
				IF  @UptimeMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID ) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)+ISNULL((SELECT DOWNTIMEMIN FROM @tblGetUpDownMinutes),0)),@MonitoredEvent)
					SET @strEventNum =  'CSM-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@LastEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'
				END--DATEDIFF
			----------------------------------------------------------------------------
			END--UPTIMEMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf  WHERE ECID=@ECID) ='ScheduleMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT	@ScheduleMinutes= DATEDIFF(mi,@MonitoredEvent,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
				--SELECT @ScheduleMinutes = scheduleMin FROM 	@tblGetUpDownMinutes

				IF  @ScheduleMinutes >= (SELECT QualifierValue from @tblListenerConf  WHERE ECID=@ECID) 
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,(isnull((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0) + ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)),@MonitoredEvent)
					SET @strEventNum =  'CSM-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@LastEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			----------------------------------------------------------------------------
			END --SCHEDULE Time
			ELSE
			BEGIN

			 INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-CSM:Invalid Qualifier')
					
			END
			END -- OTHER QUALIFIER
		   END--WITH QUALIFIER
			
		END--CREATE EVENT

	END

END

END--@MonitoredEvent IS NOT NULL 
ELSE
BEGIN

 			INSERT INTO @Output( ReturnStatus,
								ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-CSM:No Crew Schedule programmed')

END
END--Shift change


----------------------------------------------------------------------------------------------------------------------
--  7.b. ShiftChangeOnce
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf  WHERE ecid=@ecid ) ='ShiftChangeOnce'
BEGIN

-----------------------------------------------------------------------------------------------------------------------
--Verify for shift change
--find last shift end time.
-----------------------------------------------------------------------------------------------------------------------

SET @MonitoredEvent = (SELECT MAX(end_time) FROM dbo.crew_schedule WHERE (pu_id = @thisPUId) AND (end_time <@spEndTime))

IF @MonitoredEvent IS NOT NULL --There is Shift change
BEGIN
	SET @MonitoredEvent=DATEADD(mi,convert(INT,ISNULL((SELECT TriggerValue FROM @tblListenerConf WHERE ECID=@ECID),0)),@MonitoredEvent )
	SET @LastEvent= (SELECT MAX(End_Time) FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType))
-----------------------------------------------------------------------------------------------------------------------
--Verify if there is already an event at end of shift time + trigger value 
-----------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT UDE_Id FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.End_Time = @MonitoredEvent) AND (ude.Event_Subtype_Id=@EventSubType)) AND (@MonitoredEvent <= @spEndTime) AND  ((SELECT Qualifier from @tblListenerConf WHERE ECID=@ECID ) IS NULL)
	BEGIN
		--Yes we can create an event.
		--Build event @spEndTime
		
		

		SET @strEventNum =  'CSO-' + CONVERT(VARCHAR(30),@MonitoredEvent,20)  + '-'  + convert (VARCHAR(5), @EventSubType)
		--Set @spEndTime=	@MonitoredEvent 
		------------------------------------------------------------------------------
		--UD Event Result Set 8
		------------------------------------------------------------------------------
		-- BEGIN
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
			SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@MonitoredEvent,120) 				,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@LastEvent,120),
				convert(varchar(30),dateadd(s,-60,@MonitoredEvent),120)) ,											
				@EventSubType										,
				1													,
				'Success'

	END
	ELSE
	BEGIN
	IF ((SELECT Qualifier from @tblListenerConf WHERE ECID=@ECID ) IS NOT NULL)
		BEGIN
		    
			IF (@MonitoredEvent > @LastEvent ) OR (@LastEvent IS NULL) --FO-04455
				BEGIN 
				
				INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN , UPTIMEMIN   ,SCHEDULEMin ,PreviousReason,ActualReason, StartTime)
				EXEC spLocal_GetUpDownMinutes  @MonitoredEvent,@thisPUId, @spEndTime


				IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='CalendarMinutes'
				BEGIN
			    
					--SET @spEndTime   =@spEndTime
					SET @CalendarMinutes = datediff(mi,@MonitoredEvent,@spEndTime)
					IF  @CalendarMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)
					BEGIN

						SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),@MonitoredEvent)
						SET @strEventNum =  'CSO-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)
					

						INSERT INTO @Output(
						Event_Id				,
						Event_Num				,
						PU_Id					,
						Time_Stamp				,
						Event_Status			,
						Transaction_Type		,
						User_Id					,
						Start_Time				,
						Event_Subtype			,
						ReturnStatus			,
						ReturnMessage)
					SELECT
						0													,
						@strEventNum										,	-- Event_Num
						@thisPUId											,	-- PU_Id
						convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
						0													,
						1													,	-- Transact
						@intUserId											,
						isnull (convert(varchar(30),@LastEvent,120),
						convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
						@EventSubType										,
						1													,
						'Success'

					END--DATEDIFF
				END--END CalendarMinutes
				ELSE
				BEGIN
					IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='DowntimeMinutes'
					BEGIN
					--SET @spEndTime   =@spEndTime

					IF (SELECT StartTime FROM @tblGetUpDownMinutes) IS NOT NULL
						SELECT @DowntimeMinutes = DATEDIFF(mi,(SELECT StartTime FROM @tblGetUpDownMinutes),@spEndTime)
					ELSE
				    	SELECT @DowntimeMinutes =0                 

					IF  @DowntimeMinutes > = (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=0)
					BEGIN
						
						SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),ISNULL((SELECT StartTime FROM @tblGetUpDownMinutes),@MonitoredEvent))
						SET @strEventNum =  'CSO-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					


						INSERT INTO @Output(
						Event_Id				,
						Event_Num				,
						PU_Id					,
						Time_Stamp				,
						Event_Status			,
						Transaction_Type		,
						User_Id					,
						Start_Time				,
						Event_Subtype			,
						ReturnStatus			,
						ReturnMessage	
						)
						SELECT
						0													,
						@strEventNum										,	-- Event_Num
						@thisPUId											,	-- PU_Id
						convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
						0													,
						1													,	-- Transact
						@intUserId											,
						isnull (convert(varchar(30),@LastEvent,120),
						convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
						@EventSubType										,
						1													,
						'Success'
										


					END--DATEDIFF
				END--END DowntimeMinutes
				ELSE
				BEGIN
				----------------------------------------------------------------------------
				IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID ) ='UptimeMinutes'
				BEGIN
					--SET @spEndTime   =@spEndTime
					SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
				                     
					IF  @UptimeMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID ) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
					BEGIN
						SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)+ISNULL((SELECT DOWNTIMEMIN FROM @tblGetUpDownMinutes),0)),@MonitoredEvent)
						SET @strEventNum =  'CSO-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')

						INSERT INTO @Output(
						Event_Id				,
						Event_Num				,
						PU_Id					,
						Time_Stamp				,
						Event_Status			,
						Transaction_Type		,
						User_Id					,
						Start_Time				,
						Event_Subtype			,
						ReturnStatus			,
						ReturnMessage	)
						SELECT
						0													,
						@strEventNum										,	-- Event_Num
						@thisPUId											,	-- PU_Id
						convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
						0													,
						1													,	-- Transact
						@intUserId											,
						isnull (convert(varchar(30),@LastEvent,120),
						convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
						@EventSubType										,
						1													,
						'Success'
					END--DATEDIFF
				----------------------------------------------------------------------------
				END--UPTIMEMinutes
				ELSE
				BEGIN
				----------------------------------------------------------------------------
				IF  (SELECT QUALIFIER from @tblListenerConf  WHERE ECID=@ECID) ='ScheduleMinutes'
				BEGIN
					--SET @spEndTime   =@spEndTime
					SELECT	@ScheduleMinutes= DATEDIFF(mi,@MonitoredEvent,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
					--SELECT @ScheduleMinutes = scheduleMin FROM 	@tblGetUpDownMinutes
			
					IF  @ScheduleMinutes >= (SELECT QualifierValue from @tblListenerConf  WHERE ECID=@ECID) 
					BEGIN
						SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0) + ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)),@MonitoredEvent)
						SET @strEventNum =  'CSO-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)

						INSERT INTO @Output(
						Event_Id				,
						Event_Num				,
						PU_Id					,
						Time_Stamp				,
						Event_Status			,
						Transaction_Type		,
						User_Id					,
						Start_Time				,
						Event_Subtype			,
						ReturnStatus			,
						ReturnMessage	)
						SELECT
						0													,
						@strEventNum										,	-- Event_Num
						@thisPUId											,	-- PU_Id
						convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
						0													,
						1													,	-- Transact
						@intUserId											,
						isnull (convert(varchar(30),@LastEvent,120),
						convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
						@EventSubType										,
						1													,
						'Success'


					END--DATEDIFF
				----------------------------------------------------------------------------
				END --SCHEDULE Time
				--ELSE
				--BEGIN

				-- INSERT INTO @Output( ReturnStatus,
				--					 ReturnMessage )
			
				--Values			 ( 0,
				--				  CONVERT(VARCHAR(10),@ecid) +'-CS:Invalid Qualifier')
					
				--END
				END -- OTHER QUALIFIER
			   END--WITH QUALIFIER
			
			END--CREATE EVENT

		END

	END
END
END--@MonitoredEvent IS NOT NULL 
ELSE
BEGIN

 			INSERT INTO @Output( ReturnStatus,
								ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-CSO:No Crew Schedule programmed')

END
END--Shift change once


----------------------------------------------------------------------------------------------------------------------
--  8. SIZE CHANGE EVENT
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='SizeChange'
BEGIN
	IF @Prod_Size <> @PreviousProd_Size
	BEGIN

	    SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
		SELECT @POStartTime=  Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)
		IF (@MonitoredEvent < @POStartTime) OR (@MonitoredEvent IS NULL)
		BEGIN
		   
		   IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) IS NULL
		     BEGIN
			        
					--Set @spEndTime=	@spEndTime
					SET @strEventNum =  'SC-' + CONVERT(VARCHAR(30),@POStartTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					
					------------------------------------------------------------------------------
					--UD Event Result Set 8
					------------------------------------------------------------------------------
					-- BEGIN

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@POStartTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@POStartTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


			--RETURN
		   END--WITHOUT QUALIFIER

		   ELSE
		   BEGIN
		 
			INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN ,UPTIMEMIN,SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
		    EXEC spLocal_GetUpDownMinutes  @POStartTime,@thisPUId, @spEndTime

			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='CalendarMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SET @CalendarMinutes = datediff(mi,@POStartTime,@spEndTime)
				IF  @CalendarMinutes > = (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)
				BEGIN

					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),@POStartTime)
					SET @strEventNum =  'SC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'
				END--DATEDIFF
			END--END CalendarMinutes
			ELSE
			BEGIN
				IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='DowntimeMinutes'
				BEGIN

			   -- SET @spEndTime   =@spEndTime
			   IF (SELECT StartTime FROM @tblGetUpDownMinutes) IS NOT NULL
					SELECT @DowntimeMinutes = datediff(mi, (SELECT StartTime FROM @tblGetUpDownMinutes),@spEndTime)
			   ELSE 
					SELECT @DowntimeMinutes = 0                 

				IF  @DowntimeMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID ) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=0)
				BEGIN

					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),ISNULL((SELECT StartTime FROM @tblGetUpDownMinutes),@POStartTime))
					SET @strEventNum =  'SC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)


					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

				END--DATEDIFF
			END--END DowntimeMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='UptimeMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
				                     
				IF  @UptimeMinutes > = (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID ) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
				BEGIN
				
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)+ISNULL((SELECT DOWNTIMEMIN FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'SC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType) --replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			----------------------------------------------------------------------------
			END--UPTIMEMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='ScheduleMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT	@ScheduleMinutes= DATEDIFF(mi,@POStartTime,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
				--SELECT @ScheduleMinutes = ScheduleMin FROM @tblGetUpDownMinutes
			              

				IF  @ScheduleMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0) + ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'SC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			----------------------------------------------------------------------------
			END --SCHEDULE Time
			ELSE
			BEGIN
			 INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-SC:Invalid Qualifier')
						
			END
			END -- OTHER QUALIFIER
		   END--WITH QUALIFIER
			
		END--CREATE EVENT

	END--END COMPARE SIZE
	    
		END --  @MonitoredEvent < @POStartTime
		ELSE
		BEGIN
		IF (@POStartTime IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-SC:No PO Runnning')

			END			
		END
END --  @Prod_Size <> @PreviousProd_Size

	
END --END SIZE CHANGE

----------------------------------------------------------------------------------------------------------------------
--  9.--Brand Change
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType FROM @tblListenerConf WHERE ecid=@ecid  ) ='BrandChange'
BEGIN
	IF @ProdId <> @PreviousProdId AND  @ProdId IS NOT NULL
	BEGIN
	    SELECT  @MonitoredEvent =	MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
		SELECT	@POStartTime	=	Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)
		IF (@MonitoredEvent < @POStartTime) OR (@MonitoredEvent IS NULL)
		BEGIN
		   IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) IS NULL
		   BEGIN

					--Set @spEndTime=	@spEndTime
					SET @strEventNum =  'BC-' + CONVERT(VARCHAR(30),@POStartTime,20)  + '-' + convert (nvarchar(5), @EventSubType)


					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@POStartTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@POStartTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

			--RETURN
		   END--WITHOUT QUALIFIER

		   ELSE
		   BEGIN
		   INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN ,UPTIMEMIN,SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
		   EXEC spLocal_GetUpDownMinutes  @POStartTime,@thisPUId, @spEndTime

			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID ) ='CalendarMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SET @CalendarMinutes = datediff(mi,@POStartTime,@spEndTime)
				IF  @CalendarMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)
				BEGIN
					
					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),@POStartTime)
					SET @strEventNum =  'BC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)


					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

				END--DATEDIFF
			END--END CalendarMinutes
			ELSE
			               
			BEGIN
				IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID ) ='DowntimeMinutes'
				BEGIN
			    --SET @spEndTime   =@spEndTime

				IF (SELECT StartTime FROM @tblGetUpDownMinutes) IS NOT NULL
					SELECT @DowntimeMinutes = datediff(mi, (SELECT StartTime FROM @tblGetUpDownMinutes),@spEndTime)
				ELSE
					SELECT @DowntimeMinutes = 0                     

				IF  @DowntimeMinutes > = (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=0)
				BEGIN

					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),ISNULL((SELECT StartTime FROM @tblGetUpDownMinutes),@POStartTime))
					SET @strEventNum =  'BC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			END--END DowntimeMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='UptimeMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
				                     
				IF  @UptimeMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
				BEGIN
				
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)+ISNULL((SELECT DOWNTIMEMIN FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'BC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)


					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			----------------------------------------------------------------------------
			END--UPTIMEMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='ScheduleMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT	@ScheduleMinutes= DATEDIFF(mi,@POStartTime,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
				--SELECT @ScheduleMinutes = ScheduleMin FROM @tblGetUpDownMinutes
				                     
									 
				IF  @ScheduleMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0) + ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'BC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			----------------------------------------------------------------------------
			END --SCHEDULE Time
			ELSE
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-BC:Invalid Qualifier')
						
			END
			END -- OTHER QUALIFIER
		   END--WITH QUALIFIER
			
		END--CREATE EVENT

	END--END COMPARE 
	    
	END --  @MonitoredEvent < @POStartTime
		ELSE
		BEGIN
		IF (@POStartTime IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-BC:No PO Runnning')

			END			
		END
END --  @PP_Id<> @PreviousPP_Id

END --END Process Order CHange

----------------------------------------------------------------------------------------------------------------------
--	10. Line State Cange
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType FROM @tblListenerConf WHERE ecid=@ecid  ) ='LineStateChange'
BEGIN
    SELECT @StopStart = Start_Time FROM dbo.Timed_event_details ted WITH(NOLOCK) WHERE ted.PU_Id = @thisPUId AND (ted.End_Time IS NULL)
	SELECT @MonitoredEvent =ISNULL((SELECT MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)),@StopStart)

    INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG,DOWNTIMEMIN ,UPTIMEMIN ,SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
    EXEC spLocal_GetUpDownMinutes  @StopStart,@thisPUId, @spEndTime


	IF ((SELECT PreviousReason FROM @tblGetUpDownMinutes) NOT LIKE (SELECT TriggerValue from @tblListenerConf WHERE ECID=@ECID))  AND ((SELECT ActualReason FROM @tblGetUpDownMinutes) = (SELECT TriggerValue from @tblListenerConf WHERE ECID=@ECID)) 
	BEGIN
	    

		IF (@MonitoredEvent < = @StopStart) 
		BEGIN
		   IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) IS NULL
		   BEGIN
		      			    --Yes we can create an event.
					--Build event Num
					--Set @spEndTime=	@spEndTime
					SET @strEventNum =  'LSC-' + CONVERT(VARCHAR(30),@StopStart,20)  + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					
					------------------------------------------------------------------------------
					--UD Event Result Set 8
					------------------------------------------------------------------------------
					-- BEGIN

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@StopStart,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@StopStart),120)) ,											
					@EventSubType										,
					1													,
					'Success'
			--RETURN
		   END--WITHOUT QUALIFIER
		   ELSE
		   BEGIN
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='CalendarMinutes'
			BEGIN
			   -- SET @spEndTime   =@spEndTime
				SET @CalendarMinutes = datediff(mi,@StopStart,@spEndTime)
				IF  @CalendarMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)
				BEGIN

					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),@StopStart)
					SET @strEventNum =  'LSC-' + CONVERT(VARCHAR(30),@spEndTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)
					
					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			END--END CalendarMinutes
			ELSE
			BEGIN
				IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID ) ='DowntimeMinutes'
				BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT @DowntimeMinutes = DOWNTIMEMIN FROM @tblGetUpDownMinutes
				                     

				IF  @DowntimeMinutes > = (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=0)
				BEGIN
				
				    SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),@StopStart)
					SET @strEventNum =  'LSC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20)  + '-'  + convert (VARCHAR(5), @EventSubType)


					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

				END--DATEDIFF
			END--END DowntimeMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='ScheduleMinutes'
			BEGIN
			   -- SET @spEndTime   =@spEndTime
			   
				SELECT	@ScheduleMinutes= DATEDIFF(mi,@StopStart,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
				--SELECT @ScheduleMinutes = ScheduleMin FROM @tblGetUpDownMinutes


				IF  @ScheduleMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
				
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0) + ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)),@StopStart)
					SET @strEventNum =  'LSC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)


					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

				END--DATEDIFF
			----------------------------------------------------------------------------
			END --SCHEDULE Time
			ELSE
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-LSC:Invalid Qualifier')
						
			END
			END -- OTHER QUALIFIER
		   END--WITH QUALIFIER
			
		END--CREATE EVENT

	        --END--END COMPARE 
	    
		END --  @MonitoredEvent < @StopStart
		
    END --  (SELECT PreviousReason FROM @tblGetUpDownMinutes) ='PlannedDowntime' AND (SELECT ActualReason FROM @tblGetUpDownMinutes) ='idle' AND (SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes )= 0

END --END line State change

----------------------------------------------------------------------------------------------------------------------
--  11. Process Order
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType FROM @tblListenerConf WHERE ecid=@ecid ) ='ProcessOrder'
BEGIN
	IF @PPID <> @Previous_PPID
	BEGIN
	    SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
		SELECT  @POStartTime=  Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)
		IF (@MonitoredEvent < @POStartTime) OR (@MonitoredEvent IS NULL)
		BEGIN
		   
		   IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) IS NULL
		   BEGIN
		      			    --Yes we can create an event.
					--Build event Num
					--Set @spEndTime=	@spEndTime
					SET @strEventNum =  'PO-' + CONVERT(VARCHAR(30),@POStartTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					
					------------------------------------------------------------------------------
					--UD Event Result Set 8
					------------------------------------------------------------------------------
					-- BEGIN
	
					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@POStartTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@POStartTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

			--RETURN
		   END--WITHOUT QUALIFIER
		   ELSE
		   BEGIN
		   INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG,DOWNTIMEMIN ,UPTIMEMIN,SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
		    EXEC spLocal_GetUpDownMinutes  @POStartTime,@thisPUId, @spEndTime

			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='CalendarMinutes'
			BEGIN
			   -- SET @spEndTime   =@spEndTime
				SET @CalendarMinutes = datediff(mi,@POStartTime,@spEndTime)
				IF  @CalendarMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),@POStartTime)
					SET @strEventNum =  'PO-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
					
					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

				END--DATEDIFF
			END--END CalendarMinutes
			ELSE
			BEGIN
				IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID ) ='DowntimeMinutes'
				BEGIN

			    --SET @spEndTime   =@spEndTime
				IF (SELECT StartTime FROM @tblGetUpDownMinutes) IS NOT NULL
					SELECT @DowntimeMinutes = ISNULL(datediff(mi, (SELECT StartTime FROM @tblGetUpDownMinutes),@spEndTime),0)
				ELSE
					SELECT @DowntimeMinutes = 0


				IF  @DowntimeMinutes > = (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=0)
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),ISNULL((SELECT StartTime FROM @tblGetUpDownMinutes),@POStartTime))
					SET @strEventNum =  'PO-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			END--END DowntimeMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='UptimeMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
				                     
				IF  @UptimeMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)+ISNULL((SELECT DOWNTIMEMIN FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'PO-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

				END--DATEDIFF
			----------------------------------------------------------------------------
			END--UPTIMEMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='ScheduleMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				
				SELECT	@ScheduleMinutes= DATEDIFF(mi,@POStartTime,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
--				SELECT @ScheduleMinutes = ScheduleMin FROM @tblGetUpDownMinutes
				                     

				IF  @ScheduleMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0) + ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'PO-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					
					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120)	,
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'



				END--DATEDIFF
			----------------------------------------------------------------------------
			END --SCHEDULE Time
			ELSE
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-PO:Invalid Qualifier')

						
			END
			END -- OTHER QUALIFIER
		   END--WITH QUALIFIER
			
		END--CREATE EVENT

	END--END COMPARE BRAND
	    
		END --  @MonitoredEvent < @POStartTime
		ELSE
			BEGIN
			IF (@POStartTime IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-PO:No PO is running')

						
			END
			END
END --  @Prod_Id<> @PreviousProd_Id
END --END Process Order
----------------------------------------------------------------------------------------------------------------------
--  12. BATCH ID EVENT
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType FROM @tblListenerConf WHERE ecid=@ecid ) ='BatchIDChange'
BEGIN

	IF ISNULL(@BN,'') <> ISNULL(@PreviousBN,'')
	BEGIN

	    SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
		SELECT  @POStartTime=  Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)

		IF (@MonitoredEvent < @POStartTime) OR (@MonitoredEvent IS NULL)
		BEGIN
		  
		   IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) IS NULL
		   BEGIN
		      			    --Yes we can create an event.
					--Build event Num
					--Set @spEndTime=	@spEndTime
					SET @strEventNum =  'BN-' + CONVERT(VARCHAR(30),@POStartTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					
					------------------------------------------------------------------------------
					--UD Event Result Set 8
					------------------------------------------------------------------------------
					-- BEGIN

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@POStartTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@POStartTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

		   END--WITHOUT QUALIFIER
		   ELSE
		   BEGIN
		   INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG,DOWNTIMEMIN ,UPTIMEMIN, SCHEDULEMin ,PreviousReason,ActualReason, StartTime)
		   EXEC spLocal_GetUpDownMinutes  @POStartTime,@thisPUId, @spEndTime

			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='CalendarMinutes'
			BEGIN
			    --SET @spEndTime = @spEndTime
				SET @CalendarMinutes = datediff(mi,@POStartTime,@spEndTime)
				IF  @CalendarMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),@POStartTime)
					SET @strEventNum =  'BN-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			END--END CalendarMinutes
			ELSE
			BEGIN
				IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='DowntimeMinutes'
				BEGIN
			   -- SET @spEndTime   =@spEndTime

				IF (SELECT StartTime FROM @tblGetUpDownMinutes) IS NOT NULL
					SELECT @DowntimeMinutes = DATEDIFF(mi, (SELECT StartTime FROM @tblGetUpDownMinutes),@spEndTime)
				ELSE  
				     SELECT @DowntimeMinutes =	0
					               
				IF  (@DowntimeMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=0)
				BEGIN
					--Set @spEndTime=	GETDATE()
					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),ISNULL((SELECT StartTime FROM @tblGetUpDownMinutes),@POStartTime))
					SET @strEventNum =  'BN-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
					
					------------------------------------------------------------------------------
					--UD Event Result Set 8
					------------------------------------------------------------------------------
					-- BEGIN

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

				END--DATEDIFF
			END--END DowntimeMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='UptimeMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
				                     
				IF  (@UptimeMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)+ISNULL((SELECT DOWNTIMEMIN FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'BN-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
					
					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			----------------------------------------------------------------------------
			END--UPTIMEMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='ScheduleMinutes' 
			BEGIN
			   -- SET @spEndTime   = @spEndTime
			   
			    SELECT	@ScheduleMinutes= DATEDIFF(mi,@POStartTime,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
				--SELECT @ScheduleMinutes = ScheduleMin FROM @tblGetUpDownMinutes

				IF  (@ScheduleMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID))  
				BEGIN
				    SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0) + ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'BN-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
					
					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			----------------------------------------------------------------------------
				END --SCHEDULE Time
			ELSE
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-BN:Invalid Qualifier')
						
			END
			END -- OTHER QUALIFIER
		   END--WITH QUALIFIER
			
		END--CREATE EVENT

	END--END COMPARE BATC ID NUMBER
	    
END --  @MonitoredEvent < @POStartTime
		ELSE
		BEGIN
			IF   (@POStartTime IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-BN:No PO running')
				
			END
		END
END --  @BN<> @PreviousBN
	
END --END BATCH ID CHANGE

---------------------------------------------------------------------------------------------------------------------
-- 13. Per. Production Complete
---------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='%ProductionComplete'
BEGIN

	SELECT @POStartTime=  Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)
	SELECT @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)

	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@MonitoredEvent

	SELECT @Production=  PercQuantity FROM @tblGetQuantity

	IF ((@MonitoredEvent < = @POStartTime) OR (@MonitoredEvent IS NULL)) AND (@POStartTime IS NOT NULL) AND   @Production >= (SELECT TriggerValue FROM @tblListenerConf WHERE ECID=@ECID) 
	   BEGIN
		--SET @spEndTime=@spEndTime
		SET @strEventNum =  '%PC-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					
					------------------------------------------------------------------------------
					--UD Event Result Set 8
					------------------------------------------------------------------------------
					-- BEGIN


					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


   END 
   		ELSE
		BEGIN
			IF (@POStartTime IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'-PC: NO PO Running')
							
			END
		END
END--(SELECT TriggerType from @tblListenerConf ) ='%ProductionComplete'

---------------------------------------------------------------------------------------------------------------------
-- 14.	Units Produced
---------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType FROM @tblListenerConf WHERE ecid=@ecid ) ='UnitsProduced'
BEGIN

   	SELECT @POStartTime=  Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)
    SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)

	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@MonitoredEvent

	SELECT @Production=  ActualQuantity  FROM @tblGetQuantity

	
	IF ((@MonitoredEvent < = @POStartTime) OR (@MonitoredEvent IS NULL)) AND (@POStartTime IS NOT NULL) AND   (@Production >= (SELECT TriggerValue FROM @tblListenerConf WHERE ECID=@ECID))
	BEGIN
		--SET @spEndTime=@spEndTime
		SET @strEventNum =  'UP-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					
					------------------------------------------------------------------------------
					--UD Event Result Set 8
					------------------------------------------------------------------------------
					-- BEGIN

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'
   END 
   ELSE
	BEGIN
		IF (@POStartTime IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'-UP: NO PO Running')
						
			END
   END
END--(SELECT TriggerType from @tblListenerConf ) ='%ProductionComplete'

---------------------------------------------------------------------------------------------------------------------
-- 15. Units Remaining
---------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid ) ='UnitsRemaining'
BEGIN
    SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
	SELECT  @POStartTime=  Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)


	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@MonitoredEvent


   SELECT @Production= RemainingQuantity  FROM @tblGetQuantity



	IF ((@MonitoredEvent < = @POStartTime) OR (@MonitoredEvent IS NULL)) AND (@POStartTime IS NOT NULL) AND   (@Production >= (SELECT TriggerValue FROM @tblListenerConf WHERE ECID=@ECID))
   BEGIN
		--SET @spEndTime=@spEndTime
		SET @strEventNum =  'UR-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					
					------------------------------------------------------------------------------
					--UD Event Result Set 8
					------------------------------------------------------------------------------
					-- BEGIN

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'
   END 
   ELSE
	BEGIN
		IF (@POStartTime IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'-UR: NO PO Running')

				
			END
   END
END--(SELECT TriggerType from @tblListenerConf ) ='%ProductionComplete'

----------------------------------------------------------------------------------------------------------------------
--  16. EventByUptime
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid ) ='EventByUptime'
	BEGIN

	SELECT  @MonitoredEvent  = 	CASE  ParentEvent 
								WHEN  'ProcessOrder' THEN  (SELECT Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL))
								WHEN  'Production Event'  THEN  (SELECT MAX(TimeStamp) FROM dbo.Events e WITH(NOLOCK) WHERE (e.pu_id = @thisPUId))
								ELSE (SELECT MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@ParentSubType) )  
								-- ELSE  NULL
								END

    FROM @tblListenerConf  
	WHERE ECID=@ECID


	SELECT @lastEvent=MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)

	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@MonitoredEvent

	INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN , UPTIMEMIN   ,SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
	EXEC spLocal_GetUpDownMinutes  @MonitoredEvent,@thisPUId, @spEndTime

	IF  (@MonitoredEvent IS NOT NULL) AND ((@LastEvent < @MonitoredEvent) OR  (@LastEvent IS NULL))

	 BEGIN 
	  --SET @spEndTime   =@spEndTime

	  SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
	  IF  @UptimeMinutes > = (SELECT TriggerValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
	  BEGIN
		IF  (SELECT QUALIFIER FROM @tblListenerConf  WHERE ECID=@ECID) ='Min Quantity'
		 BEGIN
		    IF (SELECT QuantityVar FROM @tblListenerConf  WHERE ECID=@ECID) IS NOT NULL
			 BEGIN
			     
				-- SET @spEndTime   =@spEndTime
			   	     
				IF (SELECT MinQuantity FROM  @tblGetQuantity) >= (SELECT QualifierValue FROM @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
				 SET @strEventNum =  'EBU-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
			
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTime,120)					,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'

				END --@MinQuantity >= (SELECT QualifierValue FROM @tblListenerConf) 
			 END--QuantityVar
			 ELSE
			 BEGIN
				INSERT INTO @Output( ReturnStatus,
									ReturnMessage )
			
				VALUES				( 0,
									CONVERT(VARCHAR(10),@ecid) + '-EBU:Quantity Var is NULL')
			END
		 END--Min Quantity'
		 ELSE
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'-EBU:Invalid Qualifier')

					
			END
	  END-- @CalendarMinutes > = (SELECT QualifierValue from @tblListenerConf )
	END --@MonitoredEvent not null and not event created yet
	ELSE
	BEGIN
		IF (@MonitoredEvent IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'EBU: No event Parent present')
						
			END
   END
	
END -- ='EventByCalendar
----------------------------------------------------------------------------------------------------------------------
--  17. Event by Schedule Time
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='EventByScheduleTime'
	BEGIN
	
	SELECT  @MonitoredEvent  = 	CASE  ParentEvent 
								WHEN  'ProcessOrder' THEN  (SELECT Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL))
								WHEN  'Production Event'  THEN  (SELECT MAX(TimeStamp) FROM dbo.Events e WITH(NOLOCK) WHERE (e.pu_id = @thisPUId))
								ELSE  (SELECT MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@ParentSubType) )  
								--ELSE   NULL
								END

    FROM @tblListenerConf  
	WHERE ECID=@ECID

	SELECT @lastEvent=MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)

	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@MonitoredEvent
	
	INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN , UPTIMEMIN   ,SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
	EXEC spLocal_GetUpDownMinutes  @MonitoredEvent,@thisPUId, @spEndTime


	IF  (@MonitoredEvent IS NOT NULL)  AND ((@LastEvent <= @MonitoredEvent) OR  (@LastEvent IS NULL))
	 BEGIN 
	 -- SET @spEndTime   =@spEndTime
	  SELECT	@ScheduleMinutes= DATEDIFF(mi,@MonitoredEvent,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
	   -- SELECT @ScheduleMinutes = ScheduleMIN FROM @tblGetUpDownMinutes


	  IF  @ScheduleMinutes > = (SELECT TriggerValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
	  BEGIN
		IF  (SELECT QUALIFIER FROM @tblListenerConf  WHERE ECID=@ECID) ='Min Quantity'
		 BEGIN
		    IF (SELECT QuantityVar FROM @tblListenerConf  WHERE ECID=@ECID) IS NOT NULL
			 BEGIN
			     
				-- SET @spEndTime   =@spEndTime
			   	     
				IF (SELECT MinQuantity FROM  @tblGetQuantity) >= (SELECT QualifierValue FROM @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
				 SET @strEventNum =  'EBS-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)

				------------------------------------------------------------------------------
				--UD Event Result Set 8
				------------------------------------------------------------------------------
				-- BEGIN
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTime,120)					,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'
				END --@MinQuantity >= (SELECT QualifierValue FROM @tblListenerConf) 
			 END--QuantityVar
			 ELSE
			 BEGIN
					INSERT INTO @Output( ReturnStatus,
										ReturnMessage )
			
					VALUES				( 0,
										CONVERT(VARCHAR(10),@ecid) + '-EBS:Quantity Var is NULL')
			 END
		 END--Min Quantity'
		 ELSE
		 BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'-EBS:Invalid Qualifier')

					
		 END
	  END-- @CalendarMinutes > = (SELECT QualifierValue from @tblListenerConf )
	END --@MonitoredEvent not null
	ELSE
	BEGIN
		IF (@MonitoredEvent IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'EBS: No event Parent present')
						
			END
   END
END -- ='EventByCalendar

----------------------------------------------------------------------------------------------------------------------
--  18. Event By Calendar Time
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='EventByCalendarTime'
	BEGIN
	SELECT  @MonitoredEvent  = 	CASE  ParentEvent 
								WHEN  'ProcessOrder' THEN  (SELECT Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL))
								WHEN  'Production Event'  THEN  (SELECT MAX(TimeStamp) FROM dbo.Events e WITH(NOLOCK) WHERE (e.pu_id = @thisPUId))  
								WHEN  'Downtime'  THEN (SELECT Start_Time FROM dbo.Timed_Event_Details e WITH(NOLOCK) WHERE (e.pu_id = @thisPUId) and (End_Time IS NULL))
								ELSE (SELECT MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@ParentSubType) )
								--ELSE   NULL 
								END
    FROM @tblListenerConf  
	WHERE ECID=@ECID
	
	SELECT @lastEvent = MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)

	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@MonitoredEvent

	--SELECT @LastEvent, @MonitoredEvent

	IF  (@MonitoredEvent IS NOT NULL) AND ((@LastEvent < @MonitoredEvent) OR  (@LastEvent IS NULL))
	BEGIN 
	  --SET @spEndTime   = @spEndTime
	  SET @CalendarMinutes = datediff(mi,@MonitoredEvent,@spEndTime)
	
	  IF  @CalendarMinutes > = (SELECT TriggerValue from @tblListenerConf WHERE ECID=@ECID)
	  BEGIN
		IF  (SELECT QUALIFIER FROM @tblListenerConf WHERE ECID=@ECID) ='Min Quantity'
		 BEGIN
		    IF (SELECT QuantityVar FROM @tblListenerConf WHERE ECID=@ECID) IS NOT NULL AND ((@LastEvent < @MonitoredEvent) OR  (@LastEvent IS NULL))
			 BEGIN
			 
				 --SET @spEndTime   =@spEndTime		
   	     
				IF (SELECT MinQuantity FROM  @tblGetQuantity) >= (SELECT QualifierValue FROM @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
				 SET @strEventNum =  'EBC-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
			
				------------------------------------------------------------------------------
				--UD Event Result Set 8
				------------------------------------------------------------------------------
				-- BEGIN
					
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTime,120)					,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'
				END --@MinQuantity >= (SELECT QualifierValue FROM @tblListenerConf) 
			 END--QuantityVar
			 ELSE
			 BEGIN
			 IF (SELECT QuantityVar FROM @tblListenerConf WHERE ECID=@ECID) IS NULL
				 BEGIN
					INSERT INTO @Output( ReturnStatus,
										ReturnMessage )
			
					 VALUES				( 0,
										CONVERT(VARCHAR(10),@ecid) + '-EBC:Quantity Var is NULL')
				 END
			 END
		 END--Min Quantity'
		 ELSE
		 BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'-EBC:Invalid Qualifier')
					
		 END
	  END-- @CalendarMinutes > = (SELECT QualifierValue from @tblListenerConf )
	END --@MonitoredEvent not null
	ELSE
	BEGIN
		IF (@MonitoredEvent IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			VALUES			 ( 0,
							 CONVERT(VARCHAR(10),@ecid) +'EBC: No event Parent present')
					
			END
   END
END -- ='TimeByCalendar


----------------------------------------------------------------------------------------------------------------------
--  19. MULTI WEEK
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='Weekly'
BEGIN


	  SELECT @input = TriggerValue from @tblListenerConf WHERE ECId=@ecid
	  
      IF(@input is not null)
      BEGIN
            SET @ind = CharIndex(',',@input)
            WHILE @ind > 0
            BEGIN
                  SET @str = SUBSTRING(@input,1,@ind-1)
                  SET @input = SUBSTRING(@input,@ind+1,LEN(@input)-@ind)
                  INSERT INTO @Result values (@str)
                  SET @ind = CharIndex(',',@input)
            END
            SET @str = @input
            INSERT INTO @Result values (@str)
      END
	SELECT @1st_day_ofweek = (CASE value
									 WHEN 2	THEN  2+1
									 WHEN 3	THEN  3+1
									 WHEN 4	THEN  4+1
									 WHEN 5	THEN  5+1
									 WHEN 6	THEN  6+1
									 WHEN 7	THEN  1
									 WHEN 1	THEN  1+1
							END)

	FROM  dbo.Site_Parameters WITH(NOLOCK)
	WHERE Parm_Id =(SELECT Parm_Id 
					FROM dbo.Parameters WITH(NOLOCK)
					WHERE Parm_Name ='EndOfWeekDay')

	SET DATEFIRST @1st_day_ofweek  
	SELECT @day = DATEPART(dw, @spEndTime)  
	-- FO-03535
	SELECT @year= datepart(yy,@spEndTime)
	SELECT @month= datepart(mm, @spEndTime)	

      
	SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
	IF  @MonitoredEvent IS NULL
	BEGIN
	   IF   @day IN  (SELECT VALUE FROM @Result) AND (CONVERT(NVARCHAR(5), @spEndTime, 108)  >=  (SELECT QualifierValue from @tblListenerConf WHERE ECId=@ecid  )) AND (CONVERT(NVARCHAR(5), @Last5Minutes, 108)  <  (SELECT QualifierValue from @tblListenerConf WHERE ECId=@ecid  ))
	   BEGIN
	    --Set @spEndTime=	@spEndTime
		IF NOT EXISTS(SELECT UDE_Id FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.End_Time = @spEndTime) AND (ude.Event_Subtype_Id=@EventSubType))
	
			SELECT @spEndTimeOnTime=  CONVERT(DATETIME,(CONVERT(NVARCHAR(4),@year)+ '-' + CONVERT(NVARCHAR(2),@month)+ '-' + CONVERT(NVARCHAR(2),DATEPART(dd, @spEndTime)) + ' ' + (SELECT QualifierValue from @tblListenerConf WHERE ecid=@ecid )))
			
			SET @strEventNum =  'MW-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
			

				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'

		--END
	   END
	   END
	ELSE
	   BEGIN
	    IF    @day IN  (SELECT VALUE FROM @Result)  AND (CONVERT(NVARCHAR(5), @spEndTime, 108)  >=  (SELECT QualifierValue from @tblListenerConf WHERE ECId=@ecid  )) AND (CONVERT(NVARCHAR(5), @Last5Minutes, 108)  <  (SELECT QualifierValue from @tblListenerConf WHERE ECId=@ecid  ))
			BEGIN
			--SET @spEndTime=	@spEndTime 
			IF NOT EXISTS(SELECT UDE_Id FROM dbo.User_Defined_Events ude WHERE (ude.pu_id = @thisPUId) AND (ude.End_Time = @spEndTime) AND (ude.Event_Subtype_Id=@EventSubType))
			  BEGIN
				
				SELECT @spEndTimeOnTime=  CONVERT(DATETIME,(CONVERT(NVARCHAR(4),@year)+ '-' + CONVERT(NVARCHAR(2),@month)+ '-' + CONVERT(NVARCHAR(2),DATEPART(dd, @spEndTime)) + ' ' + (SELECT QualifierValue from @tblListenerConf WHERE ecid=@ecid )))
			
				SET @strEventNum =  'MW-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
			

				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage	)
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@MonitoredEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,													 
				@EventSubType										,
				1													,
				'Success'
		   END
	END

END

END-- END MultiWeek


----------------------------------------------------------------------------------------------------------------------
--  20. FORMULA CHANGE EVENT
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid  ) ='FormulaGroupChange'
BEGIN
	IF @Prod_Formula <> @PreviousProd_Formula
	BEGIN

	    SELECT  @MonitoredEvent =MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
		SELECT @POStartTime=  Start_Time FROM dbo.Production_Plan_Starts pps WITH(NOLOCK) WHERE pps.PU_Id = @thisPUId AND (pps.End_Time IS NULL)
		IF (@MonitoredEvent < @POStartTime) OR (@MonitoredEvent IS NULL)
		BEGIN
		   
		   IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) IS NULL
		     BEGIN
			        
					--Set @spEndTime=	@spEndTime
					SET @strEventNum =  'FC-' + CONVERT(VARCHAR(30),@POStartTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')
					
					------------------------------------------------------------------------------
					--UD Event Result Set 8
					------------------------------------------------------------------------------
					-- BEGIN

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@POStartTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@POStartTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


			--RETURN
		   END--WITHOUT QUALIFIER

		   ELSE
		   BEGIN
		 
			INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN ,UPTIMEMIN,SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
		    EXEC spLocal_GetUpDownMinutes  @POStartTime,@thisPUId, @spEndTime

			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='CalendarMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SET @CalendarMinutes = datediff(mi,@POStartTime,@spEndTime)
				IF  @CalendarMinutes > = (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID)
				BEGIN

					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),@POStartTime)
					SET @strEventNum =  'FC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'
				END--DATEDIFF
			END--END CalendarMinutes
			ELSE
			BEGIN
				IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='DowntimeMinutes'
				BEGIN

			   -- SET @spEndTime   =@spEndTime
			   IF (SELECT StartTime FROM @tblGetUpDownMinutes) IS NOT NULL
					SELECT @DowntimeMinutes = datediff(mi, (SELECT StartTime FROM @tblGetUpDownMinutes),@spEndTime)
			   ELSE 
					SELECT @DowntimeMinutes = 0                 

				IF  @DowntimeMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID ) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=0)
				BEGIN

					SET @spEndTimeOnTime	= DATEADD(mi,CONVERT(INT,ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)),ISNULL((SELECT StartTime FROM @tblGetUpDownMinutes),@POStartTime))
					SET @strEventNum =  'FC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)


					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'

				END--DATEDIFF
			END--END DowntimeMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='UptimeMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
				                     
				IF  @UptimeMinutes > = (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID ) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)
				BEGIN
				
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0)+ISNULL((SELECT DOWNTIMEMIN FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'FC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)--replace(convert(varchar(30),@dteLastShiftTime,20) + convert(varchar(6),@thisPUId),' ','')

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			----------------------------------------------------------------------------
			END--UPTIMEMinutes
			ELSE
			BEGIN
			----------------------------------------------------------------------------
			IF  (SELECT QUALIFIER from @tblListenerConf WHERE ECID=@ECID) ='ScheduleMinutes'
			BEGIN
			    --SET @spEndTime   =@spEndTime
				SELECT	@ScheduleMinutes= DATEDIFF(mi,@POStartTime,@spEndTime) - ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)
				--SELECT @ScheduleMinutes = ScheduleMin FROM @tblGetUpDownMinutes
			              

				IF  @ScheduleMinutes >= (SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID) 
				BEGIN
					SET @spEndTimeOnTime	= DATEADD(mi,(ISNULL((SELECT QualifierValue from @tblListenerConf WHERE ECID=@ECID),0) + ISNULL((SELECT scheduleMin FROM @tblGetUpDownMinutes),0)),@POStartTime)
					SET @strEventNum =  'FC-' + CONVERT(VARCHAR(30),@spEndTimeOnTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)

					INSERT INTO @Output(
					Event_Id				,
					Event_Num				,
					PU_Id					,
					Time_Stamp				,
					Event_Status			,
					Transaction_Type		,
					User_Id					,
					Start_Time				,
					Event_Subtype			,
					ReturnStatus			,
					ReturnMessage	)
					SELECT
					0													,
					@strEventNum										,	-- Event_Num
					@thisPUId											,	-- PU_Id
					convert(varchar(30),@spEndTimeOnTime,120) 				,	-- TimeStamp
					0													,
					1													,	-- Transact
					@intUserId											,
					isnull (convert(varchar(30),@MonitoredEvent,120),
					convert(varchar(30),dateadd(s,-60,@spEndTimeOnTime),120)) ,											
					@EventSubType										,
					1													,
					'Success'


				END--DATEDIFF
			----------------------------------------------------------------------------
			END --SCHEDULE Time
			ELSE
			BEGIN
			 INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-FC:Invalid Qualifier')
						
			END
			END -- OTHER QUALIFIER
		   END--WITH QUALIFIER
			
		END--CREATE EVENT

	END--END COMPARE SIZE
	    
		END --  @MonitoredEvent < @POStartTime
		ELSE
		BEGIN
		IF (@POStartTime IS NULL)
			BEGIN
			INSERT INTO @Output( ReturnStatus,
								 ReturnMessage )
			
			Values			 ( 0,
							  CONVERT(VARCHAR(10),@ecid) +'-FC:No PO Runnning')

			END			
		END
END --  @Prod_Formula <> @PreviousProd_Formula

	
END --END FORMULA CHANGE


----------------------------------------------------------------------------------------------------------------------
--  21. Time By Uptime Only
----------------------------------------------------------------------------------------------------------------------
IF  (SELECT TriggerType from @tblListenerConf WHERE ecid=@ecid ) ='TimeByUptimeOnly'
	BEGIN

	SELECT @LastEvent=MAX(End_Time) FROM dbo.User_Defined_Events ude WITH(NOLOCK) WHERE (ude.pu_id = @thisPUId) AND (ude.Event_Subtype_Id=@EventSubType)
	SET @MonitoredEvent = ISNULL(@LastEvent,@spEndTime)

	INSERT INTO @tblGetQuantity (MinQuantity, PercQuantity ,ActualQuantity, RemainingQuantity )
	EXEC dbo.spLocal_GetQuantity  @VarQuantity, @thisPUId ,@spEndTime ,@MonitoredEvent

	INSERT INTO  @tblGetUpDownMinutes (UPDOWNFLAG, DOWNTIMEMIN , UPTIMEMIN, SCHEDULEMin ,PreviousReason,ActualReason,StartTime)
	EXEC spLocal_GetUpDownMinutes  @MonitoredEvent,@thisPUId, @spEndTime

	IF  (@MonitoredEvent IS NOT NULL)
	 BEGIN 
	  --SET @spEndTime   =@spEndTime

	  SELECT @UptimeMinutes = UPTIMEMIN FROM @tblGetUpDownMinutes
	  IF (@UptimeMinutes > = (SELECT TriggerValue from @tblListenerConf WHERE ECID=@ECID) AND ((SELECT UPDOWNFLAG FROM @tblGetUpDownMinutes)=1)) OR (@LastEvent IS NULL)
	  BEGIN
		IF  (SELECT QUALIFIER FROM @tblListenerConf WHERE ECID=@ECID) ='Min Quantity'
		 BEGIN
		    IF (SELECT QuantityVar FROM @tblListenerConf WHERE ECID=@ECID) IS NOT NULL
			 BEGIN
			     
				-- SET @spEndTime   =@spEndTime
			   	     
				IF (SELECT MinQuantity FROM  @tblGetQuantity) >= (SELECT QualifierValue FROM @tblListenerConf WHERE ECID=@ECID)  OR (@LastEvent IS NULL)
				BEGIN
				 SET @strEventNum =  'TBUO-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
			
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage)	
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTime,120)					,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@LastEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'

				END --@MinQuantity >= (SELECT QualifierValue FROM @tblListenerConf) 
			 END--QuantityVar
			 ELSE
				BEGIN
					INSERT INTO @Output( ReturnStatus,
										ReturnMessage )
			
					VALUES				( 0,
										CONVERT(VARCHAR(10),@ecid) + '-TBU:Quantity Var is NULL')
				
				END

		 END--Min Quantity'
		 ELSE
		 BEGIN
				SET @strEventNum =  'TBUO-' + CONVERT(VARCHAR(30),@spEndTime,20) + '-'  + convert (VARCHAR(5), @EventSubType)
			
				INSERT INTO @Output(
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage)	
				SELECT
				0													,
				@strEventNum										,	-- Event_Num
				@thisPUId											,	-- PU_Id
				convert(varchar(30),@spEndTime,120)					,	-- TimeStamp
				0													,
				1													,	-- Transact
				@intUserId											,
				isnull (convert(varchar(30),@LastEvent,120),
				convert(varchar(30),dateadd(s,-60,@spEndTime),120)) ,													
				@EventSubType										,
				1													,
				'Success'
				
		END
	  END-- @UptimeMinutes > = (SELECT QualifierValue from @tblListenerConf )
	END --@LastEvent not null and not event created yet
	
END -- ='TimeByUptimeOnly




	DELETE 
	FROM @tblGetQuantity

	DELETE
	FROM @tblGetUpDownMinutes


SET @CountMin= @CountMin+1
END

--------------------------------------------------------------------------------------------------------------
--Output sent to Listener
--------------------------------------------------------------------------------------------------------------

				SELECT
				Event_Id				,
				Event_Num				,
				PU_Id					,
				Time_Stamp				,
				Event_Status			,
				Transaction_Type		,
				User_Id					,
				Start_Time				,
				Event_Subtype			,
				ReturnStatus			,
				ReturnMessage
				FROM @OUTPUT

--END



--SET @ReturnStatus=1

------------------------------------------------------------------------------------------------------------------------
SET NOCOUNT OFF

