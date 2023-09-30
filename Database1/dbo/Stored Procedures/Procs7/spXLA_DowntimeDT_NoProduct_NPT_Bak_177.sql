-- DESCRIPTION: spXLA_DowntimeDT_NoProduct_NPT is modified from spXLA_DowntimeDetail_NoProduct_New. Changes includes
-- 6 additional input parameters: Action1... Action4(mt/8-6-2002); Crew, Shift (Defect #24395:mt/8/30-2002;mt/9-16-2002)
--
-- ECR #25517 (mt/5-13-2003): Performance Tuning Where Clause; Making use of the index on End_Time
-- ECR #25517(mt/5-19-2003): Added (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) to the JOIN Crew_Schedule
-- to Timed_Event_Details. Without this additional clause the D.End_Time Is NULL will sweep crew periods that are 
-- completely outside the report time.
--
-- ECR #25704(mt/6-12-2003) Proficy Software Version 4.0 will remove Comments from Waste_n_Timed_Comments into Comments Table.
--
CREATE PROCEDURE dbo.[spXLA_DowntimeDT_NoProduct_NPT_Bak_177]
 	   @Start_Time 	 DateTime
 	 , @End_Time 	 DateTime
 	 , @PU_Id 	 Int 	  	  	 --Add-In;sUnit (which is MasterUnit)
 	 , @SelectSource 	 Int 	  	  	 -- 	  	  	  slave units
 	 , @SelectR1 	 Int
 	 , @SelectR2 	 Int
 	 , @SelectR3 	 Int
 	 , @SelectR4 	 Int
 	 , @SelectA1 	 Int
 	 , @SelectA2 	 Int
 	 , @SelectA3 	 Int
 	 , @SelectA4 	 Int
 	 , @Crew_Desc 	 Varchar(10)
 	 , @Shift_Desc 	 Varchar(10)
 	 , @TimeSort 	 TinyInt = NULL
 	 , @Username Varchar(50) = Null
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
DECLARE @MasterUnit  	 Int
DECLARE @Unit 	  	 Varchar(50)
 	 --Needed for Crew,Shift Filters
DECLARE @CrewShift       TinyInt
DECLARE @NoCrewNoShift   TinyInt
DECLARE @HasCrewNoShift  TinyInt
DECLARE @NoCrewHasShift  TinyInt
DECLARE @HasCrewHasShift TinyInt
DECLARE @Unspecified varchar(50)
 	 --Define Crew,Shift Type
SELECT @NoCrewNoShift   = 1
SELECT @HasCrewNoShift  = 2
SELECT @NoCrewHasShift  = 3
SELECT @HasCrewHasShift = 4
--DECLARE @UserId 	 Int
--SELECT @UserId = User_Id
--FROM users
--WHERE Username = @Username
--
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--
--SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     SELECT @CrewShift = @NoCrewNoShift
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL SELECT @CrewShift = @HasCrewNoShift
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL SELECT @CrewShift = @NoCrewHasShift
Else                                                   SELECT @CrewShift = @HasCrewHasShift
--EndIf:Crew,shift
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else SELECT @MasterUnit = @PU_Id
-- Get All TED Records In Field I Care About
CREATE TABLE #TopNDR (
 	   Detail_Id         Int
 	 , Start_Time        DateTime
 	 , End_Time          DateTime    NULL
  	 , Duration          real        NULL
        , Uptime            Real        NULL 
 	 , SourcePU          Int         NULL
 	 , MasterUnit        Int         NULL
        , Cause_Comment_Id  Int         NULL 	 ---- ECR #25704(mt/6-16-2003)
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
 	 , Crew_Desc         Varchar(10) NULL
 	 , Shift_Desc        Varchar(10) NULL
 	 , First_Comment_Id  Int         NULL
 	 , Last_Comment_Id   Int         NULL
 	 , NPT tinyint 	 NULL
)
-- Get All The Detail Records We Care About
-- Insert Data Into #TopNDR Temp Table
  If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_INSERT
  Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_INSERT
  Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_INSERT
  Else                                 GOTO HASCREW_HASSHIFT_INSERT
  --EndIf:@CrewShift
