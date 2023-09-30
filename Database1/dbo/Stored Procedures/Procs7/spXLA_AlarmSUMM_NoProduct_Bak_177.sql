-- DESCRIPTION: spXLA_AlarmSUMM_NoProduct is modified from spXLA_AlarmSummary_AP. Changes include additon of action-level reasons.
-- (MT/8-16-2002) and Crew,shift filters (defect #24440:mt/9-10-2002)
--
-- ECR #25128: mt/3-13-2003: handle duplicate Var_desc since GBDB allows it; must handle via code
--
CREATE PROCEDURE dbo.[spXLA_AlarmSUMM_NoProduct_Bak_177]
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50)
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Acknowledged 	  	 TinyInt
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @SelectA1 	  	 Int
 	 , @SelectA2 	  	 Int
 	 , @SelectA3 	  	 Int
 	 , @SelectA4 	  	 Int
 	 , @ReasonLevel 	  	 Int
    , @Crew_Desc            Varchar(10)
    , @Shift_Desc           Varchar(10)
 	 , @Username Varchar(50)= NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Define Reason Levels
DECLARE @LevelLocation 	  Int --Slave Units
DECLARE @LevelReason1 	  Int
DECLARE @LevelReason2 	  Int
DECLARE @LevelReason3 	  Int
DECLARE @LevelReason4 	  Int
DECLARE @LevelAction1 	  Int
DECLARE @LevelAction2 	  Int
DECLARE @LevelAction3 	  Int
DECLARE @LevelAction4 	  Int
 	 --Identifiers for Alarms
DECLARE @TotalDurations 	  	 Real
DECLARE @TotalOperating  	 Real
DECLARE @MasterUnit 	  	 Int
 	 --Pertaining Data To Be included in ResultSet
DECLARE @Pu_Id 	  	  	 Integer
DECLARE @Data_Type_Id 	  	 Integer
DECLARE @VariableFetchCount 	 Integer
DECLARE @RowCount               Integer
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
 	 --Define levels.....
SELECT @LevelLocation  = 0
SELECT @LevelReason1   = 1
SELECT @LevelReason2   = 2
SELECT @LevelReason3   = 3
SELECT @LevelReason4   = 4
SELECT @LevelAction1   = 5
SELECT @LevelAction2   = 6
SELECT @LevelAction3   = 7
SELECT @LevelAction4   = 8
-- ECR #25128: mt/3-13-2003: handle duplicate Var_desc. GBDB doesn't enforce unique Var_desc across entire database system
-- must screen out duplicate Var_Desc
--
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --input variable NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have @Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @MasterUnit = pu.Master_Unit --@Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, 
      FROM Variables v 
      JOIN Prod_Units pu ON pu.Pu_Id = v.Pu_Id  
     WHERE v.Var_Id = @Var_Id
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        RETURN
      END
    --EndIf:count=0
  END
Else --@Var_Desc NOT null, use it
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @MasterUnit = pu.Master_Unit  --@Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, 
      FROM Variables v
      JOIN Prod_Units pu on pu.Pu_Id = v.Pu_Id
     WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount <> 1
      BEGIN
        If @VariableFetchCount = 0
          SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND    
        Else --too many var_desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND in var_desc
        --EndIf:Count
        RETURN
      END
    --EndIf:Count<>1
  END
--EndIf:Both @Var_Id and @Var_Desc null
If @MasterUnit Is NULL SELECT @MasterUnit = @Pu_Id
-- CREATE All TEMP TABLES here .................
CREATE TABLE #MyReport 
  ( ReasonName 	  	 Varchar(100) 	 
  , NumberOfOccurances 	 Int  NULL
  , TotalReasonMinutes  	 Real NULL
  , AvgReasonMinutes  	 Real NULL
  , TotalAlarmMinutes 	 Real NULL
  , TotalOperatingMinutes Real NULL
  )
-- Create All Temp tables we would need here.....
CREATE TABLE #TempAlarmData 
  ( Alarm_Id 	  	 Int
  , Alarm_Desc 	  	 Varchar(1000) NULL
  , Start_Time 	  	 DateTime
  , End_Time 	  	 DateTime    NULL
  , Duration 	  	 real        NULL
  , Reason_Name 	         Varchar(100) NULL  --extra for Summary to report Reason Name at reason level Summary being sought
  , Source_Pu_Id 	 Int         NULL
  , Reason1_Id 	  	 Int         NULL
  , Reason2_Id 	  	 Int         NULL 
  , Reason3_Id  	  	 Int         NULL
  , Reason4_Id  	  	 Int         NULL
  , Comment_Id 	  	 Int         NULL
  , Max_Result          Varchar(25) NULL
  , Min_Result          Varchar(25) NULL
  , Start_Result        Varchar(25) NULL
  , End_Result          Varchar(25) NULL
  , Modified_On         DateTime    NULL    
  , Ack_On              DateTime    NULL
  , A1_Id               Int         NULL
  , A2_Id               Int         NULL
  , A3_Id               Int         NULL
  , A4_Id               Int         NULL
  , Cutoff              TinyInt     NULL
  , User_Id             Int         NULL
  , Research_User_Id    Int         NULL
  , Research_Status_Id  Int         NULL
  , Research_Open_Date  DateTime    NULL
  , Research_Close_Date DateTime    NULL
  )
