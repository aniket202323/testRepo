CREATE FUNCTION dbo.fnCMN_Performance840D(
 	  	  	  	  	 @UnitId int, 
 	  	  	  	  	 @StartTime 	 datetime, 
 	  	  	  	  	 @EndTime 	 datetime,
 	  	  	  	  	 @FilterNPT 	 Int) 
  	  RETURNS @ReturnData TABLE (ProductionAmount Float) 
AS 
BEGIN
 	 DECLARE @ProductionVarId Int
 	 DECLARE @SumEquivelentTime Bigint
 	 DECLARE @CalendarTime 	 Bigint
 	 DECLARE @TotallPlannedDT 	  	 BigInt
 	 DECLARE @NPTCategoryId Int
 	 DECLARE @PlannedDTNPT  TABLE(Id int Identity(1,1), StartTime DateTime, EndTime DateTime)
 	 DECLARE @ProductiveTime TABLE(Id int Identity(1,1), StartTime DateTime, EndTime DateTime)
 	 DECLARE @Start Int, @End Int,@LoopStartTime DateTime,@LoopEndTime DateTime
 	 DECLARE @NextStart DateTime,@NextEnd DateTime
 	 SET @TotallPlannedDT = 0
 	  	 /* 	 840D  	  	  	 Performance = Sum(ET)/Available Time
 	  	  	  	  	  	  	 Available Time = Calendar Time - Planned DT  	  	  	  	  	 
 	  	  	  	  	  	  	 ET = Equivalent Time (Variable providing runtime over interval) 	  	 */ 	 
 	 SELECT @ProductionVarId = Production_Variable,
 	  	  	 @NPTCategoryId 	 = Non_Productive_Category
 	  	 FROM Prod_Units a
 	  	 WHERE a.pu_Id = @Unitid
 	 IF @ProductionVarId Is Null 
 	 BEGIN
 	  	 INSERT INTO @ReturnData(ProductionAmount )  	 VALUES(0)
 	  	 RETURN
 	 END
 	 IF @NPTCategoryId Is Not Null and @FilterNPT = 1
 	 BEGIN
 	  	 INSERT INTO @PlannedDTNPT (StartTime,EndTime)
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
 	  	  	 
 	  	 SELECT @Start = Min(Id) From @PlannedDTNPT 	 
 	  	 SELECT @End = Max(Id) From @PlannedDTNPT
 	  	 IF @End Is Null 
 	  	  	 SET @End = 0
 	  	 IF @Start Is NUll
 	  	  	 SET @Start = 1
 	  	 SET @LoopStartTime = @StartTime
 	  	 SET @LoopEndTime = @EndTime
 	  	 WHILE @Start <= @End
 	  	 BEGIN
 	  	  	 SET @NextStart = Null
 	  	  	 SET @NextEnd = Null
 	  	  	 SELECT @NextStart = StartTime,@NextEnd = EndTime
 	  	  	  	 FROM @PlannedDTNPT 
 	  	  	  	 WHERE Id = @Start
 	  	  	 IF @LoopStartTime < @NextStart
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO @ProductiveTime(StartTime,EndTime) Values(@LoopStartTime,@NextStart)
 	  	  	 END
 	  	  	 SET @LoopStartTime = @NextEnd
 	  	  	 SET @Start = @Start +1
 	  	 END
 	  	 IF @LoopStartTime < @EndTime
 	  	 BEGIN
 	  	  	  	 INSERT INTO @ProductiveTime(StartTime,EndTime) Values(@LoopStartTime,@EndTime)
 	  	 END
 	 END
 	 IF Not Exists(Select 1 From @ProductiveTime)
 	 BEGIN
 	  	 INSERT INTO @ProductiveTime(StartTime,EndTime) Values(@StartTime,@EndTime)
 	 END
 	 SELECT @SumEquivelentTime = SUM(convert(Float,Result)) 
 	  	 FROM Tests a
 	  	 JOIN @ProductiveTime b ON a.result_On > b.StartTime and a.result_On <= b.EndTime
 	  	 Where Var_Id = @ProductionVarId AND Result Is Not Null
 	 
 	 SET @SumEquivelentTime = COALESCE(@SumEquivelentTime,0)
 	 INSERT INTO @ReturnData(ProductionAmount)  	 VALUES(@SumEquivelentTime)
 	 RETURN
END
