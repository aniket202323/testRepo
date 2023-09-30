
-----------------------------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_CmnRptGetPR
-----------------------------------------------------------------------------------------------------------------------
-- Author				: Arido Software
-- Date created			: 2016-06-01
-- Version 				: 1.0
-- SP Type				: Report Stored Procedure
-- Caller				: Report
-- Description			: This stored procedure provides the data for PR.
-- Editor tab spacing	: 4 
-- --------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- --------------------------------------------------------------------------------------------------------------------
-- ========	====	  		====					=====
-- 1.0		2016-06-01		Arido Software     		Initial Release
-- ======== ====			====					=====
CREATE PROCEDURE [dbo].[spLocal_CmnRptGetPR]
--DECLARE	
		@dtmStartTime			DATETIME		,
		@dtmEndTime				DATETIME		,
		@strWorkCellId			NVARCHAR(MAX)

--SELECT
--	@dtmStartTime				= '2016-06-06 06:30'		,
--	@dtmEndTime					= '2016-06-07 06:30'		,
--	@strWorkCellId				= '317,345,373,401,3866,3757'--,345,205,401,177,149,1363,1391,373,1335'

AS
SET NOCOUNT ON
---------------------------------------------------------------------------------------------------	
DECLARE	@ProductionPlan	TABLE (
		TimeSliceId					INT	Identity(1, 1),
		PPId						INT				,
		DeptId						INT				,
		PLId						INT				,
		PUId						INT				,
		ProdId						INT				,
		ProdCode					NVARCHAR(50)	,  
		ProdDesc					NVARCHAR(100)	,  
		Volume						FLOAT			,
		FinishedQuantity			FLOAT			,
		FQFromFunction				FLOAT			,
		BadQuantity					FLOAT			,
		MaterialClassId				UNIQUEIDENTIFIER,
		TargetRateId				INT				,
		ActualRate					FLOAT			,
		TargetRate					FLOAT			,
		StatFactorId				INT				,
		StatFactor					FLOAT			,
		TimeSliceStart				DATETIME		,
		TimeSliceEnd				DATETIME		,
		ActivePathId				INT				,
		TimeWindow					NVARCHAR(100)	
		)	
---------------------------------------------------------------------------------------------------
DECLARE @WorkCellList TABLE	(
		RcdId						INT IDENTITY	,
		EquipmentId					UNIQUEIDENTIFIER,
		SKEqId						INT				,
		PLId						INT				,
		PLDesc						VARCHAR(100)	,
		WCId						INT				,
		PUId						INT				,
		FLDEsc						VARCHAR(100)	,
		WCDesc						VARCHAR(100)	,
		NPT							INT				,
		IsSchedule					INT				)
---------------------------------------------------------------------------------------------------
DECLARE @ResultTable TABLE (
		ID							INT IDENTITY	,
		WorkCellId				INT				,
		WorkCell					NVARCHAR(200)	,
		ScheduledTime				FLOAT			,
		TargetRate					FLOAT			,
		NetProductionTime			FLOAT			,
		ProcessReliability			FLOAT			)
CREATE TABLE #WasteDetailHistory (
		RcId						INT IDENTITY,
		--Detail_History_Id			INT			,
		WEDId						INT			,
		WEMTId						INT			,
		WETId						INT			,
		EquipmentId					VARCHAR(100),
		ValueStream					NVARCHAR(255),
		DeptId						INT			,
		DeptDesc					NVARCHAR(255),
		PUId						INT			,		
		PUDesc						VARCHAR(100),
		PLId						INT			,		
		PLDesc						VARCHAR(100),
		Source_PUId					INT			,
		Event_id					INT			,
		Location					VARCHAR(100),
		EquipmentArea				VARCHAR(100),
		PEEngUnits					NVARCHAR(100),
		UOM							NVARCHAR(100),
		Conversion					FLOAT DEFAULT 1	,
		ScrapType					NVARCHAR(100),
		WEFaultId					INT			,	
		WEFaultValue				VARCHAR(100),
		FLDesc						VARCHAR(100),
		RejectTimeStamp				DATETIME	,
		UserId						INT			,
		Username					NVARCHAR(50),
		Entry_On					DATETIME	,
		Modified_On					DATETIME	,
		RejectAmount				INT			,
		CauseCommentId				INT			,
		SummaryCauseCommentId		INT		,
		CommentIdList				VARCHAR(1000),
		DelayRL1Id					INT			,
		DelayRL2Id					INT			,
		DelayRL3Id					INT			,
		DelayRL4Id					INT			,
		EventReasonName1			VARCHAR(100),
		EventReasonName2			VARCHAR(100),
		EventReasonName3			VARCHAR(100),
		EventReasonName4			VARCHAR(100),
		ShiftDesc					VARCHAR(50)	,
		CrewDesc					VARCHAR(50)	,
		ProductionDay				DATETIME	,
		ProdStatus					VARCHAR(50)	,
		ProdId						INT			,
		ProdCode					VARCHAR(50)	,
		ProdDesc					VARCHAR(200),
		ExecPath					VARCHAR(100),
		EventId						INT,
		PPId						INT,
		DiffRejectAmount			INT			,
		DBTT						VARCHAR(25)	,
		ConstraintWorkCell			INT			,
		ProductionWorkCell			INT	)
		
