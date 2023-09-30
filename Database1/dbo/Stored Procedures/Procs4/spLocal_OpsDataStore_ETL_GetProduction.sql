


-------------------------------------------------------------------------------------------------------------
-- 										OPS Database Stored Procedure									   --	
--						This stored procedure will feed the OpsDB_Production_Data table						   --
-------------------------------------------------------------------------------------------------------------
-- 										SET TAB SPACING TO 4											   --	
-------------------------------------------------------------------------------------------------------------
-- 2016-10-20		Mrakovich E.			Initial Development											   --
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_OpsDataStore_ETL_GetProduction]
--declare
@Table_MaxStartTime4Lines dbo.TT_OpsDB_ProdLastTransf_by_Line READONLY
--insert into @Table_MaxStartTime4Lines SELECT Max(StartTime) as StartTime,LineDesc FROM OpsDataStore.dbo.OpsDB_Production_Data WITH(NOLOCK) WHERE Endtime < DATEADD(hh,-120,GETDATE()) Group by Linedesc
--WITH ENCRYPTION 
AS

------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
SET ANSI_WARNINGS OFF
------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------
-- Variables Table Declaration 
------------------------------------------------------------------------------------------------------------------
DECLARE @Products TABLE  (
				PUID					int,  
				ProdID					int,  
				ProdDesc				nvarchar(100), 
				ProdCode				nvarchar(100),  
				ProdFam					nvarchar(100),
				ProdGroup				nvarchar(100),
				ProcessOrder			nvarchar(50), 
				ProductSize				nvarchar(100),  
				StartTime				datetime,  
				EndTime					datetime)  
------------------------------------------------------------------------------------------------------------------
DECLARE @Crew_Schedule TABLE  (
				RcId					int identity,
				StartTime				datetime,   
				EndTime					datetime,  
				PUId					int,  
				Crew					varchar(20),   
				Shift					varchar(5))    
------------------------------------------------------------------------------------------------------------------
DECLARE @LineStatus TABLE  (
				RcID					int identity,
				PU_ID					int,  
				Phrase_Value			nvarchar(50),  
				StartTime				datetime,  
				EndTime					datetime)  
------------------------------------------------------------------------------------------------------------------
DECLARE @RE_Specs TABLE	(	
				Spec_Id					int,
				Spec_Desc				varchar(200))
------------------------------------------------------------------------------------------------------------------
DECLARE @Product_Specs TABLE(				 
				prod_code 				nvarchar(20),
				prod_desc      			nvarchar(200),
				Spec_Id					int,
				Spec_Desc				nvarchar(200),
				target 					FLOAT )

------------------------------------------------------------------------------------------------------------------
DECLARE @PLIDList TABLE (	
				RCDID	 				Int,
				PLID 					Int,
				PLDESC 					Varchar(50),
				ConvUnit 				Int,
				STLSUnit				INT,
				SpliceUnit 				Int,
				PackerUnit	 			Int,				
				PartPadCountVarID		Int,
				CompPadCountVarID		Int,
				PartCaseCountVarID		Int,
				PartRunCountVarID		Int,
				CompRunCountVarID		Int,
				CompSpeedActVarID		Int,
				PartStartUPCountVarID	Int,
				CompStartUPCountVarID	Int,
				CompSpeedTargetVarID	Int,
				PartSpeedActVarID		Int,
				PartSpeedTargetVarID	Int,
				UnitEventType			VARCHAR(25),
				MaxEvent				DATETIME	)
------------------------------------------------------------------------------------------------------------------
DECLARE @Production TABLE (
				Id						Int IDENTITY,
				StartTIME				Datetime,
				EndTIME					Datetime,
				StartTimeUTC			DatetimeOffset(7),
				EndTimeUTC				DatetimeOffset(7),
				PLID					Int,
				LineDesc				Varchar(50),
				PUID					Int,
				UnitDesc           		Varchar(100),
				--Product					Varchar(50),
				ProdDesc				NVARCHAR(100),
				ProdCode				NVARCHAR(100),
				ProdFam					NVARCHAR(100),
				ProdGroup				NVARCHAR(100),
				ProcessOrder			NVARCHAR(50),
				ProdID					Int,
				Crew					Varchar(25),
				Shift					Varchar(25),
				LineStatus				Varchar(25),
				TotalPad				Float,
				RunningScrap			Float,
				Stopscrap				Float,
				LineSpeedTAR			Float,
				TotalCases				Float,
				ProdPerBag				Float,
				BagSPerCase				Float,
				CasesPerPallet			Float,
				ProdPerStat				Float,				
				TypeOfEvent				Varchar(50),   			
				Uptime					Float,
				LineSpeedAct			Float,
				ParentIdCrew			INT,
				ParentIdLs				INT,
				EventId					Int		,
				EventType				VARCHAR(50),
				SplitProdStarts			INT		DEFAULT 0,
				SplitLS					INT		DEFAULT 0)
------------------------------------------------------------------------------------------------------------------
DECLARE @Prod_StartEndTime TABLE (
				PL_Id					INT,
				PU_Id 					INT,
				Pu_desc 				Varchar(200),
				in_StartTime 			Datetime,
				in_EndTime 				Datetime,
				Min_Event				Datetime,
				Last_LSChange			Datetime,
				Last_LSDelete			Datetime,
				EventInThePastFlag		INT	)

------------------------------------------------------------------------------------------------------------------
DECLARE @Down_MaxStartTime TABLE(
				PL_Id					INT,
				Pu_Id 					INT,
        		MaxStartTime 			DATETIME,
				MaxEndTime				DATETIME )
