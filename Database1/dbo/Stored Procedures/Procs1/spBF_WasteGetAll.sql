CREATE PROCEDURE dbo.spBF_WasteGetAll
 	   @Start_Time DateTime
 	 , @End_time 	 DateTime
 	 , @PUIds 	 nvarchar(max) = null
 	 , @InTimeZone 	 nVarChar(200) = null
 	 , @Seperator nvarchar(1) = ','
 	 , @IncludeAllNpt Int = 0
 	 , @ReturnTable Int = 0
AS
IF @ReturnTable is Null
 	 SET @ReturnTable = 0
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_time = dbo.fnServer_CmnConvertToDBTime(@End_time,@InTimeZone)
DECLARE @MasterUnit  	 Int
DECLARE @Unit 	  	 nvarchar(50)
DECLARE @Unspecified nVarChar(100)
DECLARE @AllUnits Table (PU_Id Int,MUnit Int)
DECLARE @MasterUnits Table (id Int Identity(1,1),PU_Id Int,Npc Int)
DECLARE @PUStart Int,@PUEnd  Int,@CurrentPU Int,@CurrentNPC Int
DECLARE @SliceStart Int,@SliceEnd Int,@CurrentSliceStart DateTime,@CurrentSliceEnd DateTime
Declare @CurrentValue1 nvarchar(100),@CurrentValue2 nVarChar(100)
Declare @CurrentInt Int,@CurrentInt2 Int,@CurrentInt3 Int
DECLARE @NPTTimes TABLE (Id int IDENTITY(1,1),StartTime Datetime, EndTime Datetime,TrueNpt Int,NPTDetId Int,CatId Int)
DECLARE @ShiftTimes TABLE (Id int IDENTITY(1,1),StartTime Datetime, EndTime Datetime,CrewDesc nvarchar(10),ShiftDesc nvarchar(10))
DECLARE @ProdStarts TABLE (Id int IDENTITY(1,1),StartTime Datetime, EndTime Datetime,ProdId Int)
DECLARE @ProdPlan TABLE (Id int IDENTITY(1,1),StartTime Datetime, EndTime Datetime,PPId Int)
DECLARE   @Waste TABLE (
 	 Detail_Id         Int
 	 , Start_Time        DateTime
 	 , End_Time          DateTime    NULL
 	 , Duration          Float       NULL
 	 , SourcePU          Int         NULL
 	 , MasterUnit        Int         NULL
 	 , Cause_Comment_Id  Int         NULL 	 
 	 , R1_Id 	             Int         NULL
 	 , R2_Id 	             Int         NULL
 	 , R3_Id             Int         NULL
 	 , R4_Id             Int         NULL
 	 , A1_Id 	             Int         NULL
 	 , A2_Id             Int         NULL
 	 , A3_Id             Int         NULL
 	 , A4_Id             Int         NULL
 	 , Fault_Id          Int         NULL
 	 , Crew_Desc         nvarchar(10) NULL
 	 , Shift_Desc        nvarchar(10) NULL
 	 , First_Comment_Id  Int         NULL
 	 , Last_Comment_Id   Int         NULL
 	 , IsNPT tinyint 	 NULL
 	 , ProdId  Int Null
 	 , PPId     Int  Null
 	 , NPTDetId  Int Null
 	 , NPTCatId  Int Null
 	 , Amount    Float Null
 	 , Event_id Int Null
 	 , Waste_Measure_Id Int Null
 	 , Waste_Type_id 	 Int Null
)
INSERT INTO @AllUnits(PU_Id) 
 	 SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@PUIds,@Seperator)
Update @AllUnits SET Munit = coalesce(Master_Unit,b.pu_Id)
 	  FROM  @AllUnits a
 	  JOIN Prod_Units b on a.PU_Id = b.PU_Id
INSERT Into @MasterUnits(PU_Id)
 	 SELECT DISTINCT munit From @AllUnits
Update @MasterUnits SET Npc = b.Non_Productive_Category
 	  FROM  @MasterUnits a
 	  JOIN Prod_Units b on a.PU_Id = b.PU_Id
