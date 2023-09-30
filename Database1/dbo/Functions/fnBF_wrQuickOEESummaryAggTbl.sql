CREATE FUNCTION [dbo].[fnBF_wrQuickOEESummaryAggTbl](
  	  @PUId                    Varchar(max),
  	  @StartTime               datetime = NULL,
  	  @EndTime                 datetime = NULL,
  	  @InTimeZone  	    	    	    	   nvarchar(200) = null,
  	  @ReportType Int = 1,
 	  @IncludeNPTFilter BIT = 0
  	  )
/* ##### fnBF_wrQuickOEESummaryAgg #####
Description  	  : Returns raw data like npt, downtime, production amount & etc at unit level.
Creation Date  	  : if any
Created By  	  : if any
#### Update History ####
DATE  	    	    	    	  Modified By 	  	 UserStory/Defect No  	    	  	  	 Comments  	    	  
----  	    	    	    	  -----------  	    	 -------------------  	    	    	    	 --------
2018-02-20  	  	  	 Prasad  	    	  	  	 7.0 SP3  	    	    	    	    	    	    	 Added logic to fetch data along with NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL from one slice type Id. 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  No more different agg store for different groups
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	  	 Passed actual filter for NPT 	 
*/
RETURNS  @unitData Table(ProductId int,
  	    	    	    	    	    	  Product nVarchar(100),
  	    	    	    	    	    	  PPId Int,
  	    	    	    	    	    	  PathId Int,
  	    	    	    	    	    	  PathCode  nVarChar(100),
  	    	    	    	    	    	  ProcessOrder nVarChar(100),
  	    	    	    	    	    	  CrewDesc nVarchar(100),
  	    	    	    	    	    	  ShiftDesc nVarchar(100),
  	    	    	    	    	    	  IdealSpeed Float DEFAULT 0,
  	    	    	    	    	    	  ActualSpeed Float DEFAULT 0,
  	    	    	    	    	    	  IdealProduction Float DEFAULT 0,
  	    	    	    	    	    	  PerformanceRate Float DEFAULT 0,
  	    	    	    	    	    	  NetProduction Float DEFAULT 0,
  	    	    	    	    	    	  Waste Float DEFAULT 0,
  	    	    	    	    	    	  QualityRate Float DEFAULT 0,
  	    	    	    	    	    	  PerformanceDowntime Float DEFAULT 0,
  	    	    	    	    	    	  RunTime Float DEFAULT 0,
  	    	    	    	    	    	  Loadtime Float DEFAULT 0,
  	    	    	    	    	    	  AvaliableRate Float DEFAULT 0,
  	    	    	    	    	    	  OEE Float DEFAULT 0
  	    	    	    	    	    	  ,NPT Float DEFAULT 0
  	    	    	    	    	    	  ,DowntimeA Float DEFAULT 0
  	    	    	    	    	    	  ,DowntimeP Float DEFAULT 0
  	    	    	    	    	    	  ,DowntimeQ Float DEFAULT 0
  	    	    	    	    	    	  ,DowntimePL Float DEFAULT 0
 	  	  	  	  	  	  ,OEEType Int DEFAULT 0
 	  	  	  	  	  	  ,pu_id int
  	    	    	    	    	    	    	    	    	    	    	    	  )