------------------------------------------------------------------------------------------------------------------
DECLARE @Prod_Units TABLE (
				Prod_Desc				Varchar(50),
    			Rcd_Id					Int,
				Pu_Id					Int,
				PL_Id					Int	)
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
-- SP VARIABLES
------------------------------------------------------------------------------------------------------------------
DECLARE
				@AppVersion						NVARCHAR(20),
				@RPTPartSpeedTarTag				NVARCHAR(200),
				@RPTPadCountTag  				NVARCHAR(200),
 	 			@RPTCaseCountTag 				NVARCHAR(200),
	 			@RPTRunCountTag  				NVARCHAR(200),
	 			@RPTSpeedActTag					NVARCHAR(200),
	 			@RPTStartupCountTag				NVARCHAR(200),
	 			@RPTConverterSpeedTag 			NVARCHAR(200),
	 			@RPTPartSpeedActTag 			NVARCHAR(200),
	 			@RPTPadsPerStat 				NVARCHAR(200),
	 			@RPTPadsPerBag 					NVARCHAR(200),
	 			@RPTBagsPerCase 				NVARCHAR(200),
	 			@RPTCasesPerPallet 				NVARCHAR(200),
	 			@RPTSpecProperty 				NVARCHAR(200),
				@RPTDowntimesystemUser			NVARCHAR(100),
				@DowntimesystemUserID			INT			 ,
				@PLID							INT			 , 
				@PU_Id							INT			 , 
				@EndTime						DATETIME	 ,
				@SpecPropertyID           	 	INT			,
	    		@PadsPerStatSpecID        	 	INT			,
	    		@PadsPerBagSpecID         	 	INT			,
	    		@BagsPerCaseSpecID        	 	INT

---------------------------------------------------------------------------------------------
-- Get the Proficy Database Version
---------------------------------------------------------------------------------------------
SELECT @AppVersion = App_Version FROM dbo.AppVersions WITH(NOLOCK) WHERE App_Name = 'Database'
----------------------------------------------------------------------------
-- SET Default Values
----------------------------------------------------------------------------
SET @RPTDowntimesystemUser	= 'ReliabilitySystem'

SELECT @DowntimesystemUserID = 
	User_ID
	FROM dbo.USERS WITH(NOLOCK) 
	WHERE UserName = @RPTDowntimesystemUser
------------------------------------------------------------------------------------------------------------------
-- Check Parameters: Establish default values
------------------------------------------------------------------------------------------------------------------
SET 			@RPTPadCountTag  		= 		'PRPadCNTLow'
SET 			@RPTCaseCountTag 		= 		'PRCaseCount'
SET 			@RPTRunCountTag  		= 		'PRRunCNTLow'
SET 			@RPTSpeedActTag			= 		'PRConverter_Speed_Actual'
SET 			@RPTStartupCountTag		= 		'PRSTUPCNTLow'
SET 			@RPTConverterSpeedTag 	= 		'PRConverter_Speed_Target'
SET 			@RPTPartSpeedActTag 	= 		'PRConverter_Speed_Actual'
SET 			@RPTPartSpeedTarTag 	= 		'PRConverter_Speed_Target'
SET 			@RPTPadsPerStat 		= 		'Pads Per Stat'
SET 			@RPTPadsPerBag 			= 		'Pads Per Bag'
SET 			@RPTBagsPerCase 		= 		'Bags Per Case'
SET 			@RPTCasesPerPallet 		= 		'Cases Per Pallet'
SET 			@RPTSpecProperty 		= 		'RE_Product InformatiON'

------------------------------------------------------------------------------------------------------------------
--DELETE FROM  OpsDataStore.dbo.OpsDB_Production_Data  WHERE endtime < dateadd(day,-360,getdate())
------------------------------------------------------------------------------------------------------------------
INSERT @PLIDList (PLID			,			
					PLDESC		,
					STLSUnit				)
SELECT  DISTINCT
		pu.PL_Id								,
		pl.PL_Desc								,
		CASE	WHEN	(CharIndex	('STLS=', pu.Extended_Info, 1)) > 0
											THEN	Substring	(	pu.Extended_Info,
												(	CharIndex	('STLS=', pu.Extended_Info, 1) + 5),
													Case 	WHEN 	(CharIndex(';', pu.Extended_Info, CharIndex('STLS=', pu.Extended_Info, 1))) > 0
															THEN 	(CharIndex(';', pu.Extended_Info, CharIndex('STLS=', pu.Extended_Info, 1)) - (CharIndex('STLS=', pu.Extended_Info, 1) + 5)) 
															ELSE 	Len(pu.Extended_Info)
													END )
									END   		
FROM	dbo.Prod_Units	pu	WITH(NOLOCK)
JOIN	dbo.Prod_Lines  pl	WITH(NOLOCK)	ON		pu.PL_Id	=	pl.PL_Id
WHERE   CharIndex('STLS=', pu.Extended_Info, 1) > 0

UPDATE @PLIDList	SET ConvUnit = STLSUnit


DELETE FROM @PLIDList 
	WHERE ConvUnit IS NULL AND STLSUnit IS NULL