SELECT @Unspecified = 'n/a'
  If Not Exists(select 1 from @MasterUnits)
    BEGIN
 	 -- Time based
      INSERT INTO @Waste (Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id)
        SELECT  W.WED_Id, W.TimeStamp, W.TimeStamp, 0, W.Source_PU_Id, PU.PU_Id, W.Cause_Comment_Id, W.Reason_Level1, W.Reason_Level2,W.Reason_Level3,W.Reason_Level4, W.Action_Level1, W.Action_Level2, W.Action_Level3, W.Action_Level4, W.WEFault_Id, W.Amount,W.WEMT_Id,W.WET_Id
          FROM  Waste_Event_Details w
          JOIN Prod_Units PU ON (PU.PU_Id = W.PU_Id AND PU.PU_Id <> 0) and W.Event_Id is null
        WHERE ( W.TimeStamp > @Start_Time ) AND W.TimeStamp <= @End_time 
 	 -- event based
 	     INSERT INTO @Waste (Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id)
        SELECT  W.WED_Id, e.Start_Time, e.TimeStamp, 0, W.Source_PU_Id, PU.PU_Id, W.Cause_Comment_Id, W.Reason_Level1, W.Reason_Level2,W.Reason_Level3,W.Reason_Level4, W.Action_Level1, W.Action_Level2, W.Action_Level3, W.Action_Level4, W.WEFault_Id, W.Amount,W.WEMT_Id,W.WET_Id
          FROM  Events e
  	  	   Join Waste_Event_Details w on e.Event_Id = W.Event_Id
          JOIN Prod_Units PU ON (PU.PU_Id = W.PU_Id AND PU.PU_Id <> 0)
         WHERE e.Start_Time <= @End_time AND ( e.TimeStamp > @Start_Time )
    END       
  Else    --@MasterUnit not null
    BEGIN   
       INSERT INTO @Waste (Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id)
        SELECT  W.WED_Id, W.TimeStamp, W.TimeStamp, 0, W.Source_PU_Id, PU.PU_Id, W.Cause_Comment_Id, W.Reason_Level1, W.Reason_Level2,W.Reason_Level3,W.Reason_Level4, W.Action_Level1, W.Action_Level2, W.Action_Level3, W.Action_Level4, W.WEFault_Id, W.Amount,W.WEMT_Id,W.WET_Id
          FROM  Waste_Event_Details w
           JOIN @MasterUnits PU ON (PU.PU_Id = W.PU_Id)  
       WHERE ( W.TimeStamp > @Start_Time ) AND W.TimeStamp <= @End_time  and W.Event_Id is null
 	    INSERT INTO @Waste (Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id)
        SELECT  W.WED_Id, e.Start_Time, e.TimeStamp, 0, W.Source_PU_Id, PU.PU_Id, W.Cause_Comment_Id, W.Reason_Level1, W.Reason_Level2,W.Reason_Level3,W.Reason_Level4, W.Action_Level1, W.Action_Level2, W.Action_Level3, W.Action_Level4, W.WEFault_Id, W.Amount,W.WEMT_Id,W.WET_Id
          FROM  Events e
  	  	   Join Waste_Event_Details w on e.Event_Id = W.Event_Id
          JOIN @MasterUnits PU ON (PU.PU_Id = W.PU_Id)  
         WHERE e.Start_Time <= @End_time AND ( e.TimeStamp > @Start_Time )
    END
  -- Take Care Of Record Start And End Times 
  UPDATE @Waste SET start_time = @Start_Time WHERE start_time < @Start_Time
  UPDATE @Waste SET end_time = @End_time WHERE end_time > @End_time OR end_time is null
  DECLARE   @Comments TABLE(Detail_Id Int, FirstComment Int NULL, LastComment Int NULL)
  INSERT INTO @Comments
    SELECT W.Detail_Id, FirstComment = W.Cause_Comment_Id, LastComment = C.Comment_Id
      FROM @Waste W
      LEFT JOIN Comments C ON C.TopOfChain_Id = W.Cause_Comment_Id AND C.NextComment_Id Is NULL AND C.Comment_Id <> W.Cause_Comment_Id   
  UPDATE @Waste 
      SET First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
     FROM @Waste w
     JOIN @Comments C ON C.Detail_Id = W.Detail_Id
SELECT @PUStart = Min(id) from @MasterUnits
SELECT @PUEnd = max(id) from @MasterUnits
WHILE @PUStart <= @PUEnd
BEGIN
 	 SET @CurrentPU = Null
 	 SET @CurrentNPC = Null
 	 SELECT  @CurrentNPC = Npc,@CurrentPU =PU_Id FROM @MasterUnits where Id = @PUStart
 ---------------------------------------------------------------------------------------    
