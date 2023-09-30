﻿-- DESCRIPTION: spXLA_NPTSUMM_NoProduct is modified from spXLA_DowntimeSummary_NoProduct. Changes include
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
CREATE PROCEDURE dbo.spXLA_NPTSUMM_NoProduct
 	   @Start_Time 	 DateTime
 	 , @End_Time 	 DateTime
 	 , @PU_Id 	 Int 	  	 --Add-In's "Line" is masterUnit here
 	 , @SelectSource Int 	  	 --Slave Units PU_Id in Timed_Event_
 	 , @SelectR1 	 Int
 	 , @SelectR2 	 Int
 	 , @SelectR3 	 Int
 	 , @SelectR4 	 Int
 	 , @SelectA1     Int
 	 , @SelectA2 	 Int
 	 , @SelectA3 	 Int
 	 , @SelectA4 	 Int
 	 , @ReasonLevel 	 Int
 	 , @Crew_Desc 	 Varchar(10)
 	 , @Shift_Desc 	 Varchar(10)
 	 , @Username Varchar(50) = Null
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
DECLARE @TotalPLT 	 Real
DECLARE @TotalOperating Real
DECLARE @QueryType 	 TinyInt
DECLARE @MasterUnit 	 Int
DECLARE @RowCount 	 Int  --mt/6-26-2002
 	 --Define Reason Levels
DECLARE @LevelLocation 	 Int --Slave Units
DECLARE @LevelReason1 	 Int
DECLARE @LevelReason2 	 Int
DECLARE @LevelReason3 	 Int
DECLARE @LevelReason4 	 Int
DECLARE @LevelFault 	 Int
DECLARE @LevelStatus 	 Int
DECLARE @LevelAction1 	 Int
DECLARE @LevelAction2 	 Int
DECLARE @LevelAction3 	 Int
DECLARE @LevelAction4 	 Int
DECLARE @LevelUnit 	 Int --Master Unit
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
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else Select @MasterUnit = @PU_Id
CREATE TABLE #MyReport (
 	   ReasonName 	  	 Varchar(100)  NULL --MSI/MT/6-25-2001 length change; from 30 to 100; mt/6-26-2002 nullable
 	 , NumberOfOccurances 	 Int           NULL
 	 , TotalReasonMinutes  	 Real          NULL
 	 , AvgReasonMinutes  	 Real          NULL
 	 , TotalDowntimeMinutes 	 Real          NULL
        , AvgUptimeMinutes      Real          NULL 	 -- ECR #25306: mt/3-26-2003
        , TotalUptimeMinutes    Real          NULL 	 -- ECR #25306: mt/3-26-2003
 	 , TotalOperatingMinutes Real          NULL
)
-- Get All TED Records In Field I Care About
CREATE TABLE #TopNDR (
          Detail_Id     Int          
  	 , Start_Time 	 DateTime
 	 , End_Time 	 DateTime     NULL
 	 , Duration  	 Real         NULL
        , Uptime        Real         NULL 	 -- ECR #25306: mt/3-26-2003
 	 , Reason_Name 	 varchar(100) NULL
 	 , SourcePU  	 Int          NULL
 	 , MasterUnit 	 Int          NULL
 	 , R1_Id 	  	 Int          NULL
 	 , R2_Id 	  	 Int          NULL
 	 , R3_Id 	  	 Int          NULL
 	 , R4_Id 	  	 Int          NULL
 	 , A1_Id         Int          NULL
 	 , A2_Id         Int          NULL
 	 , A3_Id         Int          NULL
 	 , A4_Id         Int          NULL
 	 , Fault_Id 	 Int          NULL
 	 , Status_Id 	 Int          NULL
)
  --   ---------------------------------------
  --   Insert Data Into Temp Table #TopNDR
  --   ---------------------------------------
