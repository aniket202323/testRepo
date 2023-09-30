CREATE PROCEDURE [dbo].[spLocal_OpsDataStore_ETL_GetDowntimes]
@Table_MaxStartTime4Unit dbo.TT_OpsDB_DownLastTransf_by_Unit ReadOnly, 
@MaxTEDetid INT

--WITH ENCRYPTION 
AS
--INSERT INTO @Table_MaxStartTime4Unit SELECT dateAdd(dd,0,Max(StartTime)) as Starttime, UnitId FROM OpsDataStore.dbo.OpsDB_DowntimeUptime_Data with(nolock) GROUP BY UnitId
--SELECT @MaxTEDetid=MAX(TEDetid) FROM  OpsDataStore.dbo.OpsDB_DowntimeUptime_Data  WITH(NOLOCK)
-- EXEC dbo.spLocal_OpsDataStore_GetRejects
------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
SET ANSI_WARNINGS OFF
------------------------------------------------------------------------------------------------------------------
PRINT '	.	START Stored Procedure ...'
---------------------------------------------------------------------------------------------------
PRINT '	.	Create table variables'
---------------------------------------------------------------------------------------------------
DECLARE	@tblRptStartOverlappingRcds	TABLE	(
		DetId					Int,
		Start_Time				DateTime	)
---------------------------------------------------------------------------------------------------
DECLARE @tblDownMaxStartTime TABLE(
		PLId					INT,
		PUId 					INT,
		MaxStartTime 			DATETIME,
		MaxEndTime				DATETIME )
---------------------------------------------------------------------------------------------------
DECLARE @tblTest1 TABLE (
		PUId					INT,
		MinStartTime  			DATETIME)
---------------------------------------------------------------------------------------------------
DECLARE @tblTest2 TABLE (
		PUId					INT,
		MaxStartTime  			DATETIME)


---------------------------------------------------------------------------------------------------
PRINT '	.	Create Temporary Tables'
---------------------------------------------------------------------------------------------------
CREATE TABLE	#PUList (
	RcdId					Int IDENTITY,
	PLId					Int,
	PLDesc					VarChar(100),
	PUId					Int,
	PUDesc					VarChar(100),
	AlternativePUId			Int,				-- This PUId will be used if no schedule or line status has been configured for
												-- the selected PUId
	LookUpPUId				Int )		
---------------------------------------------------------------------------------------------------
CREATE TABLE	#LineStatusList (
	PUId					Int,
	LineStatusSchedId		Int,
	LineStatusId			Int,
	LineStatusDesc			VarChar(50),
	LineStatusStart			DateTime,
	LineStatusEnd			DateTime		)
---------------------------------------------------------------------------------------------------
CREATE TABLE	#ShiftList (
	CSId					Int,
	PUId					Int,
	ShiftDesc				VarChar(10),
	CrewDesc				VarChar(10),
	ShiftStart				DateTime,
	ShiftEnd				DateTime )	
---------------------------------------------------------------------------------------------------


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


Declare @Crew_Schedule Table  (
				RcId					int identity,
				StartTime				datetime,   
				EndTime					datetime,  
				PUId					int,  
				Crew					varchar(20),   
				Shift					varchar(5))    

Declare @LineStatus Table  (
				RcID					int identity,
				PU_ID					int,  
				Phrase_Value			nvarchar(50),  
				StartTime				datetime,  
				EndTime					datetime)  
--------------------------------------

DECLARE @RE_Specs Table	(	
				Spec_Id					int,
				Spec_Desc				varchar(200))

DECLARE @Product_Specs Table(				 
				prod_code 				nvarchar(20),
				prod_desc      			nvarchar(200),
				Spec_Id					int,
				Spec_Desc				nvarchar(200),
				target 					FLOAT )

DECLARE @Test1 TABLE (
				Pu_Id					INT,
				Prod_Desc				NVARCHAR(200),
				Min_Start_Time  		DATETIME)

DECLARE @Test2 TABLE (
				Pu_Id					INT,
				MaxStartTime  			DATETIME)

DECLARE @Max_Modified_On TABLE	( 
				TeDet_Id				INT,
				Max_Modified_On			DATETIME)