/* 	  	 Non Productive Time  */
---------------------------------------------------------------------------------------  
 	 DELETE FROM @NPTTimes
    INSERT INTO @NPTTimes (Starttime,Endtime,TrueNpt,NPTDetId,CatId)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @End_time THEN @End_time
                                                ELSE np.End_Time
                                                END,
 	  	  	  	   TrueNpt     = CASE WHEN ercd.ERC_Id = @CurrentNPC THEN 1
 	  	  	  	  	  	  	  	  	  ELSE 0
 	  	  	  	  	  	  	  	  	  END,
 	  	  	  	  np.NPDet_Id,
 	  	  	  	  ercd.ERC_Id 	  	  	  	 
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
      Left JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
      WHERE PU_Id = @CurrentPU AND np.Start_Time < @End_time  AND np.End_Time > @Start_Time
    IF @IncludeAllNpt = 0
 	 BEGIN
 	  	 DELETE FROM @NPTTimes WHERE TrueNpt = 0 
 	 END
 	 SELECT @SliceStart = Min(Id) from @NPTTimes
 	 SELECT @SliceEnd = max(Id) from @NPTTimes
 	 WHILE @SliceStart <= @SliceEnd
 	 BEGIN
 	  	 SET @CurrentSliceStart = Null
 	  	 SET @CurrentSliceEnd = Null
 	  	 SELECT  @CurrentSliceStart = Starttime,@CurrentSliceEnd =Endtime, @CurrentInt = TrueNpt, @CurrentInt2 = NPTDetId, @CurrentInt3 = CatId  
 	  	  	 FROM @NPTTimes 
 	  	  	 WHERE Id = @SliceStart
 	 -- Case 1 :  NPT 	  	  	 St---------------------End
 	 -- 	  	  	  Waste                    St--------------End
 	 --or 	  	  Waste    St----------------------------------End
 	  	 INSERT INTO @Waste(Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id)
 	  	  	 SELECT Detail_Id, @CurrentSliceEnd, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id
 	  	  	 FROM @Waste
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @Waste SET End_Time = @CurrentSliceEnd
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 2 :  NPT            St---------------------End
 	 -- 	  	  	  Waste  St--------------End
 	  	 INSERT INTO @Waste(Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id)
 	  	  	 SELECT Detail_Id, Start_Time, @CurrentSliceStart, Duration, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id
 	  	  	 FROM @Waste
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @Waste SET Start_Time = @CurrentSliceStart
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 3 :  NPT   St---------------------End
 	 -- 	  	  	  Downtime   St--------------End
 	  	 UPDATE @Waste SET IsNPT = @CurrentInt,NPTDetId = @CurrentInt2,NPTCatId = @CurrentInt3 WHERE Start_Time  >= @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 SELECT @SliceStart = Min(Id) from @NPTTimes Where Id > @SliceStart
 	 END
---------------------------------------------------------------------------------------    
/* 	  	 Shift/Crew  */
---------------------------------------------------------------------------------------  
 	 DELETE FROM @ShiftTimes
    INSERT INTO @ShiftTimes (Starttime,Endtime,ShiftDesc,CrewDesc)
      SELECT      
                  StartTime               = CASE      WHEN cs.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE cs.Start_Time
                                                END,
                  EndTime           = CASE      WHEN cs.End_Time > @End_time THEN @End_time
                                                ELSE cs.End_Time
                                                END,
 	  	  	  	 shift_desc,
 	  	  	  	 Crew_Desc
      FROM dbo.Crew_Schedule cs WITH (NOLOCK)
      WHERE PU_Id = @CurrentPU AND cs.Start_Time < @End_time  AND cs.End_Time > @Start_Time
 	 SELECT @SliceStart = Min(Id) from @ShiftTimes
 	 SELECT @SliceEnd = max(Id) from @ShiftTimes
 	 WHILE @SliceStart <= @SliceEnd
 	 BEGIN
 	  	 SET @CurrentSliceStart = Null
 	  	 SET @CurrentSliceEnd = Null
 	  	 SELECT  @CurrentSliceStart = Starttime,@CurrentSliceEnd =Endtime,@CurrentValue1 = crewdesc,@CurrentValue2 = Shiftdesc FROM @ShiftTimes where Id = @SliceStart
 	 -- Case 1 :
 	  	 INSERT INTO @Waste(Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc)
 	  	  	 SELECT Detail_Id, @CurrentSliceEnd, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,@CurrentValue1,@CurrentValue2
 	  	  	 FROM @Waste
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @Waste SET End_Time = @CurrentSliceEnd
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 2 : 
 	  	 INSERT INTO @Waste(Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc)
 	  	  	 SELECT Detail_Id, Start_Time, @CurrentSliceStart, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id,Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,@CurrentValue1,@CurrentValue2
 	  	  	 FROM @Waste
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @Waste SET Start_Time = @CurrentSliceStart
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 3 : 
 	  	 UPDATE @Waste SET Crew_Desc = @CurrentValue1 ,Shift_Desc = @CurrentValue2 WHERE Start_Time  >= @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 SELECT @SliceStart = Min(Id) from @ShiftTimes Where Id > @SliceStart
 	 END
