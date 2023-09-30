CREATE FUNCTION [dbo].[fnBF_wrQuickOEESummaryAgg](
  	  @PUId                    Int,
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
  	    	    	    	    	    	    	    	    	    	    	    	  )
AS
BEGIN
  	  DECLARE  	    	  @CapRates  	    	    	    	    	    	  tinyint
  	  SELECT  	  @CapRates = dbo.fnCMN_OEERateIsCapped()
  	  Declare @OrigStartTime Datetime, @OrigEndTime Datetime,@StartDate1 Datetime, @StartDate2 Datetime, @EndDate1 Datetime, @EndDate2 DateTime
  	  Select @OrigStartTime = @StartTime,@OrigEndTime = @endTime  	  
  	  SELECT @StartTime = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
  	  SELECT @endTime = dbo.fnServer_CmnConvertToDbTime(@endTime,@InTimeZone)
  	  
  	  Select @StartDate1 = @StartTime, @EndDate2 = @EndTime
  	  Select @EndDate1 = Min(Start_Time) from OEEAggregation Where Pu_Id =@PUId and Start_Time >= @StartTime and End_Time <= @EndTime
  	  Select @StartDate2 = Max(End_Time) from OEEAggregation Where Pu_Id =@PUId and End_Time < = @EndTime And Start_time >= @StartTime
  	  
  	  IF @EndDate1 IS NULL AND @StartDate2 IS NULL 
  	  BEgin
  	    	  SET @StartDate2 = @StartDate1
 	  	  SET @StartDate1 = NULL
  	  ENd
 	  IF @StartDate1 = @EndDate1
 	  	 SET @StartDate1 = NULL
 	  IF @StartDate2 = @EndDate2
 	  	 SET @EndDate2 = NULL
  	  Declare @OEEType nvarchar(10)
  	  set @OEEType  = ''
  	  Select 
  	    	  @OEEType = EDFTV.Field_desc
  	  From 
  	    	  Table_Fields TF
  	    	  JOIN Table_Fields_Values TFV on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
  	    	  Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
  	    	  LEFT OUTER Join ED_FieldType_ValidValues EDFTV on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
  	  Where 
  	    	  TF.Table_Field_Desc = 'OEE Calculation Type'
  	    	  AND TFV.KeyID = @PUId
  	  
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
  	    	    	    	    	    	    	    	    	    	    	    	  )
 	  	  	  	  	  	  	  	  	  	  	  	  
  	  DELETE FROM @unitData1
  	  INSERT INTO @unitData1(PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	  Loadtime,AvaliableRate,OEE,NPT, DowntimeA, DowntimeP, DowntimeQ,DowntimePL )  	  
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
  	    	    	    	  
  	    	    	    	  
  	    	    	    	  Case When @OEEType <>'Time Based' Then Sum(LoadingTime) - Sum(RunningTime+PerformanceDowntime) Else SUM( 	  	  	  	  
 	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND agg.IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimeA END
 	  	  	  	  
 	  	  	  	  ) End DowntimeA ,
  	    	    	    	  Case When @OEEType <>'Time Based' Then Case when NOT (SUM(TargetProduction) > 0 AND SUM(TotalProduction) > 0) Then 0 Else (SUM(RunningTime)*SUM(TargetProduction)-SUM(RunningTime)*sum(TotalProduction))/SUM(TargetProduction) end Else 
 	  	  	  	  SUM(
 	  	  	  	  
 	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND agg.IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimeP end) End DowntimeP,
  	    	    	    	  Case When @OEEType <>'Time Based' Then Case when NOT (SUM(TargetProduction) > 0 AND SUM(TotalProduction) > 0 ) Then 0 Else ((SUM(RunningTime)*SUM(TotalProduction))-(sum(RunningTime)*sum(GoodProduction)))/sum(TargetProduction) end Else 
 	  	  	  	  
 	  	  	  	  SUM(CASE WHEN @IncludeNPTFilter =1 AND agg.IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimeQ end ) End DowntimeQ ,
  	    	    	    	  isnull(SUM(CASE WHEN @IncludeNPTFilter =1 AND agg.IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimePL end),0) DowntimePL
  	    	    	  FROM OEEaggregation  agg
  	    	    	    	  LEFT JOIN dbo.Production_Plan pp WITH (NOLOCK) ON agg.PP_Id = pp.PP_Id
  	    	    	    	  LEFT JOIN Prdexec_Paths pep on pep.Path_Id = agg.Path_Id 
  	    	    	    	  LEFT JOIN dbo.Products p WITH (NOLOCK) ON agg.Prod_Id = p.Prod_Id
  	    	    	  WHERE Start_Time >= @EndDate1 and End_Time <= @StartDate2 and slice_type_id = 1 and agg.PU_Id = @PUId --and agg.Reprocess_Record != 2
 	  	  	  AND 
 	  	  	  	 (
 	  	  	  	  	 (agg.IsNPT = 0 AND @OEEType <> 'Time Based' AND @IncludeNPTFilter = 1)
 	  	  	  	  	 OR
 	  	  	  	  	 (1=1  AND @IncludeNPTFilter =0 AND @OEEType <> 'Time Based' )
 	  	  	  	  	 OR
 	  	  	  	  	 (1=1  AND @OEEType = 'Time Based')
 	  	  	  	 )
  	    	    	  GROUP BY agg.PP_Id,  	  pp.Process_Order,  	    	  agg.Path_Id,
  	    	    	    	  pep.Path_Code,
  	    	    	    	  agg.prod_Id,
  	    	    	    	  p.Prod_Code,
  	    	    	    	  agg.Shift_Desc,
  	    	    	    	  agg.Crew_Desc
  	 IF @StartDate1 <> @EndDate1 And @StartDate1 IS NOT NULL
 	 Begin 
 	    	  INSERT INTO @unitData1(PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	    	  Loadtime,AvaliableRate,OEE,NPT, DowntimeA, DowntimeP, DowntimeQ,DowntimePL )  	  
  	    	  Select PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	    	  Loadtime,AvaliableRate,OEE,NPT, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimeA end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimeP end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimeQ end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimePL end
  	    	  from dbo.fnBF_wrQuickOEEProductSummary(@PUId,@StartDate1,@EndDate1,NULL,1,1,0)
  	    	  Where 
 	  	  	 (
 	  	  	  	 (IsNPT = 0 AND @OEEType <> 'Time Based' AND @IncludeNPTFilter = 1)
 	  	  	  	 OR
 	  	  	  	 (1=1  AND @IncludeNPTFilter =0 AND @OEEType <> 'Time Based' )
 	  	  	  	 OR
 	  	  	  	 (1=1  AND @OEEType = 'Time Based')
 	  	  	 )
  	    	 End
 	  	 -- UNION ALL  	  
