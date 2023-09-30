-- DESCRIPTION: spXLA_DowntimeSUMM_NoProduct_NPT is modified from spXLA_DowntimeSummary_NoProduct. Changes include
-- 6 additional input parameters (Action_Level1... Action_Level4; Crew_Desc, Shift_Desc) [MT/8-30-2002}
--
-- ECR #25306: mt/3-26-2003: added uptime
--
-- ECR #25517(mt/5-14-2003): Performance Tune Timed_Event_Details's Where Clause
-- ECR #25517(mt/5-19-2003): Added (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) to the JOIN of Crew_Schedule
-- to Timed_Event_Details. Without it, D.End_Time Is NULL would include crew periods that are completely outside the 
-- report time.
--
-- ECR #29652(mt/7-28-2005): QA failed, count of rows in summary doesn't match that in details be cause of slight differences in code between the two
-- modify spXLA_DownttimeSUMM_NoProduct code to match that in spXLA_DownttimeDT_NoProduct
--
CREATE PROCEDURE dbo.[spXLA_DowntimeSUMM_NoProduct_NPT_Bak_177]
        @Start_Time     DateTime
      , @End_Time DateTime
      , @PU_Id    Int         --Add-In's "Line" is masterUnit here
      , @SelectSource Int           --Slave Units PU_Id in Timed_Event_
      , @SelectR1 Int
      , @SelectR2 Int
      , @SelectR3 Int
      , @SelectR4 Int
      , @SelectA1     Int
      , @SelectA2 Int
      , @SelectA3 Int
      , @SelectA4 Int
      , @ReasonLevel    Int
      , @Crew_Desc      Varchar(10)
      , @Shift_Desc     Varchar(10)
      , @Username Varchar(50) = NULL
      , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
DECLARE @MasterUnit     Int,@LevelLocation  Int,@LevelReason1   Int,@LevelReason2   Int,@LevelReason3   Int
DECLARE @LevelReason4   Int,@LevelFault     Int,@LevelStatus    Int,@LevelAction1   Int,@LevelAction2   Int
DECLARE @LevelAction3   Int,@LevelAction4   Int,@LevelUnit      Int,@NPCat 	  	  	 Int,@NumberOfOccurances INT
DECLARE @TotalDowntimeMinutes Float,@TotalReasonMinutes Float,@TotalReasonCount Int,@TotalUptimeMinutes  Float,@TotalOperatingMinutes Float
DECLARE @NPTMinutes Float,@NumberOfUTOccurances Int
SELECT @LevelLocation = 0
SELECT @LevelReason1  = 1
SELECT @LevelReason2  = 2
SELECT @LevelReason3  = 3
SELECT @LevelReason4  = 4
SELECT @LevelAction1  = 5
SELECT @LevelAction2  = 6
SELECT @LevelAction3  = 7
SELECT @LevelAction4  = 8
SELECT @LevelFault    = 9
SELECT @LevelStatus   = 10
SELECT @LevelUnit     = -1
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else Select @MasterUnit = @PU_Id
SELECT @NPCat = Non_Productive_Category 
 	 FROM prod_units 
 	 WHERE PU_id = @PU_Id
-- Get All TED Records In Field I Care About
CREATE TABLE #TopNDR (
                  Id int IDENTITY(1,1),
          Detail_Id     Int          
      , Start_Time      DateTime
      , End_Time  DateTime     NULL
      , Duration Float         NULL
      , Uptime        Float         NULL -- ECR #25306: mt/3-26-2003
      , Reason_Name     varchar(100) NULL
      , SourcePU Int          NULL
      , MasterUnit      Int          NULL
      , R1_Id           Int          NULL
      , R2_Id           Int          NULL
      , R3_Id           Int          NULL
      , R4_Id           Int          NULL
      , A1_Id         Int          NULL
      , A2_Id         Int          NULL
      , A3_Id         Int          NULL
      , A4_Id         Int          NULL
      , Fault_Id  Int          NULL
      , Status_Id Int          NULL
 	   , DNPDuration Float  NULL,
 	   UptimeOffOffset 	 Int Null
)
  --   ---------------------------------------
  --   Insert Data Into Temp Table #TopNDR
  --   ---------------------------------------