-------------------------------------   
/* 	  	 Production Starts          */
-------------------------------------- 
 	 DELETE FROM @ProdStarts
    INSERT INTO @ProdStarts (Starttime,Endtime,ProdId)
 	  	 SELECT  StartTime ,EndTime,ProdId 
 	  	  	 FROM dbo.fnBF_GetPSFromEvents(@CurrentPU,@Start_Time ,@End_Time ,16) 
-- 	  	  	 FROM dbo.fncmn_SplitGradeChanges(@Start_Time ,@End_Time ,@CurrentPU) 
 	 SELECT @SliceStart = Min(Id) from @ProdStarts
 	 SELECT @SliceEnd = max(Id) from @ProdStarts
 	 WHILE @SliceStart <= @SliceEnd
 	 BEGIN
 	  	 SET @CurrentSliceStart = Null
 	  	 SET @CurrentSliceEnd = Null
 	  	 SELECT  @CurrentSliceStart = Starttime,@CurrentSliceEnd =Endtime,@CurrentInt = Prodid FROM @ProdStarts where Id = @SliceStart
 	 -- Case 1 :
 	  	 INSERT INTO @Waste(Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc,Prodid)
 	  	  	 SELECT Detail_Id, @CurrentSliceEnd, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc,@CurrentInt
 	  	  	 FROM @Waste
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @Waste SET End_Time = @CurrentSliceEnd
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 2 : 
 	  	 INSERT INTO @Waste(Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc,Prodid)
 	  	  	 SELECT Detail_Id, Start_Time, @CurrentSliceStart, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc,@CurrentInt
 	  	  	 FROM @Waste
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @Waste SET Start_Time = @CurrentSliceStart
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 3 : 
 	  	 UPDATE @Waste SET Prodid = @CurrentInt  WHERE Start_Time  >= @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 SELECT @SliceStart = Min(Id) from @ProdStarts Where Id > @SliceStart
 	 END
-------------------------------------   
/* 	  	 Production Plan Starts          */
-------------------------------------- 
 	 DELETE FROM @ProdPlan
    INSERT INTO @ProdPlan (Starttime,Endtime,PPId)
 	  	 SELECT 
                StartTime               = CASE      WHEN ps.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE ps.Start_Time
                                                END,
                  EndTime           = CASE      WHEN ps.End_Time > @End_time THEN @End_time
                                                ELSE ps.End_Time
                                                END,
 	  	  	  	 PP_Id
      FROM dbo.Production_Plan_Starts ps WITH (NOLOCK)
      WHERE ps.PU_Id = @CurrentPU AND ps.Start_Time < @End_time  AND ps.End_Time > @Start_Time
 	 SELECT @SliceStart = Min(Id) from @ProdPlan
 	 SELECT @SliceEnd = max(Id) from @ProdPlan
 	 WHILE @SliceStart <= @SliceEnd
 	 BEGIN
 	  	 SET @CurrentSliceStart = Null
 	  	 SET @CurrentSliceEnd = Null
 	  	 SELECT  @CurrentSliceStart = Starttime,@CurrentSliceEnd =Endtime,@CurrentInt = PPId FROM @ProdPlan where Id = @SliceStart
 	 -- Case 1 :
 	  	 INSERT INTO @Waste(Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc,Prodid,PPId)
 	  	  	 SELECT Detail_Id, @CurrentSliceEnd, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc,Prodid,@CurrentInt
 	  	  	 FROM @Waste
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @Waste SET End_Time = @CurrentSliceEnd
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 2 : 
 	  	 INSERT INTO @Waste(Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc,Prodid,PPId)
 	  	  	 SELECT Detail_Id, Start_Time, @CurrentSliceStart, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id,IsNPT,Crew_Desc,Shift_Desc,Prodid,@CurrentInt
 	  	  	 FROM @Waste
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @Waste SET Start_Time = @CurrentSliceStart
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 3 : 
 	  	 UPDATE @Waste SET PPId = @CurrentInt  WHERE Start_Time  >= @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 SELECT @SliceStart = Min(Id) from @ProdPlan Where Id > @SliceStart
 	 END
