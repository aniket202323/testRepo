-- ECR #25704(mt/6-17-2003) Waste_n_Timed_Comments Table is no longer the storage for comments. Comments Table is the 
-- only source for all comments in Proficy database. 
-- ECR #25732 (mt/7-24-2003): add Waste Time Stamp.
CREATE PROCEDURE dbo.[spXLA_WasteDT_NoProduct_NPT_Bak_177]
 	   @Start_Time  	 DateTime
 	 , @End_Time  	 DateTime
 	 , @PU_Id  	 Int
 	 , @SelectSource 	 Int
 	 , @SelectR1  	 Int
 	 , @SelectR2  	 Int
 	 , @SelectR3  	 Int
 	 , @SelectR4  	 Int
 	 , @SelectA1 	 Int
 	 , @SelectA2 	 Int
 	 , @SelectA3 	 Int
 	 , @SelectA4 	 Int
 	 , @Crew_Desc 	 Varchar(10)
 	 , @Shift_Desc 	 Varchar(10)
 	 , @TimeSort  	 TinyInt = NULL
 	 , @Username Varchar(50) = Null
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
DECLARE @MasterUnit      Int
DECLARE @Unspecified varchar(50)
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else SELECT @MasterUnit = @PU_Id
If @TimeSort Is NULL SELECT @TimeSort = 1 	 --Set Default Value
-- Get All WED Records In Field I Care About
CREATE TABLE #TopNDR (
      Detail_Id  	 Int
 	 , Start_Time DateTime 	 
    , TimeStamp 	  	 DateTime     NULL --When Waste is timed-based
    , WasteTimeStamp    DateTime          --ECR #25732 (mt/7-24-2003)
    , Amount  	  	 real         NULL
    , Reason_Name  	 Varchar(100) NULL
    , SourcePU  	  	 Int          NULL
    , Cause_Comment_Id  Int          NULL  --ECR #25704(mt/6-17-2003)
    , R1_Id  	  	 Int          NULL
    , R2_Id  	  	 Int          NULL
    , R3_Id  	  	 Int          NULL
    , R4_Id  	  	 Int          NULL
    , A1_Id             Int          NULL
    , A2_Id             Int          NULL
    , A3_Id             Int          NULL
    , A4_Id             Int          NULL
    , Type_Id  	  	 Int          NULL
    , Meas_Id  	  	 Int          NULL
    , Crew_Desc         Varchar(10)  NULL
    , Shift_Desc        Varchar(10)  NULL
    , First_Comment_Id  	 Int          NULL
    , Last_Comment_Id  	 Int          NULL
    , EventBased  	 TinyInt      NULL
    , EventNumber  	 Varchar(50)  NULL
 	 , NPT tinyint 	 NULL      
)
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     GOTO NOCREW_NOSHIFT_INSERT
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL GOTO HASCREW_NOSHIFT_INSERT
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL GOTO NOCREW_HASSHIFT_INSERT
Else                                                   GOTO HASCREW_HASSHIFT_INSERT
--EndIf:Crew,Shift
NOCREW_NOSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Detail_Id, Start_Time, TimeStamp, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, EventNumber)
      SELECT D.WED_Id, EV.Start_Time,EV.TimeStamp, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 1, EV.Event_Num 
        FROM Events EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
       WHERE EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (Detail_Id, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased)
      SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 0  
        FROM Waste_Event_Details D 
       WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
    END
  Else
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Detail_Id, Start_Time,TimeStamp, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, EventNumber)
      SELECT D.WED_Id, EV.Start_Time, EV.TimeStamp, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 1, EV.Event_Num 
        FROM Events EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
       WHERE EV.PU_Id = @MasterUnit AND EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (Detail_Id, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased)
      SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 0  
        FROM Waste_Event_Details D 
       WHERE D.PU_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
    END
  --EndIf:@MasterUnit
  GOTO FINISHING_NOPRODUCT_WASTE
