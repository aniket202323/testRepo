


-- ====================================================================================================================
-- Author:		Fran Osorno
-- Create date: 2015-08-17
-- Description:	return data for downtime bucket chart
-- ====================================================================================================================
-- --------------------------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
-- --------------------------------------------------------------------------------------------------------------------
-- =====	====	  		====				=====
-- 1.0		2015-08-17		Fran Osorno		 	Initial Release
-- 1.0		2015-08-18		Dave Molenda(GE)	Added Hourly Results
-- 1.0		2015-08-18		Dave Molenda(GE)	Added Scrap as an Option
-- 1.1		2015-09-08		Fran Osorno			corected grant mistake Fran Made
-- Release 1.4 version 1.3
--			2016-07-18		Fran Osorno			for CR FO-02547 to remove 0's from the Scrap returned results set
CREATE PROCEDURE [dbo].[spLocal_CmnFlexDowntimeDetailByEquipment]
--DECLARE
		@strWorkCellId			NVARCHAR(MAX)	,
		@ReportWindow			VARCHAR(50),
		@Stops_Or_Scrap			VARCHAR(50)
/*
SELECT
		@strWorkCellId		= '317',
		@ReportWindow		= 'CurrentShift'
*/
AS			

DECLARE
		@strAreaId				NVARCHAR(200)	,
		@strProdLineId			NVARCHAR(800)	,
		@vchTimeOption			NVARCHAR(50)		,		-- Time Option 
		@dtmStartDateTime		DATETIME		,		-- Start Time of the Report
		@dtmEndDateTime			DATETIME,				-- End Time of the Report
		@vchSplitLogicalRcd		NVARCHAR(20)		,
		@vchExcludeNPT			NVARCHAR(3),
		@ReportTime				DATETIME,
		@WPUID					INT,
		@ShiftEnd				DATETIME,
		@StartHourIterator		DATETIME,
		@EndHourIterator		DATETIME,
		@EndShift				DATETIME,
		@ShiftHourCount			INT,
		@CurrentScrapAmt		FLOAT
		
CREATE TABLE #DownTimeINT (	ShiftStart			datetime DEFAULT NULL,
							ShiftEnd			datetime DEFAULT NULL,
							ReportWindowEnd		datetime DEFAULT NULL,
							PUDESC				varchar(250) DEFAULT NULL,
							DowntimeStart		datetime DEFAULT NULL,
							DowntimeEnd			datetime DEFAULT NULL,
							Downtime			float DEFAULT 0.0,
							ProdStatus			varchar(250) DEFAULT NULL,
							SplitEventFlag		varchar(250) DEFAULT NULL) 
							
CREATE TABLE #DownTimeCOUNT (	ShiftStart			int DEFAULT NULL,
								DowntimeCount			int DEFAULT NULL) 

CREATE TABLE #SCRAPTimeINT (
								ShiftStart			datetime DEFAULT NULL,
								ShiftEnd			datetime DEFAULT NULL,
								ReportWindowEnd		datetime DEFAULT NULL,
								RejectTimeStamp			datetime DEFAULT NULL,
								RejectAmount			float DEFAULT 0.0)



IF UPPER(@ReportWindow) = 'CURRENTSHIFT'
BEGIN
SELECT 
	@vchTimeOption		= 'UserDefined',
	@ReportTime			= GETDATE(),
	@dtmStartDateTime	= DATEADD(DAY,-1,@ReportTime),
	@dtmEndDateTime		= @ReportTime,
	@vchSplitLogicalRcd	= 'Yes',
	@vchExcludeNPT		= 'Yes'
SET @WPUID = CONVERT(int,@strWorkCellId)	
SELECT TOP 1 @dtmStartDateTime = Start_time, @ShiftEnd = end_time FROM dbo.Crew_Schedule (NOLOCK)  WHERE PU_Id = @WPUID AND (Start_time <= @ReportTime and end_time >= @ReportTime) ORDER BY Start_Time DESC
		
			
SELECT @strAreaID = pl.dept_id, @strProdLineID = pl.pl_id
	FROM dbo.Prod_Lines pl (NOLOCK) 
		JOIN dbo.Prod_Units pu (NOLOCK) ON pu.PL_Id = pl.PL_Id
	WHERE pu.PU_Id = @strWorkCellId