AS
BEGIN
 	  	 DECLARE  	    	  @CapRates  	    	    	    	    	    	  tinyint
 	  	 SELECT  	  @CapRates = dbo.fnCMN_OEERateIsCapped()
 	  	 Declare @OrigStartTime Datetime, @OrigEndTime Datetime,@StartDate1 Datetime, @StartDate2 Datetime, @EndDate1 Datetime, @EndDate2 DateTime
 	  	 Select @OrigStartTime = @StartTime,@OrigEndTime = @endTime  	  
 	  	 SELECT @StartTime = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
 	  	 SELECT @endTime = dbo.fnServer_CmnConvertToDbTime(@endTime,@InTimeZone)
 	  	 Declare @units Table (Pu_Id Int, OEEType Int,Start_Date1 Datetime,End_Date1 Datetime,Start_Date2 Datetime,End_Date2 Datetime)
 	  	 Declare @units_temp AS UnitsType
 	  	 Insert Into @Units(Pu_Id)
 	  	 select Id from dbo.fnCMN_IdListToTable('xxx',@PUId,',')
  	  
 	  	 --  	  Select @StartDate1 = @StartTime, @EndDate2 = @EndTime
 	  	 UPDATE @units set Start_Date1 = @StartTime, End_Date2 = @EndTime,OEEType = 0
 	  	 ;WITH S As 
 	  	 (
 	  	  	 SELECT 
 	  	  	  	 O.Pu_Id,Min(O.Start_Time) Start_Time
 	  	  	 From 
 	  	  	  	 @units u 
 	  	  	  	 join OEEAggregation O   on O.Pu_Id = u.Pu_Id 
 	  	  	 Where 
 	  	  	  	 O.Start_Time >= @StartTime and O.End_Time <= @EndTime 
 	  	  	 Group by O.Pu_Id
 	  	 )
 	  	 UPDATE u
 	  	 SET 
 	  	  	 u.End_Date1 = S.Start_Time
 	  	 From 
 	  	  	 @units u 
 	  	  	 join S on S.Pu_Id = u.Pu_Id
 	  	 ;WITH S As 
 	  	 (
 	  	  	 SELECT 
 	  	  	  	 O.Pu_Id,Max(O.End_Time)  End_Time
 	  	  	 From 
 	  	  	  	 @units u join OEEAggregation O   on O.Pu_Id = u.Pu_Id 
 	  	  	 Where 
 	  	  	  	 O.End_Time < = @EndTime And O.Start_time >= @StartTime 
 	  	  	 Group by O.Pu_Id
 	  	 )
 	  	 UPDATE u
 	  	 SET 
 	  	  	 u.Start_Date2 = S.End_Time
 	  	 From 
 	  	  	 @units u 
 	  	  	 join S on S.Pu_Id = u.Pu_Id
  	  
 	  UPDATE @units SET Start_Date2 = Start_Date1,Start_Date1 = NULL Where End_Date1 IS NULL AND Start_Date2 IS NULL
 	  UPDATE @units SET Start_Date1 = NULL Where Start_Date1 = End_Date1
 	  UPDATE @units SET End_Date2 = NULL WHERE Start_Date2 = End_Date2
 	  Declare @OEEType nvarchar(10)
 	  UPDATE u
   	      	  SET u.OEEType = TFV.Value
   	   From 
   	      	   Table_Fields TF 
 	  	  	   
   	      	   JOIN Table_Fields_Values TFV  on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
   	      	   Join ED_FieldTypes EDFT  On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
   	      	   LEFT OUTER Join ED_FieldType_ValidValues EDFTV  on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
 	  	  	   LEFT OUTER join @units u on u.Pu_Id = TFV.KeyID 
   	   Where 
   	      	   TF.Table_Field_Desc = 'OEE Calculation Type'
 	   
  	  Declare @unitData1 Table(ProductId int,
  	    	    	    	    	    	  Product nVarchar(100),
  	    	    	    	    	    	  PPId Int,
  	    	    	    	    	    	  PathId Int,
  	    	    	    	    	    	  PathCode  nVarChar(100),
  	    	    	    	    	    	  ProcessOrder nVarChar(100),
  	    	    	    	    	    	  CrewDesc nVarchar(100),
  	    	    	    	    	    	  ShiftDesc nVarchar(100),
  	    	    	    	    	    	  IdealSpeed Float DEFAULT 0,
  	    	    	    	    	    	  ActualSpeed Float DEFAULT 0,
  	    	    	    	    	    	  IdealProduction Float DEFAULT 0,
  	    	    	    	    	    	  PerformanceRate Float DEFAULT 0,
  	    	    	    	    	    	  NetProduction Float DEFAULT 0,
  	    	    	    	    	    	  Waste Float DEFAULT 0,
  	    	    	    	    	    	  QualityRate Float DEFAULT 0,
  	    	    	    	    	    	  PerformanceDowntime Float DEFAULT 0,
  	    	    	    	    	    	  RunTime Float DEFAULT 0,
  	    	    	    	    	    	  Loadtime Float DEFAULT 0,
  	    	    	    	    	    	  AvaliableRate Float DEFAULT 0,
  	    	    	    	    	    	  OEE Float DEFAULT 0
  	    	    	    	    	    	  ,NPT Float DEFAULT 0
  	    	    	    	    	    	  ,DowntimeA Float DEFAULT 0
  	    	    	    	    	    	  ,DowntimeP Float DEFAULT 0
  	    	    	    	    	    	  ,DowntimeQ Float DEFAULT 0
  	    	    	    	    	    	  ,DowntimePL Float DEFAULT 0
 	  	  	  	  	  	  ,OEEType Int DEFAULT 0
 	  	  	  	  	  	  ,pu_id int
  	    	    	    	    	    	    	    	    	    	    	    	  )
 	  	  	  	  	  	  	  	  	  	  	  	  
  	 
  	  INSERT INTO @unitData1(PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	  Loadtime,AvaliableRate,OEE,NPT, DowntimeA, DowntimeP, DowntimeQ,DowntimePL,OEEType,pu_id )  	  
  	    	    	  SELECT 
  	    	    	    	  agg.PP_Id,
  	    	    	    	  pp.Process_Order,
  	    	    	    	  agg.Path_Id,
  	    	    	    	  pep.Path_Code,
  	    	    	    	  agg.prod_Id,
  	    	    	    	  p.Prod_Code,
  	    	    	    	  agg.Shift_Desc,
  	    	    	    	  agg.Crew_Desc,
  	    	    	    	  Sum(IdealSpeed), 
  	    	    	    	  Sum(ActualSpeed),
  	    	    	    	  Sum(TargetProduction),
  	    	    	    	  dbo.fnGEPSPerformance(sum(TotalProduction), sum(TargetProduction), @CapRates),
  	    	    	    	  Sum(GoodProduction),
  	    	    	    	  Sum(TotalProduction-GoodProduction),
  	    	    	    	  dbo.fnGEPSQuality(sum(TotalProduction), Sum(TotalProduction-GoodProduction), @CapRates),
  	    	    	    	  Sum(PerformanceDowntime),
  	    	    	    	  Sum(RunningTime),
  	    	    	    	  Sum(LoadingTime),
  	    	    	    	  dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunningTime), @CapRates),
  	    	    	    	  0 --PercentOEE --???OEE
  	    	    	    	  ,SUM(NPT), 
  	    	    	    	  
  	    	    	    	  
  	    	    	    	  Case When u.OEEType <> 4 Then Sum(LoadingTime) - Sum(RunningTime+PerformanceDowntime) Else SUM( 	  	  	  	  
 	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND agg.IsNPT = 1 AND u.OEEType = 4 THEN 0 ELSE DowntimeA END
 	  	  	  	  
 	  	  	  	  ) End DowntimeA ,
  	    	    	    	  Case When u.OEEType <> 4 Then Case when NOT (SUM(TargetProduction) > 0 AND SUM(TotalProduction) > 0) Then 0 Else (SUM(RunningTime)*SUM(TargetProduction)-SUM(RunningTime)*sum(TotalProduction))/SUM(TargetProduction) end Else 
 	  	  	  	  SUM(
 	  	  	  	  
 	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND agg.IsNPT = 1 AND u.OEEType = 4 THEN 0 ELSE DowntimeP end) End DowntimeP,
  	    	    	    	  Case When u.OEEType <> 4 Then Case when NOT (SUM(TargetProduction) > 0 AND SUM(TotalProduction) > 0 ) Then 0 Else ((SUM(RunningTime)*SUM(TotalProduction))-(sum(RunningTime)*sum(GoodProduction)))/sum(TargetProduction) end Else 
 	  	  	  	  
 	  	  	  	  SUM(CASE WHEN @IncludeNPTFilter =1 AND agg.IsNPT = 1 AND u.OEEType = 4 THEN 0 ELSE DowntimeQ end ) End DowntimeQ ,
  	    	    	    	  isnull(SUM(CASE WHEN @IncludeNPTFilter =1 AND agg.IsNPT = 1 AND u.OEEType = 4 THEN 0 ELSE DowntimePL end),0) DowntimePL
 	  	  	  	  ,u.OEEType,u.Pu_Id
  	    	    	  FROM 
 	  	  	  	  OEEaggregation  agg 
 	  	  	  	  Join @units u on u.Pu_Id = agg.Pu_Id
  	    	    	    	  LEFT JOIN dbo.Production_Plan pp  ON agg.PP_Id = pp.PP_Id
  	    	    	    	  LEFT JOIN Prdexec_Paths pep  on pep.Path_Id = agg.Path_Id 
  	    	    	    	  LEFT JOIN dbo.Products p  ON agg.Prod_Id = p.Prod_Id
  	    	    	  WHERE Start_Time >= u.End_Date1 and End_Time <= u.Start_Date2 and slice_type_id = 1 --and agg.PU_Id = @PUId --and agg.Reprocess_Record != 2
 	  	  	  AND 
 	  	  	  	 (
 	  	  	  	  	 (agg.IsNPT = 0 AND u.OEEType <> 4 AND @IncludeNPTFilter = 1)
 	  	  	  	  	 OR
 	  	  	  	  	 (1=1  AND @IncludeNPTFilter =0 AND u.OEEType <> 4 )
 	  	  	  	  	 OR
 	  	  	  	  	 (1=1  AND u.OEEType = 4)
 	  	  	  	 )
  	    	    	  GROUP BY agg.PP_Id,  	  pp.Process_Order,  	    	  agg.Path_Id,
  	    	    	    	  pep.Path_Code,
  	    	    	    	  agg.prod_Id,
  	    	    	    	  p.Prod_Code,
  	    	    	    	  agg.Shift_Desc,
  	    	    	    	  agg.Crew_Desc,u.OEEType,u.Pu_Id
 	  	  	 
 	  	  	 Insert Into @units_temp
 	  	  	 Select Pu_ID,OEEType,Start_Date1,End_Date1,NULL,NULL from @Units Where Start_Date1 <> End_Date1 and Start_Date1 IS NOT NULL
 	  	  	 if EXISTS (sELECT 1 FROM @units_temp)
 	  	  	 Begin
 	  	 INSERT INTO @unitData1(PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	    	  Loadtime,AvaliableRate,OEE,NPT, DowntimeA, DowntimeP, DowntimeQ,DowntimePL ,pu_id,OEEType)  	  
  	    	  Select PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	    	  Loadtime,AvaliableRate,OEE,NPT, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND OEEType = 4 THEN 0 ELSE DowntimeA end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND OEEType = 4 THEN 0 ELSE DowntimeP end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND OEEType = 4 THEN 0 ELSE DowntimeQ end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND OEEType = 4 THEN 0 ELSE DowntimePL end
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  ,PuId,OEEType
  	    	  from dbo.fnBF_wrQuickOEEProductSummaryTbl(@units_Temp,1,@StartDate1,@EndDate1,NULL,1,1,0)
  	    	  Where 
 	  	  	 (
 	  	  	  	 (IsNPT = 0 AND OEEType <> 4 AND @IncludeNPTFilter = 1)
 	  	  	  	 OR
 	  	  	  	 (1=1  AND @IncludeNPTFilter =0 AND OEEType <> 4 )
 	  	  	  	 OR
 	  	  	  	 (1=1  AND OEEType = 4)
 	  	  	 )
 	  	  	 End
 	  	  	 Delete from @units_temp
 	  	  	 Insert Into @units_temp
 	  	  	  	  
 	  	  	  	  Select Pu_ID,OEEType,Start_Date2,End_Date2,NULL,NULL from @Units Where Start_Date2 <> End_Date2 and End_Date2 IS NOT NULL
