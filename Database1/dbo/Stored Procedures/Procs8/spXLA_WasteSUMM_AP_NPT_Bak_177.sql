-- DESCRIPTION: spXLA_WasteSUMM_AP_NPT is based on spXLA_WasteSummary_AP. Changes include additional filters 
-- Action1...Action4(MT/8-15-2002) and Crew,Shift Filters(9-10-2002)
CREATE PROCEDURE dbo.[spXLA_WasteSUMM_AP_NPT_Bak_177]
 	   @Start_Time  	  	 DateTime
 	 , @End_Time  	  	 DateTime
 	 , @Pu_Id  	  	 Int
 	 , @SelectSource 	  	 Int
 	 , @SelectR1  	  	 Int
 	 , @SelectR2  	  	 Int
 	 , @SelectR3  	  	 Int
 	 , @SelectR4  	  	 Int
 	 , @SelectA1 	  	 Int
 	 , @SelectA2 	  	 Int
 	 , @SelectA3 	  	 Int
 	 , @SelectA4 	  	 Int
 	 , @ReasonLevel  	  	 Int
 	 , @Crew_Desc            Varchar(10)
 	 , @Shift_Desc           Varchar(10)
 	 , @Prod_Id  	  	 Int
 	 , @Group_Id  	  	 Int
 	 , @Prop_Id  	  	 Int
 	 , @Char_Id  	  	 Int
 	 , @IsAppliedProdFilter 	 TinyInt 	 --1 = Yes, filter by applied product; 0 = No, filter by original product
 	 , @Username Varchar(50) = null
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Local query assistance
DECLARE @QueryType  	     TinyInt
DECLARE @SingleProduct 	     TinyInt 	 --1
DECLARE @Group 	  	     TinyInt --2
DECLARE @Characteristic 	     TinyInt 	 --3
DECLARE @GroupAndProperty   TinyInt --4
DECLARE @NoProductSpecified TinyInt --5
DECLARE @Unspecified varchar(50)
 	 --Waste-Related identifiers
DECLARE @TotalWaste         real
DECLARE @TotalOperating     real
DECLARE @MasterUnit         Int 
 	 --Needed For Reason Levels
DECLARE @LevelLocation 	     Int --Slave Units
DECLARE @LevelReason1 	     Int
DECLARE @LevelReason2 	     Int
DECLARE @LevelReason3 	     Int
DECLARE @LevelReason4 	     Int
DECLARE @LevelEventType 	     Int
DECLARE @LevelEventMeas 	     Int
DECLARE @LevelAction1 	     Int
DECLARE @LevelAction2 	     Int
DECLARE @LevelAction3 	     Int
DECLARE @LevelAction4 	     Int
DECLARE @LevelUnit 	     Int --Master Unit
DECLARE @NPval         	  Int
DECLARE @NOF             Int
DECLARE @NPTCOUNT        Int 	 
 	 
 	 --Needed for Crew,Shift
DECLARE @CrewShift         TinyInt
DECLARE @NoCrewNoShift     TinyInt
DECLARE @HasCrewNoShift    TinyInt
DECLARE @NoCrewHasShift    TinyInt
DECLARE @HasCrewHasShift   TinyInt
 	 --Define Crew,Shift types
SELECT @NoCrewNoShift   = 1
SELECT @HasCrewNoShift  = 2
SELECT @NoCrewHasShift  = 3
SELECT @HasCrewHasShift = 4
 	 --Define Reason levels
