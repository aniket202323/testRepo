
/*

@lineId					- line_id
@startDate              - Start time
@endDate                - End time
@OEEType				- Availability, OEE, Performance, Quality
@sliceType              - defalault type is 1

*/

CREATE FUNCTION [dbo].[fnMesData_ProcAnz_GetParallelLineAggOEE] (
	@lineId					int,
	@startDate				DateTime,
	@endDate				DateTime,
	@OEEType				nVarChar(20),
	@sliceType				int = 1)

RETURNS @returnTable TABLE (
	RowID					int,
	End_Time				DateTime NULL,
	OEE_Value				float NULL, 
	OEE_Type				nVarChar(20) NULL,
	Plant_Model_Level		nVarChar(20) NULL)

AS
BEGIN

	DECLARE @CapRates tinyint, @DbTZ nVarChar(200), @row int, @UnitRows int

	DECLARE @Units table (	
		RowID				int identity,
		UnitId				int NULL)

	DECLARE @Result table (	
		RowID				int identity,
		End_Time			DateTime NULL,
		OEE_Value			float NULL,
		OEE_Type			nVARCHAR(255) NULL,
		Plant_Model_Level	nVARCHAR(255))

	DECLARE @tempTable table (	
		RowID				int identity,
		End_Time			DateTime NULL,
		LoadingTime			float NULL,
		RunningTime			float NULL,
		TotalProduction		float NULL,
		TargetProduction	float NULL,
		GoodProduction		float NULL)
	
	SELECT @CapRates = dbo.fnCMN_OEERateIsCapped()
	SELECT @DbTZ = value FROM site_parameters WHERE parm_id = 192
	SELECT @startDate = dbo.fnServer_CmnConvertToDbTime(@startDate, 'UTC')
	SELECT @endDate = dbo.fnServer_CmnConvertToDbTime(@endDate, 'UTC')

	INSERT INTO @Units (UnitId)
	SELECT PU_ID FROM Prod_Units WHERE PL_Id = @lineId

	SET @row = 0
	SELECT @UnitRows = COUNT(*) FROM @Units
	---- LOOPING START
	WHILE @Row <  @UnitRows
	BEGIN
 		SELECT @Row = @Row + 1
		INSERT INTO @tempTable
		SELECT End_Time, ISNULL(LoadingTime, 0), ISNULL(RunningTime, 0), ISNULL(TotalProduction, 0), 
		ISNULL(TargetProduction, 0), ISNULL(GoodProduction, 0)
		FROM OEEAggregation WITH (NOLOCK)
		WHERE End_Time >= @startDate AND End_Time <= @endDate 
		AND slice_type_id = @sliceType 
		AND PU_Id = (SELECT UnitId FROM @Units WHERE RowID = @row)
	 END
	---- LOOPING END

	 INSERT INTO @Result
	 SELECT End_Time = dbo.fnServer_CmnConvertTime(End_Time, @DbTZ, 'UTC'),
	 OEE_Value = CASE 
					WHEN @OEEType = 'Availability' 
						THEN dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunningTime), @CapRates)
					WHEN @OEEType = 'OEE' 
						THEN (dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunningTime), @CapRates)/100
							* dbo.fnGEPSPerformance(sum(TotalProduction), sum(TargetProduction), @CapRates)/100 
							* dbo.fnGEPSQuality(sum(TotalProduction), Sum(TotalProduction - GoodProduction), @CapRates)/100) * 100
					WHEN @OEEType = 'Performance' 
						THEN  dbo.fnGEPSPerformance(sum(TotalProduction), sum(TargetProduction), @CapRates)
					WHEN @OEEType = 'Quality'	
						THEN  dbo.fnGEPSQuality(sum(TotalProduction), Sum(TotalProduction-GoodProduction), @CapRates) 
				END,
	@OEEType, 
	'Line'
	FROM @tempTable  			
	GROUP BY End_Time
	  
	INSERT INTO @returnTable 
	SELECT * FROM @Result
	RETURN
END
