CREATE PROCEDURE [dbo].[spBF_DowntimeGetAll]
 	   @Start_Time DateTime
 	 , @End_time 	 DateTime
 	 , @PUIds 	 nvarchar(max) = null
 	 , @InTimeZone 	 nVarChar(200) = null
 	 , @Seperator nvarchar(1) = ','
 	 , @IncludeAllNpt Int = 0
 	 , @ReturnTable Int = 0
 	 , @LineId 	 Int = Null
 	 ,@OEEParameter nvarchar(50) = NULL--Time based OEE : Availability/Performance/Quality. NULL in case of Classic OEE
 	 ,@ExcludeProductInfo Bit = 0
AS
/* ##### spBF_DowntimeGetAll #####
Description 	 : Returns data for Gaant chart (Summary/Line level) for Availability donut in case of classic OEE and for Availability, Performance & Quality donuts in case of Time based OEE
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Modified procedure to handle time based downtime calculation.
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
2018-05-30 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Exclude Units for which Production event is Inactive
2018-06-07 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Changed logic of excluding Units [Production rate specification is not defined and Oee mode not set]
2018-09-19 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE28396 	  	  	  	  	 Added @ExcludeProductInfo parameter to decide whether include product info in the resultset or not
*/
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
If @OEEParameter IS NOT NULL AND @OEEParameter NOT LIKE '%loss%'
Begin
 	 If (@OEEParameter = 'Quality')
 	 Begin
 	  	 Set @OEEParameter = 'Quality losses'
 	 End
 	 Else
 	 Begin
 	  	 Set @OEEParameter = @OEEParameter + ' loss'
 	 End
