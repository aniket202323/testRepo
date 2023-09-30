-- DESCRIPTION: spXLA_AlarmDT_NoProduct is modified from spXLA_AlarmDetail_AP. Changes include additions of action level reasons,  
-- Action1...Action4(MT/8-16-2002): and Crew,Shift Filter (mt/9-10-2002)
--
-- ECR #25128: mt/3-14-2003: handle duplicate var_Desc. GBDB doesn't enforce unique Var_Desc across the entire database
-- system. Must handle duplication via code
-- ECR #25736: mt/8-20-2003: added Action & Research comments
--
CREATE PROCEDURE dbo.[spXLA_AlarmDT_NoProduct_Bak_177]
 	   @Var_Id 	  	 Int
 	 , @Var_Desc 	  	 Varchar(50)
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Acknowledged 	  	 TinyInt = 0
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @SelectA1 	  	 Int
 	 , @SelectA2 	  	 Int
 	 , @SelectA3 	  	 Int
 	 , @SelectA4 	  	 Int
 	 , @Crew_Desc            Varchar(10)
    , @Shift_Desc           Varchar(10)
 	 , @TimeSort 	  	 TinyInt
    , @DecimalChar          Varchar(1) = NULL
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
 	 --Needed for ResultSet
DECLARE @Pu_Id 	  	  	 Integer
DECLARE @Data_Type_Id 	  	 Integer
DECLARE @MasterUnit 	  	 Integer
DECLARE @VariableFetchCount 	 Integer
DECLARE @UserId 	 Int
DECLARE @Unspecified varchar(50)
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
If @DecimalChar Is NULL SELECT @DecimalChar = '.'  --Set Default Decimal Character to period
-- ECR #25128: mt/3-14-2003: handle duplicate var_Desc. GBDB doesn't enforce unique Var_Desc across the entire database
-- system. Must handle duplication via code
--
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --input variable NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have @Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @MasterUnit = pu.Master_Unit, @Data_Type_Id = v.Data_Type_Id --, @Event_Type = v.Event_Type, 
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
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @MasterUnit = pu.Master_Unit, @Data_Type_Id = v.Data_Type_Id --, @Event_Type = v.Event_Type, 
      FROM Variables v
      JOIN Prod_Units pu on pu.Pu_Id = v.Pu_Id
     WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount <> 1
      BEGIN 
        If @VariableFetchCount = 0
          SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        Else --too many Var_desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND in var_desc
        --EndIf:Count
        RETURN
      END
    --EndIf:Count<>1
  END