UPDATE TPL SET PartPadCountVarID = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V  WITH(NOLOCK) 
		ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type IN(0,5)
		AND (V.test_name Like '%'+ @RPTPadCountTag + '%' or V.test_name ='productionCNT')
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET CompPadCountVarID = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V WITH(NOLOCK) 
		ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type = 1
		AND (V.test_name Like '%'+ @RPTPadCountTag + '%' or V.test_name ='productionOUT')
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET PartCaseCountVarID = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Prod_Units pu   WITH(NOLOCK) ON pu.pu_id = tpl.cONvunit
	JOIN dbo.Prod_Units pu2  WITH(NOLOCK) ON pu2.pl_id = pu.pl_id
	JOIN dbo.Variables V     WITH(NOLOCK) ON V.PU_ID = pu2.pu_id
		AND V.Event_Type IN(0,5)
		AND v.test_name = 'PRODUCTION' AND v.User_Defined1 = 'CLASS3'
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET PartRunCountVarID = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V WITH(NOLOCK)  ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type IN(0,5)
		AND V.INPUT_Tag Like '%'+  @RPTRunCountTag + '%'
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET CompRunCountVarID = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V WITH(NOLOCK)  ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type = 1
		AND V.INPUT_Tag Like '%'+  @RPTRunCountTag + '%'
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET CompStartUPCountVarID = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V WITH(NOLOCK)  ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type = 1
		AND V.INPUT_Tag Like '%'+  @RPTStartUPCountTag + '%'
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET PartStartUPCountVarID = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V WITH(NOLOCK)  ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type IN(0,5)
		AND V.INPUT_Tag Like '%'+  @RPTStartUPCountTag + '%'
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET CompSpeedTargetVarID = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V WITH(NOLOCK)  ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type = 1
		AND V.INPUT_Tag Like '%'+  @RPTConverterSpeedTag + '%'
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET CompSpeedActVarID = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V WITH(NOLOCK)  ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type = 1
		AND V.INPUT_Tag Like '%'+  @RPTSpeedActTag + '%'
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET PartSpeedTargetVarID  = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V WITH(NOLOCK)  ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type = 1
		AND V.INPUT_Tag Like '%'+  @RPTPartSpeedTarTag + '%'
		AND V.DATA_Type_ID IN(1,2)

UPDATE TPL SET PartSpeedActVarID  = VAR_ID
	FROM @PLIDList TPL
	JOIN dbo.Variables V WITH(NOLOCK)  ON TPL.CONVUnit = V.PU_ID
		AND V.Event_Type = 1
		AND V.INPUT_Tag Like '%'+  @RPTPartSpeedActTag + '%'
		AND V.DATA_Type_ID IN(1,2)


-- Check what kind of events uses each unit
UPDATE TPL 
	SET MaxEvent = (SELECT MAX(Timestamp) 
						FROM dbo.Events e WITH(NOLOCK)
						WHERE e.PU_Id = TPL.CONVUnit 
						GROUP BY e.PU_Id)
	FROM @PLIDList TPL

UPDATE TPL 
	SET UnitEventType = CASE
						WHEN (SELECT TOP 1 Start_Time
								FROM dbo.Events e WITH(NOLOCK)
								WHERE e.PU_Id = TPL.CONVUnit 
								AND e.Timestamp = TPL.MaxEvent) IS NOT NULL
						THEN 'Hybrid'
						ELSE 'Regular'
						END
	FROM @PLIDList TPL

----------------------------------------------------------------------------
-- Check Parameter: SpecificatiONs
----------------------------------------------------------------------------
DECLARE
		@72hoursOld				DATETIME

SET @72hoursOld = DATEADD(hh,-12,GETDATE())

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- SECTION 3 .
-- Gather the Last Time the Raw Data table was Updated and the End Time for the 
-- Time Window Buckett
-- START
-----------------------------------------------------------------------------------------------------------------

INSERT INTO @Prod_StartEndTime			(PL_Id		,
										 PU_ID		,
										 PU_Desc	,
										 EventInThePastFlag						)
SELECT									 pu.PL_Id		,
										 pu.PU_Id		,
										 pu.PU_Desc		,
										0 
FROM			dbo.Prod_Units	pu			WITH(NOLOCK)
JOIN			@PLIDList		pl			ON					pu.PL_ID		=		pl.PLID
											AND					pl.STLSUnit		=		pu.PU_Id

UPDATE @Prod_StartEndTime
        SET in_StartTime = (SELECT MAX(StartTime)
									FROM			@Table_MaxStartTime4Lines  lprod   
									JOIN			dbo.Prod_Lines pl WITH(NOLOCK)		ON			pl.pl_desc COLLATE database_default		=	lprod.LineDesc COLLATE database_default
									--JOIN			dbo.Prod_Lines pl WITH(NOLOCK)		ON			pl.pl_desc 	=	lprod.LineDesc 
									JOIN			dbo.Prod_Units pu WITH(NOLOCK)		ON			pu.pl_id								=	pl.pl_id 
									WHERE			pu.pu_id = tp.pu_id)
FROM @Prod_StartEndTime tp
-----------------------------------------------------------------------------------------------------------------
-- SET the Start_Time
-- Get last Events modified since the flat tables have been updated
UPDATE @Prod_StartEndTime
        SET Min_Event =  (SELECT MIN(Timestamp) 
								FROM dbo.Events e  WITH(NOLOCK) 
									WHERE	Entry_On >= tp.in_StartTime 
											AND Entry_On < @72hoursOld 
											AND e.PU_Id = tp.PU_Id				)
FROM @Prod_StartEndTime tp

-- Get Last Line Status Changes
UPDATE @Prod_StartEndTime
        SET Last_LSChange = (SELECT MIN(lsc.Start_DateTime)
								FROM dbo.Local_PG_Line_Status ls WITH(NOLOCK)	 
								JOIN dbo.Local_PG_Line_Status_Comments lsc WITH(NOLOCK) ON ls.Status_Schedule_Id = lsc.Status_Schedule_Id
								WHERE Entered_On BETWEEN tp.in_StartTime AND @72hoursOld
									  AND ls.Unit_Id = tp.PU_Id)
FROM @Prod_StartEndTime tp

-- Get Last Line Status Deletion
UPDATE @Prod_StartEndTime
        SET Last_LSDelete = (SELECT MIN(lsh.Start_DateTime) 
								FROM dbo.Local_PG_Line_Status_History  lsh WITH(NOLOCK)
								JOIN dbo.Local_PG_Line_Status_Comments lsc WITH(NOLOCK) ON lsh.Status_Schedule_Id = lsc.Status_Schedule_Id
								WHERE lsc.Entered_On BETWEEN tp.in_StartTime AND @72hoursOld
												 AND lsh.Unit_Id = tp.PU_Id
												 AND lsc.Start_DateTime IS NULL
												 AND lsc.End_DateTime IS NULL)
FROM @Prod_StartEndTime tp

