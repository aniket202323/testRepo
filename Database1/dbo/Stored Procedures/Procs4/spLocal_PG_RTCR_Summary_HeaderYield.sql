
CREATE   PROCEDURE  [dbo].[spLocal_PG_RTCR_Summary_HeaderYield]
--DECLARE
	@p_StartTime			DATETIME							, -- Starttime selected from user
	@p_EndTime				DATETIME							, -- Endtime selected from user
	@p_LineName				VARCHAR(255)						
	
AS
SET	NOCOUNT	ON	
				
--SET @p_LineName		=	'KWT'
--SET @p_StartTime	=	'2017-08-15 10:24:38.000'
--SET @p_EndTime		=	'2017-10-02 10:24:38.000'

--=================================================================================================
DECLARE	@tOutput table	(	
	HRName		VARCHAR(255)	,
	TestHasFail	INT				,
	MajorGroup	VARCHAR(255)	,
	MinorGroup	VARCHAR(255)
)

DECLARE	@pOutput	table	(
	TestName		VARCHAR(255)	,
	BatchYield		DECIMAL(18,2)	,
	BatchYieldState	INT			,
	MajorGroup		VARCHAR(255)	,
	MinorGroup		VARCHAR(255)
)
------------------------------------------------------------------------------------------------------
	SET @p_LineName='%' + @p_LineName +'%'

	IF @p_LineName IS NULL OR @p_LineName = ''
	BEGIN
		SELECT ''
		RETURN
	END
	
	IF OBJECT_ID('tempdb..#B') IS NOT NULL
    DROP TABLE #B;
    
	 SELECT * INTO #B
		FROM (SELECT ROW_NUMBER() OVER (ORDER BY vbr1.CampaignID, vbr1.TaskCount)
					AS R,vbr1.CampaignID,RecipeID,vbr1.TaskCount
				FROM		dbo.View_BatchReport1	AS	vbr1	WITH(NOLOCK)
				INNER JOIN	dbo.View_BatchTime		AS	vbt		WITH(NOLOCK)
				ON			vbr1.CampaignID = vbt.CampaignID	
			   WHERE 1=1 
				AND (@p_LineName IS NULL 
				OR	(	vbr1.RecipeName LIKE @p_LineName 
					AND	vbt.BatchStartTime	>=	@p_StartTime
					AND	vbt.BatchEndTime	<	@p_EndTime
					)
				)) AS T
		ORDER BY T.R DESC;
           
	IF OBJECT_ID('tempdb..#A') IS NOT NULL
		DROP TABLE #A;

	SELECT *
		INTO #A
		FROM [dbo].[View_BatchReport2Tbl] WITH(NOLOCK)
		WHERE (CampaignID IN (SELECT CampaignID FROM #B))
			AND (RecipeID IN (SELECT RecipeID FROM #B))
			AND (TaskCount IN (SELECT TaskCount FROM #B)); 
			
	IF OBJECT_ID('tempdb..#BatchData') IS NOT NULL
		DROP TABLE #BatchData;

	SELECT  * INTO #BatchData FROM (
		SELECT ROW_NUMBER() OVER(ORDER BY View_BatchReport1.CampaignID,View_BatchReport1.TaskCount) AS R, View_BatchReport1.CampaignID,View_BatchReport1.RecipeID,
			View_BatchReport1.RecipeName,View_BatchReport1.StartDate,
			View_BatchReport1.StartTime,View_BatchReport1.OperationTeam,
			View_BatchReport1.Operator,View_BatchReport1.BatchSize,
			View_BatchReport1.TaskCount,View_BatchReport1.RecipeGroupName,
			View_BatchReport1.GroupID,View_BatchTime.BatchStartTime,
			View_BatchTime.BatchEndTime,View_BatchReport1.BatchScale
		FROM dbo.View_BatchReport1 AS View_BatchReport1
			INNER JOIN dbo.View_BatchTime AS View_BatchTime
			ON View_BatchReport1.CampaignID = View_BatchTime.CampaignID
			   AND View_BatchReport1.TaskCount = View_BatchTime.TaskCount
			   --WHERE RecipeName LIKE '%kwt%'
			   WHERE 1=1 
				AND (	@p_LineName IS NULL 
					OR	(	View_BatchReport1.RecipeName LIKE @p_LineName 
						AND	View_BatchTime.BatchStartTime	>=	@p_StartTime
						AND	View_BatchTime.BatchEndTime	<	@p_EndTime
						)
					)

			   ) AS T ORDER BY T.R DESC

INSERT INTO	@pOutput	
(
	TestName	,
	BatchYield	,
	MajorGroup	,
	MinorGroup
)
SELECT	DISTINCT 
		'Batch Yield'	,
		ROUND((SELECT SUM(CONVERT(DECIMAL(18,2),Value)) FROM dbo.RTCR_BatchDetails WHERE TestName NOT IN ('NaCl_Dos','POD_Dos','Amoni_Dos','PPG_Dos') and ISNUMERIC(Value)=1 and BatchNumber=CONVERT(VARCHAR(10),bd.CampaignID)+CONVERT(VARCHAR(10),bd.TaskCount))*100/2000,2)	,
		'Making'	,
		'Batch''s'
FROM		#A			a
INNER JOIN	#BatchData	bd	ON	bd.CampaignID	=	a.CampaignId
							AND	bd.TaskCount	=	a.TaskCount
							AND	bd.RecipeId		=	a.RecipeId

UPDATE @pOutput SET BatchYieldState=CASE WHEN BatchYield BETWEEN 99 AND 101 THEN 0 ELSE 1 END

INSERT	INTO	@tOutput
(
	HRName		,
	TestHasFail	,
	MajorGroup	,
	MinorGroup
)

SELECT	DISTINCT	p.TestName												,
					CASE WHEN MIN(BatchYieldState) = 0	THEN 1 ELSE 0 END	,
					'Making'												,
					'Batch''s'
FROM				@pOutput	p
GROUP BY			p.TestName

SELECT * FROM @tOutput
	
SET NOCOUNT OFF
    
RETURN
