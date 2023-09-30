Create Procedure [dbo].[spBF_OEEAggPopulateAllSlices]
 	 @PUId Int
 	 ,@StartTime DateTime
 	 ,@EndTime 	 DateTime
AS
/* ##### spBF_OEEAggPopulateAllSlices #####
Description 	 : Used to populate OEEaggregation table.
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Retaining one type of slice which includes prodid, shift, crew, ppid, path. Also populates new columns
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL
2018-05-29 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Added new column in slice IsNPT and creating new slice for NPT records
*/
DECLARE @DBStart 	 DateTime
DECLARE @DBEnd 	  	 DateTime
DECLARE @CurrentDate DateTime
DECLARE @InTimeZone nvarchar(10)
SET @InTimeZone = 'UTC'
SET @CurrentDate = dbo.fnServer_CmnConvertToDbTime(getutcdate(),@InTimeZone )
 	 SET @DBStart = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
 	 SET @DBEnd   = dbo.fnServer_CmnConvertToDbTime(@EndTime,@InTimeZone)
 	  
 	 DELETE FROM OEEaggregation WHERE Pu_Id = @PUId and Start_Time = @DbStart and End_Time = @DBEnd 
 	 INSERT INTO OEEaggregation( 	  Start_Time, End_Time 	 , Pu_Id 	 , Granularity_Id, Slice_Type_Id
 	  	  	  	  	  	  	  	 , Prod_Id, PercentOEE, PerformanceOEE, QualityOEE, AvailabilityOEE
 	  	  	  	  	  	  	  	 , TotalProduction, GoodProduction, TargetProduction, RunningTime, LoadingTime,
 	  	  	  	  	  	  	  	 IdealSpeed,ActualSpeed,PerformanceDowntime,Entry_On
 	  	  	  	  	  	  	  	 ,Shift_Desc
 	  	  	  	  	  	  	  	 ,Crew_Desc
 	  	  	  	  	  	  	  	 ,PP_Id
 	  	  	  	  	  	  	  	 ,Path_id,Reprocess_Record,
 	  	  	  	  	  	  	  	 NPT,DowntimeA,DownTimeP,DowntimeQ, DowntimePL, IsNPT
 	  	  	  	  	  	  	  	 )
 	 SELECT @DBStart,@DBEnd,@PUId,1,1 --Product
 	  	  	 ,ProductId,OEE,PerformanceRate,QualityRate,AvaliableRate
 	  	  	 ,NetProduction+Waste,NetProduction,COALESCE(IdealProduction,0),
 	  	  	 RunTime,Loadtime,
 	  	  	 COALESCE(IdealSpeed,0),COALESCE(ActualSpeed,0),COALESCE(PerformanceDowntime,0),@CurrentDate,
 	  	  	 ShiftDesc,CrewDesc,PPId,PathId,0,ISNULL(NPT,0),ISNULL(DowntimeA,0),ISNULL(DownTimeP,0),ISNULL(DowntimeQ,0),ISNULL(DowntimePL,0)
 	  	  	 ,IsNPT
 	  	 FROM dbo.fnBF_wrQuickOEEProductSummary(@PUId,@StartTime,@EndTime,@InTimeZone,1,1,0)
 	 UPDATE OEEaggregation 
 	 SET 
 	  	 AvailabilityOEE 	  	 = 	 Case when (LoadingTime-DowntimePL) <=0 then 0 ELSE ((LoadingTime-DowntimeA-DowntimePL)/(LoadingTime-DowntimePL))*100 end,
 	  	 PerformanceOEE 	  	 = 	 Case when (LoadingTime-DowntimePL-DowntimeA) <=0 then 0 ELSE ((LoadingTime-DowntimeA-DowntimePL-DownTimeP)/(LoadingTime-DowntimePL-DowntimeA))*100 End,
 	  	 QualityOEE 	  	  	 = 	 Case when (LoadingTime-DowntimeA-DowntimePL-DownTimeP) <=0 then 0 ELSE ((LoadingTime-DowntimeA-DowntimePL-DownTimeP-DownTimeQ)/(LoadingTime-DowntimeA-DowntimePL-DownTimeP))*100 End
 	 Where 
 	  	 Pu_Id = @PUId
 	  	 AND Start_Time = @DBStart 
 	  	 AND End_Time = @DBEnd
 	  	 AND Exists (Select 1 from  dbo.Table_Fields_Values  where KeyId = @PUId   AND Table_Field_Id = -91 AND TableId = 43 and Value = 4)
 	 UPDATE OEEaggregation 
 	 SET 
 	  	 PercentOEE = (AvailabilityOEE*PerformanceOEE*QualityOEE)/10000
 	 Where 
 	  	 Pu_Id = @PUId
 	  	 AND Start_Time = @DBStart 
 	  	 AND End_Time = @DBEnd
 	  	 AND Exists (Select 1 from  dbo.Table_Fields_Values  where KeyId = @PUId   AND Table_Field_Id = -91 AND TableId = 43 and Value = 4)