End
 	  	 Declare @ReasonIDFilter int
 	  	 Select @ReasonIDFilter = Event_Reason_Id from Event_Reasons Where Event_Reason_Name_Local = @OEEParameter
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
DECLARE   @DownTime TABLE (
 	 Detail_Id         Int
 	 , Start_Time        DateTime
 	 , End_Time          DateTime    NULL
 	 , Duration          Float       NULL
 	 , Uptime            Float       NULL 
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
 	 , Status_Id         Int         NULL
 	 , Crew_Desc         nvarchar(10) NULL
 	 , Shift_Desc        nvarchar(10) NULL
 	 , First_Comment_Id  Int         NULL
 	 , Last_Comment_Id   Int         NULL
 	 , IsNPT tinyint 	 NULL
 	 , ProdId  Int Null
 	 , PPId     Int  Null
 	 , NPTDetId  Int Null
 	 , NPTCatId  Int Null
 	 , ERT_Id 	 Int Null
 	 ,OEEMode Int NULL
)
 	 --<Start: Logic to exclude Units>
 	 DECLARE @xml XML
 	 DECLARE @ActiveUnits TABLE(Pu_ID int)
 	 SET @xml = cast(('<X>'+replace(@PUIds,',','</X><X>')+'</X>') as xml)
 	 INSERT INTO @ActiveUnits(Pu_ID)
 	 SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
 	 SET @PUIds = NULL
 	 ;WITH NotConfiguredUnits As
 	 (
 	  	 Select 
 	  	  	 Pu.Pu_Id from Prod_Units Pu
 	  	 Where
 	  	  	 Not Exists (Select 1 From Table_Fields_Values Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	 AND Production_Rate_Specification IS NULL
 	 )
 	 SELECT 
 	  	 @PUIds = COALESCE(@PUIds + ',', '') + Cast(Au.Pu_ID as nvarchar)
 	 FROM 
 	  	 @ActiveUnits Au
 	  	 LEFT OUTER JOIN NotConfiguredUnits Nu ON Nu.PU_Id = Au.Pu_ID
 	 WHERE 
 	  	 Nu.PU_Id IS NULL
--<End: Logic to exclude Units>
If @LineId Is Not NUll
BEGIN
 	 INSERT INTO @AllUnits(PU_Id)
 	 SELECT a.PU_Id
 	 FROM Prod_Units_Base a
 	 Join Event_Configuration  b on b.ET_Id = 2 and b.PU_Id = a.PU_Id
 	 WHERE a.PL_Id = @LineId
END
ELSE
BEGIN
 	 INSERT INTO @AllUnits(PU_Id) 
 	  	 SELECT Id FROM dbo.fnCMN_IdListToTable('Prod_Units',@PUIds,@Seperator)
END
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
 	  	 IF @LineId Is NOt Null GOTO RETURNDATA
 	  	 INSERT INTO @DownTime (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, 
 	  	 A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id , ERT_Id)
 	  	  	 SELECT  D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, D.Reason_Level1,
 	  	  	  D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEFault_Id, 
 	  	  	  D.TEStatus_Id,D.Event_Reason_Tree_Data_Id
 	  	  	 FROM  Timed_Event_Details D
 	  	  	 JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	  	  	 WHERE D.Start_Time < @End_time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
END       
  Else    --@MasterUnit not null
    BEGIN   
       INSERT INTO @DownTime (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id,
 	    R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,ERT_Id)
        SELECT D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, 
 	  	 D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, 
 	  	 D.Action_Level3, D.Action_Level4, D.TEFault_Id, D.TEStatus_Id, D.Event_Reason_Tree_Data_Id
          FROM Timed_Event_Details D
          JOIN @MasterUnits PU ON (PU.PU_Id = D.PU_Id)  
         WHERE D.Start_Time < @End_time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
    END
  -- Take Care Of Record Start And End Times 
  UPDATE @DownTime SET start_time = @Start_Time WHERE start_time < @Start_Time
  UPDATE @DownTime SET end_time = @End_time WHERE end_time > @End_time OR end_time is null
  --ECR #25704(mt/6-16-2003) Get comments from Comments Table instead of Waste_n_Timed_Comments (outdated in 4.0)
  DECLARE   @Comments TABLE(Detail_Id Int, FirstComment Int NULL, LastComment Int NULL)
  INSERT INTO @Comments
    SELECT D.Detail_Id, FirstComment = D.Cause_Comment_Id, LastComment = C.Comment_Id
      FROM @DownTime D
      LEFT JOIN Comments C ON C.TopOfChain_Id = D.Cause_Comment_Id AND C.NextComment_Id Is NULL AND C.Comment_Id <> D.Cause_Comment_Id   
  DELETE FROM @Comments Where FirstComment IS NULL AND  LastComment IS NULL
  UPDATE @DownTime 
      SET First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
     FROM @DownTime D
     JOIN @Comments C ON C.Detail_Id = D.Detail_Id
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
 	  	  	  	   TrueNpt     = CASE WHEN ercd.ERC_Id = @CurrentNPC /*AND T.KeyId IS NOT NULL*/ THEN 1
 	  	  	  	  	  	  	  	  	  ELSE 0
 	  	  	  	  	  	  	  	  	  END,
 	  	  	  	  np.NPDet_Id,
 	  	  	  	  ercd.ERC_Id 	  	  	  	 
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
      Left JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	   --LEFT OUTER JOIN TmpchkIsInclueNPT T ON T.KeyID = np.PU_Id
      WHERE PU_Id = @CurrentPU AND np.Start_Time < @End_time  AND np.End_Time > @Start_Time
 	 
    IF @IncludeAllNpt = 0
 	 BEGIN
 	  	 DELETE FROM @NPTTimes-- WHERE TrueNpt = 0 
 	 END
 	 DELETE A
 	 FROM
 	  	 @DownTime A 
 	  	 JOin @NPTTimes Npd on A.MasterUnit = @CurrentPU
 	 Where 
 	  	 A.Start_Time = Npd.StartTime And A.End_Time = Npd.EndTime
 	  	 AND ISNULL(Npd.TrueNpt,0) = 0 
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
 	 -- 	  	  	  Downtime                    St--------------End
 	 --or 	  	  Downtime    St----------------------------------End
 	  	 INSERT INTO @DownTime(Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,ERT_Id)
 	  	  	 SELECT Detail_Id, @CurrentSliceEnd, End_Time, Duration, 0, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,ERT_Id
 	  	  	 FROM @DownTime
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	  	 
 	  	 UPDATE @DownTime SET End_Time = @CurrentSliceEnd
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU 
 	 -- Case 2 :  NPT            St---------------------End
 	 -- 	  	  	  Downtime  St--------------End
 	  	 INSERT INTO @DownTime(Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,ERT_Id)
 	  	  	 SELECT Detail_Id, Start_Time, @CurrentSliceStart, Duration, 0, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,ERT_Id
 	  	  	 FROM @DownTime
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @DownTime SET Start_Time = @CurrentSliceStart
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 3 :  NPT   St---------------------End
 	 -- 	  	  	  Downtime   St--------------End
 	  	 UPDATE @DownTime SET IsNPT = @CurrentInt,NPTDetId = @CurrentInt2,NPTCatId = @CurrentInt3 WHERE Start_Time  >= @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 SELECT @SliceStart = Min(Id) from @NPTTimes Where Id > @SliceStart
 	 END
 	 
 	 UPDATE D SET D.IsNPT = 1 FROM @DownTime D Join @NPTTimes N On D.Start_Time >= N.StartTime AND D.End_Time <= N.EndTime
 	 DELETE A
 	 from @Downtime A Join 
 	 @NPTTimes Npd On A.MasterUnit = @CurrentPU
 	 Where 
 	 1=1
 	 --Datediff(second,A.Start_Time,A.End_Time) <> Datediff(second,Npd.StartTime, Npd.EndTime)
 	 AND A.Start_Time between Npd.StartTime AND Npd.EndTime
 	 AND A.End_Time between Npd.StartTime AND Npd.EndTime
 	 AND Npd.TrueNpt = 1 
 	 UPDATE @DownTime SET Duration = Datediff(SECOND,Start_Time,End_Time)/60.0
 	 
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
 	  	 INSERT INTO @DownTime(Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,ERT_Id)
 	  	  	 SELECT Detail_Id, @CurrentSliceEnd, End_Time, Duration, 0, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,@CurrentValue1,@CurrentValue2,ERT_Id
 	  	  	 FROM @DownTime
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @DownTime SET End_Time = @CurrentSliceEnd
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 2 : 
 	  	 INSERT INTO @DownTime(Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,ERT_Id)
 	  	  	 SELECT Detail_Id, Start_Time, @CurrentSliceStart, Duration, 0, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,@CurrentValue1,@CurrentValue2,ERT_Id
 	  	  	 FROM @DownTime
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @DownTime SET Start_Time = @CurrentSliceStart
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 3 : 
 	  	 UPDATE @DownTime SET Crew_Desc = @CurrentValue1 ,Shift_Desc = @CurrentValue2 WHERE Start_Time  >= @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 SELECT @SliceStart = Min(Id) from @ShiftTimes Where Id > @SliceStart
 	 END
 	 
-------------------------------------   
/* 	  	 Production Starts          */
-------------------------------------- 
IF @ExcludeProductInfo = 0
Begin
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
 	  	 INSERT INTO @DownTime(Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,Prodid,ERT_Id)
 	  	  	 SELECT Detail_Id, @CurrentSliceEnd, End_Time, Duration, 0, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,@CurrentInt,ERT_Id
 	  	  	 FROM @DownTime
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @DownTime SET End_Time = @CurrentSliceEnd
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 2 : 
 	  	 INSERT INTO @DownTime(Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,Prodid,ERT_Id)
 	  	  	 SELECT Detail_Id, Start_Time, @CurrentSliceStart, Duration, 0, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,@CurrentInt,ERT_Id
 	  	  	 FROM @DownTime
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @DownTime SET Start_Time = @CurrentSliceStart
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 3 : 
 	  	 UPDATE @DownTime SET Prodid = @CurrentInt  WHERE Start_Time  >= @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 SELECT @SliceStart = Min(Id) from @ProdStarts Where Id > @SliceStart
 	 END
End
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
 	  	 INSERT INTO @DownTime(Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,Prodid,PPId,ERT_Id)
 	  	  	 SELECT Detail_Id, @CurrentSliceEnd, End_Time, Duration, 0, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,Prodid,@CurrentInt,ERT_Id
 	  	  	 FROM @DownTime
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @DownTime SET End_Time = @CurrentSliceEnd
 	  	  	 WHERE Start_Time  < @CurrentSliceEnd  and End_Time > @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 2 : 
 	  	 INSERT INTO @DownTime(Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,Prodid,PPId,ERT_Id)
 	  	  	 SELECT Detail_Id, Start_Time, @CurrentSliceStart, Duration, 0, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,IsNPT,Crew_Desc,Shift_Desc,Prodid,@CurrentInt,ERT_Id
 	  	  	 FROM @DownTime
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 UPDATE @DownTime SET Start_Time = @CurrentSliceStart
 	  	  	 WHERE Start_Time  < @CurrentSliceStart and End_Time  > @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	 -- Case 3 : 
 	  	 UPDATE @DownTime SET PPId = @CurrentInt  WHERE Start_Time  >= @CurrentSliceStart and End_Time <= @CurrentSliceEnd and MasterUnit = @CurrentPU
 	  	 SELECT @SliceStart = Min(Id) from @ProdPlan Where Id > @SliceStart
 	 END
-------------------------------------   
/* 	  	 End Of Slicing         */
-------------------------------------- 
 	 SELECT @PUStart = Min(id) from @MasterUnits Where id > @PUStart
END
UPDATE @DownTime SET duration = datediff(ss, start_time, end_time) / 60.0
--SELECT * FROM @DownTime where cast(start_time as  date)='2017-12-29'
RETURNDATA:
 	 update a
 	 Set OEEMode = coalesce(b.Value,1) 
 	 From @DownTime a
 	 left Join dbo.Table_Fields_Values  b on b.KeyId = a.MasterUnit   AND b.Table_Field_Id = -91 AND B.TableId = 43
 	 
IF @ReturnTable  = 0
 	 WITH S AS ( 	 SELECT  
 	  	  	 Row_Number() over (Partition by Detail_Id,Start_Time,COALESCE(p.Prod_Code,@Unspecified),COALESCE(pp.Process_Order,@Unspecified),COALESCE(ppp.Path_Code,@Unspecified) Order by erc1.ERC_Id) Rownum,
 	  	  	 D.Detail_Id 
 	  	  	 , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(D.Start_Time,@InTimeZone)
 	  	  	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(D.End_Time,@InTimeZone)
 	  	  	 , D.Duration, D.Uptime
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
 	  	  	 , Status   = COALESCE(S.TEStatus_Name,@Unspecified)
 	  	  	 , D.First_Comment_Id, D.Last_Comment_Id, D.Crew_Desc, D.Shift_Desc
 	  	  	 , IsNonProductive  = isnull(d.IsNPT,0)
 	  	  	 ,ProductCode = COALESCE(p.Prod_Code,@Unspecified)
 	  	  	 ,[ProcessOrder] =  COALESCE(pp.Process_Order,@Unspecified)
 	  	  	 ,[Path Code] =  COALESCE(ppp.Path_Code,@Unspecified)
 	  	  	 ,[NPT Category] =  COALESCE(erc.ERC_Desc,@Unspecified)
 	  	  	 ,UnitId =  d.MasterUnit
 	  	  	 ,Category = COALESCE(CASE wHEN erc1.ERC_Desc IN('Availability','Performance') THEN erc1.ERC_Desc+' Loss' wHEN erc1.ERC_Desc IN('Quality') THEN erc1.ERC_Desc+' Losses' ELSE erc1.ERC_Desc end,@Unspecified)
 	  	 FROM  @DownTime D
 	  	 LEFT OUTER JOIN Prod_Units PU ON (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
 	  	 LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL) 	 --
 	  	 LEFT OUTER JOIN Event_Reasons R1 ON (D.R1_Id = R1.Event_Reason_Id)
 	  	 LEFT OUTER JOIN Event_Reasons R2 ON (D.R2_Id = R2.Event_Reason_Id)
 	  	 LEFT OUTER JOIN Event_Reasons R3 ON (D.R3_Id = R3.Event_Reason_Id)
 	  	 LEFT OUTER JOIN Event_Reasons R4 ON (D.R4_Id = R4.Event_Reason_Id)
 	  	 LEFT OUTER JOIN Event_Reasons A1 ON (D.A1_Id = A1.Event_Reason_Id)
 	  	 LEFT OUTER JOIN Event_Reasons A2 ON (D.A2_Id = A2.Event_Reason_Id)
 	  	 LEFT OUTER JOIN Event_Reasons A3 ON (D.A3_Id = A3.Event_Reason_Id)
 	  	 LEFT OUTER JOIN Event_Reasons A4 ON (D.A4_Id = A4.Event_Reason_Id)
 	  	 LEFT OUTER JOIN Timed_Event_Fault F ON (D.Fault_Id = F.TEFault_Id)
 	  	 LEFT OUTER JOIN Timed_Event_Status S ON (D.Status_Id = S.TEStatus_Id)
 	  	 Left Join Products p on p.Prod_Id = d.ProdId
 	  	 Left Join Production_Plan pp on pp.PP_Id = d.ppid
 	  	 Left Join PrdExec_Paths ppp on ppp.Path_Id = pp.path_id
 	  	 Left Join Event_Reason_Catagories erc on erc.ERC_Id = d.NPTCatId 
 	  	 Left Join Event_Reason_Category_Data ercd on d.ERT_Id = ercd.Event_Reason_Tree_Data_Id
 	  	 left Join Event_Reason_Catagories erc1 on ercd.ERC_Id = erc1.ERC_Id
 	  	 where 
 	  	 1=1
 	  	 And 
 	  	  	 (
 	  	  	  	 (d.R1_Id = @ReasonIDFilter AND @ReasonIDFilter is not NULL)
 	  	  	  	 OR
 	  	  	  	 (d.OEEMode <> 4 AND @ReasonIDFilter IS NULL)
 	  	  	  	 OR
 	  	  	  	 (
 	  	  	  	  	 @ReasonIDFilter IS NULL
 	  	  	  	  	 AND d.OEEMode = 4 
 	  	  	  	  	 AND d.R1_Id IN (Select Event_Reason_Id from Event_Reasons Where Event_Reason_Name_Local in ('Availability Loss'/*,'Performance Loss','Quality Losses'*/))
 	  	  	  	 )
 	  	  	 ) 	 
 	 )
 	 Select Detail_Id 
 	 , [Start_Time]
 	 , [End_Time]
 	 , D.Duration, D.Uptime
 	 , Unit
 	 , Location
 	 , Reason1
 	 , Reason2
 	 , Reason3
 	 , Reason4
 	 , Action1
 	 , Action2
 	 , Action3
 	 , Action4
 	 , Fault
 	 , Status
 	 , D.First_Comment_Id, D.Last_Comment_Id, D.Crew_Desc, D.Shift_Desc
 	 , IsNonProductive
 	 ,ProductCode
 	 ,[ProcessOrder]
 	 ,[Path Code]
 	 ,[NPT Category]
 	 ,UnitId
 	 ,Category from S D 
 	 Where rownum = 1
 	 --where reason1 = 'Machine failures'
 	  	 ORDER BY D.UnitId,D.Start_Time ASC
ELSE
   SELECT Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id,Crew_Desc,Shift_Desc,Prodid,ppId,
   IsNPT,NPTDetId,NPTCatId
 	  	 FROM @DownTime
--where isnull(NPTCatId,0) not in ((Select ERC_ID from Event_Reason_Catagories where ERC_Desc like 'NPT%' or ERC_Desc = 'Non-Productive Time'))--excluded npt downtimes