CREATE TABLE #Downtimes (	
				Id						int IDENTITY,
				TedID					Int,
				PU_ID					Int,
				PU_Desc					NVARCHAR(200),
				PL_ID					Int,
				Line_Desc				Varchar(255),
				Start_Time				Datetime,
				End_Time				Datetime,
				Fault_Code				Varchar(10),
				Fault					Varchar(100),
				LocatiON				Varchar(50),
			    -- 
				Reason1					Varchar(100),
				Reason1_code			Varchar(10),
				Reason2					Varchar(100),
				Reason2_code			Varchar(10),
				Reason3					Varchar(100),
				Reason3_code			Varchar(10),
				Reason4					Varchar(100),
				Reason4_code			Varchar(10),
			    --
			    ActiON1					Varchar(100),
				ActiON1_code			Varchar(10),
				ActiON2					Varchar(100),
				ActiON2_code			Varchar(10),
				ActiON3					Varchar(100),
				ActiON3_code			Varchar(10),
				ActiON4					Varchar(100),
				ActiON4_code			Varchar(10),
			    --
				DuratiON				Float,
				Uptime					Float,
				IsStops					Int,
				ProdId					INT,
				ProdDesc				nvarchar(100) ,
				ProdCode				nvarchar(100) ,
				ProdFam					nvarchar(100) ,
				ProdGroup				nvarchar(100) ,
				ProcessOrder			nvarchar(50) ,
				Crew					Varchar(10),
				Shift					Varchar(10),
				LineStatus				Varchar(25),
				LineStatusId 			Int,
				LineStatusSchedId		Int,
				--
				Total_Downtime			Float,
				Total_Uptime			Float,
				--
				Comment					Varchar(1000),
				Main_Comment			Varchar(1000),				
				Comment_ID				Int,
				MainComment_ID			Int,
				Dev_Comment				Varchar (50),
				UserID					Int,
				Action_Level1			INT,
				SplitCrew				INT DEFAULT 0			,
				OverlapFlagShift			Int Default 0,		-- The overlap fields are used in the logic that split records
				OverlapFlagLineStatus		Int Default 0,		-- accross shifts and line status boundaries. The fields are zeroed	
				OverlapSequence				Int,					-- out after the record has been split
				OverlapRcdFlag				Int Default 0,		
				SplitFlagShift				Int Default 0,		-- Used for debugging only: marks records that have been split at shift boundaries
				SplitFlagLineStatus			Int Default 0,  	-- Used for debugging only: marks records that have been split at line status boundaries)
)

DECLARE @Down_MaxStartTime TABLE(
				PL_Id					INT,
				Pu_Id 					INT,
        		MaxStartTime 			DATETIME,
				MaxEndTime				DATETIME )


DECLARE @Timed_Event_Detail_History TABLE(
				Tedet_ID				int,
				User_ID					int)

DECLARE @TEDH_ModifiedOn TABLE( 
				Tedet_ID				INT,
				Modified_On				DATETIME)

DECLARE @Temp_Uptime TABLE (
				id						int,
				pu_id					int,
				Start_Time				datetime,
				End_Time				datetime,
				Uptime					float,
				LineStatus				nvarchar(100),
				Product					nvarchar(25))

--New Temporal Table for recalculate uptime when records are deleted
DECLARE @Down_Uptime TABLE (	
				down_id					int,
				ted_id					Int,
				Unit_id					Int,
				PU_Desc					NVARCHAR(200),
				PL_ID					Int,
				Line_Desc				Varchar(255),
				StartTime				Datetime,
				EndTime					Datetime,
				DuratiON				float,
				Uptime					float,
				Fault					Varchar(100),
				Gleds_Transfer_Status	Int
)						   
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
	    		@BagsPerCaseSpecID        	 	INT			,
				@i								INT			,
				@j								INT			,
				@c_intPUId						INT			,
				@c_intLookUpPUId				INT			

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
--SET 			@RPTPadCountTag  		= 		'PRPadCNTLow'
--SET 			@RPTCaseCountTag 		= 		'PRCaseCount'
--SET 			@RPTRunCountTag  		= 		'PRRunCNTLow'
--SET 			@RPTSpeedActTag			= 		'PRConverter_Speed_Actual'
--SET 			@RPTStartupCountTag		= 		'PRSTUPCNTLow'
--SET 			@RPTConverterSpeedTag 	= 		'PRConverter_Speed_Target'
--SET 			@RPTPartSpeedActTag 	= 		'PRConverter_Speed_Actual'
--SET 			@RPTPartSpeedTarTag 	= 		'PRConverter_Speed_Target'
--SET 			@RPTPadsPerStat 		= 		'Pads Per Stat'
--SET 			@RPTPadsPerBag 			= 		'Pads Per Bag'
--SET 			@RPTBagsPerCase 		= 		'Bags Per Case'
--SET 			@RPTCasesPerPallet 		= 		'Cases Per Pallet'
--SET 			@RPTSpecProperty 		= 		'RE_Product InformatiON'

------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
INSERT INTO 	#PUList (PUId)
SELECT pu.PU_Id 
FROM dbo.Event_Configuration ec
JOIN dbo.Prod_Units pu			WITH(NOLOCK)	ON ec.PU_Id = pu.PU_Id
JOIN   dbo.Event_Types et		WITH(NOLOCK)	ON ec.ET_Id = et.ET_Id  
JOIN @Table_MaxStartTime4Unit tm				ON tm.UnitId = pu.PU_Id
WHERE ET_Desc LIKE '%Downtime%' 