NOCREW_NOSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
        SELECT  D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEFault_Id, D.TEStatus_Id
          FROM  Timed_Event_Details D
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
    END       
  Else    --@MasterUnit not null
    BEGIN      
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id)
        SELECT D.TEDEt_Id, D.Start_Time, D.End_Time, D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEFault_Id, D.TEStatus_Id
          FROM Timed_Event_Details D
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
  --EndIf @PU_Id
  GOTO CONTINUE_DOWNTIME_NOPRODUCT
--End NOCREW_NOSHIFT_INSERT:
HASCREW_NOSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id, Crew_Desc, Shift_Desc)
        SELECT DISTINCT
               D.TEDEt_Id
             , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEFault_Id, D.TEStatus_Id, C.Crew_Desc, C.Shift_Desc
          FROM Timed_Event_Details D
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc 
           AND D.Start_Time < C.End_Time AND ( D.End_Time > C.Start_Time OR D.End_Time Is NULL )
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                          --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
    END       
  Else    --@MasterUnit not null
    BEGIN       
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id, Crew_Desc, Shift_Desc)
        SELECT DISTINCT
               D.TEDEt_Id
             , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEFault_Id, D.TEStatus_Id, C.Crew_Desc, C.Shift_Desc
          FROM Timed_Event_Details D
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc
           AND D.Start_Time < C.End_Time AND ( D.End_Time > C.Start_Time OR D.End_Time Is NULL )
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                          --ECR #25517(mt/5-19-2003)
           AND C.PU_Id = @MasterUnit                                                            --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
  --EndIf @PU_Id
  GOTO CONTINUE_DOWNTIME_NOPRODUCT
--End HASCREW_NOSHIFT_INSERT:
NOCREW_HASSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id, Crew_Desc, Shift_Desc)
        SELECT DISTINCT
               D.TEDEt_Id
             , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEFault_Id, D.TEStatus_Id, C.Crew_Desc, C.Shift_Desc
          FROM Timed_Event_Details D
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND ( D.End_Time > C.Start_Time OR D.End_Time Is NULL )
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                          --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
    END       
  Else    --@MasterUnit not null
    BEGIN       
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id, Crew_Desc, Shift_Desc)
        SELECT DISTINCT
               D.TEDEt_Id
             , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEFault_Id, D.TEStatus_Id, C.Crew_Desc, C.Shift_Desc
          FROM Timed_Event_Details D
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND ( D.End_Time > C.Start_Time OR D.End_Time Is NULL )
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                          --ECR #25517(mt/5-19-2003)
           AND C.PU_Id = @MasterUnit                                                            --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
  --EndIf @PU_Id
  GOTO CONTINUE_DOWNTIME_NOPRODUCT
--End NOCREW_HASSHIFT_INSERT:
HASCREW_HASSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id, Crew_Desc, Shift_Desc)
        SELECT DISTINCT
               D.TEDEt_Id
             , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEFault_Id, D.TEStatus_Id, C.Crew_Desc, C.Shift_Desc
          FROM Timed_Event_Details D
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND ( D.End_Time > C.Start_Time OR D.End_Time Is NULL )
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                          --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
    END       
  Else    --@MasterUnit not null
    BEGIN       
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Fault_Id, Status_Id, Crew_Desc, Shift_Desc)
        SELECT DISTINCT
               D.TEDEt_Id
             , [Start_Time] = Case When C.Start_Time >= D.Start_Time Then C.Start_Time Else D.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then C.End_Time
                                   When C.End_Time <= D.End_Time Then C.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.TEFault_Id, D.TEStatus_Id, C.Crew_Desc, C.Shift_Desc
          FROM Timed_Event_Details D
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND ( D.End_Time > C.Start_Time OR D.End_Time Is NULL )
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                          --ECR #25517(mt/5-19-2003)
           AND C.PU_Id = @MasterUnit                                                            --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
  --EndIf @PU_Id
  GOTO CONTINUE_DOWNTIME_NOPRODUCT
