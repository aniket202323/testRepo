CREATE PROCEDURE [dbo].[spBF_CrewScheduleBasedonCriteria]
       @pu_id                     int = NULL,
       @starttime                 datetime,
       @endtime                   datetime,
       @isIncremental int = 0
AS
BEGIN
    DECLARE @ConvertedST                datetime,
            @ConvertedET                datetime,
            @DbTZ                       nvarchar(25),
            @TempDateST                 datetime,
            @TempDateET                 datetime,
            @InitialST                  DateTime,
            @ShiftStartMinutes          int,
            @ShiftIntervalMinutes       int
    DECLARE @TempCrewSchedule TABLE 
            (
                Id int Identity(1,1),
                Shift_Desc nvarchar(50),
                start_time datetime,
                end_time datetime
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
        INSERT INTO @TempCrewSchedule VALUES( 
                NULL, 
                @TempDateST, 
                DATEADD(MINUTE, @ShiftIntervalMinutes, @TempDateST)
                )
        SET @TempDateST = DATEADD(MINUTE, @ShiftIntervalMinutes, @TempDateST)
    END
    IF EXISTS(SELECT 1 FROM @TempCrewSchedule)
    BEGIN
 	  	 SELECT @InitialST = MIN(e.Start_time) FROM @TempCrewSchedule e 	 WHERE @ConvertedST BETWEEN e.start_time AND e.end_time
        SELECT null Shift_Desc, 
        Case WHEN @isIncremental = 1 THEN @InitialST ELSE CS.start_time END AS start_time,
        CS.end_time,
        dbo.fnServer_CmnConvertTime(CS.end_time, @DbTZ, 'UTC') AS 'UTCTimeStamp'
        FROM @TempCrewSchedule CS
        WHERE (CS.start_time BETWEEN @ConvertedST AND @ConvertedET)
        AND (CS.end_time BETWEEN @ConvertedST AND @ConvertedET)
 	  	 OR @ConvertedST BETWEEN CS.start_time AND CS.end_time
 	  	 OR @ConvertedET BETWEEN CS.start_time AND CS.end_time
        ORDER BY start_time
    END
    ELSE
    BEGIN
        SELECT -999
    END
END