CREATE NONCLUSTERED INDEX ScrapDetailsWEDIdPUIdTimeStamp_Idx                                               
ON #WasteDetailHistory (WEDId, PUId, RejectTimeStamp)  		
--=================================================================================================	
-- Constants:
--=================================================================================================		
DECLARE
		@vchTgtRateSpec				NVARCHAR(200)
-----------------------------------------------------------------------------------------------------	
---- Constants for Specifications:	
SET		@vchTgtRateSpec				= 'Target Rate'


---------------------------------------------------------------------------------------------------
-- Step 1. Gather the Production Units
---------------------------------------------------------------------------------------------------
INSERT  @WorkCellList (PUId)
SELECT Value FROM fnLocal_CmnParseListLong(@strWorkCellId,',')

UPDATE wc
	SET	WCDesc	= pu.PU_Desc	,
		PLId	= pl.PL_Id		,
		PLDesc	= pl.PL_Desc 
FROM @WorkCellList	wc
JOIN dbo.Prod_Units pu WITH(NOLOCK) ON pu.PU_Id = wc.PUId
JOIN dbo.Prod_Lines pl WITH(NOLOCK) ON pl.PL_Id = pu.PL_Id

---------------------------------------------------------------------------------------------------
-- Step 2 - Start building Production Plan table
---------------------------------------------------------------------------------------------------
INSERT INTO	@ProductionPlan	(
						PLId				,
						PUId				,
						ProdId				,
						TimeSliceStart		,
						TimeSliceEnd		,
						ActivePathId		,
						PPId				,
						BadQuantity			,
						 TimeWindow		
						)
SELECT	DISTINCT
						wc.PLId,
						wc.PUId,
						pp.Prod_Id,
						ps.Start_Time,
						ISNULL(ps.End_Time, CONVERT(DATETIME, GETDATE())),
						pp.Path_Id	,
						pp.PP_Id	,
						CASE WHEN pp.Actual_Good_Quantity < 0 THEN 0 ELSE pp.Actual_Good_Quantity END,
						--CASE WHEN pp.Actual_Bad_Quantity < 0 THEN 0 ELSE pp.Actual_Bad_Quantity END ,
						CASE WHEN ps.Start_Time < CONVERT(DATETIME, @dtmStartTime) 
									OR ps.End_Time > CONVERT(DATETIME, @dtmEndTime)
									OR ps.End_Time IS NULL 
							THEN 'Partial' ELSE 'Complete' END
FROM	dbo.Production_Plan_Starts						ps		WITH(NOLOCK)	
JOIN    dbo.Production_Plan								pp		WITH(NOLOCK)	ON ps.PP_Id = pp.PP_Id 
JOIN	@WorkCellList									wc						ON wc.PUId = ps.PU_Id
JOIN	dbo.Prod_Units									pu		WITH(NOLOCK)	ON wc.PUId = pu.PU_Id
WHERE	ps.Start_Time <= @dtmEndTime
		AND	(ps.End_Time > @dtmStartTime
		OR	ps.End_Time IS NULL)

---------------------------------------------------------------------------------------------------
-- Step 3 - Bad quantity from scrap history
-----------------------------------------------------------------------------------------------------------------
INSERT INTO #WasteDetailHistory(
						WEDID						,
						--WED_Id					,
						EventId						,
						PPId						,
						RejectTimeStamp				,
						RejectAmount				,
						UOM							,
						ValueStream					,
						DeptDesc					,
						PLDesc						,
						PUDesc						,
						WEFaultValue				,
						Location					,
						EquipmentArea				,
						FLDesc						,
						EventReasonName1			,
						EventReasonName2			,
						EventReasonName3			,
						EventReasonName4			,
						CommentIdList				,
						ShiftDesc					,
						CrewDesc					,
						ProductionDay				,
						--ProdDay					,
						ProdStatus					,
						ProdCode					,
						ProdDesc					,
						ExecPath					)
			EXEC dbo.spLocal_CmnRptScrapHistory
						@strWorkCellId				,
						'UserDefined'				,
						@dtmStartTime				,
						@dtmEndTime					,
						'Yes'						,
						''							,
						''		

						
			UPDATE		wd	
				SET		PLId = wc.PLId				,
						PUId = wc.PUId				
			FROM		#WasteDetailHistory				wd	
			JOIN		@WorkCellList				wc	ON wc.PUId = wd.PUId


