﻿CREATE PROCEDURE dbo.[spXLA_WasteSUMM_NoProduct_NPT_Bak_177]
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
 	 , @ReasonLevel  	 Int
 	 , @Crew_Desc    Varchar(10)
    , @Shift_Desc   Varchar(10)
 	 , @Username Varchar(50) = Null
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
DECLARE @TotalWaste  	  Real
DECLARE @TotalOperating  Real
DECLARE @MasterUnit  	  Int
DECLARE @Unspecified varchar(50)
 	 --Define Reason Levels
DECLARE @LevelLocation 	  Int --Slave Units
DECLARE @LevelReason1 	  Int
DECLARE @LevelReason2 	  Int
DECLARE @LevelReason3 	  Int
DECLARE @LevelReason4 	  Int
DECLARE @LevelEventType 	  Int
DECLARE @LevelEventMeas 	  Int
DECLARE @LevelAction1 	  Int
DECLARE @LevelAction2 	  Int
DECLARE @LevelAction3 	  Int
DECLARE @LevelAction4 	  Int
DECLARE @NPval         	  Int
DECLARE @NOF             Int
DECLARE @NPTCOUNT        Int
 	 --Define Levels....
SELECT @LevelLocation = 0
SELECT @LevelReason1  = 1
SELECT @LevelReason2  = 2
SELECT @LevelReason3  = 3
SELECT @LevelReason4  = 4
SELECT @LevelAction1  = 5
SELECT @LevelAction2  = 6
SELECT @LevelAction3  = 7
SELECT @LevelAction4  = 8
SELECT @LevelEventType    = 9
SELECT @LevelEventMeas   = 10
SELECT @NPTCOUNT       = 0
SELECT @NOF            = 0
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else SELECT @MasterUnit = @PU_Id 
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--SELECT @Unspecified = dbo.fnDBTranslate(@LangId, 38333, 'Unspecified')
CREATE TABLE #MyReport (
      ReasonName  	  	 Varchar(100)
    , NumberOfOccurances  	 Int          NULL
    , TotalReasonUnits  	  	 Real         NULL
    , AvgReasonUnits  	  	 Real         NULL
    , TotalWasteUnits  	  	 Real         NULL
    , TotalOperatingUnits  	 Real         NULL
    )
-- Get All WED Records In Field I Care About
CREATE TABLE #TopNDR (
     Start_Time DateTime 
 	 ,TimeStamp  	 DateTime
    , Amount 	  	 Real         NULL
    , Reason_Name  	 Varchar(100) NULL
    , SourcePU  	  	 Int          NULL
    , R1_Id  	  	 Int          NULL
    , R2_Id  	  	 Int          NULL
    , R3_Id  	  	 Int          NULL
    , R4_Id  	  	 Int          NULL
    , A1_Id             INt          NULL
    , A2_Id             INt          NULL
    , A3_Id             INt          NULL
    , A4_Id             INt          NULL
    , Type_Id  	  	 Int          NULL
    , Meas_Id  	  	 Int          NULL
    , Total real NULL
 	 , Diff real NULL
    )
-----------------------------------------------------
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     GOTO NOCREW_NOSHIFT_INSERT
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL GOTO HASCREW_NOSHIFT_INSERT
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL GOTO NOCREW_HASSHIFT_INSERT
Else                                                   GOTO HASCREW_HASSHIFT_INSERT
--EndIf:Crew,Shift
NOCREW_NOSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT EV.Actual_Start_Time, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id
        FROM Events_With_StartTime EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
       WHERE EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id  
        FROM Waste_Event_Details D 
       WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT EV.Actual_Start_Time, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id
        FROM Events_With_StartTime EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
       WHERE EV.PU_Id = @MasterUnit AND EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
       Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id  
        FROM Waste_Event_Details D 
       WHERE D.PU_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO FINISHING_NO_PRODUCT_WASTE
HASCREW_NOSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT EV.Actual_Start_Time, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id
        FROM Events_With_StartTime EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id  
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT EV.Actual_Start_Time, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id
        FROM Events_With_StartTime EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.PU_Id = @MasterUnit AND EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
       	 Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id  
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.PU_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
END
  --EndIf:@MasterUnit
  GOTO FINISHING_NO_PRODUCT_WASTE