IF @Crew_Desc Is NULL AND @Shift_Desc Is NULL 
BEGIN
 	 If @MasterUnit IS NULL
 	 BEGIN
 	  	 INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
 	  	 SELECT D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, TEFault_Id, TEStatus_Id  
 	  	  	 FROM Timed_Event_Details D
 	  	  	 JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)         
 	  	  	 WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
 	 END
 	 ELSE 
 	 BEGIN
 	  	 INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
 	  	 SELECT D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, TEFault_Id, TEStatus_Id  
 	  	  	 FROM Timed_Event_Details D
 	  	  	 JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	  	  	 WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
 	  	  	 AND D.PU_Id = @MasterUnit
 	  	 Update #TopNDR set End_Time = @End_Time where End_Time = NULL 
 	 END
END
IF @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL 
BEGIN
 	 If @MasterUnit Is NULL
 	 BEGIN
 	  	 INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
 	  	 SELECT DISTINCT
 	  	  	 D.TEDEt_Id
 	  	  	 , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
 	  	  	 , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
 	  	  	 When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
 	  	  	 , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, TEFault_Id, TEStatus_Id  
 	  	 FROM Timed_Event_Details D
 	  	  	 JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	  	  	 JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc
 	  	  	 AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
 	  	  	 AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
 	  	  	 WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
 	 END
 	 ELSE   --@MasterUnit not null
 	 BEGIN
 	  	 INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
 	  	 SELECT DISTINCT
 	  	  	 D.TEDEt_Id
 	  	  	 , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
 	  	  	 , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
 	  	  	 When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
 	  	  	 , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1
 	  	  	 , D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, TEFault_Id, TEStatus_Id  
 	  	 FROM Timed_Event_Details D
 	  	  	 JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	  	  	 JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc
 	  	  	 AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
 	  	  	 AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
 	  	  	 AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
 	  	 WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
 	  	 AND D.PU_Id = @MasterUnit
 	 END
END
If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL
BEGIN
 	 If @MasterUnit Is NULL
 	 BEGIN
 	  	 INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
 	  	   SELECT DISTINCT
 	  	  	  	  D.TEDEt_Id
 	  	  	    , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
 	  	  	    , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
 	  	  	  	  	  	  	  	  	  When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
 	  	  	    , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, TEFault_Id, TEStatus_Id  
 	  	  	 FROM Timed_Event_Details D
 	  	  	 JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
 	  	  	 JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
 	  	  	  AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
 	  	  	  AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
 	  	    WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
 	 END
 	 ELSE   --@MasterUnit not null
 	 BEGIN
        INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
          SELECT DISTINCT
                 D.TEDEt_Id
               , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
               , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
                                     When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
               , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1
               , D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, TEFault_Id, TEStatus_Id  
            FROM Timed_Event_Details D
            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
             AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
             AND D.PU_Id = @MasterUnit
      END
END
IF @Crew_Desc Is NOT NULL AND @Shift_Desc Is NOT NULL
BEGIN
  If @MasterUnit Is NULL
  BEGIN
    INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
      SELECT DISTINCT
             D.TEDEt_Id
           , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
           , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
                                 When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
           , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, TEFault_Id, TEStatus_Id  
        FROM Timed_Event_Details D
        JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
         AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
       WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
  END
  ELSE   --@MasterUnit not null
  BEGIN
    INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
      SELECT DISTINCT 
             D.TEDEt_Id
           , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
           , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
                                 When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
           , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1
           , D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, TEFault_Id, TEStatus_Id  
        FROM Timed_Event_Details D
        JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
         AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
         AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
       WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
         AND D.PU_Id = @MasterUnit
  END
END
If @SelectSource Is NOT NULL 
BEGIN
  If @SelectSource = -1     --MSi/MT/4-11-2001: AddIn's "None" keyword; Want to retain NULL location, delete others
    DELETE FROM #TopNDR WHERE SourcePU Is NOT NULL
  Else
    DELETE FROM #TopNDR WHERE ( SourcePU Is NULL AND MasterUnit <> @PU_Id ) Or SourcePU <> @SelectSource  -- ECR #29652: mt/7-28-2005