--End HASCREW_HASSHIFT_INSERT:
CONTINUE_DOWNTIME_NOPRODUCT:
  -- Clean up unwanted PU_Id = 0 (marked for unused/obsolete)
  DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
  --Delete For Additional Selection Criteria
  If @SelectSource Is Not NULL 	  	  	 --@SelectSource = AddIn's locations
    BEGIN 	 
      If @SelectSource = -1 	  	  	 --MSi/MT/4/11/01:AddIn's "None" location=>to retain only null locations, delete others
        DELETE FROM #TopNDR WHERE SourcePU Is NOT NULL
      Else
      --DELETE FROM #TopNDR WHERE SourcePU Is NULL Or SourcePU <> @SelectSource
        DELETE FROM #TopNDR WHERE (SourcePU Is NULL AND MasterUnit <> @PU_Id) OR SourcePU <> @SelectSource
      --EndIf
    END
  --EndIf
  If @SelectR1 Is Not NULL  DELETE FROM #TopNDR WHERE R1_Id Is NULL Or R1_Id <> @SelectR1  
  If @SelectR2 Is Not NULL  DELETE FROM #TopNDR WHERE R2_Id Is NULL Or R2_Id <> @SelectR2
  If @SelectR3 Is Not NULL  DELETE FROM #TopNDR WHERE R3_Id Is NULL Or R3_Id <> @SelectR3
  If @SelectR4 Is Not NULL  DELETE FROM #TopNDR WHERE R4_Id Is NULL Or R4_Id <> @SelectR4
  If @SelectA1 Is NOT NULL  DELETE FROM #TopNDR WHERE A1_Id Is NULL OR A1_Id <> @SelectA1
  If @SelectA2 Is NOT NULL  DELETE FROM #TopNDR WHERE A2_Id Is NULL OR A2_Id <> @SelectA2
  If @SelectA3 Is NOT NULL  DELETE FROM #TopNDR WHERE A3_Id Is NULL OR A3_Id <> @SelectA3
  If @SelectA4 Is NOT NULL  DELETE FROM #TopNDR WHERE A4_Id Is NULL OR A4_Id <> @SelectA4
  -- Take Care Of Record Start And End Times 
  UPDATE #TopNDR SET start_time = @Start_Time WHERE start_time < @Start_Time
  UPDATE #TopNDR SET end_time = @End_Time WHERE end_time > @End_Time OR end_time is null
  UPDATE #TopNDR SET duration = datediff(ss, start_time, end_time) / 60.0
  --ECR #25704(mt/6-16-2003) Get comments from Comments Table instead of Waste_n_Timed_Comments (outdated in 4.0)
  CREATE TABLE #Comments (Detail_Id Int, FirstComment Int NULL, LastComment Int NULL)
  INSERT INTO #Comments
    SELECT D.Detail_Id, FirstComment = D.Cause_Comment_Id, LastComment = C.Comment_Id
      FROM #TopNDR D
      LEFT JOIN Comments C ON C.TopOfChain_Id = D.Cause_Comment_Id AND C.NextComment_Id Is NULL AND C.Comment_Id <> D.Cause_Comment_Id
  UPDATE #TopNDR 
      SET First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
     FROM #TopNDR D
     JOIN #Comments C ON C.Detail_Id = D.Detail_Id
  /* Old code
  CREATE TABLE #Comments (Detail_Id Int, FirstComment Int NULL, LastComment Int NULL)  
  --Get First And Last Comment
  INSERT INTO #Comments
    SELECT  D.Detail_Id,  min(C.WTC_ID), max(C.WTC_ID)
      FROM  #TopNDR D, Waste_n_Timed_Comments C
     WHERE  C.WTC_Source_Id = D.Detail_Id AND C.WTC_Type = 2
  GROUP BY  D.Detail_Id   
  UPDATE #TopNDR 
      SET  First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
     FROM  #TopNDR D, #Comments C 
    WHERE  D.Detail_Id = C.Detail_Id 
  DROP TABLE #Comments
  */