If @Crew_Desc Is NULL AND @Shift_Desc Is NULL          GOTO NOCREW_NOSHIFT_TEMPTABLE_INSERT
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL GOTO HASCREW_NOSHIFT_TEMPTABLE_INSERT
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL GOTO NOCREW_HASSHIFT_TEMPTABLE_INSERT
Else                                                   GOTO HASCREW_HASSHIFT_TEMPTABLE_INSERT
--EndIf:Crew, Shift
NOCREW_NOSHIFT_TEMPTABLE_INSERT:
  If @MasterUnit IS NULL
      BEGIN
        INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
          SELECT D.NPDet_Id, 
 	  	  	  	  start_time =   CASE      WHEN D.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE D.Start_Time
                                                END,
                 End_Time   =   CASE      WHEN D.End_Time > @End_time THEN @End_time
                                                ELSE D.End_Time
                                                END, 
 	  	  	  	  NULL, 
                 NULL,
                 D.PU_Id, 
 	  	  	  	  D.PU_Id, 
 	  	  	      D.Reason_Level1,
                 D.Reason_Level2,
                 D.Reason_Level3, 
                 D.Reason_Level4, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL  
            FROM dbo.NonProductive_Detail D WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = D.Event_Reason_Tree_Data_Id
 	  	  	 AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
            --JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)         
           --WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
      END
  Else   --@MasterUnit not null 
      BEGIN
        INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
          SELECT D.NPDet_Id, 
 	  	  	  	  start_time =   CASE      WHEN D.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE D.Start_Time
                                                END,
                 End_Time   =   CASE      WHEN D.End_Time > @End_time THEN @End_time
                                                ELSE D.End_Time
                                                END, 
 	  	  	  	  NULL, 
                 NULL,
                 D.PU_Id, 
 	  	  	  	  D.PU_Id, 
 	  	  	      D.Reason_Level1,
                 D.Reason_Level2,
                 D.Reason_Level3, 
                 D.Reason_Level4, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL  
            FROM dbo.NonProductive_Detail D WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = D.Event_Reason_Tree_Data_Id
 	  	  	 AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
 	  	  	 WHERE PU_Id = @PU_id
 	  	  	 AND D.Start_Time < @End_time
             AND D.End_Time > @Start_Time 	 
--            JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
--           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
            AND D.PU_Id = @MasterUnit
      END
  --EndIf @PU_Id
  GOTO CONTINUE_AFTER_TEMPTABLE_INSERT
--End NOCREW_NOSHIFT_TEMPTABLE_INSERT:
HASCREW_NOSHIFT_TEMPTABLE_INSERT:
  If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
          SELECT DISTINCT
                 D.NPDet_Id, 
 	  	  	  	  start_time =   CASE      WHEN D.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE D.Start_Time
                                                END,
                 End_Time   =   CASE      WHEN D.End_Time > @End_time THEN @End_time
                                                ELSE D.End_Time
                                                END, 
 	  	  	  	  NULL, 
                 NULL,
                 NULL, 
 	  	  	  	  D.PU_Id, 
 	  	  	      D.Reason_Level1,
                 D.Reason_Level2,
                 D.Reason_Level3, 
                 D.Reason_Level4, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL  
            FROM dbo.NonProductive_Detail D WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = D.Event_Reason_Tree_Data_Id
 	  	  	 AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
            --JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
           --WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
      END
  Else   --@MasterUnit not null
      BEGIN
        INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
          SELECT DISTINCT
                 D.NPDet_Id, 
 	  	  	  	  start_time =   CASE      WHEN D.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE D.Start_Time
                                                END,
                 End_Time   =   CASE      WHEN D.End_Time > @End_time THEN @End_time
                                                ELSE D.End_Time
                                                END, 
 	  	  	  	  NULL, 
                 NULL,
                 NULL, 
 	  	  	  	  D.PU_Id, 
 	  	  	      D.Reason_Level1,
                 D.Reason_Level2,
                 D.Reason_Level3, 
                 D.Reason_Level4, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL  
            FROM dbo.NonProductive_Detail D WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = D.Event_Reason_Tree_Data_Id
 	  	  	 AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
          --  JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
             AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
           --WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
            AND D.PU_Id = @MasterUnit
      END
  --EndIf @PU_Id
  GOTO CONTINUE_AFTER_TEMPTABLE_INSERT
