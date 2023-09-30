

--======================================================================================================================= 
-------------------------------------------------------------------------------------------------------------------------
-- Local Stored Procedure: spLocal_NPTAdmin_Main
-------------------------------------------------------------------------------------------------------------------------
-- Author				: Martin Casalis - Arido Software
-- Date created			: 2020-04-06
-- Description			: This stored procedure will be called from a windows task every 5 minutes and checks if has to
--						  create or close a NPT based on the POs completed or activated
-- Editor tab spacing	: 4 
-------------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY: 
-------------------------------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			2020-04-06		Martin Casalis			Initial Release
--======================================================================================================================= 
-------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[spLocal_NPTAdmin_Main]
--DECLARE
	@POEnabled	BIT = 1
AS

--SET STATISTICS IO ON;
--SET STATISTICS TIME ON;
--SET @POEnabled = 0

DECLARE
         @StartTime				DATETIME
        ,@EndTime				DATETIME

DECLARE 
		 @Now					DATETIME
		,@5Minutes				DATETIME
		,@PathId				INT
		,@PPId					INT
		,@DefaultReasonId		INT
		,@PROutReasonId			INT
		,@ReasonId				INT
		,@NPTPlannedId			INT
        ,@Idx					INT
        ,@IdxMax				INT
		,@Username				NVARCHAR(255)
		,@DefaultReasonName		NVARCHAR(50)
		,@PROutReasonName		NVARCHAR(50)
		,@NPTTreeName			NVARCHAR(50)
		,@ValidNPTAdmin			NVARCHAR(50)
		,@NoSchedCrewName		NVARCHAR(50)
		
if OBJECT_ID('tempdb..#NonProductiveTime') IS NOT NULL	DROP TABLE #NonProductiveTime
CREATE TABLE #NonProductiveTime
        (RcdIdx					INT IDENTITY
		,PathId					INT
		,PPId					INT
		,ReasonId				INT
		,NPTPlannedId			INT
		,Username				NVARCHAR(255)
		,StartTime				DATETIME
		,EndTime				DATETIME)

-------------------------------------------------------------------------------------------------------------------------
SET @DefaultReasonName	= 'PR In: Line Normal'
SET @PROutReasonName	= 'PR Out: Line Not Staffed'
SET @NPTTreeName		= 'Non-Productive Time'
SET @ValidNPTAdmin		= 'validNPTAdmin'
SET @NoSchedCrewName	= 'NoSchedule'
SET @Now				= GETDATE()
SELECT @5Minutes		= DATEADD(MINUTE,-5,@Now)
-------------------------------------------------------------------------------------------------------------------------

SELECT	TOP 1
		@DefaultReasonId = er.Event_Reason_Id
FROM dbo.Event_Reasons					er		(NOLOCK)
JOIN dbo.Event_Reason_Tree_Data			ertd	(NOLOCK)	ON er.Event_Reason_Id = ertd.Event_Reason_Id
JOIN dbo.Event_Reason_Tree				ert		(NOLOCK)	ON ert.Tree_Name_Id = ertd.Tree_Name_Id
JOIN dbo.Event_Reason_Category_Data		ercd	(NOLOCK)	ON ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
JOIN dbo.Event_Reason_Catagories		erc		(NOLOCK)	ON ercd.ERC_ID = erc.ERC_ID
WHERE ert.Tree_Name = @NPTTreeName
AND erc.ERC_Desc = @ValidNPTAdmin
AND er.Event_Reason_Name LIKE @DefaultReasonName
ORDER BY er.Event_Reason_Id

SELECT	TOP 1
		@PROutReasonId = er.Event_Reason_Id
FROM dbo.Event_Reasons					er		(NOLOCK)
JOIN dbo.Event_Reason_Tree_Data			ertd	(NOLOCK)	ON er.Event_Reason_Id = ertd.Event_Reason_Id
JOIN dbo.Event_Reason_Tree				ert		(NOLOCK)	ON ert.Tree_Name_Id = ertd.Tree_Name_Id
JOIN dbo.Event_Reason_Category_Data		ercd	(NOLOCK)	ON ercd.Event_Reason_Tree_Data_Id = ertd.Event_Reason_Tree_Data_Id
JOIN dbo.Event_Reason_Catagories		erc		(NOLOCK)	ON ercd.ERC_ID = erc.ERC_ID
WHERE ert.Tree_Name = @NPTTreeName
AND erc.ERC_Desc = @ValidNPTAdmin
AND er.Event_Reason_Name LIKE @PROutReasonName
ORDER BY er.Event_Reason_Id
-------------------------------------------------------------------------------------------------------------------------