---------------------------------------------------------------------------------------    
/*
 	  	 Non Productive Time
 	  	 
*/
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration int)
      INSERT INTO @Periods_NPT ( Starttime,Endtime)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @End_time THEN @End_time
                                                ELSE np.End_Time
                                                END
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
            JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
                                                                                                      AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
      WHERE PU_Id = @PU_id
                  AND np.Start_Time < @End_time
                  AND np.End_Time > @Start_Time
-------NPT OF Downtime-------
-- Case 1 :  Downtime    St---------------------End
-- 	  	  	  NPT   St--------------End
UPDATE #TopNDR SET Start_Time = n.Endtime,
 	  	  	  	  	 NPT = 1
FROM #TopNDR  JOIN @Periods_NPT n ON (Start_Time > n.StartTime AND End_time > n.EndTime AND Start_Time < n.EndTime)
-- Case 2 :  Downtime    St---------------------End
-- 	  	  	  NPT 	  	  	  	  	 St--------------End
UPDATE #TopNDR SET End_Time = n.Starttime,
 	  	  	  	    NPT = 1
FROM 	 #TopNDR 	  	    
JOIN @Periods_NPT n ON (Start_Time < n.StartTime AND End_Time < n.Endtime AND End_Time > n.StartTime)
 	  	 
-- Case 3 :  Downtime   St-----------------------End
-- 	  	  	  NPT   St-------------------------------End
UPDATE #TopNDR SET Start_Time = End_Time,
 	  	  	  	  	 NPT = 1