-- Compare Start_Time and Last_Event and see if we have to expand the Time Window
UPDATE @Prod_StartEndTime
		SET in_StartTime = (CASE WHEN in_StartTime > MIn_Event THEN Min_Event ELSE in_StartTime END),
			EventInThePastFlag = (CASE WHEN in_StartTime > MIn_Event THEN 0 ELSE 1 END)

UPDATE @Prod_StartEndTime
		SET in_StartTime = (CASE WHEN in_StartTime > Last_LSChange THEN Last_LSChange ELSE in_StartTime END),
			EventInThePastFlag = (CASE WHEN in_StartTime > Last_LSChange THEN 0 ELSE 1 END)

UPDATE @Prod_StartEndTime
		SET in_StartTime = (CASE WHEN in_StartTime > Last_LSDelete THEN Last_LSDelete ELSE in_StartTime END),
			EventInThePastFlag = (CASE WHEN in_StartTime > Last_LSDelete THEN 0 ELSE 1 END)

-----------------------------------------------------------------------------------------------------------------
UPDATE @Prod_StartEndTime
        SET in_EndTime = (SELECT MIN(Start_Time) FROM dbo.Crew_Schedule  WITH(NOLOCK)
						  WHERE Start_Time <= GETDATE() AND GETDATE() < End_Time -- End_Time > pset.in_StartTime
						   AND PU_Id = pset.PU_Id)
FROM @Prod_StartEndTime pset

----------------------------------------------------------------------------------------------------------------
-- Once the Minimun StartTime is Detected; then go and get the 'prior' Event in the Crew Schedule
-----------------------------------------------------------------------------------------------------------------
UPDATE @Prod_StartEndTime
        SET in_StartTime = (SELECT MAX(Start_Time) FROM dbo.Crew_Schedule  WITH(NOLOCK)
						    WHERE Start_Time < pset.in_StartTime AND PU_Id = pset.PU_Id)
FROM @Prod_StartEndTime pset

-----------------------------------------------------------------------------------------------------------------
-- Case initial where the Production_unit is new
-----------------------------------------------------------------------------------------------------------------
UPDATE @Prod_StartEndTime
        SET in_EndTime = GETDATE(),
			in_starttime = @72hoursOld
FROM @Prod_StartEndTime pset
WHERE			in_starttime Is NULL 
				AND in_endtime Is NULL

UPDATE @Down_MaxStartTime
		SET MaxEndTime = DATEADD(hour,-12,GETDATE())
FROM @Down_MaxStartTime d
WHERE			MaxEndTime Is NULL

-----------------------------------------------------------------------------------------------------------------
-- SECTION 3 .
-- END
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- SECTION 4 .
-- Get Production Data
-- 
-- START
-----------------------------------------------------------------------------------------------------------------
-- Get 'Regular' PE Events:
INSERT INTO @Production
				(EndTIME			, 
					PLID			, 
					PUID			, 
					TypeOfEvent		,
					EventId			,
					EventType				)
	SELECT			e.TimeStamp		, 
					tpl.PLId		, 
					e.PU_Id			, 
					'Complete'		, 
					Event_Id		, 
					'Regular'
FROM				@PLIDList			tpl
JOIN				dbo.Events e  WITH(NOLOCK) ON TPL.CONVUnit	= e.PU_ID
JOIN				@Prod_StartEndTime tp		ON e.PU_Id		= tp.pu_id
														AND e.TimeStamp			> tp.in_StartTime
															AND e.TimeStamp <= tp.in_EndTime
WHERE			Start_Time IS NULL
					AND TPL.UnitEventType = 'Regular'

--****************************************************************************************************************
-- Get 'New' PE Events
--****************************************************************************************************************
-- Get 'New' PE Events
Insert @Production
	(StartTime, EndTIME, PLID, PUID, TypeOfEvent,eventid,EventType)
	SELECT cs.Start_Time, cs.End_Time, TPL.PLID, cs.PU_ID, 'Complete', null, 'Hybrid'
	FROM @PLIDList TPL
	JOIN dbo.Crew_Schedule cs  WITH(NOLOCK) ON TPL.CONVUnit = cs.PU_ID
        JOIN @Prod_StartEndTime tp ON cs.pu_id = tp.pu_id
		AND cs.Start_Time > tp.in_StartTime
		AND cs.Start_Time <= tp.in_EndTime
		AND TPL.UnitEventType = 'Hybrid'

--****************************************************************************************************************
--
-- 
DECLARE
	@PUId 					Int,
	@curEndTime 			DATETIME,
	@curStartTime 			DATETIME,
	@EventID 				INT


Declare ProductionStart INSENSITIVE Cursor For
	(SELECT ID, EndTIME, PUID
	FROM @Production WHERE EventType = 'Regular'
	)
	For Read ONly

Open ProductiONStart

FETCH NEXT FROM ProductiONStart INTO @EventID,@curEndTIME, @PUId

While @@Fetch_Status = 0
BEGIN
	SET @curStartTime = null
	SELECT @curStartTime = MAX(TimeStamp)
		FROM dbo.Events E WITH(NOLOCK) 
		WHERE PU_ID = @PUID
			AND Timestamp < @curEndTIME
	--
	UPDATE @Production
		SET StartTIME = isnull(@curStartTime,@72HoursOld)
	WHERE ID = @EventID
	--
	FETCH NEXT FROM ProductiONStart INTO @EventID,@curEndTIME, @PUId
End
Close ProductiONStart
Deallocate ProductiONStart
--select * from @Production

