
/*

@lineId					- line_id
@startDate              - Start time
@endDate                - End time
@OEEType				- Availability, OEE, Performance, Quality
@sliceType              - defalault type is 1

*/

CREATE FUNCTION [dbo].[fnMesData_ProcAnz_GetSerialLineAggOEE] (
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

	DECLARE @CapRates TINYINT, @DbTZ nVARCHAR(200), @row INT, @UnitRows INT

	DECLARE @Units TABLE (	
		RowID				int identity,
		UnitId				int NULL)

	DECLARE @Result TABLE (	
		RowID				int identity,
		End_Time			DateTime NULL,
		OEE_Value			float NULL, 
		OEE_Type			nVarChar(20) NULL,
		Plant_Model_Level	nVarChar(20) NULL)

	DECLARE @TempTable TABLE (	
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

---------- AVALABILITY
	IF(@OEEType = 'Availability' OR @OEEType = 'OEE')
	BEGIN
		DECLARE @Unit_Id int
		SELECT @Unit_Id = MIN(a.PU_Id)
		FROM Prod_Units_Base a
		JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
		JOIN Table_Fields_Values c ON c.TableId = 43 and a.PU_Id = c.KeyId and c.Table_Field_Id = -92
		WHERE a.pl_Id = @lineId

		INSERT INTO @TempTable 
		SELECT End_Time, ISNULL(LoadingTime, 0), ISNULL(RunningTime, 0), ISNULL(TotalProduction, 0), 
		ISNULL(TargetProduction, 0), ISNULL(GoodProduction, 0)
		FROM OEEAggregation WITH (NOLOCK)
		WHERE End_Time >= @startDate AND End_Time <= @endDate 
		AND slice_type_id = @sliceType AND PU_Id = @Unit_Id

		IF(@OEEType = 'Availability') --- if the requested OEE type is 'availability' then jump to result section to return 'availability' related value  only
		GOTO RESULT
	END

-------- PERFORMANCE
	IF(@OEEType = 'Performance' OR @OEEType = 'OEE')
	BEGIN
		INSERT INTO @Units
		SELECT PU_Id
		FROM Prod_Units_Base a
		JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
		JOIN Table_Fields_Values c ON c.TableId = 43 AND a.PU_Id = c.KeyId AND c.Table_Field_Id = -94
		WHERE a.pl_Id = @lineId

		SET @row = 0
		SELECT @UnitRows = COUNT(*) FROM @Units
			
		WHILE @Row <  @UnitRows
		BEGIN
			SELECT @Row = @Row + 1
			INSERT INTO @TempTable 
			SELECT End_Time, ISNULL(LoadingTime, 0), ISNULL(RunningTime, 0), ISNULL(TotalProduction, 0), 
			ISNULL(TargetProduction, 0), ISNULL(GoodProduction, 0)
			FROM OEEAggregation WITH (NOLOCK)
			WHERE End_Time >= @startDate AND End_Time <= @endDate 
			AND slice_type_id = @sliceType 
			AND PU_Id = (SELECT UnitId FROM @Units WHERE RowID = @row)
		END

		IF(@OEEType = 'Performance') ---if the requested OEE type is 'Performance' then jump to result section to return 'Performance' related value  only
		GOTO RESULT 
	END

--------- QUALITY
	IF(@OEEType = 'Quality' OR @OEEType = 'OEE')
	BEGIN
		DELETE FROM @Units
		INSERT INTO @Units
		SELECT PU_Id
		FROM Prod_Units_Base a
		JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
		JOIN Table_Fields_Values c ON c.TableId = 43 and a.PU_Id = c.KeyId and c.Table_Field_Id = -93
		WHERE a.pl_Id = @lineId

		SET @row = 0
		SELECT @UnitRows = COUNT(*) FROM @Units
		WHILE @Row <  @UnitRows
		BEGIN
			SELECT @Row = @Row + 1
			INSERT INTO @TempTable 
			SELECT End_Time, ISNULL(LoadingTime, 0), ISNULL(RunningTime, 0), ISNULL(TotalProduction, 0), 
			ISNULL(TargetProduction, 0), ISNULL(GoodProduction, 0)
			FROM OEEAggregation WITH (NOLOCK)
			WHERE End_Time >= @startDate AND End_Time <= @endDate 
			AND slice_type_id = @sliceType 
			AND PU_Id = (SELECT UnitId FROM @Units WHERE RowID = @row)
		END

		IF(@OEEType = 'Quality') ---if the requested OEE type is 'Quality' then jump to result section to return 'Quality' related value  only
		GOTO RESULT 
	END

--------- OEE   ------ As OEE required to be calculated on Availability, Performance and Quality we get the desired OEE result 
	RESULT:
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