HASCREW_NOSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Detail_Id, Start_Time,TimeStamp, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, EventNumber, Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, EV.Start_Time, EV.TimeStamp, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 1, EV.Event_Num , C.Crew_Desc, C.Shift_Desc
        FROM Events EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (Detail_Id, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased , Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 0, C.Crew_Desc, C.Shift_Desc  
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
    END
  Else
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Detail_Id, Start_Time, TimeStamp, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, EventNumber , Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, EV.Start_Time, EV.TimeStamp, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 1, EV.Event_Num, C.Crew_Desc, C.Shift_Desc
        FROM Events EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.PU_Id = @MasterUnit AND EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (Detail_Id, TimeStamp, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased , Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, D.TimeStamp, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 0, C.Crew_Desc, C.Shift_Desc  
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.PU_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
    END
  --EndIf:@MasterUnit
  GOTO FINISHING_NOPRODUCT_WASTE
NOCREW_HASSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Detail_Id, Start_Time,TimeStamp, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, EventNumber, Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, EV.Start_Time,EV.TimeStamp, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 1, EV.Event_Num, C.Crew_Desc, C.Shift_Desc 
        FROM Events EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
     INSERT INTO #TopNDR (Detail_Id, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, Crew_Desc, Shift_Desc)
     SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 0, C.Crew_Desc, C.Shift_Desc
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
    END
  Else
    BEGIN
      -- Get All The Event Based Waste
     INSERT INTO #TopNDR (Detail_Id, Start_Time,TimeStamp, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, EventNumber, Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, EV.Start_Time, EV.TimeStamp, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 1, EV.Event_Num, C.Crew_Desc, C.Shift_Desc
        FROM Events EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.PU_Id = @MasterUnit AND EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (Detail_Id, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 0, C.Crew_Desc, C.Shift_Desc
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.PU_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
    END
  --EndIf:@MasterUnit
  GOTO FINISHING_NOPRODUCT_WASTE
HASCREW_HASSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Detail_Id, Start_Time,TimeStamp, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, EventNumber, Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, EV.Start_Time, EV.TimeStamp, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 1, EV.Event_Num, C.Crew_Desc, C.Shift_Desc
        FROM Events EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (Detail_Id, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 0, C.Crew_Desc, C.Shift_Desc
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
    END
  Else
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Detail_Id, Start_Time,TimeStamp, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, EventNumber, Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, EV.Start_Time, EV.TimeStamp, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 1, EV.Event_Num, C.Crew_Desc, C.Shift_Desc
        FROM Events EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.PU_Id = @MasterUnit AND EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (Detail_Id, WasteTimeStamp, Amount, SourcePU, Cause_Comment_Id, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id, EventBased, Crew_Desc, Shift_Desc)
      SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_PU_Id, D.Cause_Comment_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id, 0, C.Crew_Desc, C.Shift_Desc
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.PU_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
     END
  --EndIf:@MasterUnit
  GOTO FINISHING_NOPRODUCT_WASTE
FINISHING_NOPRODUCT_WASTE:
  --DELETE For Additional Selection Criteria
  If @SelectSource Is NOT NULL DELETE FROM #TopNDR WHERE SourcePU Is NULL Or SourcePU <> @SelectSource
  If @SelectR1     Is NOT NULL DELETE FROM #TopNDR WHERE R1_Id Is NULL Or R1_Id <> @SelectR1  
  If @SelectR2     Is NOT NULL DELETE FROM #TopNDR WHERE R2_Id Is NULL Or R2_Id <> @SelectR2
  If @SelectR3     Is NOT NULL DELETE FROM #TopNDR WHERE R3_Id Is NULL Or R3_Id <> @SelectR3
  If @SelectR4     Is NOT NULL DELETE FROM #TopNDR WHERE R4_Id Is NULL Or R4_Id <> @SelectR4
  If @SelectA1     Is NOT NULL DELETE FROM #TopNDR WHERE A1_Id Is NULL OR A1_Id <> @SelectA1
  If @SelectA2     Is NOT NULL DELETE FROM #TopNDR WHERE A2_Id Is NULL OR A2_Id <> @SelectA2
  If @SelectA3     Is NOT NULL DELETE FROM #TopNDR WHERE A3_Id Is NULL OR A3_Id <> @SelectA3
  If @SelectA4     Is NOT NULL DELETE FROM #TopNDR WHERE A4_Id Is NULL OR A4_Id <> @SelectA4
  --ECR #25704(mt/6-17-2003) Get comments from Comments Table instead of Waste_n_Timed_Comments (outdated in 4.0)
  CREATE TABLE #Comments (Detail_Id Int, FirstComment Int NULL, LastComment Int NULL)
  INSERT INTO #Comments
    SELECT D.Detail_Id, FirstComment = D.Cause_Comment_Id, LastComment = C.Comment_Id
      FROM #TopNDR D
      LEFT JOIN Comments C ON C.TopOfChain_Id = D.Cause_Comment_Id AND C.NextComment_Id Is NULL AND C.Comment_Id <> D.Cause_Comment_Id
  UPDATE #TopNDR 
      SET First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
     FROM #TopNDR D
     JOIN #Comments C ON C.Detail_Id = D.Detail_Id
  /* Old Code
  Insert Into #Comments
    SELECT D.Detail_Id,  min(C.WTC_ID), max(C.WTC_ID)
      FROM #TopNDR D, Waste_n_Timed_Comments C
     WHERE C.WTC_Source_Id = D.Detail_Id AND C.WTC_Type = 3
  Group By D.Detail_Id   
  Update #TopNDR 
    Set First_Comment_Id = FirstComment
      , Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
                           FROM #TopNDR D, #Comments C WHERE D.Detail_Id = C.Detail_Id 
  */
-------------------------------------------------------------------
-----------------------------------------------------------------------------------
/*
 	  	 Non Productive Time
 	  	 
*/
------------------------------------------------------------------------------------
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
FROM #TopNDR  JOIN @Periods_NPT n ON (Start_Time > n.StartTime AND TimeStamp > n.EndTime AND Start_Time < n.EndTime)
-- Case 2 :  Downtime    St---------------------End
-- 	  	  	  NPT 	  	  	  	  	 St--------------End
UPDATE #TopNDR SET TimeStamp = n.Starttime,
 	  	  	  	    NPT = 1
FROM 	 #TopNDR 	  	    
JOIN @Periods_NPT n ON (Start_Time < n.StartTime AND TimeStamp < n.Endtime AND TimeStamp > n.StartTime)
 	  	 
-- Case 3 :  Downtime   St-----------------------End
-- 	  	  	  NPT   St-------------------------------End
UPDATE #TopNDR SET Start_Time = TimeStamp,
 	  	  	  	  	 NPT = 1
FROM 	 #TopNDR  	  	    
JOIN @Periods_NPT n ON( (Start_Time BETWEEN n.StartTime AND n.EndTime) AND (TimeStamp BETWEEN n.StartTime AND n.EndTime))
--Update #TopNDR Set Duration =DateDiff(ss,Start_Time,TimeStamp)/60.0
-- Case 4 :  Downtime   St-----------------------End
-- 	  	  	  NPT 	  	    St-----------------End
UPDATE #TopNDR  SET NPT = 1
FROM #TopNDR  JOIN @Periods_NPT n ON( (n.StartTime BETWEEN Start_Time AND TimeStamp) AND (n.Endtime BETWEEN Start_Time AND TimeStamp))
-- --------------------------------------------------
  DROP TABLE #Comments
  --Return Data And Join Results
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @TimeSort = 1 
    BEGIN
         SELECT [TimeStamp] = dbo.fnServer_CmnConvertFromDbTime(TimeStamp,@InTimeZone)
              , [WasteTimeStamp] = dbo.fnServer_CmnConvertFromDbTime(WasteTimeStamp,@InTimeZone)
              , Amount
              , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
              , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
              , Event_Number = Case 
                                 When #TopNDR.EventBased = 0 Then dbo.fnDBTranslate(N'0', 31333, 'Not Applicable')
                                 When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                                 Else #TopNDR.EventNumber 
                               End
              , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
              , Reason1  = Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
              , Reason2  = Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
              , Reason3  = Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
              , Reason4  = Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
              , Action1  = Case When #TopNDR.A1_Id Is NULL Then @Unspecified  Else A1.Event_Reason_Name End
              , Action2  = Case When #TopNDR.A2_Id Is NULL Then @Unspecified  Else A2.Event_Reason_Name End
              , Action3  = Case When #TopNDR.A3_Id Is NULL Then @Unspecified  Else A3.Event_Reason_Name End
              , Action4  = Case When #TopNDR.A4_Id Is NULL Then @Unspecified  Else A4.Event_Reason_Name End
              , Crew_Desc
              , Shift_Desc
              , First_Comment_Id
              , Last_Comment_Id  
           FROM #TopNDR
      LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.PU_Id)
      LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A1 ON (#TopNDR.A1_Id = A1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A2 ON (#TopNDR.A2_Id = A2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A3 ON (#TopNDR.A3_Id = A3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A4 ON (#TopNDR.A4_Id = A4.Event_Reason_Id)
      LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
      LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
 	   WHERE NPT IS NULL 	 
      ORDER BY TimeStamp ASC, Amount ASC
    END
  Else
    BEGIN
        SELECT [TimeStamp] = dbo.fnServer_CmnConvertFromDbTime(TimeStamp,@InTimeZone)
             , [WasteTimeStamp] = dbo.fnServer_CmnConvertFromDbTime(WasteTimeStamp,@InTimeZone)
             , Amount
             , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
             , Type        = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
             , Event_Number = Case 
                                When #TopNDR.EventBased = 0 Then dbo.fnDBTranslate(N'0', 31333, 'Not Applicable')
                                When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                                Else #TopNDR.EventNumber 
                              End
             , Location    = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
             , Reason1     = Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
             , Reason2     = Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
             , Reason3     = Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
             , Reason4     = Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
             , Action1     = Case When #TopNDR.A1_Id Is NULL Then @Unspecified  Else A1.Event_Reason_Name End
             , Action2     = Case When #TopNDR.A2_Id Is NULL Then @Unspecified  Else A2.Event_Reason_Name End
             , Action3     = Case When #TopNDR.A3_Id Is NULL Then @Unspecified  Else A3.Event_Reason_Name End
             , Action4     = Case When #TopNDR.A4_Id Is NULL Then @Unspecified  Else A4.Event_Reason_Name End
             , Crew_Desc
             , Shift_Desc
             , First_Comment_Id
             , Last_Comment_Id
          FROM #TopNDR
      LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.PU_Id)
      LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A1 ON (#TopNDR.A1_Id = A1.Event_Reason_Id) 
      LEFT OUTER JOIN Event_Reasons A2 ON (#TopNDR.A2_Id = A2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A3 ON (#TopNDR.A3_Id = A3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons A4 ON (#TopNDR.A4_Id = A4.Event_Reason_Id)
      LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
      LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
 	   WHERE NPT IS NULL 	 
      ORDER BY TimeStamp DESC, Amount DESC
    END
  --EndIf:
--SELECT * FROM #TOPNDR
  DROP TABLE #TopNDR
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