--*******************************************************************************************************  
-- Start building Products Table  
--Print convert(varchar(25), getdate(), 120) + ' Build @Products Table'  
--*******************************************************************************************************  
Insert Into @Products(PUID ,ProdID,ProdCode,ProdDesc,ProdFam,ProdGroup,ProcessOrder,ProductSize,StartTime,EndTime)  
SELECT ps.PU_ID,P.Prod_ID,Prod_Code,Prod_Desc,PF.Product_Family_Desc_Global,'',PP.Process_Order,'',PS.start_Time as StartTime,PS.End_Time as EndTime  
 FROM dbo.Production_Starts Ps WITH(NOLOCK)      
 JOIN @PLIDList pl ON ps.pu_id = pl.convUnit  
    JOIN dbo.Products P WITH(NOLOCK) ON PS.Prod_ID = P.Prod_ID 
    JOIN dbo.Product_Family PF WITH(NOLOCK) ON p.Product_Family_Id=PF.Product_Family_Id
	JOIN @Prod_StartEndTime tp ON ps.pu_id = tp.pu_id     
    JOIN dbo.Production_Plan_starts PPS WITH(NOLOCK) ON PPS.PU_Id=PS.PU_Id and PPS.Start_time<=tp.in_EndTime and (PPS.End_Time>tp.In_StartTime or PPS.End_Time is null)
	JOIN dbo.Production_Plan PP WITH(NOLOCK) ON PP.PP_Id=PPS.PP_Id     
        WHERE  
          Ps.Start_Time <= tp.in_EndTime AND  
            (Ps.End_Time > tp.in_StartTime or PS.End_TIME IS null)  
  

-- This statement avoid same product that belongs to different sizes to cause duplicated entries  
UPDATE @Products   
 Set ProductSize = pg.Product_Grp_Desc,  
	 ProdGroup	= pg.Product_Grp_Desc_Global	
FROM @Products p  
JOIN dbo.Product_Group_Data pgd WITH(NOLOCK) ON pgd.Prod_Id = P.ProdId  
JOIN dbo.Product_Groups pg WITH(NOLOCK) ON pgd.product_grp_id = pg.product_grp_id 


--**********************************************************************************************************************************************
---------------------------------------------------------------------------------------------------------------
--	Split by Production Starts
--  This splits needs to be done only if the Configuration is an HybridConfiguration !!!!!!!!!!!!!!!!!!!!!!!!!!
---------------------------------------------------------------------------------------------------------------

UPDATE p SET p.SplitProdStarts = 1
	FROM @Production			p
	JOIN dbo.Production_Starts	ps WITH(NOLOCK)	ON p.PUId = ps.PU_ID  
												AND ps.Start_Time < p.StartTime 
												AND ps.End_Time > p.StartTime
												AND ps.End_Time < p.EndTime
	WHERE EventType = 'Hybrid'

UPDATE p SET p.SplitProdStarts = 1
	FROM @Production			p
	JOIN dbo.Production_Starts	ps WITH(NOLOCK)	ON p.PUId = ps.PU_ID  
												AND ps.Start_Time > p.StartTime
												AND ps.Start_Time < p.EndTime
												AND (ps.End_Time > p.EndTime OR ps.End_Time IS NULL)
WHERE EventType = 'Hybrid'

UPDATE p SET p.SplitProdStarts = 1
	FROM @Production			p
	JOIN dbo.Production_Starts	ps WITH(NOLOCK)	ON p.PUId = ps.PU_ID  
												AND ps.Start_Time > p.StartTime
												AND ps.End_Time < p.EndTime 												
WHERE EventType = 'Hybrid'


-- Insert new records in #Production from the Splits by Production_Starts
Insert into @Production (
			puid, 
			PLID, 
			StartTIME, 
			EndTime,
			StarttimeUTC,
			EndtimeUTC, 
			EventId,
			TypeOfEvent, 
			Crew, 
			Shift, 
			ParentIdCrew,
			EventType )  
		SELECT	DISTINCT 
			tpt.puid, 
			tpt.plid, 
			CASE WHEN ps.Start_Time > tpt.StartTime 
				THEN ps.Start_Time 
				ELSE tpt.StartTime 
			END,
			CASE WHEN ps.End_Time < tpt.EndTime 
				THEN ps.End_Time 
				ELSE tpt.EndTime 
			END, 
			CASE WHEN ps.Start_Time > tpt.StartTime 
				THEN dateadd(minute,datediff(minute,getdate(),getutcdate()),ps.Start_Time) 
				ELSE dateadd(minute,datediff(minute,getdate(),getutcdate()),tpt.StartTime) 
			END,
			CASE WHEN ps.End_Time < tpt.EndTime 
				THEN dateadd(minute,datediff(minute,getdate(),getutcdate()),ps.End_Time) 
				ELSE dateadd(minute,datediff(minute,getdate(),getutcdate()),tpt.EndTime) 
			END, 
			tpt.EventId,
			tpt.TypeOfEvent, 
			tpt.Crew, 
			tpt.Shift, 
			tpt.Id,
			'Hybrid'
	FROM @Production			tpt	
	JOIN dbo.Production_Starts	ps	 WITH(NOLOCK)	ON tpt.PUId = ps.PU_ID  
												AND (((tpt.StartTime BETWEEN ps.Start_Time AND ps.End_Time) 
														OR (tpt.EndTime > ps.Start_Time AND tpt.EndTime < ps.End_Time OR ps.End_Time IS NULL)
														OR (ps.Start_Time >= tpt.StartTime AND ps.End_Time < tpt.EndTime)))
	WHERE tpt.SplitProdStarts = 1
-- Delete rows with the same time
DELETE FROM @Production 
	WHERE StartTIME = EndTIME 

-- Delete records in #Production
DELETE FROM @Production	
	WHERE SplitProdStarts = 1 

---------------------------------------------------------------------------------------------------------------
--	Update #Production
----------------------------------------------------------------------------------------------------  
UPDATE @Production  
	SET Crew = CS.Crew_Desc,   
		Shift = CS.Shift_Desc
	FROM @Production		TPT  
	JOIN @PLIDList			TPL					ON tpt.PuID = TPL.ConvUnit  
	JOIN dbo.Crew_Schedule	cs	WITH(NOLOCK)	ON tpl.STLSUnit = cs.PU_ID  
												AND tpt.EndTime > cs.Start_Time   
												AND (tpt.EndTime <= cs.End_Time or cs.End_Time IS null)  
