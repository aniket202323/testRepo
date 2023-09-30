CREATE PROCEDURE [dbo].[spBF_GetKPIDataForTrending] 
 	 @unit_id 	  	 nvarchar(700),
 	 @Start_Time datetime,
 	 @End_Time datetime,
 	 @KPIType int = null --null return all ,1 OEE, 2 Availablity, 3 Waste , 4 Performance
 	 
AS 
SET NOCOUNT ON
DECLARE  @Results TABLE (id int identity(1,1),
 	  	  	  	  	  	 Line nvarchar(100),
 	  	  	  	  	  	 LineId Int, 
 	  	  	  	  	  	 Unit  nvarchar(100),
 	  	  	  	  	  	 UnitOrder Int,
 	  	  	  	  	  	 ProductionAmount Float, 
                        IdealProductionAmount Float,
 	  	  	  	  	  	 ActualSpeed  Float,
 	  	  	  	  	  	 IdealSpeed Float,
 	  	  	  	  	  	 PerformanceRate Float,
 	  	  	  	  	  	 WasteAmount Float, 
                        QualityRate  Float,
 	  	  	  	  	  	 PerformanceTime Float,
 	  	  	  	  	  	 RunTime Float,
 	  	  	  	  	  	 LoadingTime Float,
 	  	  	  	  	  	 AvailableRate  Float,        
                        PercentOEE Float,
 	  	  	  	  	  	 TimeStamp  datetime)
DECLARE @TimeBasedLinesummary TABLE
(
 	 LineDesc nvarchar(50) null,
 	 UnitId 	 Int null,
 	 UnitDesc nvarchar(50) null,
 	 UnitOrder 	 Int Null,
 	 UtilizationTime Float null,
 	 EffectivelyUsedTime Float null,
 	 PerformanceRate Float null,
 	 UsedTime Float null,
 	 QualityRate Float null,
 	 WorkingTime Float DEFAULT 0,
 	 ActivityTime Float DEFAULT 0,
 	 AvailableRate Float null,
 	 PercentOEE  Float DEFAULT 0,
 	 StartTime 	 DateTime,
 	 EndTime 	  	 DateTime,
 	 LineStatus 	 Int,
 	 PerformanceSeconds Int,
 	 QualitySeconds Int,
 	 AvailabilitySeconds Int
)
DECLARE @Eventtimeframe TABLE ( 	 id int identity(1,1),
 	  	  	  	  	  	  	  	 Starttime datetime,
 	  	  	  	  	  	  	  	 endtime datetime
 	  	  	  	  	  	  	  	 )
DECLARE @numloop int = 1,
 	  	 @maxloop int,
 	  	 @localstarttime DateTime,
 	  	 @localendtime DateTime,
 	  	 @ConvertedST  	  DateTime,
  	    	 @ConvertedET  	  DateTime,
 	  	 @DbTZ nVarChar(200),
 	  	 @OEECalcType Int
SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@Start_Time,'UTC')
SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@End_Time,'UTC')
SELECT @DbTZ = value from site_parameters where parm_id=192
IF EXISTS( SELECT 1 FROM dbo.Events  WITH(NOLOCK) WHERE pu_id = CAST (@unit_id AS int))    
 	 BEGIN
 	  	 INSERT INTO @Eventtimeframe (Starttime,endtime)
 	  	 SELECT Start_time,timestamp from dbo.Events WITH(NOLOCK)  
 	  	 WHERE pu_id = CAST (@unit_id as int) AND timestamp BETWEEN @ConvertedST AND @ConvertedET
 	  	 SELECT @OEECalcType = COALESCE(pl.LineOEEMode,1)
 	  	 FROM Prod_Units_Base pu
 	  	 JOIN Prod_Lines pl on pl.PL_Id = pu.PL_Id
 	  	 WHERE pu.PU_Id =  CAST (@unit_id as int)
 	  	 UPDATE  d1
 	  	  	 SET d1.StartTime = d2.EndTime
 	  	  	 FROM @Eventtimeframe d2
 	  	  	 JOIN @Eventtimeframe d1 ON d1.Id = (d2.Id - 1)
 	  	  	 WHERE d1.StartTime is null