--EndIf:Both @Var_Desc and @Var_Id null
If @MasterUnit Is NULL SELECT @MasterUnit = @Pu_Id
-- Create All Temp tables we would need here.....
CREATE TABLE #TempAlarmData 
  ( Alarm_Id 	  	 Int
  , Alarm_Desc 	  	 Varchar(1000) NULL
  , Start_Time 	  	 DateTime
  , End_Time 	  	 DateTime    NULL
  , Duration 	  	 real        NULL
  , Source_Pu_Id 	 Int         NULL
  , Reason1_Id 	  	 Int         NULL
  , Reason2_Id 	  	 Int         NULL 
  , Reason3_Id  	  	 Int         NULL
  , Reason4_Id  	  	 Int         NULL
  , Comment_Id 	  	 Int         NULL
  , Action_Comment_Id 	 Int         NULL 	 --ECR #25736
  , Research_Comment_Id Int         NULL 	 --ECR #25736
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
  , Crew_Desc           Varchar(10) NULL
  , Shift_Desc          Varchar(10) NULL
  , Cutoff              TinyInt     NULL
  , User_Id             Int         NULL
  , Research_User_Id    Int         NULL
  , Research_Status_Id  Int         NULL
  , Research_Open_Date  DateTime    NULL
  , Research_Close_Date DateTime    NULL
  )
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     GOTO NOCREW_NOSHIFT_NOPRODUCT_INSERT
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL GOTO HASCREW_NOSHIFT_NOPRODUCT_INSERT
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL GOTO NOCREW_HASSHIFT_NOPRODUCT_INSERT
Else                                                   GOTO HASCREW_HASSHIFT_NOPRODUCT_INSERT
--EndIf:Crew,shift
-- Fill In TopNDR Table ..................
NOCREW_NOSHIFT_NOPRODUCT_INSERT:
  If @Acknowledged = 1 
    BEGIN
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
       , Reason2_Id , Reason3_Id, Reason4_Id, Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On
       , Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date
       , Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc, a.Start_Time, a.End_Time, a.Duration, a.Source_PU_Id, a.Cause1, a.Cause2
              , a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
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
      INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id
                , Reason2_Id, Reason3_Id, Reason4_Id, Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
                , Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id
                , Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc, a.Start_Time, a.End_Time, a.Duration, a.Source_PU_Id, a.Cause1, a.Cause2, a.Cause3
                , a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result, a.Modified_On
                , a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id
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
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
                , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                      When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time
                                 End
                , a.Duration, a.Source_PU_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result 
                , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                 Or a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
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
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
                , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                      When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time
                                 End
                , a.Duration, a.Source_PU_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result 
                , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                 Or a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
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
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
                , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                      When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time
                                 End
                , a.Duration, a.Source_PU_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result 
                , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                 Or a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
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
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
                , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                      When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time
                                 End
                , a.Duration, a.Source_PU_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result 
                , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                 Or a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
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
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
                , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                      When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time
                                 End
                , a.Duration, a.Source_PU_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result 
                , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                 Or a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
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
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                , [Start_Time] = Case When C.Start_Time >= a.Start_Time Then C.Start_Time Else a.Start_Time End
                , [End_Time]   = Case When a.End_Time Is NULL Then C.End_Time
                                      When C.End_Time <= a.End_Time Then C.End_Time Else a.End_Time
                                 End
                , a.Duration, a.Source_PU_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result 
                , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON 
               (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
                 OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                 Or a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
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
  --Clean up unwanted PU_Id = 0 (0 means they are marked for unused/obsolete)
  DELETE FROM #TempAlarmData WHERE Source_Pu_Id = 0
  --Economize table: If certain reason is specified, delete unspecified reasons (null ids) or the unmatched reasons
  If @SelectR1 Is NOT NULL DELETE FROM #TempAlarmData WHERE Reason1_Id Is NULL OR Reason1_Id <> @SelectR1  
  If @SelectR2 Is NOT NULL DELETE FROM #TempAlarmData WHERE Reason2_Id Is NULL OR Reason2_Id <> @SelectR2
  If @SelectR3 Is NOT NULL DELETE FROM #TempAlarmData WHERE Reason3_Id Is NULL OR Reason3_Id <> @SelectR3
  If @SelectR4 Is NOT NULL DELETE FROM #TempAlarmData WHERE Reason4_Id Is NULL OR Reason4_Id <> @SelectR4
  If @SelectA1 Is NOT NULL DELETE FROM #TempAlarmData WHERE A1_Id Is NULL OR A1_Id <> @SelectA1
  If @SelectA2 Is NOT NULL DELETE FROM #TempAlarmData WHERE A2_Id Is NULL OR A2_Id <> @SelectA1
  If @SelectA3 Is NOT NULL DELETE FROM #TempAlarmData WHERE A3_Id Is NULL OR A3_Id <> @SelectA1
  If @SelectA4 Is NOT NULL DELETE FROM #TempAlarmData WHERE A4_Id Is NULL OR A4_Id <> @SelectA1
  --We have picked Alarm rows that may have started before the specified @Start_Time OR ended after the specified @End_Time 
  --Thus we must change change #TempAlarmData's start and end times to match the specified @Start_Time and @End_Time OR our durations
  --will be outside the specified time range
  UPDATE #TempAlarmData SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
  UPDATE #TempAlarmData SET End_Time = @End_Time WHERE End_Time > @End_Time OR End_Time Is NULL
  --Calculate duration based on the specified time range
  UPDATE #TempAlarmData SET duration = DATEDIFF(ss, Start_Time, End_Time) / 60.0
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  --Retreiving Data, replacing Null Reason ID with the wording 'Unspecified'
  If @TimeSort = 1 --Ascending Order
    BEGIN
        SELECT t.Alarm_Id
             , t.Alarm_Desc
             , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(t.Start_Time,@InTimeZone)
             , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(t.End_Time,@InTimeZone)
             , t.Duration
             , Location = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
             , Reason1  = Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2  = Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End 	  	  	 
             , Reason3  = Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4  = Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , t.Comment_Id 
             , t.Action_Comment_Id
             , t.Research_Comment_Id
             , [Max_Result]   = Case When @DecimalChar <> '.' ANd @Data_Type_Id = 2 Then REPLACE(t.Max_Result,   '.', @DecimalChar) Else t.Max_Result   End
             , [Min_Result]   = Case When @DecimalChar <> '.' ANd @Data_Type_Id = 2 Then REPLACE(t.Min_Result,   '.', @DecimalChar) Else t.Min_Result   End
             , [Start_Result] = Case When @DecimalChar <> '.' ANd @Data_Type_Id = 2 Then REPLACE(t.Start_Result, '.', @DecimalChar) Else t.Start_Result End
             , [End_Result]   = Case When @DecimalChar <> '.' ANd @Data_Type_Id = 2 Then REPLACE(t.End_Result,   '.', @DecimalChar) Else t.End_Result   End
             , [Modified_On] = dbo.fnServer_CmnConvertFromDbTime(t.Modified_On,@InTimeZone)
             , [Ack_On] = dbo.fnServer_CmnConvertFromDbTime(t.Ack_On,@InTimeZone)
             , [Action1] = Case When t.A1_Id Is NULL Then NULL Else A1.Event_Reason_Name End
             , [Action2] = Case When t.A2_Id Is NULL Then NULL Else A2.Event_Reason_Name End
             , [Action3] = Case When t.A3_Id Is NULL Then NULL Else A3.Event_Reason_Name End
             , [Action4] = Case When t.A4_Id Is NULL Then NULL Else A4.Event_Reason_Name End
             , Crew_Desc
             , Shift_Desc
             , t.Cutoff
             , [User]            = u.Username
             , [Research_User]   = u2.Username
             , [Research_Status] = r.Research_Status_Desc
             , [Research_Open_Date] = dbo.fnServer_CmnConvertFromDbTime(t.Research_Open_Date,@InTimeZone)
             , [Research_Close_Date] = dbo.fnServer_CmnConvertFromDbTime(t.Research_Close_Date,@InTimeZone)
             , [Data_Type_Id] = @Data_Type_Id
          FROM #TempAlarmData t
          JOIN Prod_Units pu ON t.Source_Pu_Id = pu.Pu_Id AND pu.Pu_Id <> 0
          LEFT OUTER JOIN Event_Reasons R1 ON t.Reason1_Id = R1.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R2 ON t.Reason2_Id = R2.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R3 ON t.Reason3_Id = R3.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R4 ON t.Reason4_Id = R4.Event_Reason_Id
          LEFT OUTER JOIN Users u ON u.User_Id = t.User_Id
          LEFT OUTER JOIN Users u2 ON u2.User_Id = t.Research_User_Id
          LEFT OUTER JOIN Research_Status r ON r.Research_Status_Id = t.Research_Status_Id
          LEFT OUTER JOIN Event_Reasons A1 ON A1.Event_Reason_Id = t.A1_Id
          LEFT OUTER JOIN Event_Reasons A2 ON A2.Event_Reason_Id = t.A2_Id
          LEFT OUTER JOIN Event_Reasons A3 ON A3.Event_Reason_Id = t.A3_Id
          LEFT OUTER JOIN Event_Reasons A4 ON A4.Event_Reason_Id = t.A4_Id
      ORDER BY t.Start_Time ASC
    END
  Else   -- Descending Order
    BEGIN
        SELECT t.Alarm_Id
             , t.Alarm_Desc
             , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(t.Start_Time,@InTimeZone)
             , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(t.End_Time,@InTimeZone)
             , t.Duration
             , Location = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
             , Reason1  = Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2  = Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End 	  	  	 
             , Reason3  = Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4  = Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , t.Comment_Id 
             , t.Action_Comment_Id
             , t.Research_Comment_Id
             , [Max_Result]   = Case When @DecimalChar <> '.' ANd @Data_Type_Id = 2 Then REPLACE(t.Max_Result,   '.', @DecimalChar) Else t.Max_Result   End
             , [Min_Result]   = Case When @DecimalChar <> '.' ANd @Data_Type_Id = 2 Then REPLACE(t.Min_Result,   '.', @DecimalChar) Else t.Min_Result   End
             , [Start_Result] = Case When @DecimalChar <> '.' ANd @Data_Type_Id = 2 Then REPLACE(t.Start_Result, '.', @DecimalChar) Else t.Start_Result End
             , [End_Result]   = Case When @DecimalChar <> '.' ANd @Data_Type_Id = 2 Then REPLACE(t.End_Result,   '.', @DecimalChar) Else t.End_Result   End
             , [Modified_On] = dbo.fnServer_CmnConvertFromDbTime(t.Modified_On,@InTimeZone)
             , [Ack_On] = dbo.fnServer_CmnConvertFromDbTime(t.Ack_On,@InTimeZone)
             , [Action1] = Case When t.A1_Id Is NULL Then NULL Else A1.Event_Reason_Name End
             , [Action2] = Case When t.A2_Id Is NULL Then NULL Else A2.Event_Reason_Name End
             , [Action3] = Case When t.A3_Id Is NULL Then NULL Else A3.Event_Reason_Name End
             , [Action4] = Case When t.A4_Id Is NULL Then NULL Else A4.Event_Reason_Name End
             , Crew_Desc
             , Shift_Desc
             , t.Cutoff
             , [User]            = u.Username
             , [Research_User]   = u2.Username
             , [Research_Status] = r.Research_Status_Desc
             , [Research_Open_Date] = dbo.fnServer_CmnConvertFromDbTime(t.Research_Open_Date,@InTimeZone)
             , [Research_Close_Date] = dbo.fnServer_CmnConvertFromDbTime(t.Research_Close_Date,@InTimeZone)
             , [Data_Type_Id] = @Data_Type_Id
          FROM #TempAlarmData t
          JOIN Prod_Units pu ON t.Source_Pu_Id = pu.Pu_Id AND pu.Pu_Id <> 0
          LEFT OUTER JOIN Event_Reasons R1 ON t.Reason1_Id = R1.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R2 ON t.Reason2_Id = R2.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R3 ON t.Reason3_Id = R3.Event_Reason_Id
          LEFT OUTER JOIN Event_Reasons R4 ON t.Reason4_Id = R4.Event_Reason_Id
          LEFT OUTER JOIN Users u ON u.User_Id = t.User_Id
          LEFT OUTER JOIN Users u2 ON u2.User_Id = t.Research_User_Id
          LEFT OUTER JOIN Research_Status r ON r.Research_Status_Id = t.Research_Status_Id
          LEFT OUTER JOIN Event_Reasons A1 ON A1.Event_Reason_Id = t.A1_Id
          LEFT OUTER JOIN Event_Reasons A2 ON A2.Event_Reason_Id = t.A2_Id
          LEFT OUTER JOIN Event_Reasons A3 ON A3.Event_Reason_Id = t.A3_Id
          LEFT OUTER JOIN Event_Reasons A4 ON A4.Event_Reason_Id = t.A4_Id
      ORDER BY t.Start_Time DESC
    END
  --EndIf ToOrder...
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #TempAlarmData
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