--select * from @Production
---------------------------------------------------------------------------------------------------------------
--	Split by Line Status
---------------------------------------------------------------------------------------------------------------

UPDATE tpt SET tpt.SplitLS = 1
	FROM @Production	TPT  
	JOIN @Products		PS	ON ps.puid = tpt.puid   
							AND tpt.EndTime >= ps.StartTime   
							AND (tpt.EndTime < ps.EndTime or ps.EndTime IS Null)  
	JOIN Local_PG_Line_Status	Ls1	WITH(NOLOCK) ON tpt.PUId = Ls1.Unit_Id  
							AND TPT.EndTime > Ls1.Start_DateTime   
							AND (TPT.StartTime <= Ls1.End_DateTime or Ls1.End_DateTime IS null)   
	JOIN Local_PG_Line_Status	Ls2	WITH(NOLOCK) ON tpt.PUId = Ls2.Unit_Id  
							AND TPT.EndTime > Ls2.Start_DateTime   
							AND (TPT.StartTime <= Ls2.End_DateTime or Ls2.End_DateTime IS null)   
	WHERE EventType = 'Hybrid'
	AND Ls1.Status_Schedule_Id <> Ls2.Status_Schedule_Id


-- Insert new records in #Production from the Splits by Line Status
Insert into @Production (
			StartTIME, 
			EndTime, 
			PLID, 
			puid, 
			Crew, 
			Shift, 
			EventId,
			TypeOfEvent, 
			ParentIdLs,
			EventType )  
	SELECT	DISTINCT 
			CASE WHEN cs.Start_DateTime > tpt.StartTime 
				THEN cs.Start_DateTime 
				ELSE tpt.StartTime 
			END,
			CASE WHEN cs.End_DateTime < tpt.EndTime 
				THEN cs.End_DateTime 
				ELSE tpt.EndTime 
			END, 
			tpt.plid, 
			tpt.puid, 
			tpt.Crew, 
			tpt.Shift, 
			tpt.EventId,
			tpt.TypeOfEvent, 
			tpt.Id	,
			'Hybrid'
	FROM @Production	TPT  	
	JOIN @Products		PS	ON ps.puid = tpt.puid   
							AND tpt.EndTime >= ps.StartTime   
							AND (tpt.EndTime < ps.EndTime or ps.EndTime IS Null)  
	JOIN dbo.Local_PG_Line_Status	cs WITH(NOLOCK)	ON tpt.PUId = cs.Unit_Id  
							AND ((tpt.StartTime BETWEEN cs.Start_DateTime AND cs.End_DateTime) 
								OR (tpt.EndTime BETWEEN cs.Start_DateTime AND cs.End_DateTime)
								OR (cs.Start_DateTime >= tpt.StartTime AND cs.End_DateTime < tpt.EndTime))	
	WHERE tpt.SplitLS = 1

-- Delete rows with the same time
DELETE FROM @Production 
	WHERE StartTIME = EndTIME 

-- Delete records in #Production
DELETE FROM @Production	
	WHERE SplitLS = 1 

--********************************************************************************************************************************************
--********************************************************************************************************************************************

UPDATE @Production
	SET ProdDesc 		=	P.Prod_Desc,
	    ProdCode 		= 	P.Prod_Code, 
	    ProdID 			= 	P.Prod_ID,
		ProdFam			=	PF.Product_Family_Desc_Global,
		ProdGroup		=	PG.Product_Grp_Desc_Global,
		ProcessOrder	=	PL.Process_Order,
		Crew 			= 	cs.Crew_DESC, 
	    Shift 			= 	cs.Shift_DESC, 
	    LineStatus 		= 	phr.Phrase_Value,
		TotalPad 		= 	CONVERT(Float, TPad.RESULT),
		RunningScrap 	= 	CONVERT(Float, TRun.RESULT),
		Stopscrap 		= 	CONVERT(Float, TSTOP.RESULT)
	    
FROM @Production tpt
	LEFT JOIN @PLIDList tpl ON tpt.PLID = tpl.PLID
	LEFT JOIN dbo.ProductiON_Starts PS  WITH(NOLOCK) ON tpt.puid = PS.PU_ID
				AND tpt.EndTime > ps.Start_Time 
				AND (tpt.EndTime <= ps.End_Time or ps.End_Time IS null)
    LEFT JOIN dbo.Production_Plan_starts PPLS WITH(NOLOCK) ON PPLS.PU_Id=PS.PU_Id 
				AND tpt.EndTime > ppls.Start_Time 
				AND (tpt.EndTime <= ppls.End_Time or ppls.End_Time IS null)
    LEFT JOIN dbo.Production_Plan PL WITH(NOLOCK) ON PPLS.PP_ID=PL.PP_ID
	LEFT JOIN dbo.Products P  WITH(NOLOCK) ON ps.Prod_ID = P.Prod_ID
	LEFT JOIN dbo.Product_Family PF WITH(NOLOCK) ON p.Product_Family_Id=PF.Product_Family_Id
	LEFT JOIN dbo.Product_Group_Data PGD WITH(NOLOCK) ON p.Prod_id=PGD.Prod_id
	LEFT JOIN dbo.Product_Groups PG WITH(NOLOCK) ON PGD.Product_Grp_Id=PG.Product_Grp_Id 
	LEFT JOIN dbo.Crew_Schedule cs  WITH(NOLOCK) ON tpl.CONvUnit = cs.PU_ID
				AND tpt.EndTime > cs.Start_Time 
				AND (tpt.EndTime <= cs.End_Time or cs.End_Time IS null)
	LEFT JOIN dbo.Local_PG_Line_Status LPG WITH(NOLOCK) ON tpl.CONvUnit = lpg.Unit_ID
				AND tpt.EndTime > lpg.Start_DateTime 
				AND (tpt.EndTime <= lpg.End_DateTime or lpg.End_DateTime IS null)
	LEFT JOIN dbo.Phrase phr WITH(NOLOCK) ON lpg.Line_Status_ID = phr.Phrase_ID
	LEFT JOIN dbo.TESTS TPad WITH(NOLOCK) ON TPL.CompPadCountVarID = TPad.VAR_ID
				AND TPad.RESULT_ON = TPT.EndTIME
	LEFT JOIN dbo.TESTS TRun WITH(NOLOCK) ON TPL.CompRunCountVarID = TRun.VAR_ID
				AND TRun.RESULT_ON = TPT.EndTIME
	LEFT JOIN dbo.TESTS TSTOP WITH(NOLOCK) ON TPL.CompStartUPCountVarID = TSTOP.VAR_ID
				AND TSTOP.RESULT_ON = TPT.EndTIME
