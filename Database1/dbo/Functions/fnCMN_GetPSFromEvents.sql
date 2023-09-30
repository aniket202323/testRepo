CREATE FUNCTION dbo.fnCMN_GetPSFromEvents(@UnitId int, @StartTime datetime, @EndTime datetime) 
 	 returns  @RunTimes Table(ProdId Int, StartTime datetime, EndTime datetime)
AS 
BEGIN
 	 DECLARE   @AllEvents  TABLE(Id int Identity(1,1), Start_Time DateTime, End_Time DateTime,Prod_Id Int)
 	 DECLARE   @Prod_Starts TABLE(Pu_Id Int, prod_id Int, Start_Time DateTime, End_Time DateTime NULL)
 	 DECLARE @CurrentEndTime DateTime,@NextEnd DateTime,@CurrentStartTime DateTime,@CurrentProdId Int,@LastProdId Int
 	 DECLARE @Start Int, @PrevEnd DateTime, @End Int,@Start2 Int
 	 
 	 
 	 INSERT INTO @Prod_Starts(Pu_Id,prod_id,Start_Time,End_Time)
 	  	 SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
 	  	 FROM production_starts ps
 	  	 WHERE (ps.PU_Id = @UnitId AND  ps.PU_Id <> 0)
 	  	  	  	 AND (    Start_Time BETWEEN @StartTime AND @EndTime 
 	  	  	  	 OR End_Time BETWEEN @StartTime AND @EndTime 
 	  	  	  	 OR (Start_Time <= @StartTime AND (End_Time > @EndTime OR End_Time is null)))
 	 UPDATE @Prod_Starts SET Start_Time = @StartTime WHERE Start_Time < @StartTime
 	 UPDATE @Prod_Starts SET End_Time = @EndTime WHERE End_Time > @EndTime OR End_Time IS NULL
 	 INSERT INTO @AllEvents ( Start_Time, End_Time,Prod_Id)
 	  	 SELECT  e.Start_Time, e.TimeStamp, coalesce(e.Applied_Product,ps.prod_Id)
 	  	  	 FROM @Prod_Starts ps 
 	  	  	 JOIN Events e ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time >= e.TimeStamp ) AND ps.Pu_Id = e.Pu_Id 
 	  	  	 Order By e.Pu_Id,e.TimeStamp
 	 IF Not Exists(select 1 from @AllEvents)
 	 BEGIN
 	  	 INSERT INTO @RunTimes (ProdId , StartTime , EndTime )  
 	  	  	 SELECT prod_id,Start_Time,End_Time From @Prod_Starts 
 	  	 RETURN   
 	 END
 	  	 /*  Last event starting Before endtime  */
 	  	 Select @CurrentEndTime = MAX(End_Time) FROM @AllEvents
 	  	 IF @CurrentEndTime IS Not Null
 	  	 BEGIN
 	  	  	 IF @CurrentEndTime < @EndTime 
 	  	  	 BEGIN
 	  	  	  	 SET @NextEnd = Null
 	  	  	  	 SELECT @NextEnd = Min(Timestamp)
 	  	  	  	  	 FROM Events  
 	  	  	  	  	 WHERE TimeStamp > @CurrentEndTime and PU_Id = @UnitId
 	  	  	  	 IF @NextEnd Is Not Null
 	  	  	  	 BEGIN
 	  	  	  	  	 INSERT INTO @AllEvents( Start_Time, End_Time,Prod_Id)
  	    	    	    	    	    	  SELECT e.Start_Time,@NextEnd, coalesce(e.Applied_Product,ps.prod_Id)
 	  	  	  	  	  	  	 FROM Events e 
 	  	  	  	  	  	  	 Join Production_Starts ps on ps.PU_Id = e.PU_Id and  
 	  	  	  	  	  	  	  	  	 ps.Start_Time < e.TimeStamp AND ( ps.End_Time >= e.TimeStamp  or  ps.End_Time Is Null)
 	  	  	  	  	  	  	 WHERE e.TimeStamp = @NextEnd and e.PU_Id = @UnitId
 	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 INSERT INTO @AllEvents( Start_Time, End_Time,Prod_Id)
  	    	    	    	    	    	  SELECT @CurrentEndTime,@EndTime, ps.prod_Id
 	  	  	  	  	  	  	 FROM  Production_Starts ps 
 	  	  	  	  	  	  	 WHERE  ps.PU_Id = @UnitId  and
 	  	  	  	  	  	  	  	  	 ps.Start_Time < @EndTime AND ( ps.End_Time >= @EndTime  or  ps.End_Time Is Null)
 	  	  	  	 
 	  	  	  	 END
 	  	  	 END
 	  	 END
    SET @Start = 1
    SET @PrevEnd = Null
    SELECT @End = COUNT(*) FROM @AllEvents
    WHILE @Start <= @End
    BEGIN
 	  	 SELECT @CurrentStartTime = Start_Time,@CurrentEndTime = End_Time  FROM @AllEvents WHERE Id = @Start
 	  	 IF @CurrentStartTime IS Null
 	  	 BEGIN
 	  	  	 Select @CurrentStartTime = Null
 	  	  	 Select @CurrentStartTime = MAX(Timestamp) 
 	  	  	  	 FROM Events  
 	  	  	  	 WHERE TimeStamp < @CurrentEndTime and PU_Id = @UnitId
 	  	  	 IF @CurrentStartTime Is Null SET @CurrentStartTime = DATEADD(MINUTE,-1,@CurrentEndTime)
 	  	  	 Update @AllEvents Set Start_Time = @CurrentStartTime Where Id = @Start
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 IF @PrevEnd Is Not Null 
 	  	  	 BEGIN
 	  	  	  	 IF @CurrentStartTime < @PrevEnd
 	  	  	  	  	 Update @AllEvents Set Start_Time = @PrevEnd Where Id = @Start
 	  	  	 END
 	  	  	 SET @PrevEnd = @CurrentEndTime
 	  	 END
 	  	 IF @CurrentStartTime is Not Null and @CurrentEndTime Is Not Null
 	  	 BEGIN
 	  	  	 DELETE FROM @AllEvents WHERE Start_Time > @CurrentStartTime and End_Time < @CurrentEndTime
 	  	 END
 	  	 SET @Start2 = Null
 	  	 SELECT @Start2 = MIN(ID) FROM @AllEvents WHERE id > @Start
 	  	 IF @Start2 Is Null
 	  	  	 SET @Start = @End + 1
 	  	 ELSE
 	  	  	 SET @Start = @Start2
    END
 	 UPDATE @AllEvents SET Start_Time = @StartTime Where Start_Time < @StartTime
 	 UPDATE @AllEvents SET end_Time = @EndTime Where end_Time > @EndTime
    SET @Start = 1
    SET @CurrentStartTime = Null
    SET @CurrentEndTime = Null
    SET @LastProdId = Null
    SELECT @End = COUNT(*) FROM @AllEvents
    WHILE @Start <= @End
 	 BEGIN
 	  	 IF @CurrentStartTime Is Null
 	  	 BEGIN
 	  	  	 SELECT @CurrentStartTime = Start_Time,@CurrentEndTime = End_Time,@LastProdId = Prod_Id FROM @AllEvents Where Id = @Start
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SELECT @CurrentProdId = Prod_Id FROM @AllEvents Where Id = @Start
 	  	  	 IF @CurrentProdId = @LastProdId
 	  	  	 BEGIN
 	  	  	  	 SELECT @CurrentEndTime = End_Time FROM @AllEvents Where Id = @Start
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO @RunTimes (ProdId , StartTime , EndTime ) Values (@LastProdId,@CurrentStartTime,@CurrentEndTime)
 	  	  	  	 SELECT @CurrentStartTime = Start_Time,@CurrentEndTime = End_Time,@LastProdId = Prod_Id FROM @AllEvents Where Id = @Start 
 	  	  	 END
 	  	  	 IF @Start = @End
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO @RunTimes (ProdId , StartTime , EndTime ) Values (@LastProdId,@CurrentStartTime,@CurrentEndTime)
 	  	  	 END
 	  	 SELECT @Start = @Start + 1
 	  	 END 
 	 END 	 
 	 RETURN
END