SELECT @LevelLocation  = 0
SELECT @LevelReason1   = 1
SELECT @LevelReason2   = 2
SELECT @LevelReason3   = 3
SELECT @LevelReason4   = 4
SELECT @LevelAction1   = 5
SELECT @LevelAction2   = 6
SELECT @LevelAction3   = 7
SELECT @LevelAction4   = 8
SELECT @LevelEventType = 9
SELECT @LevelEventMeas = 10
SELECT @NPTCOUNT       = 0
SELECT @NOF            = 0
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else SELECT @MasterUnit = @Pu_Id
CREATE TABLE #Prod_Starts (Pu_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Applied_Products_From_Events(Pu_Id Int, Event_Id Int, Start_Time DateTime, TimeStamp DateTime)
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--
--SELECT @Unspecified = dbo.fnDBTranslate(@LangId, 38333, 'Unspecified')
CREATE TABLE #MyReport (  
    ReasonName  	  	 varchar(100)
  , NumberOfOccurances  	 Int          NULL
  , TotalReasonUnits  	 real         NULL
  , AvgReasonUnits  	 real         NULL
  , TotalWasteUnits  	 real         NULL
  , TotalOperatingUnits real         NULL
)
CREATE TABLE #TopNDR (
    Start_Time DateTime
  , TimeStamp 	 DateTime
  , Amount      real         NULL
  , Reason_Name Varchar(100) NULL
  , SourcePU  	 Int          NULL
  , R1_Id  	 Int          NULL
  , R2_Id  	 Int          NULL
  , R3_Id  	 Int          NULL
  , R4_Id  	 Int          NULL
  , A1_Id       Int          NULL
  , A2_Id       Int          NULL
  , A3_Id       Int          NULL
  , A4_Id       Int          NULL
  , Type_Id  	 Int          NULL
  , Meas_Id  	 Int          NULL
  , Total real NULL
  , Diff real NULL 	 
)
--Figure Out Query Type Based on Product Info given
-- NOTE: We DO NOT handle all possible null combinations of product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
-- Proficy Add-In blocks out illegal combinations, and allows only these combination:
--     * Property AND Characteristic 
--     * Group Only
--     * Group, Propery, AND Characteristic
--     * Product Only
--     * No Product Information At All 
SELECT @SingleProduct 	  	 = 1
SELECT @Group 	  	  	 = 2
SELECT @Characteristic 	  	 = 3
SELECT @GroupAndProperty 	 = 4
SELECT @NoProductSpecified 	 = 5
If @Prod_Id Is NOT NULL 	  	  	  	  	 SELECT @QueryType = @SingleProduct   	 --1
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL 	 SELECT @QueryType = @Group   	  	 --2
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL 	 SELECT @QueryType = @Characteristic  	 --3
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL 	 SELECT @QueryType = @GroupAndProperty 	 --4
Else 	  	  	  	  	  	  	 SELECT @QueryType = @NoProductSpecified 	 --5
--EndIf
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     SELECT @CrewShift = @NoCrewNoShift
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL SELECT @CrewShift = @HasCrewNoShift
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL SELECT @CrewShift = @NoCrewHasShift
Else                                                   SELECT @CrewShift = @HasCrewHasShift
--EndIf:Crew,Shift
If @IsAppliedProdFilter = 1 GOTO DO_FILTER_BY_APPLIED_PRODUCT
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Get Relevant product information from Production_Starts Table
If @QueryType = @NoProductSpecified 	 --5
  BEGIN
    If @MasterUnit Is NULL
      INSERT INTO #Prod_Starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM production_starts ps
       WHERE (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
               OR (End_Time BETWEEN @Start_Time AND @End_Time) 
               OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
             )   --Start_time & End_time condition checked;mt/3-21-2001
    Else
      INSERT INTO #Prod_Starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM production_starts ps
       WHERE Pu_Id = @MasterUnit 
         AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
               OR (End_Time BETWEEN @Start_Time AND @End_Time) 
               OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
             )
    --EndIf:@MasterUnit
  END
Else If @QueryType = @SingleProduct 	 --1
  BEGIN
    If @MasterUnit Is NULL
      INSERT INTO #Prod_Starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM production_starts ps
       WHERE Prod_Id = @Prod_Id 
         AND (   (Start_Time BETWEEN @Start_Time AND @End_Time)
               OR (End_Time BETWEEN @Start_Time AND @End_Time) 
               OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
             )   --Start_time & End_time condition checked:MT/3-21-2001
    Else
      INSERT INTO #Prod_Starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM production_starts ps
       WHERE Pu_Id = @MasterUnit 
         AND Prod_Id = @Prod_Id 
         AND (   (Start_Time BETWEEN @Start_Time AND @End_Time)
               OR (End_Time BETWEEN @Start_Time AND @End_Time) 
               OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
             )   
    --EndIf:@MasterUnit
  END