END
DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
UPDATE #TopNDR  SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
UPDATE #TopNDR  SET End_Time = @End_Time  WHERE End_Time > @End_Time OR End_Time Is NULL
UPDATE #TopNDR  SET Duration = DATEDIFF(ss, Start_Time, End_Time) 	  / 60.0
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration Float)
INSERT INTO @Periods_NPT ( Starttime,Endtime)
SELECT      
          StartTime               = CASE      WHEN np.Start_Time < @Start_Time THEN @Start_Time
                                        ELSE np.Start_Time
                                        END,
          EndTime           = CASE      WHEN np.End_Time > @End_time THEN @End_time
                                        ELSE np.End_Time
                                        END
FROM dbo.NonProductive_Detail np 
JOIN dbo.Event_Reason_Category_Data ercd  ON     ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id AND ercd.ERC_Id = @NPCat
WHERE PU_Id = @PU_id
          AND np.Start_Time < @End_time
          AND np.End_Time > @Start_Time
/* Remove NPT Events */
-- Case 1 :  Downtime     St-----------------------End
--                NPT   St-------------------------------End
DELETE  #TopNDR 
 	 FROM #TopNDR a
 	 Join @Periods_NPT b ON b.StartTime <= a.Start_Time and b.EndTime >= a.End_Time  
-- Case 2 :  Downtime      St---------------------End
--                NPT   St--------------End
UPDATE #TopNDR SET Start_Time = b.EndTime,Duration = DATEDIFF(ss, b.EndTime, a.End_Time)/ 60.0
 	 FROM #TopNDR a
 	 Join @Periods_NPT b ON b.StartTime < a.Start_Time and b.EndTime > a.Start_Time 
-- Case 3 :  Downtime 	  	 St---------------------End
--                NPT                          St--------------End
UPDATE #TopNDR SET End_Time = b.StartTime,Duration = DATEDIFF(ss, a.Start_Time , b.StartTime ) 	  / 60.0
 	 FROM #TopNDR a
 	 Join @Periods_NPT b ON b.StartTime < a.End_Time and b.EndTime > a.End_Time 
-- Case 4 :  Downtime       St-----------------------End
--                NPT           St--------------End
UPDATE #TopNDR SET Duration = (DATEDIFF(ss, a.Start_Time , b.StartTime ) + DATEDIFF(ss, b.EndTime ,a.End_Time )) / 60.0
 	 FROM #TopNDR a
 	 Join @Periods_NPT b ON a.Start_Time < b.StartTime and a.End_Time > b.EndTime 