FROM 	 #TopNDR  	  	    
JOIN @Periods_NPT n ON( (Start_Time BETWEEN n.StartTime AND n.EndTime) AND (End_time BETWEEN n.StartTime AND n.EndTime))
Update #TopNDR Set Duration =DateDiff(ss,Start_Time,End_Time)/60.0
-- Case 4 :  Downtime   St-----------------------End
-- 	  	  	  NPT 	  	    St-----------------End
UPDATE #TopNDR  SET NPT = 1
FROM #TopNDR  JOIN @Periods_NPT n ON( (n.StartTime BETWEEN Start_Time AND End_Time) AND (n.Endtime BETWEEN Start_Time AND End_Time))
-- --------------------------------------------------     
-- --------------------------------------------------
-- RETURN DATA
-- --------------------------------------------------
  If @MasterUnit Is NOT NULL SELECT @Unit = PU_Desc FROM Prod_Units WHERE PU_Id = @MasterUnit
 	   --(If "Unit" (master unit) is specified, we'll need its description)
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @TimeSort = 1
    If @MasterUnit Is NULL
      BEGIN
           SELECT D.Detail_Id 
 	  	  	  	 , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(D.Start_Time,@InTimeZone)
 	  	  	  	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(D.End_Time,@InTimeZone)
 	  	  	  	 , D.Duration, D.Uptime
                , Unit 	  = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
                             -- [When Master Unit is SourcePu we will report it as a location]
                , Location = Case When D.SourcePU Is NULL  Then @Unspecified Else PU.PU_Desc End
                , Reason1  = Case When D.R1_Id Is NULL     Then @Unspecified Else R1.Event_Reason_Name End
                , Reason2  = Case When D.R2_Id Is NULL     Then @Unspecified Else R2.Event_Reason_Name End
                , Reason3  = Case When D.R3_Id Is NULL     Then @Unspecified Else R3.Event_Reason_Name End
                , Reason4  = Case When D.R4_Id Is NULL     Then @Unspecified Else R4.Event_Reason_Name End
                , Action1  = Case When D.A1_Id Is NULL     Then @Unspecified Else A1.Event_Reason_Name End
                , Action2  = Case When D.A2_Id Is NULL     Then @Unspecified Else A2.Event_Reason_Name End
                , Action3  = Case When D.A3_Id Is NULL     Then @Unspecified Else A3.Event_Reason_Name End
                , Action4  = Case When D.A4_Id Is NULL     Then @Unspecified Else A4.Event_Reason_Name End
                , Fault 	    = Case When D.Fault_Id Is NULL  Then @Unspecified Else F.TEFault_Name End
                , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
                , D.First_Comment_Id, D.Last_Comment_Id, D.Crew_Desc, D.Shift_Desc
           FROM  #TopNDR D
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
 	  	    WHERE D.NPT IS NULL
        ORDER BY D.Start_Time ASC
      END
    Else    --@MasterUnit specified; don't need Unit
      BEGIN
 	    SELECT D.Detail_Id
 	  	  	  	 , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(D.Start_Time,@InTimeZone)
 	  	  	  	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(D.End_Time,@InTimeZone)
 	  	  	  	 , D.Duration, D.Uptime
                , Unit     = @Unit -- [When Master Unit is SourcePu we will report it as a location]
                , Location = Case When D.SourcePU Is NULL  Then @Unspecified Else PU.PU_Desc End
                , Reason1  = Case When D.R1_Id Is NULL     Then @Unspecified Else R1.Event_Reason_Name End
                , Reason2  = Case When D.R2_Id Is NULL     Then @Unspecified Else R2.Event_Reason_Name End
                , Reason3  = Case When D.R3_Id Is NULL     Then @Unspecified Else R3.Event_Reason_Name End
                , Reason4  = Case When D.R4_Id Is NULL     Then @Unspecified Else R4.Event_Reason_Name End
                , Action1  = Case When D.A1_Id Is NULL     Then @Unspecified Else A1.Event_Reason_Name End
                , Action2  = Case When D.A2_Id Is NULL     Then @Unspecified Else A2.Event_Reason_Name End
                , Action3  = Case When D.A3_Id Is NULL     Then @Unspecified Else A3.Event_Reason_Name End
                , Action4  = Case When D.A4_Id Is NULL     Then @Unspecified Else A4.Event_Reason_Name End
                , Fault    = Case When D.Fault_Id Is NULL  Then @Unspecified Else F.TEFault_Name End
                , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
                , D.First_Comment_Id, D.Last_Comment_Id, D.Crew_Desc, D.Shift_Desc
           FROM  #TopNDR D
 	    LEFT OUTER JOIN Prod_Units PU ON (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
           LEFT OUTER JOIN Event_Reasons R1 ON (D.R1_Id = R1.Event_Reason_Id)
 	    LEFT OUTER JOIN Event_ReasONs R2 ON (D.R2_Id = R2.Event_Reason_Id)
 	    LEFT OUTER JOIN Event_Reasons R3 ON (D.R3_Id = R3.Event_Reason_Id)
 	    LEFT OUTER JOIN Event_Reasons R4 ON (D.R4_Id = R4.Event_Reason_Id)
 	    LEFT OUTER JOIN Event_Reasons A1 ON (D.A1_Id = A1.Event_Reason_Id)
 	    LEFT OUTER JOIN Event_Reasons A2 ON (D.A2_Id = A2.Event_Reason_Id)
 	    LEFT OUTER JOIN Event_Reasons A3 ON (D.A3_Id = A3.Event_Reason_Id)
 	    LEFT OUTER JOIN Event_Reasons A4 ON (D.A4_Id = A4.Event_Reason_Id)
 	    LEFT OUTER JOIN Timed_Event_Fault F ON (D.Fault_Id = F.TEFault_Id)
 	    LEFT OUTER JOIN Timed_Event_Status S ON (D.Status_Id = S.TEStatus_Id)
 	    WHERE D.NPT IS NULL
        ORDER BY D.Start_Time ASC
      END
    --EndIf @MasterUnit
  Else   -- Descending
    If @MasterUnit Is NULL
      BEGIN
           SELECT D.Detail_Id
 	  	  	  	 , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(D.Start_Time,@InTimeZone)
 	  	  	  	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(D.End_Time,@InTimeZone)
 	  	  	  	 , D.Duration
 	  	  	  	 , D.Uptime
                , Unit 	    = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
 	  	    	    -- [When Master Unit is SourcePu we will report it as a location]
                , Location = Case When D.SourcePU Is NULL  Then @Unspecified Else PU.PU_Desc End
                , Reason1  = Case When D.R1_Id Is NULL     Then @Unspecified Else R1.Event_Reason_Name End
                , Reason2  = Case When D.R2_Id Is NULL     Then @Unspecified Else R2.Event_Reason_Name End
                , Reason3  = Case When D.R3_Id Is NULL     Then @Unspecified Else R3.Event_Reason_Name End
                , Reason4  = Case When D.R4_Id Is NULL     Then @Unspecified Else R4.Event_Reason_Name End
                , Action1  = Case When D.A1_Id Is NULL     Then @Unspecified Else A1.Event_Reason_Name End
                , Action2  = Case When D.A2_Id Is NULL     Then @Unspecified Else A2.Event_Reason_Name End
                , Action3  = Case When D.A3_Id Is NULL     Then @Unspecified Else A3.Event_Reason_Name End
                , Action4  = Case When D.A4_Id Is NULL     Then @Unspecified Else A4.Event_Reason_Name End
                , Fault    = Case When D.Fault_Id Is NULL  Then @Unspecified Else F.TEFault_Name End
                , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
                , D.First_Comment_Id, D.Last_Comment_Id, D.Crew_Desc, D.Shift_Desc
            FROM #TopNDR D
            LEFT OUTER JOIN Prod_Units PU ON (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
            LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
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
 	  	  	 WHERE D.NPT IS NULL
        ORDER BY D.Start_Time DESC
      END
    Else    --@MasterUnit specified
      BEGIN
           SELECT D.Detail_Id
 	  	  	  	 , [Start_Time] = dbo.fnServer_CmnConvertFromDbTime(D.Start_Time,@InTimeZone)
 	  	  	  	 , [End_Time] = dbo.fnServer_CmnConvertFromDbTime(D.End_Time,@InTimeZone)
 	  	  	  	 , D.Duration, D.Uptime
                , Unit     = @Unit -- [When Master Unit is SourcePu we will report it as a location]
                , Location = Case When D.SourcePU Is NULL  Then @Unspecified Else PU.PU_Desc End
                , Reason1  = Case When D.R1_Id Is NULL     Then @Unspecified Else R1.Event_Reason_Name End
                , Reason2  = Case When D.R2_Id Is NULL     Then @Unspecified Else R2.Event_Reason_Name End
                , Reason3  = Case When D.R3_Id Is NULL     Then @Unspecified Else R3.Event_Reason_Name End
                , Reason4  = Case When D.R4_Id Is NULL     Then @Unspecified Else R4.Event_Reason_Name End
                , Action1  = Case When D.A1_Id Is NULL     Then @Unspecified Else A1.Event_Reason_Name End
                , Action2  = Case When D.A2_Id Is NULL     Then @Unspecified Else A2.Event_Reason_Name End
                , Action3  = Case When D.A3_Id Is NULL     Then @Unspecified Else A3.Event_Reason_Name End
                , Action4  = Case When D.A4_Id Is NULL     Then @Unspecified Else A4.Event_Reason_Name End
                , Fault    = Case When D.Fault_Id Is NULL  Then @Unspecified Else F.TEFault_Name End
                , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
                , D.First_Comment_Id, D.Last_Comment_Id, D.Crew_Desc, D.Shift_Desc
            FROM #TopNDR D
 	     LEFT OUTER JOIN Prod_Units PU ON (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
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
 	  	 WHERE D.NPT IS NULL 	 
        ORDER BY D.Start_Time DESC
      END
    --EndIf @MasterUnit
  --EndIf ToOrder...
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #TopNDR
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
