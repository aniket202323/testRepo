CREATE FUNCTION dbo.fnCMN_QualityFromEvents(@UnitId int, 
 	  	  	  	  	 @StartTime 	 datetime, 
 	  	  	  	  	 @EndTime 	 datetime,
 	  	  	  	  	 @FilterNPT 	  	 Int) 
  	  RETURNS  Bigint
AS 
BEGIN
 	 DECLARE @AllReworkEvents  TABLE(Id int Identity(1,1), Start_Time DateTime, End_Time DateTime)
 	 DECLARE @AllEvents TABLE (Start_Time DateTime, End_Time DateTime,ERCId Int)
 	 DECLARE @AllEventsSorted TABLE (Id int Identity(1,1), Start_Time DateTime, End_Time DateTime)
 	 DECLARE @ReworkStatuses Table (EventStatus Int)
 	 DECLARE @RWTime Bigint 	 
 	 DECLARE @nptTime Bigint
 	 DECLARE @NPCategoryId INT,@DTPerfCategoryId Int
 	 DECLARE @Start Int,@End Int
 	 DECLARE @CurrentStart DateTime, @CurrentEnd DateTime
 	 DECLARE @Start1 Int,@End1 Int,@CurrentStart1 DateTime, @CurrentEnd1 DateTime,@InitalStart Int
 	 DECLARE @LastStart DateTime, @LastEnd DateTime,@LastId Int
 	 SELECT 	 @NPCategoryId 	 = Non_Productive_Category,
 	  	  	 @DTPerfCategoryId 	  	 = Performance_Downtime_Category
 	 FROM dbo.Prod_Units a WITH (NOLOCK)
 	 WHERE PU_Id = @UnitId
 	 SET @nptTime = 0
 	 INSERT INTO @ReworkStatuses(EventStatus)
 	  	 SELECT Distinct KeyId
 	  	 FROM Table_Fields_Values  
 	  	 WHERE Table_Field_Id = -97 AND TableId = 37
 	 INSERT INTO @AllReworkEvents(Start_Time,End_Time)
 	  	 SELECT  Start_Time,Timestamp
 	  	 FROM Events a
 	  	 JOIN @ReworkStatuses b on b.EventStatus = a.Event_Status
 	  	 WHERE a.TimeStamp > @StartTime AND a.TimeStamp <= @EndTime AND a.Pu_Id = @UnitId
 	 SET @End = @@ROWCOUNT
 	 SET @Start = 1
 	 WHILE @Start <= @end
 	 BEGIN
 	  	 SELECT @CurrentStart = Start_Time,@CurrentEnd = End_Time 
 	  	  	 FROM @AllReworkEvents 
 	  	  	 WHERE Id = @Start
 	  	 INSERT INTO @AllEvents(Start_Time,End_Time,ERCId)
 	  	  	 SELECT Start_Time = CASE 	 WHEN ted.Start_Time < @CurrentStart THEN @CurrentStart
 	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	    End_Time = CASE 	 WHEN ted.End_Time > @CurrentEnd THEN @CurrentEnd
 	  	  	  	  	  	  	  	  	 WHEN ted.End_Time Is Null THEN @CurrentEnd
 	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	 ercd.ERC_Id
 	  	  	  	 FROM Timed_Event_Details ted WITH (NOLOCK) 
 	  	  	  	 Left JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	 WHERE ted.Start_Time < @CurrentEnd
 	  	  	  	  	 AND (ted.End_Time > @CurrentStart or ted.End_Time Is Null)
 	  	  	  	  	 AND PU_Id = @UnitId 
 	  	 DELETE FROM @AllEvents WHERE  	 ERCId =  @DTPerfCategoryId
 	  	 IF  @FilterNPT = 1 	 
 	  	 BEGIN
 	  	  	 INSERT INTO @AllEvents(Start_Time,End_Time)
 	  	  	  	 SELECT 	 StartTime 	 = CASE 	 WHEN np.Start_Time < @CurrentStart THEN @CurrentStart
 	  	  	  	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > @CurrentEnd THEN @CurrentEnd
 	  	  	  	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	  	  	  	 END
 	  	  	  	 FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) 
 	  	  	  	  	  	 ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPCategoryId
 	  	  	  	 WHERE 	 PU_Id = @UnitId 	 AND np.Start_Time < @CurrentEnd AND np.End_Time > @CurrentStart
 	  	 END
 	  	 DELETE FROM @AllEventsSorted
 	  	 INSERT INTO @AllEventsSorted (Start_Time,End_Time)
 	  	  	 SELECT Start_Time,End_Time
 	  	  	  	 FROM @AllEvents
 	  	  	  	 ORDER BY Start_Time
 	  	 DELETE FROM @AllEvents
 	  	 SET @End1 = 0
 	  	 SET @Start1 = 1
 	  	 SELECT  @End1 = Max(Id) FROM @AllEventsSorted 
 	  	 SELECT @Start1 = Min(Id) FROM @AllEventsSorted 
 	  	 IF @End1 Is Null SET @End1 = 0
 	  	 IF @Start1 Is Null SET @Start1 = 1
 	  	 SET @InitalStart = @Start1
 	  	 WHILE @Start1 <= @End1
 	  	 BEGIN
 	  	  	 SELECT @CurrentStart1 = Start_Time,@CurrentEnd1 = End_Time  
 	  	  	  	 FROM @AllEventsSorted 
 	  	  	  	 WHERE Id = @Start1
 	  	  	 IF @Start1 != @InitalStart
 	  	  	 BEGIN
 	  	  	  	 IF @CurrentStart1 >= @LastEnd
 	  	  	  	 BEGIN
 	  	  	  	  	 SET @LastId = @Start1
 	  	  	  	 END
 	  	  	  	 ELSE IF @CurrentEnd1 <= @LastEnd
 	  	  	  	 BEGIN
 	  	  	  	  	 DELETE FROM @AllEventsSorted WHERE Id = @Start1
 	  	  	  	  	 SET @CurrentEnd1 = @LastEnd
 	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 UPDATE @AllEventsSorted SET End_Time = @CurrentEnd1 WHERE Id = @LastId
 	  	  	  	  	 DELETE FROM @AllEventsSorted WHERE Id = @Start1
 	  	  	  	 END
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 SET @LastId = @Start1
 	  	  	 END
 	  	  	 SET @LastStart = @CurrentStart1
 	  	  	 SET @LastEnd = @CurrentEnd1
 	  	  	 SET @Start1 = @Start1 + 1
 	  	 END
 	  	 SELECT @nptTime= @nptTime + Coalesce(Sum(DateDiff(second,Start_Time,End_Time)),0)
 	  	  	 FROM @AllEventsSorted
 	  	 SET @Start = @Start + 1
 	 END
 	 SELECT @RWTime = Sum(DateDiff(second,Start_Time,End_Time))
 	  	 FROM @AllReworkEvents
 	 RETURN coalesce(@RWTime - @nptTime,0)
END