-- Determine Crew,Shift Types
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     GOTO NOCREW_NOSHIFT_NOPRODUCT_INSERT
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL GOTO HASCREW_NOSHIFT_NOPRODUCT_INSERT
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL GOTO NOCREW_HASSHIFT_NOPRODUCT_INSERT
Else                                                   GOTO HASCREW_HASSHIFT_NOPRODUCT_INSERT
--EndIf:Crew,Shift
NOCREW_NOSHIFT_NOPRODUCT_INSERT:
  If @Acknowledged = 1 
    BEGIN
      INSERT INTO #TempAlarmData (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
             , Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
             , Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id
             , Research_Open_Date, Research_Close_Date  )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc , a.Start_Time , a.End_Time , a.Duration, a.Source_PU_Id, a.Cause1
             , a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
             , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id
             , a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
           AND a.Ack = 1
    END
  Else --@Acknowledged = 0
    BEGIN
      INSERT INTO #TempAlarmData (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
             , Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
             , Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id
             , Research_Open_Date, Research_Close_Date  )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc , a.Start_Time , a.End_Time , a.Duration, a.Source_PU_Id, a.Cause1
             , a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
             , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id
             , a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
    END
  --EndIf @Acknowledged ..
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End NOCREW_NOSHIFT_NOPRODUCT_INSERT:
HASCREW_NOSHIFT_NOPRODUCT_INSERT:
  If @Acknowledged = 1 
    BEGIN
      INSERT INTO #TempAlarmData (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
             , Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
             , Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id
             , Research_Open_Date, Research_Close_Date  )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
             , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
             , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time End
             , a.Duration, a.Source_PU_Id, a.Cause1
             , a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
             , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id
             , a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR (a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL))
               )
           AND C.Crew_Desc = @Crew_Desc
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
           AND a.Ack = 1
    END
  Else --@Acknowledged = 0
    BEGIN
      INSERT INTO #TempAlarmData (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
             , Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
             , Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id
             , Research_Open_Date, Research_Close_Date  )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
             , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
             , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time End
             , a.Duration, a.Source_PU_Id, a.Cause1
             , a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
             , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id
             , a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR (a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL))
               )
           AND C.Crew_Desc = @Crew_Desc
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
    END
  --EndIf @Acknowledged ..
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End HASCREW_NOSHIFT_NOPRODUCT_INSERT:
NOCREW_HASSHIFT_NOPRODUCT_INSERT:
  If @Acknowledged = 1 
    BEGIN
      INSERT INTO #TempAlarmData (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
             , Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
             , Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id
             , Research_Open_Date, Research_Close_Date  )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
             , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
             , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time End
             , a.Duration, a.Source_PU_Id, a.Cause1
             , a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
             , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id
             , a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR (a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL))
               )
           AND C.Shift_Desc = @Shift_Desc
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
           AND a.Ack = 1
    END
  Else --@Acknowledged = 0
    BEGIN
      INSERT INTO #TempAlarmData (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
             , Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
             , Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id
             , Research_Open_Date, Research_Close_Date  )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
             , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
             , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time End
             , a.Duration, a.Source_PU_Id, a.Cause1
             , a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
             , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id
             , a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR (a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL))
               )
           AND C.Shift_Desc = @Shift_Desc
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
    END
  --EndIf @Acknowledged ..
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End NOCREW_HASSHIFT_NOPRODUCT_INSERT:
HASCREW_HASSHIFT_NOPRODUCT_INSERT:
  If @Acknowledged = 1 
    BEGIN
      INSERT INTO #TempAlarmData (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
             , Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
             , Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id
             , Research_Open_Date, Research_Close_Date  )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
             , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
             , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time End
             , a.Duration, a.Source_PU_Id, a.Cause1
             , a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
             , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id
             , a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR (a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL))
               )
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
           AND a.Ack = 1
    END
  Else --@Acknowledged = 0
    BEGIN
      INSERT INTO #TempAlarmData (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
             , Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
             , Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id
             , Research_Open_Date, Research_Close_Date  )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
             , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
             , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time End
             , a.Duration, a.Source_PU_Id, a.Cause1
             , a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
             , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id
             , a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR (a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL))
               )
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
    END
  --EndIf @Acknowledged ..
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End HASCREW_HASSHIFT_NOPRODUCT_INSERT:
FINISH_UP_TEMP_ALARM_TABLE:
  -- Clean up zero PU_Id
  DELETE FROM #TempAlarmData WHERE Source_Pu_Id = 0
  -- We have inserted into #TempAlarmData alarms that may have started and ended beyond user-requested time range.
  -- To only report Alarms for the specified time range; need to change start_time and End_Time
  UPDATE #TempAlarmData  SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
  UPDATE #TempAlarmData  SET End_Time = @End_Time  WHERE End_Time > @End_Time OR End_Time IS NULL
  UPDATE #TempAlarmData  SET Duration = DATEDIFF(ss, Start_Time, End_Time) / 60.0
  -- Calculate Total Alarm Duration
  SELECT @TotalDurations = (SELECT SUM(Duration) FROM #TempAlarmData) 
  --Adjust For Scheduled Alarm 
  SELECT @TotalOperating = 0
  SELECT @TotalOperating = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0) - @TotalOperating
  -- Deleted rows with Null Reason IDs or unmatched reason IDs, keeping only the "Selected Reason" 
  If @SelectR1 Is NOT NULL DELETE FROM #TempAlarmData WHERE Reason1_Id Is NULL Or Reason1_Id <> @SelectR1   
  If @SelectR2 Is NOT NULL DELETE FROM #TempAlarmData WHERE Reason2_Id Is NULL Or Reason2_Id <> @SelectR2
  If @SelectR3 Is NOT NULL DELETE FROM #TempAlarmData WHERE Reason3_Id Is NULL Or Reason3_Id <> @SelectR3
  If @SelectR4 Is NOT NULL DELETE FROM #TempAlarmData WHERE Reason4_Id Is NULL Or Reason4_Id <> @SelectR4
  If @SelectA1 Is NOT NULL DELETE FROM #TempAlarmData WHERE A1_Id Is NULL OR A1_Id <> @SelectA1
  If @SelectA2 Is NOT NULL DELETE FROM #TempAlarmData WHERE A2_Id Is NULL OR A2_Id <> @SelectA2
  If @SelectA3 Is NOT NULL DELETE FROM #TempAlarmData WHERE A3_Id Is NULL OR A3_Id <> @SelectA3
  If @SelectA4 Is NOT NULL DELETE FROM #TempAlarmData WHERE A4_Id Is NULL OR A4_Id <> @SelectA4
  -- Fill in TopNDR with Reason Names
  UPDATE #TempAlarmData 
      SET Reason_Name = Case @ReasonLevel
                          When @LevelLocation Then PU.PU_Desc
                          When @LevelReason1 Then R1.Event_Reason_Name
                          When @LevelReason2 Then R2.Event_Reason_Name
                          When @LevelReason3 Then R3.Event_Reason_Name
                          When @LevelReason4 Then R4.Event_Reason_Name
                          When @LevelAction1 Then A1.Event_Reason_Name
                          When @LevelAction2 Then A2.Event_Reason_Name
                          When @LevelAction3 Then A3.Event_Reason_Name
                          When @LevelAction4 Then A4.Event_Reason_Name
                        End
     FROM #TempAlarmData t
     JOIN Prod_Units PU ON PU.Pu_Id = t.Source_Pu_Id
     LEFT OUTER JOIN Event_Reasons R1 on (t.Reason1_Id = R1.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons R2 on (t.Reason2_Id = R2.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons R3 on (t.Reason3_Id = R3.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons R4 on (t.Reason4_Id = R4.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons A1 ON (t.A1_Id = A1.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons A2 ON (t.A2_Id = A2.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons A3 ON (t.A3_Id = A3.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons A4 ON (t.A4_Id = A4.Event_Reason_Id)
  --If there still are 'Null' reason names, replace it with "Unspecified"
  UPDATE #TempAlarmData  SET Reason_Name = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified') WHERE Reason_Name Is NULL
  --Handle No Rows...
  SELECT @RowCount = 0 
  SELECT @RowCount = Count(*) FROM #TempAlarmData
  If @RowCount = 0 
    BEGIN
      INSERT INTO #MyReport (TotalOperatingMinutes) VALUES(@TotalOperating)
      GOTO RETURN_RESULT_SET
    END
  --End Handle No Rows
  -- Populate Temp Table With Reason Ordered By
  INSERT INTO #MyReport (ReasonName, NumberOfOccurances, TotalReasonMinutes, AvgReasonMinutes, TotalAlarmMinutes, TotalOperatingMinutes)
      SELECT Reason_Name, COUNT(Duration), Total_Duration = SUM(Duration),  (SUM(Duration) / COUNT(Duration)), @TotalDurations, @TotalOperating
        FROM #TempAlarmData
    GROUP BY Reason_Name
    ORDER BY Total_Duration DESC
RETURN_RESULT_SET:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  SELECT * FROM #MyReport
DROP_TEMP_TABLES:
  DROP TABLE #TempAlarmData
  DROP TABLE #MyReport
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
