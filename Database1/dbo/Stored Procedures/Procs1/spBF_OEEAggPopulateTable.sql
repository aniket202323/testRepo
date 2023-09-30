CREATE Procedure dbo.spBF_OEEAggPopulateTable
 	  @ReturnStatus int = null OUTPUT
 	 ,@ReturnMessage nvarchar(255) = null OUTPUT
 	 ,@EConfig_Id Int = null
 	 ,@OverrideEndTime 	 Datetime = Null
 	 ,@OverRidePUId 	  	 Int = Null
AS
SET @ReturnStatus = 1
SET @ReturnMessage = ''
DECLARE @StartTime DateTime
DECLARE @PrevStartTime DateTime
DECLARE @EndTime DateTime
DECLARE @Interval Int
DECLARE @PUId Int
DECLARE @InTimeZone nVarChar(100) 
DECLARE @PuStart Int
DECLARE @PuEnd Int
DECLARE @SetBack Int 
DECLARE @OEEUNITS Table (Id Int Identity(1,1),PuId Int)
DECLARE @DBStart 	 DateTime
DECLARE @DBEnd 	  	 DateTime
DECLARE @CurrentEnd 	  	 DateTime
DECLARE @CurrentDate DateTime
DECLARE @RecordToReprocess BigInt
DECLARE @MinuteOffset 	 Int
Declare @CurrentDateTrimmed Datetime
SET @InTimeZone= 'UTC' 
SELECT @SetBack = Convert(Int,Value) FROM Site_Parameters WHERE Parm_Id = 605 and hostname = ''
SELECT @Interval = Convert(Int,Value) FROM Site_Parameters WHERE Parm_Id = 602 and hostname = ''
SET @CurrentDate = dbo.fnServer_CmnConvertToDbTime(getutcdate(),@InTimeZone)
SET @MinuteOffset =  DatePart(minute,getutcdate())
SET @SetBack = Coalesce(@SetBack,0) + 1
IF @OverrideEndTime IS Not NULL SET @SetBack = 1
SET @Interval = Coalesce(@Interval,60)
Set @CurrentDateTrimmed =@CurrentDate
SET @CurrentDateTrimmed = dateadd(minute,-datepart(minute,@CurrentDateTrimmed),@CurrentDateTrimmed)
 	 SET @CurrentDateTrimmed = dateadd(second,-datepart(second,@CurrentDateTrimmed),@CurrentDateTrimmed)
 	 SET @CurrentDateTrimmed = dateadd(millisecond,-datepart(millisecond,@CurrentDateTrimmed),@CurrentDateTrimmed)
IF @OverRidePUId Is Not Null
BEGIN
 	 INSERT INTO @OEEUNITS(PuId) VALUES (@OverRidePUId)
 	 SET @PUEnd = 1