IF @POEnabled = 1
BEGIN
		INSERT INTO #NonProductiveTime
				(PathId
				,PPId
				,ReasonId
				,NPTPlannedId
				,Username		)
		SELECT DISTINCT
				pp.[Path_Id]
				,pp.[PP_Id]
				,ISNULL(npt.[Event_Reason_Id],@DefaultReasonId)
				,npt.NPTPlanned_Id
				,ISNULL(u.Username,'EventMgr')
		FROM 	dbo.PrdExec_Path_Units				ppu     (NOLOCK)
		JOIN	dbo.Production_Plan_Starts			pps		(NOLOCK)	ON pps.PU_Id = ppu.PU_Id
																		AND ppu.Is_Schedule_Point = 1
																		AND pps.Start_Time > DATEADD(DAY,-7,@Now)
																		AND (pps.End_Time > DATEADD(DAY,-7,@Now) OR End_Time IS NULL)
																		AND (pps.Start_Time >= @5Minutes
																			OR pps.End_Time >= @5Minutes
																			OR pps.Start_Time > ISNULL((SELECT MAX(Start_Time)
																											FROM dbo.NonProductive_Detail npt (NOLOCK)
																											WHERE npt.PU_Id = pps.PU_Id
																											AND Start_Time < @now
																											AND Start_Time > DATEADD(DAY,-7,@Now)),@5Minutes)
																			OR pps.End_Time > ISNULL((SELECT MAX(End_Time)
																											FROM dbo.NonProductive_Detail npt (NOLOCK)
																											WHERE npt.PU_Id = pps.PU_Id
																											AND End_Time < @now
																											AND End_Time > DATEADD(DAY,-7,@Now)),@5Minutes))
		JOIN	dbo.Production_Plan					pp		(NOLOCK)	ON pp.PP_Id = pps.PP_Id
																		AND pp.Path_Id = ppu.Path_Id
		LEFT JOIN dbo.NPTAdmin_NPTPlanned			npt		(NOLOCK)	ON npt.Path_Id = pp.Path_Id
																		AND npt.PP_Id = pp.PP_Id
																		AND npt.NPTPlanned_Id = ISNULL((SELECT TOP 1 NPTPlanned_Id
																										FROM NPTAdmin_NPTPlanned npt1
																										WHERE npt1.PP_Id = npt.PP_Id
																										ORDER BY Modified_On DESC),npt.NPTPlanned_Id)
		LEFT JOIN dbo.Users_Base					u		(NOLOCK)	ON u.[User_Id] = npt.[User_Id]
END
	
INSERT INTO #NonProductiveTime
		(PathId
		,ReasonId
		,Username			
		,StartTime	
		,EndTime)
SELECT 
		ppu.[Path_Id]
		,ISNULL(@PROutReasonId,@DefaultReasonId)
		,'EventMgr'
		,cs.Start_Time
		,cs.End_Time
FROM 	dbo.PrdExec_Path_Units		ppu     (NOLOCK)
JOIN	dbo.Crew_Schedule			cs		(NOLOCK)	ON cs.PU_Id = ppu.PU_Id
														AND ppu.Is_Schedule_Point = 1
														AND cs.Start_Time > DATEADD(DAY,-7,@Now)
														AND cs.End_Time > DATEADD(DAY,-7,@Now)
														AND ((cs.Start_Time BETWEEN @5Minutes AND @Now)
															OR (cs.Start_Time > ISNULL((SELECT MAX(Start_Time)
																							FROM dbo.NonProductive_Detail npt (NOLOCK)
																							WHERE npt.PU_Id = cs.PU_Id
																							AND Start_Time < @now
																							AND Start_Time > DATEADD(DAY,-7,@Now)),@5Minutes)
																	AND cs.Start_Time < @Now))
WHERE cs.Crew_Desc LIKE @NoSchedCrewName

-------------------------------------------------------------------------------------------------------------------------

SET @idx = 1
SELECT @idxMax = COUNT(*) FROM #NonProductiveTime

WHILE @idx <= @idxMax
BEGIN	
		SELECT	
				 @PathId		= PathId	
				,@PPId			= PPId		
				,@ReasonId		= ReasonId	
				,@NPTPlannedId	= NPTPlannedId
				,@Username		= Username	
				,@StartTime		= StartTime
				,@EndTime		= EndTime
		FROM 
				#NonProductiveTime
		WHERE 
				RcdIdx = @idx
	
 		BEGIN TRY 
			EXEC dbo.spLocal_NPTAdmin_AddNPT
 								 @NPTDetId		=	NULL	
 								,@PPId			=	@PPId
 								,@PathId		=	@PathId
 								,@ReasonId		=	@ReasonId
 								,@Username		=	@Username
 								,@NPTPlannedId	=	@NPTPlannedId
 								,@POType		=	'Actual'
 								,@StartTime		=	@StartTime
 								,@EndTime		=	@EndTime
		END TRY 
		BEGIN CATCH 
		END CATCH  

		SET @idx = @idx + 1
END

-------------------------------------------------------------------------------------------------------------------------
if OBJECT_ID('tempdb..#NonProductiveTime') IS NOT NULL	DROP TABLE #NonProductiveTime

-------------------------------------------------------------------------------------------------------------------------
GRANT EXECUTE ON spLocal_NPTAdmin_Main TO opdbmanager