---------------------------------------------------------------------------------------------------
PRINT	'	.	Get Production Unit Description and Production Line'	
---------------------------------------------------------------------------------------------------
UPDATE		pul
	SET		pul.PUDesc 			= 	pu.PU_Desc,
			pul.AlternativePUId	=	Case	WHEN	(CharIndex	('STLS=', pu.Extended_Info, 1)) > 0
											THEN	Substring	(	pu.Extended_Info,
												(	CharIndex	('STLS=', pu.Extended_Info, 1) + 5),
													Case 	WHEN 	(CharIndex(';', pu.Extended_Info, CharIndex('STLS=', pu.Extended_Info, 1))) > 0
															THEN 	(CharIndex(';', pu.Extended_Info, CharIndex('STLS=', pu.Extended_Info, 1)) - (CharIndex('STLS=', pu.Extended_Info, 1) + 5)) 
															ELSE 	Len(pu.Extended_Info)
													END )
									END,
			pul.PLId			=	pu.PL_Id,
			pul.PLDesc			=	pl.PL_Desc
	FROM	dbo.Prod_Units	pu 	WITH(NOLOCK) 
	JOIN	#PUList			pul	ON	pul.PUId = pu.PU_Id
	JOIN	dbo.Prod_Lines	pl	WITH(NOLOCK) ON	pu.PL_Id = pl.PL_Id
---------------------------------------------------------------------------------------------------
PRINT	'	.	Update LookUp PUId'	
---------------------------------------------------------------------------------------------------
UPDATE		pl
	SET		pl.LookUpPUId	= 	Coalesce(pl.AlternativePUId, pl.PUId)
	FROM	#PUList	pl	

----------------------------------------------------------------------------
PRINT   '   . Logic to GET the right StartTime'
----------------------------------------------------------------------------

INSERT INTO @tblDownMaxStartTime (
		PLId,
		PUId)
SELECT  PLId, 
		PUId
FROM #PUList

UPDATE @tblDownMaxStartTime
        SET MaxStartTime = DATEADD(hh,-200,GETDATE())

DECLARE
		@72hoursOld				DATETIME

SET @72hoursOld = DATEADD(hh,-12,GETDATE())

----------------------------------------------------------------------------
-- Logic to GET the right StartTime. 
----------------------------------------------------------------------------

-- Check if last inserted record is back in time (FROM a split in the past)
 INSERT INTO @tblTest1 (PUId		, 
						MinStartTime		)
 SELECT 				pu.PUId		,					
						MIN(Start_Time)
 FROM		dbo.Timed_Event_Details ted WITH(NOLOCK)
 JOIN		#PUList pu					ON		pu.PUId		=	ted.PU_Id
 WHERE 
			ted.TeDet_Id	>		@MaxTEDetid
			AND Start_Time	>		DATEADD(dd,-90,Start_Time)
                        AND			ISNULL(End_Time,0)		<>		0
 GROUP BY pu.PUId

-- Get the previous record FROM backed in time record
 INSERT INTO @tblTest2(	PUId			, 
							MaxStartTime		)
 SELECT 			t.PUId, 
					MAX(lprd.StartTime) as MaxStartTime
 FROM @tblTest1 t
 LEFT JOIN  @Table_MaxStartTime4Unit lprd ON t.PUId = lprd.UnitId
 WHERE 
			lprd.StartTime			<			t.MinStartTime 
 --			AND DTStatus			=			1
 GROUP BY t.PUId

 UPDATE @tblDownMaxStartTime
	SET MaxStartTime		=		t2.MaxStartTime
 FROM	@tblDownMaxStartTime tms
 JOIN	@tblTest2 t2		ON	tms.PUId	=	t2.PUId

-- If some line still did not feed records then Start Feeding 72 hour back
 UPDATE @tblDownMaxStartTime
	SET MaxStartTime = DATEADD(hh,-72,GETDATE()) 
 WHERE MaxStartTime IS NULL

  UPDATE @tblDownMaxStartTime
	SET MaxEndTime = GETDATE()
 WHERE MaxEndTime IS NULL
 
 ---------------------------------------------------------------------------------------------------
PRINT '		Shift Schedule' 
---------------------------------------------------------------------------------------------------
------------------------------------------------------------------------
-- Time Interval Get Shifts:
-- If there is a Crew Schedule for some or all production units
-------------------------------------------------------------------------

INSERT INTO	#ShiftList (
					CSId,
					PUId,
					ShiftDesc,	
					CrewDesc,
					ShiftStart,	
					ShiftEnd )
SELECT	CS_Id,
					@c_intPUId,
					Shift_Desc,	
					Crew_Desc,
					Start_Time,	
					End_Time 
FROM	dbo.Crew_Schedule	cs WITH(NOLOCK) 
JOIN    @tblDownMaxStartTime		td
									ON	cs.PU_Id = td.PUId
											AND 	Start_Time 	<= 	td.MaxEndTime
											AND 	End_Time 	> 	td.MaxStartTime