--End HASCREW_NOSHIFT_TEMPTABLE_INSERT:
NOCREW_HASSHIFT_TEMPTABLE_INSERT:
  If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
          SELECT DISTINCT
                 D.NPDet_Id, 
 	  	  	  	  start_time =   CASE      WHEN D.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE D.Start_Time
                                                END,
                 End_Time   =   CASE      WHEN D.End_Time > @End_time THEN @End_time
                                                ELSE D.End_Time
                                                END, 
 	  	  	  	  NULL, 
                 NULL,
                 NULL, 
 	  	  	  	  D.PU_Id, 
 	  	  	      D.Reason_Level1,
                 D.Reason_Level2,
                 D.Reason_Level3, 
                 D.Reason_Level4, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL  
            FROM dbo.NonProductive_Detail D WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = D.Event_Reason_Tree_Data_Id
 	  	  	 AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
           -- JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
          -- WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
      END
  Else   --@MasterUnit not null
      BEGIN
        INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
          SELECT DISTINCT
                 D.NPDet_Id, 
 	  	  	  	  start_time =   CASE      WHEN D.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE D.Start_Time
                                                END,
                 End_Time   =   CASE      WHEN D.End_Time > @End_time THEN @End_time
                                                ELSE D.End_Time
                                                END, 
 	  	  	  	  NULL, 
                 NULL,
                 NULL, 
 	  	  	  	  D.PU_Id, 
 	  	  	      D.Reason_Level1,
                 D.Reason_Level2,
                 D.Reason_Level3, 
                 D.Reason_Level4, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL  
            FROM dbo.NonProductive_Detail D WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = D.Event_Reason_Tree_Data_Id
 	  	  	 AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
          --  JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
             AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
        ---   WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
             AND D.PU_Id = @MasterUnit
      END
  --EndIf @PU_Id
  GOTO CONTINUE_AFTER_TEMPTABLE_INSERT
--NOCREW_HASSHIFT_TEMPTABLE_INSERT:
HASCREW_HASSHIFT_TEMPTABLE_INSERT:
  If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
          SELECT DISTINCT
                 D.NPDet_Id, 
 	  	  	  	  start_time =   CASE      WHEN D.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE D.Start_Time
                                                END,
                 End_Time   =   CASE      WHEN D.End_Time > @End_time THEN @End_time
                                                ELSE D.End_Time
                                                END, 
 	  	  	  	  NULL, 
                 NULL,
                 NULL, 
 	  	  	  	  D.PU_Id, 
 	  	  	      D.Reason_Level1,
                 D.Reason_Level2,
                 D.Reason_Level3, 
                 D.Reason_Level4, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL  
            FROM dbo.NonProductive_Detail D WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = D.Event_Reason_Tree_Data_Id
 	  	  	 AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
           -- JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
           --WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
      END
  Else   --@MasterUnit not null
      BEGIN
        INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
          SELECT DISTINCT 
                 D.NPDet_Id, 
 	  	  	  	  start_time =   CASE      WHEN D.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE D.Start_Time
                                                END,
                 End_Time   =   CASE      WHEN D.End_Time > @End_time THEN @End_time
                                                ELSE D.End_Time
                                                END, 
 	  	  	  	  NULL, 
                 NULL,
                 NULL, 
 	  	  	  	  D.PU_Id, 
 	  	  	      D.Reason_Level1,
                 D.Reason_Level2,
                 D.Reason_Level3, 
                 D.Reason_Level4, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL, 
                 NULL  
            FROM dbo.NonProductive_Detail D WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = D.Event_Reason_Tree_Data_Id
 	  	  	 AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
            --JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
            JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
             AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
             AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
             AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
           WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
            AND D.PU_Id = @MasterUnit
      END
  --EndIf @PU_Id
  GOTO CONTINUE_AFTER_TEMPTABLE_INSERT
