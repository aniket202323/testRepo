
CREATE   PROCEDURE  [dbo].[spLocal_PG_RTCR_BatchesYield]	
	@p_ProdLine				VARCHAR(255)		= NULL			, -- Line selected from user
	@p_StartTime			DATETIME							, -- Starttime selected from user
	@p_EndTime				DATETIME							  -- Endtime selected from user 
/*
SET @p_ProdLine		=	'KWT'
SET @p_StartTime	=	'2017-08-15 10:24:38.000'
SET @p_EndTime		=	'2017-10-02 10:24:38.000'
*/

AS
SET	NOCOUNT	ON
----=================================================================================================

--SET NOCOUNT ON
--=================================================================================================
DECLARE	@tOutput table	(
		BatchNumber							VARCHAR(255)	,
		PassCheck							VARCHAR(50)		, --Fail if any test on that batch failed, a Pass if all the tests passed for that batch
		ProductSKU							VARCHAR(100)	,
		StartTime							DATETIME		, 
		[Timestamp]							DATETIME		,
		PO_Number							VARCHAR(255)	,
		BatchYield							DECIMAL(18,2),
		BatchYieldState							VARCHAR(50)
)
---------------------------------------------------------------------------------------------------

--SET NOCOUNT OFF

	/*
		Actual code here that will populate @tOutput with  Batches that occured withing the time inteval on the corresponding to the @p_ProdLine Parameter,
		return a result of 0 if any test on that batch failed or a 1 if all the tests passed for that batch.
	*/

	--================================================================================================
	



EXEC dbo.spLocal_PG_RTCR_BatchDetails 
	@p_StartTime = @p_StartTime, -- datetime
    @p_EndTime =@p_EndTime, -- datetime
    @p_TestName = '', -- varchar(255)
    @p_ProdLine =@p_ProdLine, -- varchar(255)
    @p_PO = '' -- varchar(255)
        ,@DontShowOutput=1

	SET @p_ProdLine='%' + @p_ProdLine +'%'

		IF OBJECT_ID('tempdb..#BatchData') IS NOT NULL
			DROP TABLE #BatchData;
    
	
		SELECT  * INTO #BatchData FROM (
		SELECT ROW_NUMBER() OVER(ORDER BY View_BatchReport1.CampaignID,View_BatchReport1.TaskCount) AS R, View_BatchReport1.CampaignID,View_BatchReport1.RecipeID,
			View_BatchReport1.RecipeName,View_BatchReport1.StartDate,
			View_BatchReport1.StartTime,View_BatchReport1.OperationTeam,
			View_BatchReport1.Operator,View_BatchReport1.BatchSize,
			View_BatchReport1.TaskCount,View_BatchReport1.RecipeGroupName,
			View_BatchReport1.GroupID,View_BatchTime.BatchStartTime,
			View_BatchTime.BatchEndTime,View_BatchReport1.BatchScale,'' AS PO
		FROM dbo.View_BatchReport1 AS View_BatchReport1 WITH(NOLOCK)
			INNER JOIN dbo.View_BatchTime AS View_BatchTime WITH(NOLOCK)
			ON View_BatchReport1.CampaignID = View_BatchTime.CampaignID
			   AND View_BatchReport1.TaskCount = View_BatchTime.TaskCount
			   WHERE 1=1 
				AND (@p_ProdLine IS NULL OR (RecipeName LIKE @p_ProdLine AND CONVERT(DATETIME,StartDate+' ' + StartTime) BETWEEN @p_StartTime AND @p_EndTime))
				--AND (@BatchNumber IS NULL OR (@BatchNumber=@BatchNumber))--TODO Fix after Artoro
					
			   ) AS T ORDER BY T.R DESC
	
    
			INSERT INTO @tOutput (BatchNumber,PassCheck,ProductSKU,StartTime,Timestamp,BatchYield)
			SELECT CONVERT(VARCHAR(10),CampaignID)+CONVERT(VARCHAR(10),TaskCount),
			CASE WHEN (SELECT COUNT(0) FROM dbo.RTCR_BatchDetails WHERE PassCheck='0' AND BatchNumber=CONVERT(VARCHAR(10),CampaignID)+CONVERT(VARCHAR(10),TaskCount))
						>0 THEN 'Fail' ELSE 'Pass' END	
			,RecipeName,BatchStartTime,BatchStartTime
			,ROUND(
				 (SELECT SUM(CONVERT(DECIMAL(18,2),Value)) FROM dbo.RTCR_BatchDetails WHERE TestName NOT IN ('NaCl_Dos','POD_Dos','Amoni_Dos','PPG_Dos') and ISNUMERIC(Value)=1 and BatchNumber=CONVERT(VARCHAR(10),CampaignID)+CONVERT(VARCHAR(10),TaskCount))
					*100/2000
					,2)
			 FROM #BatchData
 --NaOH_Dos
 
	--================================================================================================
--SELECT * FROM #BatchData

UPDATE @tOutput SET BatchYieldState=CASE WHEN BatchYield BETWEEN 99 AND 101 THEN 'Pass' ELSE 'Failed' END WHERE 1=1
		SELECT  	
			BatchNumber							,
			ProductSKU							,
			[Timestamp]							,
			BatchYieldState	AS	'Pass Check'	,
			PO_Number
		FROM	@tOutput	
RETURN