/*and (
(Start_Time <= @Start_Time and TimeStamp > @Start_Time) or
(Start_Time > @Start_Time and TimeStamp <=@End_Time) or 
(Start_Time <=@End_Time   and  TimeStamp >= @End_Time)) */
 	  	 SET  @maxloop = (Select max(id) from @Eventtimeframe)
 	  	 WHILE (@numloop <=@maxloop)
 	  	  	 BEGIN
 	  	  	  	 SELECT @localstarttime = starttime,@localendtime = endtime FROM @Eventtimeframe WHERE id = @numloop
 	  	  	  	 IF(@OEECalcType = 6)
 	  	  	  	 BEGIN
 	  	  	  	  	 --Get Time Based Line Data
 	  	  	  	  	 INSERT INTO @TimeBasedLinesummary (LineDesc,UnitId,UnitDesc,UnitOrder,UtilizationTime,PerformanceRate,
 	  	  	  	  	  	  	  	  	  	  	 EffectivelyUsedTime,UsedTime,QualityRate,WorkingTime,ActivityTime,AvailableRate,PercentOEE,
 	  	  	  	  	  	  	  	  	  	  	 PerformanceSeconds,QualitySeconds,AvailabilitySeconds)
 	  	  	  	  	 EXEC   [dbo].[spBF_TimeBasedOEEGetData]
 	  	  	  	  	  	  	 @UnitList 	  	  	  	  	 = @Unit_id,
 	  	  	  	  	  	  	 @StartTime 	  	  	  	  	 = @localstarttime,
 	  	  	  	  	  	  	 @EndTime 	  	  	  	  	 = @localendtime,
 	  	  	  	  	  	  	 @FilterNonProductiveTime 	 = null,
 	  	  	  	  	  	  	 @InTimeZone 	  	  	  	  	 = @DbTZ,
 	  	  	  	  	  	  	 @ReturnLineData 	  	  	  	 = 0,
 	  	  	  	  	  	  	 @pageSize 	  	  	  	  	 = Null,
 	  	  	  	  	  	  	 @pageNum 	  	  	  	  	 = Null
 	  	  	  	  	 --Translate Results into Standard Results Return
 	  	  	  	  	 INSERT INTO @Results (Line , LineId , Unit, UnitOrder ,ProductionAmount , 
 	  	  	  	  	  	  	  	  	  	  	  IdealProductionAmount , ActualSpeed  , IdealSpeed , PerformanceRate , WasteAmount , 
 	  	  	  	  	  	  	  	  	  	  	  QualityRate  , PerformanceTime , RunTime ,  LoadingTime ,   AvailableRate  ,       
 	  	  	  	  	  	  	  	  	  	  	  PercentOEE )
 	  	  	  	  	 SELECT LineDesc, NULL, UnitDesc, UnitOrder, 0,
 	  	  	  	  	  	  	 0, 0, 0, PerformanceRate, 0,
 	  	  	  	  	  	  	 QualityRate, 0, 0, 0, AvailableRate,
 	  	  	  	  	  	  	 PercentOEE
 	  	  	  	  	 FROM @TimeBasedLinesummary
 	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 INSERT INTO @Results (Line , LineId , Unit, UnitOrder ,ProductionAmount , 
 	  	  	  	  	  	  	  	  	  	  	  IdealProductionAmount , ActualSpeed  , IdealSpeed , PerformanceRate , WasteAmount , 
 	  	  	  	  	  	  	  	  	  	  	  QualityRate  , PerformanceTime , RunTime ,  LoadingTime ,   AvailableRate  ,       
 	  	  	  	  	  	  	  	  	  	  	  PercentOEE )
 	  	  	  	  	 EXEC   [dbo].[spBF_OEEGetData]
 	  	  	  	  	  	  	 @UnitList 	  	  	  	  	 = @Unit_id,
 	  	  	  	  	  	  	 @StartTime 	  	  	  	  	 = @localstarttime,
 	  	  	  	  	  	  	 @EndTime 	  	  	  	  	 = @localendtime,
 	  	  	  	  	  	  	 @FilterNonProductiveTime 	 = null,
 	  	  	  	  	  	  	 @InTimeZone 	  	  	  	  	 = @DbTZ,
 	  	  	  	  	  	  	 @ReturnLineData 	  	  	  	 = 0,
 	  	  	  	  	  	  	 @pageSize 	  	  	  	  	 = Null,
 	  	  	  	  	  	  	 @pageNum 	  	  	  	  	 = Null
 	  	  	  	 END
 	  	  	  	 UPDATE @Results SET timestamp = @localendtime WHERE id= @numloop 
 	  	  	  	 SET @numloop = @numloop+1
 	  	  	 END
 	  	 IF @KPIType IS NULL
 	  	 BEGIN
 	  	  	 SELECT @Unit_id ModelId, dbo.fnServer_CmnConvertTime(timestamp,@DbTZ,'UTC'), PercentOEE, AvailableRate, QualityRate, PerformanceRate, WasteAmount, QualityRate, ProductionAmount 
 	  	  	 FROM @Results 
 	  	  	 --converting all timestamps from db timezone to 'UTC' expected by API's
 	  	 END
 	  	 ELSE IF @KPIType = 1
 	  	 BEGIN
 	  	  	 SELECT @Unit_id ModelId, 1 KPIDescription, dbo.fnServer_CmnConvertTime(timestamp,@DbTZ,'UTC'), PercentOEE 
 	  	  	 FROM @Results 
 	  	 END
 	  	 ELSE IF @KPIType = 2
 	  	 BEGIN
 	  	  	 SELECT @Unit_id ModelId, 2 KPIDescription ,dbo.fnServer_CmnConvertTime(timestamp,@DbTZ,'UTC') , AvailableRate 
 	  	  	 FROM @Results 
 	  	 END
 	  	 ELSE IF @KPIType = 3
 	  	 BEGIN
 	  	  	 SELECT @Unit_id ModelId, 3 KPIDescription, dbo.fnServer_CmnConvertTime(timestamp,@DbTZ,'UTC'), QualityRate 
 	  	  	 FROM @Results 
 	  	 END
 	  	 ELSE IF @KPIType = 4
 	  	 BEGIN
 	  	  	 SELECT @Unit_id ModelId, 4 KPIDescription, dbo.fnServer_CmnConvertTime(timestamp,@DbTZ,'UTC'), PerformanceRate 
 	  	  	 FROM @Results 
 	  	 END
 	  	 ELSE IF @KPIType = 5
 	  	 BEGIN
 	  	  	 SELECT @Unit_id ModelId, 5 KPIDescription, dbo.fnServer_CmnConvertTime(timestamp,@DbTZ,'UTC'), WasteAmount 
 	  	  	 FROM @Results 
 	  	 END
 	 END
 ELSE 
      BEGIN
              SELECT -999
       END