-------------------------------------   
/* 	  	 End Of Slicing         */
-------------------------------------- 
 	 SELECT @PUStart = Min(id) from @MasterUnits Where id > @PUStart
END
UPDATE @Waste SET duration = datediff(ss, start_time, end_time) / 60.0
IF @ReturnTable  = 0
 	 SELECT W.Detail_Id 
 	  	 , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(W.Start_Time,@InTimeZone)
 	  	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(W.End_Time,@InTimeZone)
 	  	 , W.Duration
 	  	 , Unit 	  = COALESCE(PU2.PU_Desc,@Unspecified )
 	  	 , Location = COALESCE(PU.PU_Desc,@Unspecified)
 	  	 , Reason1  = COALESCE(R1.Event_Reason_Name,@Unspecified)
 	  	 , Reason2  = COALESCE(R2.Event_Reason_Name, @Unspecified)
 	  	 , Reason3  = COALESCE(R3.Event_Reason_Name, @Unspecified)
 	  	 , Reason4  = COALESCE(R4.Event_Reason_Name,@Unspecified)
 	  	 , Action1  = COALESCE(A1.Event_Reason_Name,@Unspecified)
 	  	 , Action2  = COALESCE(A2.Event_Reason_Name,@Unspecified)
 	  	 , Action3  = COALESCE(A3.Event_Reason_Name,@Unspecified)
 	  	 , Action4  = COALESCE(A4.Event_Reason_Name,@Unspecified)
 	  	 , Fault 	    = COALESCE(F.TEFault_Name,@Unspecified)
 	  	 , W.First_Comment_Id, W.Last_Comment_Id, W.Crew_Desc, W.Shift_Desc
 	  	 , IsNonProductive  = isnull(W.IsNPT,0)
 	  	 ,ProductCode = COALESCE(p.Prod_Code,@Unspecified)
 	  	 ,[ProcessOrder] =  COALESCE(pp.Process_Order,@Unspecified)
 	  	 ,[Path Code] =  COALESCE(ppp.Path_Code,@Unspecified)
 	  	 ,[NPT Category] =  COALESCE(erc.ERC_Desc,@Unspecified)
 	  	 ,Amount = coalesce(Amount,0.0)
 	  	 ,wm.WEMT_Name 
 	  	 ,wt.WET_Name 
 	 FROM  @Waste w
 	 LEFT OUTER JOIN Prod_Units PU ON (W.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
 	 LEFT OUTER JOIN Prod_Units PU2 ON (W.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL) 	 --
 	 LEFT OUTER JOIN Event_Reasons R1 ON (W.R1_Id = R1.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons R2 ON (W.R2_Id = R2.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons R3 ON (W.R3_Id = R3.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons R4 ON (W.R4_Id = R4.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons A1 ON (W.A1_Id = A1.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons A2 ON (W.A2_Id = A2.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons A3 ON (W.A3_Id = A3.Event_Reason_Id)
 	 LEFT OUTER JOIN Event_Reasons A4 ON (W.A4_Id = A4.Event_Reason_Id)
 	 LEFT OUTER JOIN Timed_Event_Fault F ON (W.Fault_Id = F.TEFault_Id)
 	 Left Join Products p on p.Prod_Id = W.ProdId
 	 Left Join Production_Plan pp on pp.PP_Id = W.ppid
 	 Left Join PrdExec_Paths ppp on ppp.Path_Id = pp.path_id
 	 Left Join Event_Reason_Catagories erc on erc.ERC_Id = W.NPTCatId
 	 left join Waste_Event_Meas wm on wm.WEMT_Id = w.Waste_Measure_Id
 	 left join Waste_Event_Type wt on wt.WET_Id  = w.Waste_Type_id
 	 ORDER BY W.MasterUnit,W.Start_Time ASC
ELSE
   SELECT Detail_Id, Start_Time, End_Time, Duration,  SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Amount,Waste_Measure_Id,Waste_Type_id,Crew_Desc,Shift_Desc,Prodid,ppId,IsNPT,NPTDetId,NPTCatId
 	  	 FROM @Waste