--End HASCREW_HASSHIFT_TEMPTABLE_INSERT:
CONTINUE_AFTER_TEMPTABLE_INSERT:
  --Clean up zero PU_Id (comes from 
  DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
  UPDATE #TopNDR  SET start_time = @Start_Time WHERE start_time < @Start_Time
  UPDATE #TopNDR  SET end_time = @End_Time  WHERE end_time > @End_Time OR end_time is null
  UPDATE #TopNDR  SET Duration = DATEDIFF(ss, start_time, end_time) / 60.0
--SELECT * FROM #TOPNDR
  -- Calculate Total Downtime
  SELECT @TotalPLT = (SELECT SUM(Duration) FROM #TopNDR) 
  --Adjust For Scheduled Down If Necessary 
  SELECT @TotalOperating = 0
  SELECT @TotalOperating = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0) - @TotalOperating
  -- Delete (filter out) based ON additional selection criteria
  If @SelectSource Is Not NULL 	  	  	 --@SelectSource = AddIn's Location 
      BEGIN
 	 If @SelectSource = -1 	  	  	 --MSi/MT/4-11-2001: AddIn's "None" keyword; Want to retain null location, delete others
 	     BEGIN DELETE FROM #TopNDR WHERE SourcePU Is NOT NULL
 	     END
 	 Else
            --   { ECR #29562: QA Failed count of rows in Summary less than Details because the following code not matched change code to match that in Details counterpart
 	     --BEGIN DELETE FROM #TopNDR WHERE SourcePU Is NULL OR SourcePU <> @SelectSource
 	     --END
 	     DELETE FROM #TopNDR WHERE ( SourcePU Is NULL AND MasterUnit <> @PU_Id ) OR SourcePU <> @SelectSource
            --   } ECR #29562
 	 --EndIf
    END
  If @SelectR1 Is NOT NULL DELETE FROM #TopNDR WHERE R1_Id Is NULL OR R1_Id <> @SelectR1  
  If @SelectR2 Is NOT NULL DELETE FROM #TopNDR WHERE R2_Id Is NULL OR R2_Id <> @SelectR2
  If @SelectR3 Is NOT NULL DELETE FROM #TopNDR WHERE R3_Id Is NULL OR R3_Id <> @SelectR3
  If @SelectR4 Is NOT NULL DELETE FROM #TopNDR WHERE R4_Id Is NULL OR R4_Id <> @SelectR4
  If @SelectA1 Is NOT NULL DELETE FROM #TopNDR WHERE A1_Id Is NULL OR A1_Id <> @SelectA1
  If @SelectA2 Is NOT NULL DELETE FROM #TopNDR WHERE A2_Id Is NULL OR A2_Id <> @SelectA2
  If @SelectA2 Is NOT NULL DELETE FROM #TopNDR WHERE A2_Id Is NULL OR A2_Id <> @SelectA2
  If @SelectA3 Is NOT NULL DELETE FROM #TopNDR WHERE A3_Id Is NULL OR A3_Id <> @SelectA3
  If @SelectA4 Is NOT NULL DELETE FROM #TopNDR WHERE A4_Id Is NULL OR A4_Id <> @SelectA4
  If @MasterUnit Is NULL
    BEGIN
      UPDATE #TopNDR 
        SET Reason_Name = Case @ReasonLevel
                            When @LevelLocation Then PU.PU_Desc 	  	  	 
                            When @LevelReason1  Then R1.Event_Reason_Name
                            When @LevelReason2  Then R2.Event_Reason_Name
                            When @LevelReason3  Then R3.Event_Reason_Name
                            When @LevelReason4  Then R4.Event_Reason_Name
                            When @LevelAction1  Then A1.Event_Reason_Name
                            When @LevelAction2  Then A2.Event_Reason_Name
                            When @LevelAction3  Then A3.Event_Reason_Name
                            When @LevelAction4  Then A4.Event_Reason_Name
--                            When @LevelFault    Then F.TEFault_Name
--                            When @LevelStatus   Then S.TEStatus_Name
                            When @LevelUnit     Then PU2.PU_Desc 	   --Master Unit
                          End
        FROM #TopNDR D
        LEFT OUTER JOIN Prod_Units PU ON (D.SourcePU = PU.PU_Id) 	 --SourcePU's contain master and slave
        LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
        LEFT OUTER JOIN Event_Reasons R1 ON (D.R1_Id = R1.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons R2 ON (D.R2_Id = R2.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons R3 ON (D.R3_Id = R3.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons R4 ON (D.R4_Id = R4.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons A1 ON (D.A1_Id = A1.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons A2 ON (D.A2_Id = A2.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons A3 ON (D.A3_Id = A3.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons A4 ON (D.A4_Id = A4.Event_Reason_Id)
--        LEFT OUTER JOIN Timed_Event_Fault F ON (D.Fault_Id = F.TEFault_Id)
--        LEFT OUTER JOIN Timed_Event_Status S ON (D.Status_Id = S.TEStatus_Id)
    END
  Else    --@masterUnit not null
    BEGIN
      UPDATE #TopNDR 
        SET Reason_Name = Case @ReasonLevel
                            When @LevelLocation Then PU.PU_Desc 	  	  	 
                            When @LevelReason1  Then R1.Event_Reason_Name
                            When @LevelReason2  Then R2.Event_Reason_Name
                            When @LevelReason3  Then R3.Event_Reason_Name
                            When @LevelReason4  Then R4.Event_Reason_Name
                            When @LevelAction1  Then A1.Event_Reason_Name
                            When @LevelAction2  Then A2.Event_Reason_Name
                            When @LevelAction3  Then A3.Event_Reason_Name
                            When @LevelAction4  Then A4.Event_Reason_Name
--                            When @LevelFault    Then F.TEFault_Name
--                            When @LevelStatus   Then S.TEStatus_Name
                            When @LevelUnit     Then PU2.PU_Desc 	   --Master Unit
                          End
        From #TopNDR D
        LEFT OUTER JOIN Prod_Units PU ON (D.SourcePU = PU.PU_Id) 	 --SourcePU's contain master and slave
        LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
        LEFT OUTER JOIN Event_Reasons R1 ON (D.R1_Id = R1.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons R2 ON (D.R2_Id = R2.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons R3 ON (D.R3_Id = R3.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons R4 ON (D.R4_Id = R4.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons A1 ON (D.A1_Id = A1.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons A2 ON (D.A2_Id = A2.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons A3 ON (D.A3_Id = A3.Event_Reason_Id)
        LEFT OUTER JOIN Event_Reasons A4 ON (D.A4_Id = A4.Event_Reason_Id)
--        LEFT OUTER JOIN Timed_Event_Fault F ON (D.Fault_Id = F.TEFault_Id)
--        LEFT OUTER JOIN Timed_Event_Status S ON (D.Status_Id = S.TEStatus_Id)
    END
  --EndIf @MasterUnit
--  UPDATE #TopNDR SET Reason_Name = dbo.fnDBTranslate(@LangId, 38333, 'Unspecified') WHERE Reason_Name Is NULL
  --Start Defect #24039
  SELECT @RowCount = 0
  SELECT @RowCount = Count(*) FROM #TopNDR
  If @RowCount = 0
    BEGIN
      INSERT INTO #MyReport (TotalOperatingMinutes) VALUES ( @TotalOperating )
      GOTO RETURN_RESULT_SET
    END
  --EndIf:@RowCount
  --End Defect #24039
  -- Populate Temp Table With Reason Ordered By Top 20
  INSERT INTO #MyReport ( ReasonName
                        , NumberOfOccurances
                        , TotalReasonMinutes 
                        , AvgReasonMinutes
                        , TotalDowntimeMinutes 
                        , AvgUptimeMinutes         --ECR #25306: mt/3-26-2003
                        , TotalUptimeMinutes       --ECR #25306: mt/3-26-2003
                        , TotalOperatingMinutes)
    SELECT Reason_Name
         , COUNT(Duration)
         , Total_Duration = SUM(Duration)
         , (SUM(Duration) / COUNT(Duration))
         , @TotalPLT
         ---, (SUM(Uptime) / COUNT(Duration))         --ECR #25306: mt/3-26-2003
         , ((@TotalOperating-@TotalPLT) / COUNT(Duration))         --ECR #25306: mt/3-26-2003 
         , (@TotalOperating-@TotalPLT)             -- ECR #25108 : Arjun/2-2-2010    --ECR #25306: mt/3-26-2003
         , @TotalOperating
      FROM #TopNDR
  GROUP BY Reason_Name
  ORDER BY Total_Duration DESC
RETURN_RESULT_SET:
  -- SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  SELECT * FROM #MyReport
  DROP TABLE #TopNDR
  DROP TABLE #MyReport
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