IF @StartDate2 <> @EndDate2 AND @EndDate2 IS NOT NULL
Begin
  	    	 INSERT INTO @unitData1(PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	    	  Loadtime,AvaliableRate,OEE,NPT, DowntimeA, DowntimeP, DowntimeQ,DowntimePL )  	  
  	  	 Select PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	    	  Loadtime,AvaliableRate,OEE,NPT,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimeA end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimeP end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimeQ end,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  CASE WHEN @IncludeNPTFilter =1 AND IsNPT = 1 AND @OEEType = 'Time Based' THEN 0 ELSE DowntimePL end from 
  	    	  dbo.fnBF_wrQuickOEEProductSummary(@PUId,@StartDate2,@EndDate2,NULL,1,1,0)
  	    	  Where 
 	  	  	 (
 	  	  	  	 (IsNPT = 0 AND @OEEType <> 'Time Based' AND @IncludeNPTFilter = 1)
 	  	  	  	 OR
 	  	  	  	 (1=1  AND @IncludeNPTFilter =0 AND @OEEType <> 'Time Based' )
 	  	  	  	 OR
 	  	  	  	 (1=1  AND @OEEType = 'Time Based')
 	  	  	 )
  	  End
 	  DELETE FROM @unitData
  	  INSERT INTO @unitData(PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,ShiftDesc,CrewDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
    	      	      	      	      	      	      	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
    	      	      	      	      	      	      	    	  Loadtime,AvaliableRate,OEE,NPT, DowntimeA, DowntimeP, DowntimeQ,DowntimePL )  	  
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
  	    	    	    	  Case When @OEEType <>'Time Based' Then Sum(Loadtime) - Sum(RunTime+PerformanceDowntime) Else SUM(DowntimeA) End DowntimeA ,
  	    	    	    	  Case When @OEEType <>'Time Based' Then Case when NOT (SUM(IdealProduction) > 0 AND SUM(NetProduction+Waste) > 0) Then 0 Else (SUM(RunTime+PerformanceDowntime)*SUM(IdealProduction)-SUM(RunTime+PerformanceDowntime)*sum(NetProduction+Waste))/SUM(IdealProduction) end Else SUM(DowntimeP) End DowntimeP,
  	    	    	    	  Case When @OEEType <>'Time Based' Then Case when NOT (SUM(IdealProduction) > 0 AND SUM(NetProduction+Waste) > 0 ) Then 0 Else ((SUM(RunTime+PerformanceDowntime)*SUM(NetProduction+Waste))-(sum(RunTime+PerformanceDowntime)*sum(NetProduction)))/sum(IdealProduction) end Else SUM(DowntimeQ) End DowntimeQ ,
  	    	    	    	  isnull(SUM(DowntimePL),0) DowntimePL
  	    	    	  FROM @unitData1  	    	  
  	    	    	  GROUP BY 
  	    	    	    	  PPId,  	  
  	    	    	    	  ProcessOrder,  	    	  
  	    	    	    	  PathId,
  	    	    	    	  PathCode,
  	    	    	    	  ProductId,
  	    	    	    	  Product,
  	    	    	    	  ShiftDesc,
  	    	    	    	  CrewDesc
  	  /*
  	  After converting classic values to Time based, need to convert DownTimeP & DownTimeQ 
  	  in case of NetProduction+waste < = 0 for units having classic OEE mode
  	  */
 	  UPDATE @unitData SET NPT = 0 WHERE @OEEType <> 'Time Based' AND @IncludeNPTFilter = 0
 	  UPDATE @unitData SET Loadtime = CASE WHEN Loadtime - NPT > 0 THEN Loadtime - NPT ELSE 0 END, 
 	  RunTime = CASE WHEN Loadtime - (DowntimeA+DowntimeP+DowntimePL+DowntimeQ) - NPT > 0 THEN Loadtime - (DowntimeA+DowntimeP+DowntimePL+DowntimeQ) - NPT ELSE 0 END  
 	  WHERE @OEEType = 'Time Based' AND @IncludeNPTFilter = 1
  	  UPDATE A 
  	  SET  	    	  
  	    	  A.DownTimeP = LoadTime - DownTimeA
  	  From @UnitData  A
  	  Where @OEEType  	  <> 'Time Based' And (NetProduction+Waste)<=0
  	  --UPDATE @unitData 
  	  --SET 
  	  --  	  DowntimeA = CASE WHEN DowntimeA <0 then 0 else DowntimeA end,
  	  --  	  DowntimeP = CASE WHEN DowntimeP <0 then 0 else DowntimeP end,
  	  --  	  DowntimeQ = CASE WHEN DowntimeQ <0 then 0 else DowntimeQ end
  	  UPDATE @unitData SET OEE = AvaliableRate/100 * QualityRate/100 * PerformanceRate/100 * 100
  	  RETURN
END
