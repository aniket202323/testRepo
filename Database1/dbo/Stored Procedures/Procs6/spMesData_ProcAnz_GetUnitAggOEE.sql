
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_GetUnitAggOEE] 
	@unitId		    INT = NULL,
	@startDate		DATETIME =  NULL,
	@endDate		DATETIME =  NULL,
	@OEEType		VARCHAR(15) = NULL,
	@isNPT		    BIT =  NULL,
	@sliceType		INT = 1

AS
BEGIN
	SET NOCOUNT ON
	
    IF EXISTS(SELECT 1 FROM dbo.fnMesData_ProcAnz_PlantModelValidation(NULL, NULL, @unitId))
    BEGIN
        SELECT * FROM dbo.fnMesData_ProcAnz_PlantModelValidation(NULL, NULL, @unitId)
        RETURN
    END
	
	DECLARE @ConvertedST DateTime, @ConvertedET DateTime, @DbTZ VarChar(200)

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
		Id				 INT IDENTITY
		,End_Time			DATETIME NULL
		,Availability		FLOAT NULL
		,Performance		FLOAT NULL
		,Quality			FLOAT NULL
	)

	SELECT @DbTZ = VALUE FROM site_parameters WHERE parm_id = 192
    SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@startDate, 'UTC')
    SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endDate, 'UTC')

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
                     JOIN Prod_Lines_Base L WITH(NOLOCK) ON U.Pl_Id = L.Pl_Id
              WHERE
                     O.Pu_ID = @unitId
                     AND O.End_Time >= @ConvertedST AND O.End_Time <= @ConvertedET
                     AND Slice_Type_Id = @sliceType 
                     --AND ((@isNPT = 1 AND ISNULL(isNPT, 0) <> 1) OR (@isNPT = 0 AND 1=1))
              GROUP BY O.End_Time
               
			  IF @isNPT = 0
			  BEGIN
			  UPDATE @tempOEE SET NPT =0
			  END
			  


			   
              INSERT INTO @tempOEE2
              SELECT
                     End_Time = End_Time
                     ,Availability = CASE WHEN (LoadingTime -NPT - DowntimePL) <= 0 THEN 0 ELSE (CAST(LoadingTime  -NPT- DowntimePL - DowntimeA AS FLOAT)/CAST(LoadingTime -NPT - DowntimePL AS FLOAT)) END * 100
                     ,Performance = CASE WHEN (LoadingTime -NPT - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (CAST(LoadingTime -NPT - DowntimePL - DowntimeA - DowntimeP AS FLOAT)/CAST(LoadingTime -NPT - DowntimePL - DowntimeA AS FLOAT)) END * 100
                     ,Quality = CASE WHEN (LoadingTime -NPT - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (CAST(LoadingTime -NPT - DowntimePL - DowntimeA - DowntimeP - DowntimeQ AS FLOAT)/CAST(LoadingTime -NPT - DowntimePL - DowntimeA - DowntimeP AS FLOAT))  END * 100
              FROM 
                     @tempOEE

	
	SELECT 
		Id
		,End_Time = dbo.fnServer_CmnConvertTime(End_Time, @DbTZ, 'UTC')
		,OEE_Value = CASE 
			WHEN @OEEType = 'Availability' 
				THEN ROUND(Availability, 8)
			WHEN @OEEType = 'OEE' 
				THEN ROUND((Availability * Performance * Quality/10000), 8)
			WHEN @OEEType = 'Performance' 
				THEN ROUND(Performance, 8)
			WHEN @OEEType = 'Quality'	
				THEN ROUND(Quality, 8)
		END
		,OEE_Type = @OEEType
		,Plant_Model_Level = 'Unit'
	FROM
		@tempOEE2
END

GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_GetUnitAggOEE] TO [ComXClient]