Else 	  	  	  	  	 --Not a single product
  BEGIN
    If @QueryType = @Group 	  	  	 --2
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @Characteristic 	 --3
      BEGIN
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else 	  	  	  	  	 --Group & Property
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    --EndIf 
    If @MasterUnit Is NULL
      INSERT INTO #Prod_Starts
        SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
          FROM production_starts ps
          JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
         WHERE (   (Start_Time BETWEEN @Start_Time AND @End_Time) 
                OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
               )  --Start_time & End_time condition checked:mt/3-21-2001
    Else
      INSERT INTO #Prod_Starts
        SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
          FROM production_starts ps
          JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
         WHERE Pu_Id = @MasterUnit 
           AND (   (Start_Time BETWEEN @Start_Time AND @End_Time) 
                OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
               )  
    --EndIf:@MasterUnit 
  END
--End If @QueryType
-- Insert relevant Waste Information Into TopNDR Temp Table
If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_ORIGINAL_INSERT
Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_ORIGINAL_INSERT
Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_ORIGINAL_INSERT
Else                                 GOTO HASCREW_HASSHIFT_ORIGINAL_INSERT
--EndIf:Crew,Shift
NOCREW_NOSHIFT_ORIGINAL_INSERT:
  If @MasterUnit Is NULL
    BEGIN
       --Get All The Event Based Waste (Get TimeStamp from Events Table)
      INSERT INTO #TopNDR ( 	 Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT EV.Actual_Start_Time, ev.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM Events_With_StartTime ev 
          JOIN Waste_Event_Details D ON D.Pu_Id = ev.Pu_Id AND D.Event_Id = ev.Event_Id
          JOIN #Prod_Starts ps ON ps.Pu_Id = ev.Pu_Id AND ps.Start_Time <= ev.TimeStamp AND (ps.End_Time > ev.TimeStamp OR ps.End_Time Is NULL) 
         WHERE ev.TimeStamp > @Start_Time AND ev.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste (Get TimeStamp from Wast_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Prod_Starts ps ON ps.Pu_Id = D.Pu_Id AND ps.Start_Time <= D.TimeStamp AND (ps.End_Time > D.TimeStamp OR ps.End_Time Is NULL)
         WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
       --Get All The Event Based Waste (Get TimeStamp from Events Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT EV.Actual_Start_Time, ev.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM Events_With_StartTime ev 
          JOIN Waste_Event_Details D ON D.Pu_Id = ev.Pu_Id AND D.Event_Id = ev.Event_Id
          JOIN #Prod_Starts ps ON ps.Pu_Id = ev.Pu_Id AND ps.Start_Time <= ev.TimeStamp AND (ps.End_Time > ev.TimeStamp OR ps.End_Time Is NULL) 
         WHERE ev.Pu_Id = @MasterUnit AND ev.TimeStamp > @Start_Time AND ev.TimeStamp <= @End_Time
 	  	 Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0   
      -- Get All The Time Based Waste (Get TimeStamp from Wast_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Prod_Starts ps ON ps.Pu_Id = D.Pu_Id AND ps.Start_Time <= D.TimeStamp AND (ps.End_Time > D.TimeStamp OR ps.End_Time Is NULL)
         WHERE D.Pu_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO PROCESS_WASTE_SUMMARY
HASCREW_NOSHIFT_ORIGINAL_INSERT:
  If @MasterUnit Is NULL
    BEGIN
       --Get All The Event Based Waste (Get TimeStamp from Events Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT EV.Actual_Start_Time, ev.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM Events_With_StartTime ev  
          JOIN Waste_Event_Details D ON D.Pu_Id = ev.Pu_Id AND D.Event_Id = ev.Event_Id
          JOIN #Prod_Starts ps ON ps.Pu_Id = ev.Pu_Id AND ps.Start_Time <= ev.TimeStamp AND (ps.End_Time > ev.TimeStamp OR ps.End_Time Is NULL) 
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ev.TimeStamp > @Start_Time AND ev.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste (Get TimeStamp from Wast_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Prod_Starts ps ON ps.Pu_Id = D.Pu_Id AND ps.Start_Time <= D.TimeStamp AND (ps.End_Time > D.TimeStamp OR ps.End_Time Is NULL)
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
       --Get All The Event Based Waste (Get TimeStamp from Events Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT EV.Actual_Start_Time, ev.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM Events_With_StartTime ev  
          JOIN Waste_Event_Details D ON D.Pu_Id = ev.Pu_Id AND D.Event_Id = ev.Event_Id
          JOIN #Prod_Starts ps ON ps.Pu_Id = ev.Pu_Id AND ps.Start_Time <= ev.TimeStamp AND (ps.End_Time > ev.TimeStamp OR ps.End_Time Is NULL) 
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ev.Pu_Id = @MasterUnit AND ev.TimeStamp > @Start_Time AND ev.TimeStamp <= @End_Time   
         Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time Based Waste (Get TimeStamp from Wast_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Prod_Starts ps ON ps.Pu_Id = D.Pu_Id AND ps.Start_Time <= D.TimeStamp AND (ps.End_Time > D.TimeStamp OR ps.End_Time Is NULL)
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.Pu_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO PROCESS_WASTE_SUMMARY
NOCREW_HASSHIFT_ORIGINAL_INSERT:
  If @MasterUnit Is NULL
    BEGIN
       --Get All The Event Based Waste (Get TimeStamp from Events Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT EV.Actual_Start_Time, ev.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM Events_With_StartTime ev  
          JOIN Waste_Event_Details D ON D.Pu_Id = ev.Pu_Id AND D.Event_Id = ev.Event_Id
          JOIN #Prod_Starts ps ON ps.Pu_Id = ev.Pu_Id AND ps.Start_Time <= ev.TimeStamp AND (ps.End_Time > ev.TimeStamp OR ps.End_Time Is NULL) 
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ev.TimeStamp > @Start_Time AND ev.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste (Get TimeStamp from Wast_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Prod_Starts ps ON ps.Pu_Id = D.Pu_Id AND ps.Start_Time <= D.TimeStamp AND (ps.End_Time > D.TimeStamp OR ps.End_Time Is NULL)
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
       --Get All The Event Based Waste (Get TimeStamp from Events Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT EV.Actual_Start_Time, ev.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM Events_With_StartTime ev  
          JOIN Waste_Event_Details D ON D.Pu_Id = ev.Pu_Id AND D.Event_Id = ev.Event_Id
          JOIN #Prod_Starts ps ON ps.Pu_Id = ev.Pu_Id AND ps.Start_Time <= ev.TimeStamp AND (ps.End_Time > ev.TimeStamp OR ps.End_Time Is NULL) 
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ev.Pu_Id = @MasterUnit AND ev.TimeStamp > @Start_Time AND ev.TimeStamp <= @End_Time   
         Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time Based Waste (Get TimeStamp from Wast_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Prod_Starts ps ON ps.Pu_Id = D.Pu_Id AND ps.Start_Time <= D.TimeStamp AND (ps.End_Time > D.TimeStamp OR ps.End_Time Is NULL)
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.Pu_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO PROCESS_WASTE_SUMMARY
HASCREW_HASSHIFT_ORIGINAL_INSERT:
  If @MasterUnit Is NULL
    BEGIN
       --Get All The Event Based Waste (Get TimeStamp from Events Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT EV.Actual_Start_Time, ev.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM Events_With_StartTime ev  
          JOIN Waste_Event_Details D ON D.Pu_Id = ev.Pu_Id AND D.Event_Id = ev.Event_Id
          JOIN #Prod_Starts ps ON ps.Pu_Id = ev.Pu_Id AND ps.Start_Time <= ev.TimeStamp AND (ps.End_Time > ev.TimeStamp OR ps.End_Time Is NULL) 
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ev.TimeStamp > @Start_Time AND ev.TimeStamp <= @End_Time   
      -- Get All The Time Based Waste (Get TimeStamp from Wast_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Prod_Starts ps ON ps.Pu_Id = D.Pu_Id AND ps.Start_Time <= D.TimeStamp AND (ps.End_Time > D.TimeStamp OR ps.End_Time Is NULL)
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
       --Get All The Event Based Waste (Get TimeStamp from Events Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT EV.Actual_Start_Time, ev.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM Events_With_StartTime ev  
          JOIN Waste_Event_Details D ON D.Pu_Id = ev.Pu_Id AND D.Event_Id = ev.Event_Id
          JOIN #Prod_Starts ps ON ps.Pu_Id = ev.Pu_Id AND ps.Start_Time <= ev.TimeStamp AND (ps.End_Time > ev.TimeStamp OR ps.End_Time Is NULL) 
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ev.Pu_Id = @MasterUnit AND ev.TimeStamp > @Start_Time AND ev.TimeStamp <= @End_Time   
         Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time Based Waste (Get TimeStamp from Wast_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Prod_Starts ps ON ps.Pu_Id = D.Pu_Id AND ps.Start_Time <= D.TimeStamp AND (ps.End_Time > D.TimeStamp OR ps.End_Time Is NULL)
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.Pu_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
GOTO PROCESS_WASTE_SUMMARY
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
DO_FILTER_BY_APPLIED_PRODUCT:
  --SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
  --Get all relevant products and info from production_Start table
  INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
     WHERE Pu_Id = @MasterUnit 
       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
             OR (End_Time BETWEEN @Start_Time AND @End_Time) 
             OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
           )   --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  --Grab all of the "Specified" product(s), put them into Temp Table #Products
  BEGIN      
    If @QueryType = @Group
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
      END
    Else If @QueryType = @Characteristic
      BEGIN
         INSERT INTO #Products
         SELECT DISTINCT Prod_Id FROM Pu_Characteristics WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
      END
    Else If @QueryType = @GroupAndProperty
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
 	  INSERT INTO #Products
         SELECT distinct Prod_Id FROM pu_characteristics WHERE Prop_Id = @Prop_Id AND char_id = @Char_Id
      END
    Else -- must be @OneProductFilter
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id = @Prod_Id
      END
    --EndIf
  END
  -- Get Rows From Events Table for "Products" that fit applied products criteria ... 
  --  When matched product has Applied_Product = NULL, we take that the original product is applied product.
  --  When matched product has Applied_Product <> NULL, include that product as applied product
  -- (Note: JOIN condition for Production_Starts consistent with AutoLog's )
  -- 
  INSERT INTO #Applied_Products_From_Events
      SELECT e.Pu_Id, e.Event_Id, e.Actual_Start_Time, e.TimeStamp
        FROM Events_With_StartTime e
        JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @MasterUnit AND e.Applied_Product Is NOT NULL
    UNION
      SELECT e.Pu_Id, e.Event_Id, e.Actual_Start_Time, e.TimeStamp
        FROM Events_With_StartTime e
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @MasterUnit AND e.Applied_Product Is NULL
        JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
  If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_APPLIED_INSERT
  Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_APPLIED_INSERT
  Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_APPLIED_INSERT
  Else                                 GOTO HASCREW_HASSHIFT_APPLIED_INSERT
  --EndIf:Crew,Shift
NOCREW_NOSHIFT_APPLIED_INSERT:
  -- Insert Waste Data Into Temp Table
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event-Based Waste (Get TimeSTamp from Events Table VIA Temp Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT ap.Start_Time, ap.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM #Applied_Products_From_Events ap 
          JOIN Waste_Event_Details D ON D.Pu_Id = ap.Pu_Id AND D.Event_Id = ap.Event_Id
         WHERE ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time   
      -- Get All The Time-Based Waste (Get TimeStamp from Waste_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Applied_Products_From_Events ap ON ap.Pu_Id = D.Pu_Id AND ap.TimeStamp = D.TimeStamp
         WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
      -- Get All The Event-Based Waste (Get TimeSTamp from Events Table VIA Temp Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT ap.Start_Time, ap.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM #Applied_Products_From_Events ap 
          JOIN Waste_Event_Details D ON D.Pu_Id = ap.Pu_Id AND D.Event_Id = ap.Event_Id
         WHERE ap.Pu_Id = @MasterUnit AND ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time   
         Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time-Based Waste (Get TimeStamp from Waste_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Applied_Products_From_Events ap ON ap.Pu_Id = D.Pu_Id AND ap.TimeStamp = D.TimeStamp
         WHERE D.Pu_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO PROCESS_WASTE_SUMMARY
HASCREW_NOSHIFT_APPLIED_INSERT:
  -- Insert Waste Data Into Temp Table
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event-Based Waste (Get TimeSTamp from Events Table VIA Temp Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT ap.Start_Time, ap.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM #Applied_Products_From_Events ap 
          JOIN Waste_Event_Details D ON D.Pu_Id = ap.Pu_Id AND D.Event_Id = ap.Event_Id
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time   
      -- Get All The Time-Based Waste (Get TimeStamp from Waste_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Applied_Products_From_Events ap ON ap.Pu_Id = D.Pu_Id AND ap.TimeStamp = D.TimeStamp
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
      -- Get All The Event-Based Waste (Get TimeSTamp from Events Table VIA Temp Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT ap.Start_Time, ap.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM #Applied_Products_From_Events ap 
          JOIN Waste_Event_Details D ON D.Pu_Id = ap.Pu_Id AND D.Event_Id = ap.Event_Id
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ap.Pu_Id = @MasterUnit AND ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time 
 	  	  Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0    	   
      -- Get All The Time-Based Waste (Get TimeStamp from Waste_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Applied_Products_From_Events ap ON ap.Pu_Id = D.Pu_Id AND ap.TimeStamp = D.TimeStamp
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.Pu_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO PROCESS_WASTE_SUMMARY
NOCREW_HASSHIFT_APPLIED_INSERT:
  -- Insert Waste Data Into Temp Table
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event-Based Waste (Get TimeSTamp from Events Table VIA Temp Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT ap.Start_Time, ap.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM #Applied_Products_From_Events ap 
          JOIN Waste_Event_Details D ON D.Pu_Id = ap.Pu_Id AND D.Event_Id = ap.Event_Id
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time   
      -- Get All The Time-Based Waste (Get TimeStamp from Waste_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Applied_Products_From_Events ap ON ap.Pu_Id = D.Pu_Id AND ap.TimeStamp = D.TimeStamp
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
      -- Get All The Event-Based Waste (Get TimeSTamp from Events Table VIA Temp Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT ap.Start_Time, ap.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM #Applied_Products_From_Events ap 
          JOIN Waste_Event_Details D ON D.Pu_Id = ap.Pu_Id AND D.Event_Id = ap.Event_Id
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ap.Pu_Id = @MasterUnit AND ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time   
         Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time-Based Waste (Get TimeStamp from Waste_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Applied_Products_From_Events ap ON ap.Pu_Id = D.Pu_Id AND ap.TimeStamp = D.TimeStamp
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.Pu_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO PROCESS_WASTE_SUMMARY
HASCREW_HASSHIFT_APPLIED_INSERT:
  -- Insert Waste Data Into Temp Table
  If @MasterUnit Is NULL
    BEGIN
      -- Get All The Event-Based Waste (Get TimeSTamp from Events Table VIA Temp Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT ap.Start_Time, ap.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM #Applied_Products_From_Events ap 
          JOIN Waste_Event_Details D ON D.Pu_Id = ap.Pu_Id AND D.Event_Id = ap.Event_Id
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time   
      -- Get All The Time-Based Waste (Get TimeStamp from Waste_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Applied_Products_From_Events ap ON ap.Pu_Id = D.Pu_Id AND ap.TimeStamp = D.TimeStamp
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  Else
    BEGIN
      -- Get All The Event-Based Waste (Get TimeSTamp from Events Table VIA Temp Table)
      INSERT INTO #TopNDR (Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT ap.Start_Time, ap.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id
          FROM #Applied_Products_From_Events ap 
          JOIN Waste_Event_Details D ON D.Pu_Id = ap.Pu_Id AND D.Event_Id = ap.Event_Id
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE ap.Pu_Id = @MasterUnit AND ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time   
         Update #TOPNDR 	 SET Total = DateDiff(ss,Start_Time,TimeStamp)/60.0
      -- Get All The Time-Based Waste (Get TimeStamp from Waste_Event_Details Table)
      INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Type_Id, Meas_Id)
        SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, D.WET_Id, D.WEMT_Id  
          FROM Waste_Event_Details D 
          JOIN #Applied_Products_From_Events ap ON ap.Pu_Id = D.Pu_Id AND ap.TimeStamp = D.TimeStamp
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc AND D.TimeStamp > C.Start_Time AND D.TimeStamp <= C.End_Time
         WHERE D.Pu_Id = @MasterUnit AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
    END
  --EndIf:@MasterUnit
  GOTO PROCESS_WASTE_SUMMARY
-- PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-
-- PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-
-- PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-
-- PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-
-- PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-
-- PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-
-- PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-
-- PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-PROCESSING WASTE SUMMARY RESULTSET-
PROCESS_WASTE_SUMMARY:
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
Update #TOPNDR set total = (total - n.NPDuration)
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp > n.Endtime)
-------SC2---------------------------------------------------------------------------------------
---                               Start_time-------------------------------------Timestamp
--------                   n.St-------------------------n.End
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,T.Start_Time,n.EndTime)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
Update #TOPNDR set total = (total - n.NPDuration)
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time > n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
-- 	 
--------------------------------------------------------------------------------------------------
--SC3
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,T.Start_Time,n.EndTime)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
Update #TOPNDR set total = (total - n.NPDuration)
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp > n.Endtime And n.endtime > T.Start_Time)
----SC4------------------------------------------------------------------------------------------
---           Start_time-------------------------------------Timestamp
--------                                 n.St----------------------------------------------n.End
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,n.StartTime,T.TimeStamp)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp < n.Endtime and n.Starttime < T.TimeStamp)
--
Update #TOPNDR set total = (total - n.NPDuration)
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp < n.Endtime and T.Start_Time < n.endtime and n.Starttime < T.TimeStamp)
--SELECT Amount
--FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp < n.Endtime and T.Start_Time < n.endtime and n.Starttime < T.TimeStamp)
----SC5------------------------------------------------------------------------------------------
---           Start_time-------------------------------------Timestamp
--------                                 n.St----------------n.End
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,n.StartTime,T.TimeStamp)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp = n.Endtime and n.Starttime < T.TimeStamp)
--
Update #TOPNDR set total = (total - n.NPDuration)
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time < n.StartTime AND T.TimeStamp = n.Endtime and T.Start_Time < n.endtime and n.Starttime < T.TimeStamp)
--------------------------------------------------------------------------------------------------
---SC6--
--------             Start_time-----------Timestamp
--------                   n.St-----------n.End
UPDATE @Periods_NPT SET NPDuration = DateDiff(ss,n.StarTTime,n.EndTime)/60.0
FROM  #TOPNDR T JOIN @Periods_NPT n ON (T.Start_Time = n.StartTime AND T.TimeStamp = n.Endtime) 
Update #TOPNDR set total = (total - n.NPDuration)
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
Update #TOPNDR set Amount = ((total * Amount)/diff)
Update #TOPNDR set Amount = 0 where Amount Is Null
--SELECT * FROM @Periods_NPT
--SELECT * FROM #TOPNDR
-----------------------------------------------------
  -- Calculate Total Waste
  SELECT @TotalWaste = (SELECT Sum(Amount) FROM #TopNDR) 
  --Go And Get Total Production For Time Period
  SELECT @TotalOperating = 0
  --SELECT @TotalOperating = NULL
  SELECT @TotalOperating = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0) - @TotalOperating
--  Print @NPTCOUNT
  SELECT @NOF = Count(Amount)- @NPTCOUNT from #TOPNDR
--  Print @NOF 	 
  --Delete Rows that donot match Additional Selection Criteria
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
    LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
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
--  UPDATE #TopNDR 
--    SET Reason_Name = @Unspecified  WHERE Reason_Name Is NULL
  -- Populate Temp Table With Reason
  INSERT INTO #MyReport (ReasonName, NumberOfOccurances, TotalReasonUnits, AvgReasonUnits, TotalWasteUnits, TotalOperatingUnits)
    SELECT Reason_Name, @NOF, Total_Amount = SUM(Amount),  (SUM(Amount) / @NOF), @TotalWaste, @TotalOperating
      FROM #TopNDR
  GROUP BY Reason_Name
  ORDER BY Total_Amount DESC
  -- Get Waste Summary ResultSet
  SELECT * FROM #MyReport
DROP_TEMP_TABLES:
  DROP TABLE #TopNDR
  DROP TABLE #MyReport
  DROP TABLE #Products
  DROP TABLE #Prod_Starts
  DROP TABLE #Applied_Products_From_Events
--
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