If exists(Select 1 from @units_temp)
Begin
INSERT INTO @unitData1(PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	    	  Loadtime,AvaliableRate,OEE,NPT, DowntimeA, DowntimeP, DowntimeQ,DowntimePL,pu_id,OEEType )  	  
  	    	  Select PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	    	  Loadtime,AvaliableRate,OEE,NPT, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND OEEType = 4 THEN 0 ELSE DowntimeA end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND OEEType = 4 THEN 0 ELSE DowntimeP end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND OEEType = 4 THEN 0 ELSE DowntimeQ end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND OEEType = 4 THEN 0 ELSE DowntimePL end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  PuId,OEEType
  	    	  from dbo.fnBF_wrQuickOEEProductSummaryTbl(@units_Temp,1,@StartDate1,@EndDate1,NULL,1,1,0)
  	    	  Where 
 	  	  	 (
 	  	  	  	 (IsNPT = 0 AND OEEType <> 4 AND @IncludeNPTFilter = 1)
 	  	  	  	 OR
 	  	  	  	 (1=1  AND @IncludeNPTFilter =0 AND OEEType <> 4 )
 	  	  	  	 OR
 	  	  	  	 (1=1  AND OEEType = 4)
 	  	  	 )
 	 End 	  
  	  INSERT INTO @unitData(PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	  Loadtime,AvaliableRate,OEE,NPT, DowntimeA, DowntimeP, DowntimeQ,DowntimePL,OEEType,pu_id )  	  
  	  SELECT 
  	    	    	    	  PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,
  	    	    	    	  Sum(IdealSpeed), 
  	    	    	    	  Sum(ActualSpeed),
  	    	    	    	  Sum(IdealProduction),
  	    	    	    	  dbo.fnGEPSPerformance(sum(NetProduction+Waste), sum(IdealProduction), @CapRates),
  	    	    	    	  Sum(NetProduction),
  	    	    	    	  Sum(Waste),
  	    	    	    	  dbo.fnGEPSQuality(sum(NetProduction+Waste), Sum(Waste), @CapRates),
  	    	    	    	  Sum(PerformanceDowntime),
  	    	    	    	  Sum(RunTime),
  	    	    	    	  Sum(Loadtime),
  	    	    	    	  dbo.fnGEPSAvailability(sum(Loadtime), sum(RunTime), @CapRates),
  	    	    	    	  0 --PercentOEE --???OEE
  	    	    	    	  ,SUM(NPT), 
  	    	    	    	  Case When OEEType <> 4 Then Sum(Loadtime) - Sum(RunTime+PerformanceDowntime) Else SUM(DowntimeA) End DowntimeA ,
  	    	    	    	  Case When OEEType <> 4 Then Case when NOT (SUM(IdealProduction) > 0 AND SUM(NetProduction+Waste) > 0) Then 0 Else (SUM(RunTime+PerformanceDowntime)*SUM(IdealProduction)-SUM(RunTime+PerformanceDowntime)*sum(NetProduction+Waste))/SUM(IdealProduction) end Else SUM(DowntimeP) End DowntimeP,
  	    	    	    	  Case When OEEType <> 4 Then Case when NOT (SUM(IdealProduction) > 0 AND SUM(NetProduction+Waste) > 0 ) Then 0 Else ((SUM(RunTime+PerformanceDowntime)*SUM(NetProduction+Waste))-(sum(RunTime+PerformanceDowntime)*sum(NetProduction)))/sum(IdealProduction) end Else SUM(DowntimeQ) End DowntimeQ ,
  	    	    	    	  isnull(SUM(DowntimePL),0) DowntimePL
 	  	  	  	  ,OEEType,pu_id
  	    	    	  FROM @unitData1  	    	  
  	    	    	  GROUP BY 
  	    	    	    	  PPId,  	  
  	    	    	    	  ProcessOrder,  	    	  
  	    	    	    	  PathId,
  	    	    	    	  PathCode,
  	    	    	    	  ProductId,
  	    	    	    	  Product,
  	    	    	    	  ShiftDesc,
  	    	    	    	  CrewDesc,
 	  	  	  	  OEEType,pu_id
  	  /*
  	  After converting classic values to Time based, need to convert DownTimeP & DownTimeQ 
  	  in case of NetProduction+waste < = 0 for units having classic OEE mode
  	  */
 	  UPDATE @unitData SET NPT = 0 WHERE OEEType <> 4 AND @IncludeNPTFilter = 0
 	  UPDATE @unitData SET Loadtime = CASE WHEN Loadtime - NPT > 0 THEN Loadtime - NPT ELSE 0 END, 
 	  RunTime = CASE WHEN Loadtime - (DowntimeA+DowntimeP+DowntimePL+DowntimeQ) - NPT > 0 THEN Loadtime - (DowntimeA+DowntimeP+DowntimePL+DowntimeQ) - NPT ELSE 0 END  
 	  WHERE OEEType = 4 AND @IncludeNPTFilter = 1
  	  UPDATE A 
  	  SET  	    	  
  	    	  A.DownTimeP = LoadTime - DownTimeA
  	  From @UnitData  A
  	  Where OEEType  	  <> 4 And (NetProduction+Waste)<=0
  	  UPDATE @unitData 
  	  SET 
  	    	  DowntimeA = CASE WHEN DowntimeA <0 then 0 else DowntimeA end,
  	    	  DowntimeP = CASE WHEN DowntimeP <0 then 0 else DowntimeP end,
  	    	  DowntimeQ = CASE WHEN DowntimeQ <0 then 0 else DowntimeQ end
  	  UPDATE @unitData SET OEE = AvaliableRate/100 * QualityRate/100 * PerformanceRate/100 * 100
  	  RETURN
END