NOCREW_HASSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT EV.Actual_Start_Time, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id
        FROM Events_With_StartTime EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id  
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT EV.Actual_Start_Time, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id
        FROM Events_With_StartTime EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.PU_Id = @MasterUnit AND EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
       Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id  
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.PU_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO FINISHING_NO_PRODUCT_WASTE
HASCREW_HASSHIFT_INSERT:
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT EV.Actual_Start_Time, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id
        FROM Events_With_StartTime EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id  
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
      -- Get All The Event Based Waste
      INSERT INTO #TopNDR (Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT EV.Actual_Start_Time, EV.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id
        FROM Events_With_StartTime EV 
        JOIN Waste_Event_Details D ON D.Pu_Id = EV.Pu_Id AND D.Event_Id = EV.Event_Id
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE EV.PU_Id = @MasterUnit AND EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
       Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time Based Waste
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
      SELECT D.TimeStamp, D.Amount, D.Source_PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, WET_Id, WEMT_Id  
        FROM Waste_Event_Details D 
        JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
       WHERE D.PU_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO FINISHING_NO_PRODUCT_WASTE
FINISHING_NO_PRODUCT_WASTE:
------------------------------------------------
-- 	 SELECT * FROM #TOPNDR -- Arju
-----NPT---------------------------------------------
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
                                           AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@Pu_id)
      WHERE PU_Id = @Pu_id
                  AND np.Start_Time < @End_time
                  AND np.End_Time > @Start_Time
