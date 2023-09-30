
CREATE PROCEDURE [dbo].[spMesData_ProcAnz_CrewScheduleBasedonCriteria]
       @pu_id                   int = NULL
       ,@starttime              datetime = NULL
       ,@endtime                datetime = NULL
       ,@isIncremental          int = NULL
AS
BEGIN

    SET NOCOUNT ON

    IF EXISTS(select 1 from dbo.fnMesData_ProcAnz_PlantModelValidation(NULL, NULL, @pu_id))
    BEGIN
        SELECT * FROM dbo.fnMesData_ProcAnz_PlantModelValidation(NULL, NULL, @pu_id)
        RETURN
    END

    DECLARE @ConvertedST                datetime
            ,@ConvertedET                datetime
            ,@DbTZ                       nVARCHAR(25)
            ,@TempDateST                 datetime
            ,@TempDateET                 datetime
            ,@InitialST                  DateTime
            ,@ShiftStartMinutes          int
            ,@ShiftIntervalMinutes       int
                                        
    DECLARE @TempCrewSchedule TABLE 
            (
                Id int Identity(1,1)
                ,Shift_Desc nVARCHAR(50)
                ,start_time datetime
                ,end_time datetime
            )

    SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@starttime, 'UTC')
    SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@endtime, 'UTC')
    SELECT @DbTZ = value FROM site_parameters WHERE parm_id = 192

    SELECT @ShiftStartMinutes = CONVERT(Int,Value) from site_parameters where parm_Id = 17
    SELECT @ShiftIntervalMinutes = CONVERT(Int,Value) FROM site_parameters WHERE parm_Id = 16

    SET @TempDateST = CONVERT(date, @ConvertedST)  
    SET @TempDateST = DATEADD(MINUTE, @ShiftStartMinutes, @TempDateST) 
    SET @TempDateET = CONVERT(datetime, @ConvertedET)

    WHILE(@TempDateST <= @TempDateET)
    BEGIN
        INSERT INTO @TempCrewSchedule VALUES(NULL, @TempDateST, DATEADD(MINUTE, @ShiftIntervalMinutes, @TempDateST))
        SET @TempDateST = DATEADD(MINUTE, @ShiftIntervalMinutes, @TempDateST)
    END

    IF EXISTS(SELECT 1 FROM @TempCrewSchedule)
    BEGIN
        SELECT @InitialST = MIN(e.Start_time) FROM @TempCrewSchedule e       WHERE @ConvertedST BETWEEN e.start_time AND e.end_time

       SELECT Shift_Desc
                ,Case WHEN @isIncremental = 1 THEN  dbo.fnServer_CmnConvertTime(@InitialST, @DbTZ, 'UTC') 
				 ELSE dbo.fnServer_CmnConvertTime(start_time, @DbTZ, 'UTC') END AS start_time
				 ,CASE WHEN end_time > @ConvertedET THEN dbo.fnServer_CmnConvertTime(@ConvertedET, @DbTZ, 'UTC') 
				 ELSE dbo.fnServer_CmnConvertTime(end_time, @DbTZ, 'UTC') END AS
				 end_time
				 ,CASE WHEN end_time > @ConvertedET THEN dbo.fnServer_CmnConvertTime(@ConvertedET, @DbTZ, 'UTC') 
				 ELSE dbo.fnServer_CmnConvertTime(end_time, @DbTZ, 'UTC') END AS
				 'UTCTimeStamp'
        FROM @TempCrewSchedule
        WHERE start_time BETWEEN @ConvertedST AND @ConvertedET AND
		end_time BETWEEN @ConvertedST AND @ConvertedET
		OR @ConvertedST BETWEEN start_time AND end_time
		OR @ConvertedET BETWEEN start_time AND end_time
        ORDER BY start_time
    END
    ELSE
    BEGIN
        SELECT Error = 'ERROR: No Content Found', Code = 'NoContent', ErrorType = 'NoContentFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    END
END

GRANT EXECUTE ON [dbo].[spMesData_ProcAnz_CrewScheduleBasedonCriteria] TO [ComXClient]


