Create Procedure dbo.spEM_OEEAggReprocess
 	  @PUId int
 	 ,@StartTime DateTime
 	 ,@EndTime  DateTime 
AS
DECLARE @InTimeZone nVarChar(100)
DECLARE @PrevStartTime DateTime
DECLARE @Interval Int
DECLARE @SetBack Int 
DECLARE @OEEUNITS Table (Id Int Identity(1,1),PuId Int)
DECLARE @DBStart 	 DateTime
DECLARE @DBEnd 	  	 DateTime
DECLARE @CurrentEnd 	  	 DateTime
DECLARE @CurrentDate DateTime
DECLARE @RecordToReprocess BigInt
DECLARE @MinuteOffset 	 Int
SET @InTimeZone= 'UTC' 
SELECT @SetBack = Convert(Int,Value) FROM Site_Parameters WHERE Parm_Id = 605 and hostname = ''
SELECT @Interval = Convert(Int,Value) FROM Site_Parameters WHERE Parm_Id = 602 and hostname = ''
SET @CurrentDate = dbo.fnServer_CmnConvertToDbTime(getutcdate(),@InTimeZone)
SET @EndTime = dateadd(minute,-datepart(minute,@EndTime),@EndTime)
SET @EndTime = dateadd(second,-datepart(second,@EndTime),@EndTime)
SET @EndTime = dateadd(millisecond,-datepart(millisecond,@EndTime),@EndTime)
SET @StartTime = dateadd(minute,-datepart(minute,@StartTime),@StartTime)
SET @StartTime = dateadd(second,-datepart(second,@StartTime),@StartTime)
SET @StartTime = dateadd(millisecond,-datepart(millisecond,@StartTime),@StartTime)
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