--------------------------------------------------------------------------------------------------------
Update #TOPNDR set diff = DateDiff(ss,StarT_Time,TimeStamp)/60.0
---SC1---------------------------------------------------------------------------------------
--------   Start_time-------------------------------------Timestamp
--------                   n.St-----------n.End
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,n.StarTTime,n.EndTime)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp > n.Endtime And n.starttime < T.Timestamp )
Update #TOPNDR set total = (total - isnull(n.NPDuration,0))
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp > n.Endtime)
-------SC2---------------------------------------------------------------------------------------
---                               Start_time-------------------------------------Timestamp
--------                   n.St-------------------------n.End
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,T.Start_Time,n.EndTime)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
Update #TOPNDR set total = (total - isnull(n.NPDuration,0))
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
-- 	 
--------------------------------------------------------------------------------------------------
--SC3
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,T.Start_Time,n.EndTime)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
Update #TOPNDR set total = (total - isnull(n.NPDuration,0))
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
----SC4------------------------------------------------------------------------------------------
---           Start_time-------------------------------------Timestamp
--------                                 n.St----------------------------------------------n.End
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,n.StartTime,T.TimeStamp)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp < n.Endtime and n.Starttime < T.TimeStamp)
--
Update #TOPNDR set total = (total - isnull(n.NPDuration,0))
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp < n.Endtime and T.Start_Time < n.endtime and n.Starttime < T.TimeStamp)
--SELECT Amount
--FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp < n.Endtime and T.Start_Time < n.endtime and n.Starttime < T.TimeStamp)
----SC5------------------------------------------------------------------------------------------
---           Start_time-------------------------------------Timestamp
--------                                 n.St----------------n.End
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,n.StartTime,T.TimeStamp)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp = n.Endtime and n.Starttime < T.TimeStamp)
--
Update #TOPNDR set total = (total - isnull(n.NPDuration,0))
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp = n.Endtime and T.Start_Time < n.endtime and n.Starttime < T.TimeStamp)
--------------------------------------------------------------------------------------------------
---SC6--
--------             Start_time-----------Timestamp
--------                   n.St-----------n.End
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,n.StarTTime,n.EndTime)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp = n.Endtime) 
Update #TOPNDR set total = (total - isnull(n.NPDuration,0))
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp = n.Endtime)
SELECT @NPTCOUNT = @NPTCOUNT + 1 
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp = n.Endtime)
---------------------------------------------------------------------------------------------------
---SC7--
-------- 	  	  	  	  	 Start_time-----------Timestamp
--------        n.St------------------------------------------------n.End
UPDATE @Periods_NPT SET NPDuration = 0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp <= n.Endtime) 
Update #TOPNDR set total = 0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp <= n.Endtime)
SELECT @NPTCOUNT = @NPTCOUNT + 1 
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp <= n.Endtime)
---------------------------------------------------------------------------------------------------
--
--
--Delete from @Periods_NPT where NPDuration is NULL
Update #TOPNDR set Amount = (total * Amount)/diff
Update #TOPNDR set Amount = 0 where Amount Is null
--
--SELECT * FROM @Periods_NPT
--SELECT * FROM #TOPNDR
-----------------------------------------------------
 	  	 
  -- Calculate Total Waste
  SELECT @TotalWaste = (SELECT Sum(Amount) FROM #TopNDR) 
  --Go And Get Total Production For Time Period
  SELECT @TotalOperating = 0
  SELECT @TotalOperating = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0 ) - @TotalOperating
  SELECT @NOF = Count(Amount)- @NPTCOUNT from #TOPNDR
  --Print @NOF
  --DELETE For Additional SELECTion Criteria
  If @SelectSource Is NOT NULL DELETE FROM #TopNDR WHERE SourcePU Is NULL OR SourcePU <> @SelectSource
  If @SelectR1     Is NOT NULL DELETE FROM #TopNDR WHERE R1_Id Is NULL OR R1_Id <> @SelectR1  
  If @SelectR2     Is NOT NULL DELETE FROM #TopNDR WHERE R2_Id Is NULL OR R2_Id <> @SelectR2
  If @SelectR3     Is NOT NULL DELETE FROM #TopNDR WHERE R3_Id Is NULL OR R3_Id <> @SelectR3
  If @SelectR4     Is NOT NULL DELETE FROM #TopNDR WHERE R4_Id Is NULL OR R4_Id <> @SelectR4
  If @SelectA1     Is NOT NULL DELETE FROM #TopNDR WHERE A1_Id Is NULL OR A1_Id <> @SelectA1
  If @SelectA2     Is NOT NULL DELETE FROM #TopNDR WHERE A2_Id Is NULL OR A2_Id <> @SelectA2
  If @SelectA3     Is NOT NULL DELETE FROM #TopNDR WHERE A3_Id Is NULL OR A3_Id <> @SelectA3
  If @SelectA4     Is NOT NULL DELETE FROM #TopNDR WHERE A4_Id Is NULL OR A4_Id <> @SelectA4
  UPDATE #TopNDR 
    SET Reason_Name = 
        Case @ReasonLevel
           When @LevelLocation  Then PU.PU_Desc
           When @LevelReason1   Then R1.Event_Reason_Name
           When @LevelReason2   Then R2.Event_Reason_Name
           When @LevelReason3   Then R3.Event_Reason_Name
           When @LevelReason4   Then R4.Event_Reason_Name
           When @LevelAction1   Then A1.Event_Reason_Name
           When @LevelAction2   Then A2.Event_Reason_Name
           When @LevelAction3   Then A3.Event_Reason_Name
           When @LevelAction4   Then A4.Event_Reason_Name
           When @LevelEventType Then T.WET_Name
           When @LevelEventMeas Then M.WEMT_Name
        End
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
--  UPDATE #TopNDR SET Reason_Name = @Unspecified  Where Reason_Name Is NULL
  -- Populate Temp Table With Reason ORdered By Top 20
  INSERT INTO #MyReport (ReasonName
                       , NumberOfOccurances
                       , TotalReasonUnits
                       , AvgReasonUnits
                       , TotalWasteUnits
                       , TotalOperatingUnits)
    SELECT Reason_Name, @NOF, Total_Amount = SUM(Amount),  (SUM(Amount) / @NOF), @TotalWaste, @TotalOperating
      FROM #TopNDR
  GROUP BY Reason_Name
  ORDER BY Total_Amount DESC
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  SELECT * FROM #MyReport
  DROP TABLE #TopNDR
  DROP TABLE #MyReport
 -- DROP TABLE @Periods_NPT
--
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId