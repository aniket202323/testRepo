
/*
Get OEE data for a set of production units.
@inputId                - line_id
@startDate              - Start time
@endDate                - End time
@OEEType                - Availability, OEE, Performance, Quality
@sliceType              - defalault type is 1

*/

CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetLineAggOEE]
       @lineId                  INT = NULL,
       @startDate               DATETIME = NULL,
       @endDate                 DATETIME = NULL,
       @OEEType                 VARCHAR(15) = NULL,
	   @isNPT					BIT = NULL,
       @sliceType               INT = 1

AS
BEGIN
	SET NOCOUNT ON

    IF EXISTS(SELECT 1 FROM dbo.fnMesData_ProcAnz_PlantModelValidation(NULL, @lineId, NULL))
    BEGIN
        SELECT * FROM dbo.fnMesData_ProcAnz_PlantModelValidation(NULL, @lineId, NULL)
        RETURN
    END

	DECLARE @ConvertedST DATETIME, @ConvertedET DATETIME, @DbTZ VARCHAR(200)
	DECLARE @ActiveUnits TABLE(Pu_Id INT)
	DECLARE @Units TABLE(UnitId INT)

	DECLARE @tempOEE TABLE (
		RowID					INT IDENTITY,
		End_Time				DATETIME NULL,
		LoadingTime				FLOAT NULL,
		DowntimePL				FLOAT NULL,
		DowntimeA				FLOAT NULL,
		DowntimeP				FLOAT NULL,
		DowntimeQ				FLOAT NULL,NPT FLOAT NULL
	)

	DECLARE @tempOEE2 TABLE(
		RowID				INT IDENTITY,
		End_Time			DATETIME NULL
		,Availability		FLOAT NULL
		,Performance		FLOAT NULL
		,Quality			FLOAT NULL
	)
		
	INSERT INTO @ActiveUnits(Pu_Id)
	SELECT Pu_Id FROM Prod_Units_Base WHERE Pl_Id = @lineId

	;WITH NotConfiguredUnits AS
	(
		SELECT 
			PU.Pu_Id FROM Prod_Units_Base PU
		WHERE
			NOT EXISTS (SELECT 1 FROM Table_Fields_Values WHERE Table_Field_Id = -91 And TableId = 43 And KeyId = PU.Pu_Id)
			AND Production_Rate_Specification IS NULL
	)
	INSERT INTO @Units (UnitId)
	SELECT
		AU.Pu_ID
	FROM 
		@ActiveUnits AU
		LEFT OUTER JOIN NotConfiguredUnits NU ON NU.PU_Id = NU.Pu_ID
	WHERE 
		Nu.PU_Id IS NULL

	SELECT @DbTZ = VALUE FROM site_parameters WHERE parm_id = 192;
	SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@startDate, 'UTC');
	SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endDate, 'UTC');
	
	INSERT INTO @tempOEE
	SELECT 
		End_Time = O.End_Time,				
		LoadingTime = SUM(LoadingTime),			
		DowntimePL = SUM(DowntimePL),			
		DowntimeA = SUM(DowntimeA),			
		DowntimeP = SUM(DowntimeP),			
		DowntimeQ = SUM(DowntimeQ),NPT = SUM(NPT)
	FROM 
		OEEAggregation O WITH(NOLOCK)
		JOIN Prod_Units_Base U WITH(NOLOCK) ON O.PU_Id = U.PU_ID
		JOIN Prod_Lines_Base L WITH(NOLOCK) ON U.Pl_Id = L.Pl_Id AND L.PL_ID = @lineId
	WHERE
		O.Pu_ID IN (SELECT PU_ID FROM @ActiveUnits)
		AND O.End_Time >= @ConvertedST AND O.End_Time <= @ConvertedET
		AND Slice_Type_Id = @sliceType 
	
	GROUP BY O.End_Time


		  IF @isNPT = 0
			  BEGIN
			  UPDATE @tempOEE SET NPT =0
			  END
	
		
	BEGIN
		INSERT INTO @tempOEE2
		SELECT
			End_Time = End_Time
			,Availability = CASE WHEN (LoadingTime -NPT - DowntimePL) <= 0 THEN 0 ELSE (CAST(LoadingTime -NPT  - DowntimePL - DowntimeA AS FLOAT)/CAST(LoadingTime  -NPT  - DowntimePL AS FLOAT)) END * 100
			,Performance = CASE WHEN (LoadingTime -NPT  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (CAST(LoadingTime -NPT  - DowntimePL - DowntimeA - DowntimeP AS FLOAT)/CAST(LoadingTime  -NPT - DowntimePL - DowntimeA AS FLOAT)) END * 100
			,Quality = CASE WHEN (LoadingTime  -NPT  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (CAST(LoadingTime -NPT  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ AS FLOAT)/CAST(LoadingTime  -NPT - DowntimePL - DowntimeA - DowntimeP AS FLOAT))  END * 100
		FROM 
			@tempOEE
	END

	SELECT
		RowID
		,End_Time = dbo.fnServer_CmnConvertTime(End_Time, @DbTZ, 'UTC')
		,OEE_Value = CASE 
			WHEN @OEEType = 'Availability' 
				THEN ROUND(Availability, 6)
			WHEN @OEEType = 'OEE' 
				THEN ROUND((Availability * Performance * Quality/10000), 6)
			WHEN @OEEType = 'Performance' 
				THEN ROUND(Performance, 6)
			WHEN @OEEType = 'Quality'	
				THEN ROUND(Quality, 6)
		END
		,OEE_Type = @OEEType
		,Plant_Model_Level = 'Line'
	FROM
		@tempOEE2
END

GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetLineAggOEE] TO [ComXClient]