-------------------------------------------------------------------------------
PRINT '		LineStatus' 
-------------------------------------------------------------------------------
INSERT INTO		#LineStatusList (
				PUId,
				LineStatusSchedId,
				LineStatusId,
				LineStatusDesc,
				LineStatusStart,
				LineStatusEnd )
	SELECT		td.PUId,
				Status_Schedule_Id,
				Line_Status_Id,
				Phrase_Value,
				Start_DateTime ,
				End_DateTime
		FROM	dbo.Local_PG_Line_Status 	ls	WITH(NOLOCK) 
		JOIN	dbo.Phrase 					p 	WITH(NOLOCK) ON 	ls.Line_Status_Id = p.Phrase_Id
												AND	p.Data_Type_Id = (	SELECT		Data_Type_Id
																			FROM	Data_Type
																			WHERE	Data_Type_Desc = 'Line Status')
		JOIN    @tblDownMaxStartTime		td
									ON	ls.Unit_Id = td.PUId
											AND 	Start_DateTime 	<= 	td.MaxEndTime
											AND 	(End_DateTime 	> 	td.MaxStartTime
																	OR End_DateTime IS NULL)
--=================================================================================================
PRINT	'END SECTION : ' 
--***********************************************************************************************************
-- 										GET DOWNTIMES DATA
--***********************************************************************************************************
-- Print convert(varchar(25), GETDATE(), 120) + ' Populating @Downtimes for Proficy 4' 
INSERT	INTO	#Downtimes
					(TedID,
					PU_ID, 
					PL_ID, 
					Start_Time,
					End_Time,
					Fault_Code, 
					Fault, 
					LocatiON,
					Reason1, 
					Reason1_code, 
					Reason2, 
					Reason2_code, 
					Reason3, 
					Reason3_code, 
					Reason4, 
					Reason4_code, 
					DuratiON,
					Line_Desc, 
					Comment_ID, 
					MainComment_ID, 
					PU_Desc, 
					IsStops, 
					UserID,
				    ActiON1_Code,
					ActiON1, 
					ActiON2_Code, 
					ActiON2, 
					ActiON3_Code, 
					ActiON3, 
					ActiON4_code, 
					ActiON4,
					Action_Level1)
	SELECT 
			    	ted.TEDet_Id, 
					ted.PU_Id, 
					tpl.PL_ID, 		
					ted.Start_Time,	
					ted.End_Time,
					tef.teFault_Value,
					Replace(tef.teFault_Name,'''',' '), 
					pu.pu_DESC, 
					Replace(er1.Event_Reason_Name,'''',' '), 
					er1.event_Reason_code, 
					Replace(er2.Event_Reason_Name,'''',' '), 
					er2.event_Reason_code, 
					Replace(er3.Event_Reason_Name,'''',' '), 
					er3.event_Reason_code,
					Replace(er4.Event_Reason_Name,'''',' '), 
					er4.event_Reason_code,
					ted.duratiON,
				    tpl.pl_desc,
			        c1.comment_id,
					'',
					tpu.PUDesc, 
					1,
					ted.User_ID,
					ac1.Event_Reason_Code,
			        Replace(ac1.Event_Reason_Name,'''',' '), 
			        ac2.Event_Reason_Code,
			        Replace(ac2.Event_Reason_Name,'''',' '), 
			        ac3.Event_Reason_Code,
			        Replace(ac3.Event_Reason_Name,'''',' '), 
			        ac4.Event_Reason_Code,
			        Replace(ac4.Event_Reason_Name,'''',' '),
					ted.Action_Level1
		FROM		dbo.Timed_Event_Details ted WITH(NOLOCK) 
		JOIN 		#PUList tpu						ON		ted.PU_ID		=		tpu.PUId 
		JOIN		dbo.Prod_Lines tpl						WITH(NOLOCK) 
													ON		tpu.PLId		=		tpl.PL_Id
		JOIN 		@tblDownMaxStartTime tms		ON		tpu.PUId		=		tms.PUId
		LEFT JOIN	dbo.Timed_Event_Fault tef				WITH(NOLOCK) 
													ON		ted.teFault_id	=		tef.teFault_id		
		LEFT JOIN	dbo.Prod_Units PU  WITH(NOLOCK) ON ted.source_pu_id = pu.pu_id
		LEFT JOIN	dbo.Event_Reasons er1 WITH(NOLOCK)  ON ted.Reason_level1 = er1.event_Reason_id	
		LEFT JOIN	dbo.Event_Reasons er2 WITH(NOLOCK)  ON ted.Reason_level2 = er2.event_Reason_id
		LEFT JOIN	dbo.Event_Reasons er3 WITH(NOLOCK)  ON ted.Reason_level3 = er3.event_Reason_id
		LEFT JOIN	dbo.Event_Reasons er4 WITH(NOLOCK)  ON ted.Reason_level4 = er4.event_Reason_id
		--
		LEFT JOIN	dbo.Event_Reasons ac1 WITH(NOLOCK)  ON ted.ActiON_level1 = ac1.event_Reason_id	
		LEFT JOIN	dbo.Event_Reasons ac2 WITH(NOLOCK)  ON ted.ActiON_level2 = ac2.event_Reason_id
		LEFT JOIN	dbo.Event_Reasons ac3 WITH(NOLOCK)  ON ted.ActiON_level3 = ac3.event_Reason_id
		LEFT JOIN	dbo.Event_Reasons ac4 WITH(NOLOCK)  ON ted.ActiON_level4 = ac4.event_Reason_id
        --
		LEFT Join   dbo.Comments c1 WITH(NOLOCK)  On ted.Cause_Comment_Id = c1.Comment_Id   -- Comment_Id	
		
		WHERE ted.Start_Time < tms.MaxEndTime
			AND ted.Start_Time >= tms.MaxStartTime 
			AND End_Time IS NOT NULL


	
		--------------------------------------------------------------------------------------------
		-- Print convert(varchar(25), GETDATE(), 120) + ' @Downtimes Comments Update for Version 4' 
		
		Update #Downtimes
							Set Comment = LEFT(CONVERT(varchar(1000),comment_text), 1000)
		FROM dbo.Comments c WITH(NOLOCK) 
		JOIN #Downtimes  d ON  c.Comment_Id = d.Comment_ID
		
		Update #Downtimes
						SET					Main_Comment = LEFT(CONVERT(varchar(1000),comment_text), 1000)
		FROM dbo.Comments c WITH(NOLOCK) 
		JOIN #Downtimes d ON  c.Comment_id = d.MainComment_ID


-- FRio : DELETE FROM @Downtimes all records with End_Time = NULL, (line down)
DELETE FROM #Downtimes WHERE End_Time IS NULL

--=================================================================================================
PRINT	'	- Split overlapping records '
---------------------------------------------------------------------------------------------------
--	Delay: Split overlapping shift records
---------------------------------------------------------------------------------------------------
UPDATE		dd
	SET		OverlapFlagShift 	= sl.CSId,
			OverlapSequence 	= 1,
			OverlapRcdFlag 		= 1,
			SplitFlagShift 		= 1
	FROM	#Downtimes 	dd
	JOIN	#ShiftList 		sl ON sl.PUId = dd.PU_Id
	WHERE	Start_Time 	< sl.ShiftStart
	AND		End_Time	> sl.ShiftStart
---------------------------------------------------------------------------------------------------
SET	@j = 1
---------------------------------------------------------------------------------------------------
PRINT 'Initial @j: ' + Convert(VarChar, @j)
---------------------------------------------------------------------------------------------------
WHILE	@j < 5000 
BEGIN
			Insert #Downtimes
			(	   		TedID,	PU_ID, PU_Desc,PL_ID,Line_Desc, Start_Time,End_Time, Fault_Code,Fault, Location,
						Reason1, 
						Reason1_code, 
						Reason2, 
						Reason2_code, 
						Reason3, 
						Reason3_code, 
						Reason4, 
						Reason4_code, 
						IsStops, 
						Dev_Comment,
						UserID,
						ActiON1_Code,
						ActiON1, 
						ActiON2_Code, 
						ActiON2, 
						ActiON3_Code, 
						ActiON3, 
						ActiON4_code, 
						ActiON4,
						OverlapFlagShift,		-- The overlap fields are used in the logic that split records
						OverlapFlagLineStatus,		-- accross shifts and line status boundaries. The fields are zeroed	
						OverlapSequence,					-- out after the record has been split
						OverlapRcdFlag)
			SELECT TedID, PU_ID,PU_Desc, PL_ID,Line_Desc, @EndTime, End_Time, Fault_Code,Fault,Location,
						Reason1, 
						Reason1_code, 
						Reason2, 
						Reason2_code, 
						Reason3, 
						Reason3_code, 
						Reason4, 
						Reason4_code,   
			            0,
						'DowntimeSplit',
						UserID,
						ActiON1_Code,
						ActiON1, 
						ActiON2_Code, 
						ActiON2, 
						ActiON3_Code, 
						ActiON3, 
						ActiON4_code, 
						ActiON4		,		
						OverlapFlagShift,
						2,
						1,
						1
			FROM	#Downtimes
			WHERE	OverlapFlagShift > 0
	----------------------------------------------------------------------------------------------
	UPDATE		dd
		SET		End_Time = sl.ShiftStart
		FROM	#Downtimes 	dd
		JOIN	#ShiftList 		sl 	ON 		sl.PUId = dd.PU_Id
									AND 	dd.OverlapFlagShift = sl.CSId
									AND		dd.OverlapSequence = 1
	----------------------------------------------------------------------------------------------
	UPDATE		dd
		SET		Start_Time 	= sl.ShiftStart,
				Shift 		= sl.ShiftDesc,
				Crew 		= sl.CrewDesc
		FROM	#Downtimes 	dd
		JOIN	#ShiftList 		sl 	ON 		sl.PUId = dd.PU_Id
									AND 	dd.OverlapFlagShift = sl.CSId
									AND		dd.OverlapSequence = 2
	----------------------------------------------------------------------------------------------
	UPDATE		dd
		SET		OverlapFlagShift 	= 0,
				OverlapSequence 	= 0
		FROM	#Downtimes dd
		WHERE	dd.OverlapFlagShift > 0
	----------------------------------------------------------------------------------------------
	UPDATE		dd
		SET		OverlapFlagShift	= sl.CSId,
				OverlapSequence 	= 1,
				SplitFlagShift 		= 1
		FROM	#Downtimes 	dd
		JOIN	#ShiftList 		sl ON sl.PUId = dd.PU_Id
		WHERE	Start_Time 	< sl.ShiftStart
		AND		End_Time 	> sl.ShiftStart
		AND		dd.OverlapRcdFlag = 1
	----------------------------------------------------------------------------------------------
	UPDATE		dd
		SET		OverlapRcdFlag = 0 
		FROM	#Downtimes dd
		WHERE	dd.OverlapFlagShift = 0
	----------------------------------------------------------------------------------------------
	IF	(	SELECT 	Count(OverlapFlagShift)
				FROM	#Downtimes
				WHERE OverlapFlagShift > 0) = 0
	BEGIN
		BREAK		
	END
	--
	SELECT	@j = @j + 1
END
---------------------------------------------------------------------------------------------------
PRINT 'Final @j: ' + Convert(VarChar, @j)
---------------------------------------------------------------------------------------------------
PRINT 'Find Line Status'
---------------------------------------------------------------------------------------------------
-- Delay: Find Line Status
---------------------------------------------------------------------------------------------------
UPDATE		dd
	SET		dd.LineStatusId 		=	ps.LineStatusId,
			dd.LineStatusSchedId	= 	ps.LineStatusSchedId
	FROM	#Downtimes dd
	JOIN	#LineStatusList ps ON dd.PU_Id = ps.PUId
	WHERE	Start_Time >= ps.LineStatusStart
	AND		(Start_Time < ps.LineStatusEnd OR ps.LineStatusEnd IS NULL)
---------------------------------------------------------------------------------------------------
PRINT 'Split Overlapping Line Status Records '
---------------------------------------------------------------------------------------------------
--	Delay: Split overlapping line status records
---------------------------------------------------------------------------------------------------
UPDATE		dd
	SET		OverlapFlagLineStatus	= sl.LineStatusSchedId,
			OverlapSequence 		= 1,
			OverlapRcdFlag 			= 1,
			SplitFlagLineStatus 	= 1
	FROM	#Downtimes 	dd
	JOIN	#LineStatusList sl ON sl.PUId = dd.PU_Id
	WHERE	Start_Time 	< sl.LineStatusStart
	AND		End_Time 	> sl.LineStatusStart
---------------------------------------------------------------------------------------------------
SET	@j = 1
---------------------------------------------------------------------------------------------------
PRINT 'Initial @j: ' + Convert(VarChar, @j)
---------------------------------------------------------------------------------------------------
WHILE	@j < 5000 
BEGIN
	INSERT INTO		#Downtimes (
				   		TedID,	PU_ID, PU_Desc,PL_ID,Line_Desc, Start_Time,End_Time, Fault_Code,Fault, Location,
						Reason1, 
						Reason1_code, 
						Reason2, 
						Reason2_code, 
						Reason3, 
						Reason3_code, 
						Reason4, 
						Reason4_code, 
						IsStops, 
						Dev_Comment,
						UserID,
						ActiON1_Code,
						ActiON1, 
						ActiON2_Code, 
						ActiON2, 
						ActiON3_Code, 
						ActiON3, 
						ActiON4_code, 
						ActiON4,
						OverlapFlagLineStatus,
						OverlapSequence,
						OverlapRcdFlag,
						SplitFlagLineStatus )
			SELECT TedID, PU_ID,PU_Desc, PL_ID,Line_Desc, @EndTime, End_Time, Fault_Code,Fault,Location,
						Reason1, 
						Reason1_code, 
						Reason2, 
						Reason2_code, 
						Reason3, 
						Reason3_code, 
						Reason4, 
						Reason4_code,   
			            0,
						'DowntimeSplit',
						UserID,
						ActiON1_Code,
						ActiON1, 
						ActiON2_Code, 
						ActiON2, 
						ActiON3_Code, 
						ActiON3, 
						ActiON4_code, 
						ActiON4		,	
					OverlapFlagLineStatus,
					2,
					1,
					1
			FROM	#Downtimes
			WHERE	OverlapFlagLineStatus > 0
	----------------------------------------------------------------------------
	UPDATE		dd
		SET		End_Time = sl.LineStatusStart
		FROM	#Downtimes dd
		JOIN	#LineStatusList sl 	ON 	sl.PUId = dd.PU_Id
									AND dd.OverlapFlagLineStatus = sl.LineStatusSchedId
									AND	dd.OverlapSequence = 1
	----------------------------------------------------------------------------
	UPDATE		dd
		SET		Start_Time 		= sl.LineStatusStart,
				LineStatusId 	= sl.LineStatusId
		FROM	#Downtimes dd
		JOIN	#LineStatusList sl 	ON 	sl.PUId = dd.PU_Id
									AND dd.OverlapFlagLineStatus = sl.LineStatusSchedId
									AND	dd.OverlapSequence = 2
	----------------------------------------------------------------------------
	UPDATE		dd
		SET		OverlapFlagLineStatus 	= 0,
				OverlapSequence 		= 0
		FROM	#Downtimes dd
		WHERE	dd.OverlapFlagLineStatus > 0
	----------------------------------------------------------------------------
	UPDATE		dd
		SET		OverlapFlagLineStatus 	= sl.LineStatusSchedId,
				OverlapSequence 		= 1,
				SplitFlagLineStatus 	= 1
		FROM	#Downtimes dd
		JOIN	#LineStatusList sl ON sl.PUId = dd.PU_Id
		WHERE	Start_Time 	< sl.LineStatusStart
		AND		End_Time 	> sl.LineStatusStart
		AND		dd.OverlapRcdFlag = 1
	----------------------------------------------------------------------------
	UPDATE		dd
		SET		OverlapRcdFlag = 0 
		FROM	#Downtimes dd
		WHERE	dd.OverlapFlagLineStatus = 0
	----------------------------------------------------------------------------
	IF	(	SELECT 		Count(OverlapFlagLineStatus)
				FROM	#Downtimes
				WHERE 	OverlapFlagLineStatus > 0) = 0
	BEGIN
		BREAK		
	END
	--
	SELECT	@j = @j + 1
END
---------------------------------------------------------------------------------------------------
PRINT 'Final @j: ' + Convert(VarChar, @j)
--=================================================================================================

---------------------------------------------------------------------------------------------------------------
--	Update #Production
----------------------------------------------------------------------------------------------------  
UPDATE #Downtimes  
	SET Crew = CS.Crew_Desc,   
		Shift = CS.Shift_Desc
	FROM #Downtimes		TPT  
	JOIN #PUList			TPL					ON tpt.Pu_ID = TPL.PuID  
	JOIN dbo.Crew_Schedule	cs	WITH(NOLOCK)	ON tpl.PuID = cs.PU_ID  
												AND tpt.End_Time > cs.Start_Time   
												AND (tpt.End_Time <= cs.End_Time or cs.End_Time IS null)  

---------------------------------------------------------------------------------------
-- Update Duration
-- 2016-6-24: changed the way to update the Crew/Shift/Line Status/Products 
---------------------------------------------------------------------------------------

Update TDT
	Set Duration = Str(DatedIff(ss, tdt.Start_Time, tdt.End_Time) / 60.000,12,3)
	From #Downtimes tdt
UPDATE tdt
SET 
		Crew = cs.Crew_Desc, 
		Shift = cs.Shift_Desc
From #Downtimes tdt
JOIN #PUList	pl		ON tdt.PL_id = pl.PLId
LEFT JOIN dbo.Crew_Schedule cs  WITH(NOLOCK) ON pl.PUId = cs.PU_ID
	AND tdt.End_Time > cs.Start_Time 
	AND (tdt.End_Time <= cs.End_Time or cs.End_Time IS null)

Update TDT
	Set	LineStatus = phr.Phrase_Value  
FROM #Downtimes tdt
JOIN #PUList	pl		ON tdt.PL_id = pl.PLId
LEFT JOIN dbo.Local_PG_Line_Status LPG WITH(NOLOCK) ON pl.PUId = lpg.Unit_ID
				AND tdt.End_Time > lpg.Start_DateTime 
				AND (tdt.End_Time <= lpg.End_DateTime or lpg.End_DateTime IS null)
LEFT JOIN dbo.Phrase phr WITH(NOLOCK) ON lpg.Line_Status_ID = phr.Phrase_ID

Update TDT
	Set	ProdDesc = P.ProdDesc
From #Downtimes tdt
JOIN #PUList	pl		ON tdt.PL_id = pl.PLId
LEFT JOIN @Products p	ON p.PUId = pl.PUId
							AND tdt.End_Time > p.StartTime 
							AND (tdt.End_Time <= p.EndTime or p.EndTime IS null)


-----------------------------------------------------------------------------------------------
--Print convert(varchar(25), GETDATE(), 120) + ' Calculating the Uptime column'

Insert Into @Temp_Uptime (id,pu_id,Start_Time,End_Time)
SELECT d1.id,d1.pu_id,MAX(d2.End_Time) as Start_Time,d1.Start_Time as End_Time
From #Downtimes d1
Join #Downtimes d2 on (d1.pu_id = d2.pu_id) and (d2.End_Time <= d1.Start_Time) and (d1.id <> d2.id)
Group By d1.id,d1.Start_Time,d1.pu_id

Update #Downtimes 
        Set Uptime = Str(IsNull(DatedIff(ss,t1.Start_Time,t1.End_Time) / 60.000,0),12,3) 
From #Downtimes d
Join @Temp_Uptime t1 on d.id = t1.id 

-----------------------------------------------------------------------------------------------	
Update #Downtimes
	Set Duration = 0 Where ISNULL(Dev_Comment, 'Blank') = 'NoStops'
-----------------------------------------------------------------------------------------------	

-----------------------------------------------------------------------------------------------
--Print convert(varchar(25), GETDATE(), 120) + ' Start getting the #History table'
-----------------------------------------------------------------------------------------------

INSERT INTO @Timed_Event_Detail_History
SELECT  Tedet_ID, User_ID
From dbo.Timed_Event_Detail_History  ted WITH(NOLOCK)
Join #Downtimes tdt on ted.TEDET_ID = tdt.TedID

-----------------------------------------------------------------------------------------------	
-- Delete From @Downtimes Where TedID IS NULL
-----------------------------------------------------------------------------------------------	
UPDATE #Downtimes
				Set IsStops = (SELECT Case	WHEN	Min(User_Id) < 50
										THEN	1
										WHEN	Min(User_Id) = @DowntimesystemUserID
										THEN	1
										ELSE	0
								END
								From @Timed_Event_Detail_History Where Tedet_Id = ted.TEDET_ID
								)
		From #Downtimes tdt
		Join @Timed_Event_Detail_History ted on tdt.TEDID = ted.TEDET_ID
		Where Dev_Comment Is NULL		

		Update #Downtimes
				Set IsStops = 1
		From #Downtimes tdt
		Join @Timed_Event_Detail_History tedh on tdt.TEDID = tedh.TEDET_ID
		Where tedh.User_ID = @DowntimesystemUserID
					And tdt.Duration <> 0
					And Dev_Comment Not Like '%DowntimeSplit'

-- END
-- FRio This is to remove innecessary splits
DELETE FROM #Downtimes WHERE Uptime < 0

-----------------------------------------------------------------------------------------------	
-- Update Product Information
-----------------------------------------------------------------------------------------------	
UPDATE	dt
	SET ProdId		=	p.Prod_Id,
		ProdCode	=	p.Prod_Code,
		ProdDesc	=	p.Prod_Desc,
		ProdFam		=	pf.Product_Family_Desc
FROM #Downtimes				dt
JOIN dbo.Production_Starts	ps	WITH(NOLOCK)
								ON ps.PU_Id = dt.PU_Id
								AND dt.Start_Time > ps.Start_Time 
								AND (dt.End_Time <= ps.End_Time OR ps.End_Time IS NULL)
JOIN dbo.Products			p	WITH(NOLOCK)
								ON ps.Prod_Id = p.Prod_Id
JOIN dbo.Product_Family		pf	WITH(NOLOCK)
								ON pf.Product_Family_Id = p.Product_Family_Id

UPDATE dt
	SET ProdGroup = (	SELECT TOP 1 Product_Grp_Desc
						FROM dbo.Product_Group_Data	pgd	WITH(NOLOCK)
						JOIN dbo.Product_Groups		pg	WITH(NOLOCK)
														ON pgd.Product_Grp_Id = pg.Product_Grp_Id
						WHERE pgd.Prod_Id = dt.ProdId	)
FROM #Downtimes	dt


UPDATE	dt
	SET ProcessOrder = pp.Process_Order
FROM #Downtimes					dt
JOIN dbo.Production_Plan_Starts	pps	WITH(NOLOCK)
									ON pps.PU_Id = dt.PU_Id
									AND dt.Start_Time > pps.Start_Time 
									AND (dt.End_Time <= pps.End_Time OR pps.End_Time IS NULL)
JOIN dbo.Production_Plan		pp	WITH(NOLOCK)
									ON pp.PP_Id = pps.PP_Id

-----------------------------------------------------------------------------------------------------------------	
PRINT 'UPDATE/TRANSFER DOWNTIME Records'
-----------------------------------------------------------------------------------------------------------------
DECLARE @Site VARCHAR(50)
SELECT  @Site = (SELECT sp.value FROM site_parameters sp 
				JOIN parameters pp ON pp.parm_id = sp.parm_id WHERE pp.parm_name = 'sitename')


SELECT 
				Start_Time			,
				End_Time			,
				dateadd(minute,datediff(minute,getdate(),getutcdate()),Start_time)	as Start_TimeUTC	,
				dateadd(minute,datediff(minute,getdate(),getutcdate()),End_time)	as End_TimeUTC		,
				Duration			,
				Uptime				,
				Fault				,
				Fault_Code			,
				Reason1				,
				Reason1_code		,
				Reason2				,
				Reason2_code		,
				Reason3				,
				Reason3_code		,
				Reason4				,
				Reason4_code		,
			    Action1				,
				Action1_code		,
				Action2				,
				Action2_code		,
				Action3				,
				Action3_code		,
				Action4				,
				Action4_code		,
				0 as Planned		,
				Location			,
			    ProdDesc			,
				ProdCode			,
				ProdFam				,
				ProdGroup			,	
				ProcessOrder		,	
				Crew as Team		,
				Shift				,
				LineStatus as Status, 
				IsStops as DTStatus	, 
				Comment_ID			,
				MainComment_ID		,
				Line_Desc			,
				PU_Desc				,
				PU_ID				,
				PL_ID				,
				0 as TransferFlag	,				
				0 as DeleteFlag		,
				@Site as Site		,
				TedID
FROM #DOWNTIMES ORDER BY LINE_DESC, START_TIME
-------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
--	DROP Temporay Tables
--------------------------------------------------------------------------------------------------------------------------------------------
DROP	TABLE		#Downtimes
DROP	TABLE		#PUList
DROP 	TABLE		#LineStatusList
DROP	TABLE		#ShiftList
--------------------------------------------------------------------------------------------------------------------------------------------