----------------------------------------------------------------------------------------------------------------
-- Step 4 - Target Speed
-----------------------------------------------------------------------------------------------------------------
UPDATE pp
	SET TargetRateId	= vs.VS_Id,
		TargetRate		= CONVERT(FLOAT,vs.Target)
FROM dbo.Var_Specs			vs	WITH(NOLOCK)
JOIN @ProductionPlan		pp	ON pp.ProdId = vs.Prod_Id
JOIN dbo.Variables			v	WITH(NOLOCK)
								ON v.PU_Id = pp.PUId 
								AND v.var_id = vs.var_id 
WHERE v.Var_Desc = @vchTgtRateSpec 
AND pp.TimeSliceStart >= vs.Effective_Date AND (pp.TimeSliceStart < vs.Expiration_Date 
												OR vs.expiration_Date IS NULL)

-- Update Start and End Time outside of report timewindow 
-----------------------------------------------------------------------------------------------------------------
UPDATE @ProductionPlan
SET TimeSliceStart	=	CASE	WHEN	TimeSliceStart < CONVERT(DATETIME, @dtmStartTime)
								THEN	@dtmStartTime
								ELSE	TimeSliceStart
								END, 
	TimeSliceEnd	=	CASE	WHEN	TimeSliceEnd > CONVERT(DATETIME, @dtmEndTime)
								THEN	@dtmEndTime
								ELSE	COALESCE(TimeSliceEnd, @dtmEndTime)
								END

-----------------------------------------------------------------------------------------------------------------
 --Step 5 - Net Production
-----------------------------------------------------------------------------------------------------------------
UPDATE pp
		SET Volume = (SELECT dbo.fnLocal_CmnRptVolumeDailyReport (pp.PUId,pp.TimeSliceStart,pp.TimeSliceEnd,'No'))
FROM @ProductionPlan pp
--WHERE TimeWindow = 'Partial'

--
INSERT INTO @ResultTable (
			WorkCellId		,
			WorkCell			)
	SELECT	PUId				,
			WCDesc
	FROM	@WorkCellList

-----------------------------------------------------------------------------------------------------------------
-- Get Scrap for Partial time slices
UPDATE pp
	SET pp.BadQuantity = ISNULL((SELECT SUM(ISNULL(wd.RejectAmount,0)) 
							FROM #WasteDetailHistory wd
								WHERE wd.PPId = pp.PPId),0)
FROM @ProductionPlan pp

-- Net Production
UPDATE pp
		SET pp.FinishedQuantity = pp.Volume - pp.BadQuantity
FROM @ProductionPlan pp



-- Target Rate
-----------------------------------------------------------------------------------------------------------------
UPDATE	wc
	SET TargetRate = (SELECT SUM(pp.FinishedQuantity)/SUM(pp.FinishedQuantity/pp.TargetRate)
							FROM @ProductionPlan	pp
							WHERE wc.WorkCellId = pp.PUId		
							AND pp.FinishedQuantity <> 0
							AND pp.TargetRate <> 0 )
FROM	@ResultTable wc	

-- Net Production Time
-----------------------------------------------------------------------------------------------------------------
UPDATE	wc
	SET NetProductionTime = ISNULL((SELECT SUM(FinishedQuantity / TargetRate)
							FROM @ProductionPlan	pp
							WHERE wc.WorkCellId = pp.PUId		
							AND pp.TargetRate IS NOT NULL AND pp.TargetRate <> 0),0)
FROM	@ResultTable wc

-- Scheduled Time
-----------------------------------------------------------------------------------------------------------------
UPDATE	wc
	SET ScheduledTime = ISNULL(DATEDIFF(mi,@dtmStartTime,@dtmEndTime), 0) - ISNULL(dbo.fnLocal_GetNonProductionTime(@dtmStartTime,@dtmEndTime,wc.WorkCellId),0)
FROM	@ResultTable wc


----------------------------------------------------------------------------------------------------------------------------------------
-- Step 6 - Process Reliability Calculation
----------------------------------------------------------------------------------------------------------------------------------------

UPDATE wc
	SET ProcessReliability	=	CASE	WHEN	(ScheduledTime = 0 OR ScheduledTime IS NULL)
										THEN	0 
										ELSE	NetProductionTime / ScheduledTime 
										END
FROM	@ResultTable wc	

---------------------------------------------------------------------------------------------------
-- Output
---------------------------------------------------------------------------------------------------
ReturnData:

SELECT	WorkCellId,
		ProcessReliability * 100 AS 'PR'
FROM	@ResultTable

CleanUp:
DROP TABLE #WasteDetailHistory
---------------------------------------------------------------------------------------------------
--SELECT '@WorkCellList',* FROM @WorkCellList
--SELECT '@ProductionPlan',* FROM @ProductionPlan ORDER BY ppid
--SELECT '@ResultTable',WorkCellId,ProcessReliability,* FROM @ResultTable
---------------------------------------------------------------------------------------------------
SET NOCOUNT OFF