WHERE EventType = 'Regular'
UPDATE @Production	set
    LineSpeedTAR 	= 	CONVERT(Float, TSpeed.RESULT),
	LineSpeedAct 	= 	CONVERT(Float, ASpeed.RESULT)	    
FROM @Production tpt
	LEFT JOIN @PLIDList tpl ON tpt.PLID = tpl.PLID
	LEFT JOIN dbo.TESTS TSpeed WITH(NOLOCK) ON TPL.CompSpeedTargetVarID = TSpeed.VAR_ID
				AND TSpeed.RESULT_ON = TPT.EndTIME
	LEFT JOIN dbo.TESTS ASpeed WITH(NOLOCK) ON TPL.CompSpeedActVarID = ASpeed.VAR_ID
				AND ASpeed.RESULT_ON = TPT.EndTIME
	WHERE EventType = 'Regular'


-- Only update the information for 'Hybrid' records
UPDATE @Production
	SET ProdDesc		=	p.ProdDesc,
		ProdCode 		= 	p.ProdCode, 
		ProdFam			=	p.ProdFam,
		ProdGroup		=	p.ProdGroup,
		ProcessOrder	=	p.ProcessOrder,
	    ProdID 			= 	p.ProdId,	
		Crew 			= 	cs.Crew_DESC, 
	    Shift 		= 	cs.Shift_DESC, 
	    LineStatus 		= 	phr.Phrase_Value  
	    
	FROM @Production tpt
	LEFT JOIN @PLIDList tpl ON tpt.PLID = tpl.PLID
	LEFT JOIN @Products p	ON p.PUId = tpt.PUId
							AND tpt.EndTime > p.StartTime 
							AND (tpt.EndTime <= p.EndTime or p.EndTime IS null)
	LEFT JOIN dbo.Crew_Schedule cs  WITH(NOLOCK) ON tpl.CONvUnit = cs.PU_ID
				AND tpt.EndTime > cs.Start_Time 
				AND (tpt.EndTime <= cs.End_Time or cs.End_Time IS null)
	LEFT JOIN dbo.Local_PG_Line_Status LPG WITH(NOLOCK) ON tpl.CONvUnit = lpg.Unit_ID
				AND tpt.EndTime > lpg.Start_DateTime 
				AND (tpt.EndTime <= lpg.End_DateTime or lpg.End_DateTime IS null)
	LEFT JOIN dbo.Phrase phr WITH(NOLOCK) ON lpg.Line_Status_ID = phr.Phrase_ID
	
	WHERE EventType = 'Hybrid'
	

-- Only update the Production Counts for those 'Hybrid' records
UPDATE @Production
	SET TotalPad =	ISNULL((	SELECT SUM(CONVERT(FLOAT,Result))
								FROM dbo.Tests t WITH(NOLOCK)
								WHERE t.Var_Id = tpl.PartPadCountVarId
								AND tpt.StartTime < t.Result_On
								AND tpt.EndTime >= t.Result_On
								GROUP BY t.Var_Id	),0),
		RunningScrap = ISNULL((	SELECT SUM(CONVERT(FLOAT,Result))
								FROM dbo.Tests t WITH(NOLOCK)
								WHERE t.Var_Id = tpl.PartRunCountVarID
								AND tpt.StartTime < t.Result_On
								AND tpt.EndTime >= t.Result_On
								GROUP BY t.Var_Id	),0),
		Stopscrap = ISNULL((	SELECT SUM(CONVERT(FLOAT,Result))
								FROM dbo.Tests t WITH(NOLOCK)
								WHERE t.Var_Id = tpl.PartStartUPCountVarID
								AND tpt.StartTime < t.Result_On
								AND tpt.EndTime >= t.Result_On
								GROUP BY t.Var_Id	),0),
		LineSpeedTAR = ISNULL((	SELECT AVG(CONVERT(FLOAT,Result))
								FROM dbo.Tests t WITH(NOLOCK)
								WHERE t.Var_Id = tpl.CompSpeedTargetVarID
								AND tpt.StartTime < t.Result_On
								AND tpt.EndTime >= t.Result_On
								GROUP BY t.Var_Id	),0),
		LineSpeedAct = ISNULL((	SELECT AVG(CONVERT(FLOAT,Result))
								FROM dbo.Tests t WITH(NOLOCK)
								WHERE t.Var_Id = tpl.CompSpeedActVarID
								AND tpt.StartTime < t.Result_On
								AND tpt.EndTime >= t.Result_On
								GROUP BY t.Var_Id	),0)
	FROM @Production	tpt
	JOIN @PLIDList		tpl ON tpt.PUId = tpl.ConvUnit
	
	WHERE EventType = 'Hybrid'

	
---------------------------------------------------------------------------------------------
UPDATE @Production
    SET LineDesc = PLDESC, 
		UnitDesc = Pu_Desc
FROM @Production p
JOIN @PLIDList PL ON PL.CONvUnit = p.PUID
JOIN dbo.Prod_Units pu WITH(NOLOCK) ON PL.CONvUnit = pu.pu_id