END
ELSE
BEGIN
 	 
 	 ;WITH NotConfiguredUnits As
 	 (
 	  	 Select 
 	  	  	 Pu.Pu_Id from Prod_Units_Base Pu
 	  	 Where
 	  	  	 Not Exists (Select 1 From Table_Fields_Values WITH(NOLOCK) Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	 AND Production_Rate_Specification IS NULL
 	 )
 	 INSERT INTO @OEEUNITS(PuId)
 	 SELECT DISTINCT PU_Id from Event_Configuration  
 	 WHERE ET_Id = 1 and PU_Id > 0 and pu_id not in (Select Pu_Id from NotConfiguredUnits)
 	 UNION 
 	 Select KeyId From Table_Fields_Values A Where Table_Field_Id = -91 And TableId = 43  AND Value = 4 AND NOT EXISTS (SELECT 1 FROM Event_Configuration WHERE ET_Id = 1 AND PU_Id = A.KeyId)
 	 and KeyId not in (Select Pu_Id from NotConfiguredUnits)
 	 SET @PUEnd = @@RowCount
END
SET @PuStart = 1
WHILE @PuStart < = @PUEnd --Unit Loop
BEGIN
 	 SELECT @PUId = PuId From @OEEUNITS Where id = @PuStart
 	 SET @EndTime = COALESCE(@OverrideEndTime,GETUTCDATE())
 	 SET @EndTime = dateadd(minute,-datepart(minute,@EndTime),@EndTime)
 	 SET @EndTime = dateadd(second,-datepart(second,@EndTime),@EndTime)
 	 SET @EndTime = dateadd(millisecond,-datepart(millisecond,@EndTime),@EndTime)
 	 SET @EndTime = COALESCE(@OverrideEndTime,dbo.fnServer_CmnConvertFromDbTime(@CurrentDateTrimmed,@InTimeZone))
 	 
 	 
 	 IF @MinuteOffset > 10
 	 BEGIN
 	  	 SET @EndTime = dateadd(Hour,1,@EndTime)
 	 END
 	 SET @StartTime = dateadd(Minute,-@Interval*@SetBack,@EndTime)
 	 SET @EndTime = DateAdd(Minute,-@Interval,@EndTime)
 	 SELECT @PrevStartTime = MAX(Start_Time)
 	  	  FROM OEEAggregation WHERE PU_Id = @PUId AND Granularity_Id = 1
 	 IF @PrevStartTime IS NOT NULL
 	 BEGIN
 	  	 SELECT @PrevStartTime = dbo.fnServer_CmnConvertFromDbTime(@PrevStartTime,'UTC')
 	  	 IF @PrevStartTime < @StartTime
 	  	  	 SET @StartTime = @PrevStartTime
 	 END
 	 IF  @StartTime < DateAdd(Day,-7,@EndTime)
 	  	 SET @StartTime = DateAdd(Day,-7,@EndTime)
 	 WHILE @StartTime < @EndTime
 	 BEGIN
 	  	 SET @DBStart = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
 	  	 SET @CurrentEnd = DateAdd(Minute,@Interval,@StartTime)
 	  	 SET @DBEnd   = dbo.fnServer_CmnConvertToDbTime(@CurrentEnd,@InTimeZone)
 	  	 IF NOT EXISTS (SELECT 1 FROM OEEAggregation WHERE Pu_Id = @PUId and Start_Time = @DbStart and Granularity_Id = 1 and Slice_Type_Id = 1)
 	  	 BEGIN
 	  	  	 INSERT INTO OEEAggregation( 	 Start_Time, End_Time, Pu_Id 	 , Granularity_Id, Slice_Type_Id
 	  	  	  	  	  	  	  	  	 , Prod_Id, PercentOEE, PerformanceOEE, QualityOEE, AvailabilityOEE
 	  	  	  	  	  	  	  	  	 , TotalProduction, GoodProduction, TargetProduction, RunningTime, LoadingTime,
 	  	  	  	  	  	  	  	  	 IdealSpeed,ActualSpeed,PerformanceDowntime,Entry_On,Reprocess_Record)
 	  	  	 SELECT @DBStart,@DBEnd,@PUId,1,1 --Product
 	  	  	  	 ,1,0,0,0,0
 	  	  	  	 ,0,0,0,0,0
 	  	  	  	 ,0,0,0,@CurrentDate,2
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 UPDATE OEEAggregation SET Reprocess_Record = 1 WHERE Pu_Id = @PUId and Start_Time = @DbStart and Granularity_Id = 1 and Slice_Type_Id = 1 and Reprocess_Record = 0
 	  	 END
 	  	 SET  @StartTime = DateAdd(Minute,@Interval,@StartTime)
 	 END
 	 SET @EndTime = DateAdd(Minute,@Interval,@EndTime)
 	 SET @StartTime = dateadd(Minute,-@Interval,@EndTime)
 	 SET @EndTime = COALESCE(@OverrideEndTime,dbo.fnServer_CmnConvertFromDbTime(@CurrentDateTrimmed,@InTimeZone))
 	 SET @StartTime = dateadd(Minute,-@Interval,@EndTime)
 	 EXECUTE dbo.spBF_OEEAggPopulateAllSlices @PUId,@StartTime,@EndTime
 	 SET @PuStart = @PuStart + 1
END
WHILE EXISTS(Select 1 From OEEAggregation WHERE Reprocess_Record != 0) and dateDiff(minute,@CurrentDate,dbo.fnServer_CmnConvertToDbTime(getutcdate(),@InTimeZone)) < 3
BEGIN
 	 SELECT @StartTime = Max(Start_Time) 
 	  	 FROM OEEAggregation
 	  	 WHERE Reprocess_Record != 0
 	 SELECT @RecordToReprocess = Max(OEEAggregation_Id)
 	  	 FROM OEEAggregation
 	  	 WHERE Reprocess_Record != 0 and Start_Time = @StartTime
 	 SELECT @PUId = PU_Id,@StartTime = dbo.fnServer_CmnConvertFromDbTime(Start_Time,@InTimeZone),@EndTime = dbo.fnServer_CmnConvertFromDbTime(End_Time,@EndTime)
 	  	 FROM OEEAggregation 
 	  	 WHERE OEEAggregation_Id = @RecordToReprocess
 	 EXECUTE dbo.spBF_OEEAggPopulateAllSlices @PUId,@StartTime,@EndTime
END
