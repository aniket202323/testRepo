CREATE FUNCTION dbo.fnCMN_PerformanceEDM(
 	  	  	  	  	 @UnitId int, 
 	  	  	  	  	 @StartTime 	 datetime, 
 	  	  	  	  	 @EndTime 	 datetime,
 	  	  	  	  	 @FilterNPT 	 Int) 
  	  RETURNS @ReturnData TABLE (ProductionAmount Float,IdealProductionAmount Float) 
AS 
BEGIN
  	  DECLARE @AllEvents  TABLE(Id int Identity(1,1), Start_Time DateTime, End_Time DateTime,EventId Int,ProdId 	 Int,SpecValue Float,Duration Int)
  	  DECLARE @CurrentStart DateTime,@CurrentEnd DateTime,@CurrentProdId 	 Int,
  	  	  	  @CurrentSpecId Int,@CurrentCharId Int,@PropId Int,@ProdDesc nVarChar(50),@CurrentValue float
 	  DECLARE @CurrentEventStatus Int,@CurrentEventStart DateTime,@CurrentEventEnd DateTime
 	  DECLARE @EventId Int,@InProgressStatus Int
 	  DECLARE @TotalTime Float
 	  DECLARE @SumIdealTime Bigint 	  
 	  DECLARE @PerfDTCategory Int
 	  DECLARE @TotallPlannedDT 	  	 BigInt
 	  DECLARE @NPTCategoryId Int
  	  DECLARE @PlannedDT  TABLE(Id int Identity(1,1), StartTime DateTime, EndTime DateTime Null,ErcId INT)
 	  DECLARE @PlannedDT2  TABLE(Id int Identity(1,1), StartTime DateTime, EndTime DateTime Null)
 	  DECLARE @Start Int,@Start2 Int, @End Int
 	  DECLARE @NextStart DateTime,@NextEnd DateTime
 	 INSERT INTO @AllEvents (EventId,Start_Time, End_Time,ProdId)
   	  	 SELECT  e.Event_Id,e.Start_Time, e.TimeStamp,coalesce(e.Applied_Product,Prod_Id)
   	    	  	  	 FROM Events e 
 	  	  	  	 JOIN Production_Starts b on e.TimeStamp >= b.start_time and ( e.TimeStamp < b.end_Time  or b.end_Time is null) and b.PU_Id = e.PU_Id
 	  	  	  	 WHERE e.TimeStamp > @StartTime AND e.TimeStamp <= @EndTime and e.TimeStamp != e.Start_Time AND e.Pu_Id = @UnitId
   	    	  	  	 Order By  e.TimeStamp
 	 SELECT @InProgressStatus = Min(Valid_Status) 
 	  	  	 FROM PrdExec_Status 
 	  	  	 WHERE Is_Default_Status = 1 and PU_Id = @UnitId
 	 IF @CurrentEventStatus is null
 	  	 select @CurrentEventStatus = 16 --In Progress
 	 SELECT @CurrentEventEnd = MAX(TimeStamp) 
 	  	 FROM  Events 
 	  	 WHERE PU_Id = @UnitId 
 	 SELECT @CurrentEventStart = Start_Time,@CurrentEventStatus = Event_Status,@EventId = Event_Id
 	  	 FROM  Events
 	  	 WHERE PU_Id = @UnitId  and TimeStamp = @CurrentEventEnd
 	 IF @CurrentEventStatus = @InProgressStatus 
 	 BEGIN
 	  	 IF  Exists(select 1 from @AllEvents WHERE EventId = @EventId)
 	  	 BEGIN
 	  	  	 DELETE FROM  @AllEvents WHERE EventId= @EventId
 	  	 END
 	 END
 	 UPDATE @AllEvents SET end_Time = @EndTime Where end_Time > @EndTime
 	 UPDATE @AllEvents set Duration = DateDiff(Second,start_Time,End_Time)
 	 SELECT @StartTime = MIN(Start_Time),@EndTime = MAX(End_Time) FROM @AllEvents
 	 SELECT @CurrentSpecId = Production_Rate_Specification,
 	  	  	 @NPTCategoryId 	 = Non_Productive_Category,
 	  	  	 @PerfDTCategory = Performance_Downtime_Category
 	  	 FROM Prod_Units a
 	  	 WHERE a.pu_Id = @Unitid
 	 Insert Into @PlannedDT(StartTime,EndTime,ErcId)
 	  	  	 SELECT Start_Time,End_Time,b.ERC_Id 
 	  	  	 FROM Timed_Event_Details a
 	  	  	 LEFT JOIN Event_Reason_Category_Data b on a.Event_Reason_Tree_Data_Id = b.Event_Reason_Tree_Data_Id 
 	  	  	 WHERE PU_Id = @UnitId and Start_Time < @EndTime and (End_Time > @StartTime or End_Time is Null)
 	 IF @PerfDTCategory IS NOT NULL
 	 BEGIN
 	  	 DELETE FROM @PlannedDT WHERE ErcId = @PerfDTCategory
 	 END
 	 IF @NPTCategoryId Is Not Null and @FilterNPT = 1
 	 BEGIN
 	  	 INSERT INTO @PlannedDT (StartTime,EndTime)
 	  	 SELECT 	 StartTime 	 = CASE 	 WHEN np.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	  	 END,
 	  	  	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > @EndTime THEN @EndTime
 	  	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	  	 END
 	  	  	 FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPTCategoryId
 	  	  	 WHERE 	 PU_Id = @UnitId 	 AND np.Start_Time < @EndTime AND np.End_Time > @StartTime
 	 END
 	 Update @PlannedDT set EndTime = @EndTime WHERE EndTime Is Null
 	 Update @PlannedDT set StartTime = @StartTime WHERE StartTime < @StartTime
 	 UPDATE @PlannedDT SET EndTime = @EndTime Where EndTime > @EndTime
 	 INSERT INTO @PlannedDT2(StartTime,EndTime) SELECT StartTime,EndTime FROM @PlannedDT ORDER BY StartTime
 	 SELECT @Start = Min(Id) From @PlannedDT2 	 
 	 SELECT @End = Max(Id) From @PlannedDT2
 	 IF @End Is Null 
 	  	 SET @End = 0
 	 IF @Start Is NUll
 	  	 SET @Start = 1
 	 WHILE @Start < @End
 	 BEGIN
 	  	 SET @NextStart = Null
 	  	 SET @NextEnd = Null
 	  	 SELECT @CurrentStart = StartTime,@CurrentEnd = EndTime 	 FROM @PlannedDT2 WHERE Id = @Start
 	  	 DELETE FROM @PlannedDT2 WHERE Endtime  <= @CurrentEnd and Id > @Start
 	  	 UPDATE @PlannedDT2 SET StartTime = @CurrentEnd  WHERE Id > @Start and StartTime < @CurrentStart
 	  	 SET @Start2 = Null
 	  	 SELECT @Start2 = Min(Id) From @PlannedDT2 Where Id > @Start
 	  	 IF @Start2 Is Null
 	  	  	 SET @Start = @End +1
 	  	 ELSE 
 	  	  	 SET @Start = @Start2 
 	 END
 	 SELECT @PropId = Prop_Id 
 	  	 FROM Specifications
 	  	 WHERE Spec_Id = @CurrentSpecId
 	 SELECT @Start = Min(Id) From @AllEvents 	 
 	 SELECT @End = Max(Id) From @AllEvents
 	 IF @End Is Null 
 	  	 SET @End = 0
 	 IF @Start Is NUll
 	  	 SET @Start = 1
 	 SET @TotallPlannedDT = 0
 	 WHILE @Start <= @End
 	 BEGIN 
 	  	 SET @ProdDesc = Null
 	  	 SELECT @CurrentStart = Start_Time,@CurrentEnd = end_Time,@CurrentProdId 	 = ProdId
 	  	  	 FROM @AllEvents WHERE Id = @Start
 	  	 SELECT @ProdDesc = Prod_Desc
 	  	  	 FROM Products a
 	  	  	 WHERE Prod_Id = @CurrentProdId
 	  	 SELECT @CurrentCharId= Char_Id 
 	  	  	 FROM Characteristics 
 	  	  	 WHERE Char_Desc = @ProdDesc and Prop_Id = @PropId
 	  	 SELECT @CurrentValue = convert(float,Target) 
 	  	  	 FROM Active_Specs 
 	  	  	 Where Char_Id = @CurrentCharId and Spec_Id = @CurrentSpecId
 	  	 UPDATE @AllEvents Set specValue =@CurrentValue
 	  	  	 WHERE  Id = @Start
 	  	 SELECT @TotallPlannedDT = @TotallPlannedDT + Coalesce(SUM(DateDiff(second,
 	  	  	  	 Case WHEN StartTime < @CurrentStart THEN @CurrentStart ELSE StartTime END,
 	  	  	  	 Case WHEN EndTime > @CurrentEnd THEN @CurrentEnd  	  ELSE EndTime END )),0)
 	  	  	 FROM @PlannedDT2 a
 	  	  	 WHERE StartTime < @CurrentEnd and (EndTime > @CurrentStart)
 	  	 SET @Start = @Start + 1
 	 END
 	 SELECT @SumIdealTime = sum(specValue),@TotalTime = SUM(Duration)
 	  	 FROM @AllEvents
 	 SELECT @TotalTime = @TotalTime  - @TotallPlannedDT
 	 INSERT INTO @ReturnData(ProductionAmount ,IdealProductionAmount) 
 	  	 VALUES(@TotalTime/60.0,@SumIdealTime)
 	 RETURN
END