-- FRio : UPDATE LineSpeedAct CalculatiON, SET it to (TotalPads - StopScrap)/Uptime
UPDATE @Production
	SET LineSpeedAct = (TotalPad - isnull(StopScrap,0)) / Uptime
WHERE Uptime > 0 
--
UPDATE @Production
	SET LineDesc = PL_Desc
FROM dbo.Prod_Lines PL WITH(NOLOCK) 
JOIN @Production tpt ON PL.PL_ID = tpt.PLID

----------------------------------------------------------------------------
-- RE_ProductInformation 
----------------------------------------------------------------------------
-- @RPTPadsPerStat
SELECT @SpecPropertyID = PROP_ID
		FROM dbo.Product_Properties WITH(NOLOCK)
		WHERE Prop_Desc = @RPTSpecProperty
		
-- 
SELECT @PadsPerStatSpecID = Spec_Id
		FROM dbo.Specifications ss WITH(NOLOCK)
		WHERE Spec_Desc like '%Per Stat%' or Spec_Desc ='Stat Unit' 
		
-- @RPTPadsPerBag
SELECT @PadsPerBagSpecID = Spec_Id
		FROM dbo.Specifications WITH(NOLOCK)
		WHERE (Spec_Desc like '%Per Bag%' or Spec_Desc like '%Per Package%')  
				and Prop_Id = @SpecPropertyID
		
-- @RPTBagSPerCase
SELECT @BagsPerCaseSpecID = Spec_Id
		FROM dbo.Specifications WITH(NOLOCK)
		WHERE Spec_Desc like '%Per Case%' 
				and Prop_Id = @SpecPropertyID
		
-- For Non Numerica configuration, get RE Specs for products	
INSERT INTO @RE_Specs (Spec_Id,Spec_Desc)
SELECT Spec_Id,Spec_Desc
FROM dbo.Specifications s WITH(NOLOCK)
JOIN dbo.Product_Properties pp WITH(NOLOCK) ON s.Prop_Id = pp.Prop_id
WHERE pp.Prop_Desc = 'RE_Product Information'

INSERT INTO     @Product_Specs (
				Prod_Code 		,
				Prod_Desc      	,
				Spec_Id			,
				Spec_Desc		,
				Target			)
SELECT 			DISTINCT 
				p.ProdCode,
				p.ProdDesc,
				rs.Spec_Id,
				rs.Spec_Desc,
				ass.target 
FROM (SELECT DISTINCT ProdCode,ProdDesc FROM @Production) p
LEFT JOIN dbo.Characteristics c WITH(NOLOCK) On (c.Char_Desc Like '%' + P.ProdCode + '%'
												 OR c.Char_Desc = P.ProdDesc)
							and c.Prop_Id = @SpecPropertyId
LEFT JOIN dbo.Active_Specs ass WITH(NOLOCK) On c.char_id = ass.char_id
LEFT JOIN @RE_Specs rs On ass.Spec_Id = rs.Spec_Id 
WHERE ass.Expiration_Date Is Null 

UPDATE @Production
		SET ProdPerBag = target
FROM   @Production p
JOIN   @Product_Specs ps 		ON   p.ProdCode = ps.Prod_Code 
WHERE  (Spec_Desc Like '%per Bag' or Spec_Desc like '%Per Package%')

UPDATE @Production
		SET BagsPerCase = Target
FROM   @Production p
JOIN   @Product_Specs ps 		ON   p.ProdCode = ps.Prod_Code 
WHERE  Spec_Desc Like '%per Case'

UPDATE @Production
		SET ProdPerStat = Target
FROM   @Production p
JOIN   @Product_Specs ps 		ON   p.ProdCode = ps.Prod_Code 
WHERE  (Spec_Desc Like '%per Stat' or Spec_Desc ='Stat Unit') 

UPDATE @Production
		SET CasesPerPallet = Target
FROM   @Production p
JOIN   @Product_Specs ps 		ON   p.ProdCode = ps.Prod_Code 
WHERE  Spec_Desc Like '%per Pallet'

DECLARE @Site VARCHAR(50)
SELECT  @Site = (SELECT sp.value FROM dbo.site_parameters sp WITH(NOLOCK) 
				JOIN dbo.parameters pp ON pp.parm_id = sp.parm_id WHERE pp.parm_name = 'sitename')
SELECT 
				p.StartTime, 
				p.EndTime, 
				dateadd(minute,datediff(minute,getdate(),getutcdate()),p.Starttime),
				dateadd(minute,datediff(minute,getdate(),getutcdate()),p.Endtime),
				p.ProdDesc,
				p.ProdCode,
				p.ProdFam,
				p.ProdGroup,
				p.ProcessOrder, 
				p.Crew, 
				p.Shift, 
				p.LineStatus, 
				p.TotalPad, 
				p.RunningScrap, 
				p.StopScrap, 
				p.LineSpeedTar, 
				p.LineSpeedAct,
				p.LineDesc, 
				p.TotalCases, 
				p.ProdPerBag, 
				p.BagsPerCase, 
				p.CasesPerPallet,
				p.ProdPerStat,
				p.Uptime,
				p.PUId, 			-- UnitId 
				p.UnitDesc, 		-- UnitDesc
				p.PLID, 			-- PLID
				0,   				-- TransferFlag
				0,					-- DeleteFlag
				p.EventId,
				@Site,
				p.TypeOfEvent,
				p.EventType
FROM @Production p
--LEFT JOIN  (SELECT UnitID, StartTime, EndTime-- Prod_Id 
--			FROM OpsDataStore.dbo.OpsDB_Production_data WITH(NOLOCK)
--			WHERE TransferFlag = 0) AS lprp  ON p.PUId = lprp.UnitID AND p.StartTime = lprp.StartTime and p.EndTime=lprp.Endtime
--WHERE TypeOfEvent <> 'Partial' 
--AND (lprp.UnitID IS NULL)

RETURN