/* Set Reason Name */
UPDATE #TopNDR
        SET Reason_Name = Case @ReasonLevel
                            When @LevelLocation Then PU.PU_Desc            --Location (Slave Unit)
                            When @LevelReason1 Then R1.Event_Reason_Name
                            When @LevelReason2 Then R2.Event_Reason_Name
                            When @LevelReason3 Then R3.Event_Reason_Name
                            When @LevelReason4 Then R4.Event_Reason_Name
                            When @LevelAction1 Then A1.Event_Reason_Name
                            When @LevelAction2 Then A2.Event_Reason_Name
                            When @LevelAction3 Then A3.Event_Reason_Name
                            When @LevelAction4 Then A4.Event_Reason_Name
                            When @LevelFault   Then F.TEFault_Name
                            When @LevelStatus  Then S.TEStatus_Name
                            When -1 Then PU2.PU_Desc      --Line (Master Unit)
                          End
      FROM #TopNDR D
      LEFT OUTER JOIN Prod_Units PU on (D.SourcePU = PU.Pu_Id)  --SourcePU's contain master and slave
      LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
      LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A1 ON (D.A1_Id = A1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A2 ON (D.A2_Id = A2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A3 ON (D.A3_Id = A3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A4 ON (D.A4_Id = A4.Event_Reason_Id)
      LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
      LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
IF Not Exists(SELECT 1 FROM #TopNDR)
BEGIN
 	 SELECT @NPTMinutes = SUM(DateDiff(second,a.StartTime,a.EndTime))/60.0
 	  	 FROM @Periods_NPT a
 	 IF @NPTMinutes IS NULL SET @NPTMinutes = 0
 	 SELECT ReasonName = PU_Desc
 	  	 , NumberOfOccurances = 0
 	  	 , TotalReasonMinutes = 0
 	  	 , AvgReasonMinutes = 0
 	  	 , TotalDowntimeMinutes = 0
 	  	 , AvgUptimeMinutes = 100.0
 	  	 , TotalUptimeMinutes = DateDiff(second,@Start_Time,@End_Time) / 60.0  - @NPTMinutes  
 	  	 , TotalOperatingMinutes = DateDiff(second,@Start_Time,@End_Time) / 60.0  - @NPTMinutes
 	 FROM Prod_Units 
 	 WHERE PU_Id = @PU_Id
END
ELSE
BEGIN
 	 UPDATE #TopNDR set UptimeOffOffset = 0
 	 SELECT @NumberOfOccurances = COUNT(*),@TotalDowntimeMinutes = SUM(Duration)
 	  	 FROM #TopNDR
 	 UPDATE #TopNDR set UptimeOffOffset = -1 WHERE Start_Time = @Start_Time
 	 UPDATE #TopNDR set UptimeOffOffset = -1 WHERE End_Time = @End_Time
 	 SELECT @NPTMinutes = SUM(DateDiff(second,a.StartTime,a.EndTime))/60.0
 	 FROM @Periods_NPT a
 	 IF @NPTMinutes IS NULL SET @NPTMinutes = 0
 	 ---------------------------------------------------------------------------------------------
 	 --Reason Calcuation
 	 ---------------------------------------------------------------------------------------------
 	 If @SelectR1 Is NOT NULL  DELETE FROM #TopNDR WHERE R1_Id Is NULL Or R1_Id <> @SelectR1
 	 If @SelectR2 Is NOT NULL  DELETE FROM #TopNDR WHERE R2_Id Is NULL Or R2_Id <> @SelectR2
 	 If @SelectR3 Is NOT NULL  DELETE FROM #TopNDR WHERE R3_Id Is NULL Or R3_Id <> @SelectR3
 	 If @SelectR4 Is NOT NULL  DELETE FROM #TopNDR WHERE R4_Id Is NULL Or R4_Id <> @SelectR4
 	 If @SelectA1 Is NOT NULL  DELETE FROM #TopNDR WHERE A1_Id Is NULL OR A1_Id <> @SelectA1
 	 If @SelectA2 Is NOT NULL  DELETE FROM #TopNDR WHERE A2_Id Is NULL OR A2_Id <> @SelectA2
 	 If @SelectA3 Is NOT NULL  DELETE FROM #TopNDR WHERE A3_Id Is NULL OR A3_Id <> @SelectA3
 	 If @SelectA4 Is NOT NULL  DELETE FROM #TopNDR WHERE A4_Id Is NULL OR A4_Id <> @SelectA4
 	 SELECT @TotalReasonMinutes = SUM(Duration),@TotalReasonCount = COUNT(*) 	 FROM #TopNDR
 	 SELECT @TotalOperatingMinutes = DateDiff(second,@Start_Time,@End_Time) / 60.0  - @NPTMinutes
 	 SELECT @TotalUptimeMinutes = @TotalOperatingMinutes - @TotalDowntimeMinutes
 	 SELECT ReasonName = D.Reason_Name
 	  	 , NumberOfOccurances = COUNT(*)
 	  	 , TotalReasonMinutes = SUM(Duration) 
 	  	 , AvgReasonMinutes = SUM(Duration)/COUNT(*)
 	  	 , TotalDowntimeMinutes = @TotalDowntimeMinutes
 	  	 , AvgUptimeMinutes = @TotalUptimeMinutes / ((COUNT(*) + 1)+ SUM(UptimeOffOffset))
 	  	 , TotalUptimeMinutes = @TotalUptimeMinutes  
 	  	 , TotalOperatingMinutes = @TotalOperatingMinutes
 	 FROM #TopNDR D
 	 GROUP BY D.Reason_Name
 	 Order by TotalReasonMinutes desc
 END
DROP TABLE #TopNDR