IF UPPER(@Stops_Or_Scrap) = 'STOPS'
BEGIN	
	INSERT INTO #DownTimeINT
	select @dtmStartDateTime [ShiftStart],@ShiftEnd [ShiftEnd],@dtmEndDateTime [ReportWindowEnd],
	PUDESC,DowntimeStart,DowntimeEnd,DownTime,ProdStatus,SplitEventFlag from [dbo].[fnLocal_CmnRptDowntimeDetailByEquipment](		
			@strAreaId				,
			@strProdLineId			,
			@strWorkCellId			,
			@vchTimeOption			,
			@dtmStartDateTime		,
			@dtmEndDateTime			,
			@vchSplitLogicalRcd		,
			@vchExcludeNPT			
	

	)where SplitEventFlag IS NULL AND DownTime <> 0

	SELECT TOP 1 @StartHourIterator =  ShiftStart, @EndShift = ReportWindowEnd FROM #DownTimeINT
	SELECT @EndHourIterator = DATEADD(HH,1,@StartHourIterator)
	
	SELECT @ShiftHourCount = 1	
	
	WHILE(@StartHourIterator < @ShiftEnd) 
	BEGIN

		SELECT @CurrentScrapAmt = COUNT(*) FROM #DownTimeINT
		WHERE DowntimeStart >= @StartHourIterator and DowntimeStart <= @EndHourIterator
		IF @CurrentScrapAmt IS NULL
			SELECT @CurrentScrapAmt = 0


		INSERT INTO #DownTimeCOUNT
			SELECT @ShiftHourCount, @CurrentScrapAmt    


		--INSERT INTO #DownTimeCOUNT
		--SELECT @ShiftHourCount, COUNT(*) FROM #DownTimeINT
		--WHERE DowntimeStart >= @StartHourIterator and DowntimeStart <= @EndHourIterator
	
		SELECT @StartHourIterator = DATEADD(HH,1,@StartHourIterator)
		SELECT @EndHourIterator = DATEADD(HH,1,@EndHourIterator)
		SELECT @ShiftHourCount = @ShiftHourCount + 1
	
	
	
	
	END

  
	SELECT * FROM #DownTimeCOUNT  

END

IF UPPER(@Stops_Or_Scrap) = 'SCRAP'
BEGIN
	INSERT INTO #SCRAPTimeINT
	select @dtmStartDateTime [ShiftStart],@ShiftEnd [ShiftEnd],@dtmEndDateTime [ReportWindowEnd],
	RejectTimeStamp, RejectAmount
	 from fnLocal_CmnRptScrapDetailByEquipment(		
			@strAreaId				,
			@strProdLineId			,
			@strWorkCellId			,
			@vchTimeOption			,
			@dtmStartDateTime		,
			@dtmEndDateTime			,
			@vchExcludeNPT)	
			
	SELECT TOP 1 @StartHourIterator =  ShiftStart, @EndShift = ReportWindowEnd FROM #SCRAPTimeINT
	SELECT @EndHourIterator = DATEADD(HH,1,@StartHourIterator)
	
	SELECT @ShiftHourCount = 1
	WHILE(@StartHourIterator < @ShiftEnd) 
	BEGIN

		SELECT @CurrentScrapAmt = SUM(RejectAmount) FROM #SCRAPTimeINT
		WHERE RejectTimeStamp >= @StartHourIterator and RejectTimeStamp <= @EndHourIterator
		IF @CurrentScrapAmt IS NULL
			SELECT @CurrentScrapAmt = 0


		INSERT INTO #DownTimeCOUNT
			SELECT @ShiftHourCount, @CurrentScrapAmt
		
		--SELECT @ShiftHourCount, SUM(RejectAmount) FROM #SCRAPTimeINT
		--WHERE RejectTimeStamp >= @StartHourIterator and RejectTimeStamp <= @EndHourIterator
	
		SELECT @StartHourIterator = DATEADD(HH,1,@StartHourIterator)
		SELECT @EndHourIterator = DATEADD(HH,1,@EndHourIterator)
		SELECT @ShiftHourCount = @ShiftHourCount + 1
	
	
	
	END

	
	SELECT ShiftStart, DowntimeCount as RejectAmount FROM #DownTimeCOUNT  WHERE DowntimeCount <> 0
	
			
	
END

  
	DROP TABLE   #DownTimeINT
  
	DROP TABLE #DownTimeCOUNT
	
	DROP TABLE #SCRAPTimeINT


END
--------------------------------------------------------------------------------

