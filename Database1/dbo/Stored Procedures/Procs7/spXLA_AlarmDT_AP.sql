-- DESCRIPTION: spXLA_AlarmDT_AP is modified from spXLA_AlarmDetail_AP. Changes include additions of action level reasons,  
-- Action1...Action4. MT/8-16-2002 
--
-- ECR #25128: mt/3-14-2003: handle duplicate Var_Desc. GBDB doesn't enforce unique Var_Desc across the entire database
-- system. Must handle duplication with code.
--
-- ECR #25736: mt/8-20-2003: added action & research comments
--
CREATE PROCEDURE dbo.spXLA_AlarmDT_AP
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
 	 , @Prod_Id 	  	 Int 
 	 , @Group_Id 	  	 Int
 	 , @Prop_Id 	  	 Int
 	 , @Char_Id 	  	 Int
 	 , @ShowProductCode 	 TinyInt
 	 , @IsAppliedProdFilter 	 TinyInt 	  	 -- 1 = Yes filter by Applied Product; 0 = No, Filter By Original Product
 	 , @TimeSort 	  	 TinyInt
    , @DecimalChar          Varchar(1) = NULL
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
 	 --Needed for Reason Levels
DECLARE @LevelLocation 	  Int --Slave Units
DECLARE @LevelReason1 	  Int
DECLARE @LevelReason2 	  Int
DECLARE @LevelReason3 	  Int
DECLARE @LevelReason4 	  Int
DECLARE @LevelAction1 	  Int
DECLARE @LevelAction2 	  Int
DECLARE @LevelAction3 	  Int
DECLARE @LevelAction4 	  Int
 	 --Needed for Crew,shift
DECLARE @CrewShift       TinyInt
DECLARE @NoCrewNoShift   TinyInt
DECLARE @HasCrewNoShift  TinyInt
DECLARE @NoCrewHasShift  TinyInt
DECLARE @HasCrewHasShift TinyInt
 	 --Needed for product-related query types
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
 	 --Needed for ResultSet
DECLARE @Pu_Id 	  	  	 Integer
DECLARE @Data_Type_Id 	  	 Integer
DECLARE @MasterUnit 	  	 Integer
DECLARE @VariableFetchCount 	 Integer
 	 --Needed for Cursor ...
DECLARE @Prev_Ps_Start_Time     DateTime
DECLARE @Prev_Ps_End_Time       DateTime
DECLARE @Previous_End_Time 	 DateTime
DECLARE @Previous_Pu_Id 	  	 Int
DECLARE @Previous_Prod_Id  	 Int
DECLARE @Previous_ApProd_Id 	 Int
DECLARE @Original_Found 	         Int
DECLARE @Sum_Original_Found 	 Int
DECLARE @AP_Found 	  	 Int
DECLARE @Sum_AP_Found 	  	 Int
DECLARE @Saved_Start_Time 	 DateTime
DECLARE @Fetch_Count            Int
DECLARE @@Ps_Start_Time         DateTime
DECLARE @@Ps_End_Time           DateTime
DECLARE @@Start_Time            	 DateTime
DECLARE @@End_Time              	 DateTime
DECLARE @@Pu_Id                 	 Int
DECLARE @@Prod_Id 	  	 Int
DECLARE @@Applied_Prod_Id 	 Int
DECLARE @Unspecified varchar(50)
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
 	 --Define levels....
SELECT @LevelLocation  = 0
SELECT @LevelReason1   = 1
SELECT @LevelReason2   = 2
SELECT @LevelReason3   = 3
SELECT @LevelReason4   = 4
SELECT @LevelAction1   = 5
SELECT @LevelAction2   = 6
SELECT @LevelAction3   = 7
SELECT @LevelAction4   = 8
 	 --Define crew,shift types
SELECT @NoCrewNoShift   = 1
SELECT @HasCrewNoShift  = 2
SELECT @NoCrewHasShift  = 3
SELECT @HasCrewHasShift = 4
If @DecimalChar Is NULL SELECT @DecimalChar = '.'  --Set Default Decimal Character to period
-- ECR #25128: mt/3-14-2003: handle duplicate Var_Desc. GBDB doesn't enforce unique Var_Desc across the entire database
-- system. Must handle duplication with code.
--
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --input variable NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we've @Var_Id
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
    --EndIf:Count=0
  END
Else --@Var_Desc NOT null, use it
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @MasterUnit = pu.Master_Unit, @Data_Type_Id = v.Data_Type_Id --, @Event_Type = v.Event_Type, 
      FROM Variables v
      JOIN Prod_Units pu  on pu.Pu_Id = v.Pu_Id
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
--EndIf:Both @Var_Desc and @Var_Id null
If @MasterUnit Is NULL SELECT @MasterUnit = @Pu_Id
-- Create All Temp tables we would need here.....
CREATE TABLE #TempAlarmData 
  ( Alarm_Id 	  	 Int
  , Alarm_Desc 	  	 Varchar(1000) NULL
  , Start_Time 	  	 DateTime
  , End_Time 	  	 DateTime    NULL
  , Crew_Start          DateTime    NULL
  , Crew_End            DateTime    NULL
  , Duration 	  	 real        NULL
  , Source_Pu_Id 	 Int         NULL
  , Prod_Id 	  	 Int         NULL
  , Applied_Prod_Id 	 Int         NULL
  , Reason1_Id 	  	 Int         NULL
  , Reason2_Id 	  	 Int         NULL 
  , Reason3_Id  	  	 Int         NULL
  , Reason4_Id  	  	 Int         NULL
  , Comment_Id 	  	 Int         NULL
  , Action_Comment_Id   Int         NULL
  , Research_Comment_Id Int         NULL
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
CREATE TABLE #Prod_Starts (PU_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Applied_Products (Pu_Id Int, Ps_Start_Time DateTime, Ps_End_Time DateTime NULL, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL, Keep_Event TinyInt NULL)
--Figure Out Query Type Based on Product Info given
-- NOTE: We DO NOT handle all possible NULL combinations of product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
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
If      @Prod_Id Is NOT NULL 	  	  	  	 SELECT @QueryType = @SingleProduct   	 --1
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL 	 SELECT @QueryType = @Group   	  	 --2
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL 	 SELECT @QueryType = @Characteristic  	 --3
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL 	 SELECT @QueryType = @GroupAndProperty 	 --4
Else 	  	  	  	  	  	  	 SELECT @QueryType = @NoProductSpecified 	 --5
--EndIf
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     SELECT @CrewShift = @NoCrewNoShift
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL SELECT @CrewShift = @HasCrewNoShift
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL SELECT @CrewShift = @NoCrewHasShift
Else                                                   SELECT @CrewShift = @HasCrewHasShift
--EndIf:Crew,shift
If @IsAppliedProdFilter = 1 GOTO DO_FILTER_BY_APPLIED_PRODUCT
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Build product information from Production_Starts Table ...............
If @QueryType = @NoProductSpecified 	  	  	 --5
  BEGIN
    INSERT INTO #Prod_Starts
      SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM Production_Starts ps
       WHERE (ps.PU_Id = @MasterUnit AND ps.PU_Id <> 0)
         AND (    (ps.Start_Time BETWEEN @Start_Time AND @End_Time) 
               OR (ps.End_Time > @Start_Time AND ps.End_Time < @End_Time) 
               OR (ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time Is NULL))
             )
  END
Else If @QueryType = @SingleProduct 	  	  	 --1
  BEGIN
    INSERT INTO #Prod_Starts
      SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM Production_Starts ps
       WHERE (ps.PU_Id = @MasterUnit AND ps.PU_Id <> 0)
         AND ps.Prod_Id = @Prod_Id 
         AND (    (ps.Start_Time BETWEEN @Start_Time AND @End_Time) 
               OR (ps.End_Time > @Start_Time AND ps.End_Time < @End_Time) 
               OR (ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time Is NULL))
             )
  END
Else 	  	  	  	  	 --Not a single product 
  BEGIN
    If @QueryType = @Group 	  	  	 --2
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id  FROM Product_Group_Data  WHERE Product_Grp_Id = @Group_Id
      END
    Else If @QueryType = @Characteristic 	 --3
      BEGIN
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id  FROM Pu_Characteristics WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
      END
    Else 	  	  	  	  	 --4, Group and Property  
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id  FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id FROM Pu_Characteristics  WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
      END
    --EndIf @QueryType = Group block
    INSERT INTO #Prod_Starts
      SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM Production_Starts ps
        JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
       WHERE ps.PU_Id = @MasterUnit 
         AND ps.PU_Id <> 0
         AND (   (ps.Start_Time BETWEEN @Start_Time AND @End_Time) 
              OR (ps.End_Time > @Start_Time AND ps.End_Time < @End_Time)
              OR (ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time IS NULL))
             )
  END
--EndIf @QueryType = Single Product block
-- Fill In TopNDR Table ..................
If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_ORIGINAL_INSERT
Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_ORIGINAL_INSERT
Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_ORIGINAL_INSERT
Else                                 GOTO HASCREW_HASSHIFT_ORIGINAL_INSERT
--EndIf:Crew,Shift
NOCREW_NOSHIFT_ORIGINAL_INSERT:
  If @Acknowledged = 1 
    BEGIN
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                      , [Start_Time] = Case When ps.Start_Time >= a.Start_Time Then ps.Start_Time Else a.Start_Time End
                      , [End_Time]   = Case When a.End_Time Is NULL Then ps.End_Time
                                            When ps.End_Time Is NULL Then a.End_Time
                                            When ps.End_Time <= a.End_Time Then ps.End_Time Else a.End_Time                                   
                                       End
                      , a.Duration, a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On
                      , a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN #Prod_Starts ps ON
          (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
            OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
            OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
          )
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
           AND a.Ack = 1
    END
  Else --@Acknowledged = 0
    BEGIN
      INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                 , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                      , [Start_Time] = Case When ps.Start_Time >= a.Start_Time Then ps.Start_Time Else a.Start_Time End
                      , [End_Time]   = Case When a.End_Time Is NULL Then ps.End_Time
                                            When ps.End_Time Is NULL Then a.End_Time
                                            When ps.End_Time <= a.End_Time Then ps.End_Time Else a.End_Time                                   
                                       End
                      , a.Duration, a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On
                      , a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN #Prod_Starts ps ON
          (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
            OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
            OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
          )
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
    END  
  --EndIf @Acknowledged ..
  GOTO FINISH_UP_TEMP_ALARM_TABLE
HASCREW_NOSHIFT_ORIGINAL_INSERT:
  If @Acknowledged = 1 
    BEGIN
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                      , [Start_Time] = Case When ps.Start_Time >= a.Start_Time Then ps.Start_Time Else a.Start_Time End
                      , [End_Time]   = Case When a.End_Time Is NULL Then ps.End_Time
                                            When ps.End_Time Is NULL Then a.End_Time
                                            When ps.End_Time <= a.End_Time Then ps.End_Time Else a.End_Time                                   
                                       End
                      , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On
                      , a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN #Prod_Starts ps ON
          (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
            OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
            OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
          )
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON
               (   a.Start_Time BETWEEN C.Start_Time AND C.End_Time 
                OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
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
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                      , [Start_Time] = Case When ps.Start_Time >= a.Start_Time Then ps.Start_Time Else a.Start_Time End
                      , [End_Time]   = Case When a.End_Time Is NULL Then ps.End_Time
                                            When ps.End_Time Is NULL Then a.End_Time
                                            When ps.End_Time <= a.End_Time Then ps.End_Time Else a.End_Time                                   
                                       End
                      , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On
                      , a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN #Prod_Starts ps ON
          (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
            OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
            OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
          )
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON
               (   a.Start_Time BETWEEN C.Start_Time AND C.End_Time 
                OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
               )
           AND C.Crew_Desc = @Crew_Desc
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
    END  
  --EndIf @Acknowledged ..
  GOTO FINISH_UP_TEMP_ALARM_TABLE
NOCREW_HASSHIFT_ORIGINAL_INSERT:
  If @Acknowledged = 1 
    BEGIN
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                      , [Start_Time] = Case When ps.Start_Time >= a.Start_Time Then ps.Start_Time Else a.Start_Time End
                      , [End_Time]   = Case When a.End_Time Is NULL Then ps.End_Time
                                            When ps.End_Time Is NULL Then a.End_Time
                                            When ps.End_Time <= a.End_Time Then ps.End_Time Else a.End_Time                                   
                                       End
                      , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On
                      , a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN #Prod_Starts ps ON
          (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
            OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
            OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
          )
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON
               (   a.Start_Time BETWEEN C.Start_Time AND C.End_Time 
                OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
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
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                      , [Start_Time] = Case When ps.Start_Time >= a.Start_Time Then ps.Start_Time Else a.Start_Time End
                      , [End_Time]   = Case When a.End_Time Is NULL Then ps.End_Time
                                            When ps.End_Time Is NULL Then a.End_Time
                                            When ps.End_Time <= a.End_Time Then ps.End_Time Else a.End_Time                                   
                                       End
                      , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On
                      , a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN #Prod_Starts ps ON
          (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
            OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
            OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
          )
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON
               (   a.Start_Time BETWEEN C.Start_Time AND C.End_Time 
                OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
               )
           AND C.Shift_Desc = @Shift_Desc
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
    END  
  --EndIf @Acknowledged ..
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End NOCREW_HASSHIFT_ORIGINAL_INSERT:
HASCREW_HASSHIFT_ORIGINAL_INSERT:
  If @Acknowledged = 1 
    BEGIN
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                      , [Start_Time] = Case When ps.Start_Time >= a.Start_Time Then ps.Start_Time Else a.Start_Time End
                      , [End_Time]   = Case When a.End_Time Is NULL Then ps.End_Time
                                            When ps.End_Time Is NULL Then a.End_Time
                                            When ps.End_Time <= a.End_Time Then ps.End_Time Else a.End_Time                                   
                                       End
                      , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On
                      , a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN #Prod_Starts ps ON
          (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
            OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
            OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
          )
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON
               (   a.Start_Time BETWEEN C.Start_Time AND C.End_Time 
                OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
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
      INSERT INTO #TempAlarmData ( Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Crew_Desc, Shift_Desc, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
        SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                      , [Start_Time] = Case When ps.Start_Time >= a.Start_Time Then ps.Start_Time Else a.Start_Time End
                      , [End_Time]   = Case When a.End_Time Is NULL Then ps.End_Time
                                            When ps.End_Time Is NULL Then a.End_Time
                                            When ps.End_Time <= a.End_Time Then ps.End_Time Else a.End_Time                                   
                                       End
                      , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On
                      , a.Action1, a.Action2, a.Action3, a.Action4, C.Crew_Desc, C.Shift_Desc, a.Cutoff , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
          FROM Alarms a
          JOIN #Prod_Starts ps ON
          (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
            OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
            OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
            OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
          )
          JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
          JOIN Crew_Schedule C ON
               (   a.Start_Time BETWEEN C.Start_Time AND C.End_Time 
                OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
                OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
               )
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
                 OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
               )
    END  
  --EndIf @Acknowledged ..
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End HASCREW_HASSHIFT_ORIGINAL_INSERT:
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
DO_FILTER_BY_APPLIED_PRODUCT:
  --First Grab Relevant Original Product & Related Information From Production_Starts Table 
  INSERT INTO #Prod_Starts
    SELECT ps.pu_id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM Production_Starts ps
       WHERE ps.pu_id = @MasterUnit 
         AND (    ps.Start_Time BETWEEN @Start_Time AND @End_Time 
               OR (ps.End_Time > @Start_Time AND ps.End_Time < @End_Time AND ps.End_Time Is NOT NULL)
               OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time Is NULL) )
             )
  --Grab all of the "Specified" product(s), put them into Temp Table #Products
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
  -- Get Rows From Events Table for "Products" that fit applied products criteria ... 
  --  When matched product has Applied_Product = NULL, we take that the original product Is applied product.
  --  When matched product has Applied_Product <> NULL, include that product as applied product
  -- (Note: JOIN condition for Production_Starts consistent with AutoLog's )
  -- (Note2: Current MSI Start_Time inEvents table are mostly null, software update will insert values into Start_Time
  --         for current and older data, we'll give start_time 1 second less than Time_Stamp.
  --         For Customers who are concern about correct result, MSI will give them a script for one-time update of 
  --         their Events table. This update is time/disk-space consuming, thus, available upon request only. MT/3-20-2002.)
  --Make TEMP TABLE: Split ANY PRODUCT In #Prod_Starts into individual events.
  INSERT INTO #Applied_Products ( Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id )
      SELECT e.Pu_Id, ps.Start_Time, ps.End_Time, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product 
        FROM #Prod_Starts ps 
        JOIN Events e ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL ) 
         AND ps.Pu_Id = e.Pu_Id 
    ORDER BY e.Pu_Id, ps.Start_Time, e.TimeStamp, ps.Prod_Id
  -- Use Cursor to track the individual events in #Applied_Products 
  DECLARE TCursor INSENSITIVE CURSOR 
    FOR ( SELECT Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id FROM #Applied_Products )
    FOR READ ONLY
  --END Declare
OPEN_CURSOR_FOR_PROCESSING:
  -- Initialize local variables ......
  SELECT @Saved_Start_Time   = ''
  SELECT @Prev_Ps_Start_Time = ''
  SELECT @Prev_Ps_End_Time   = ''
  SELECT @Previous_Pu_Id     = -1
  SELECT @Previous_End_Time  = ''
  SELECT @Previous_Prod_Id   = -1
  SELECT @Previous_ApProd_Id = -1
  SELECT @Original_Found     = -1
  SELECT @Sum_Original_Found = 0
  SELECT @AP_Found 	      = -1
  SELECT @Sum_AP_Found       = 0
  SELECT @Fetch_Count        = 0
  SELECT @@Ps_Start_Time     = ''
  SELECT @@Ps_End_Time       = ''
  SELECT @@Start_Time        = ''
  SELECT @@End_Time          = ''
  SELECT @@Pu_Id             = -1
  SELECT @@Prod_Id           = -1
  SELECT @@Applied_Prod_Id   = -1
  OPEN TCursor
  --Tracking Product Events by counting successive applied events
  --(a) First loop: Save start time, store fetched variables in the "Previous" local variables
  --(a) Within same ID: 
  --    Switching occurs when Ps_Start_Time --> Ps_End_Time change.
  --    Switching occurs when previous running applied event(s) turn original, or previous running original event(s) 
  --    turn applied. When switching occurs, update the previous row with Saved start time, and mark "Keep": Update only if
  --    Prod_Id(original) or Applied_Prod_Id(applied) matches the filter.
  --(b) When product ID switch occurs: 
  --    Switching occurs when previous running original event(s) turn original, or previous running original event(s) turn
  --    applied, or previous running applied event(s) turn original, or previous running applied event(s) turn applied.
  --    When switching occurs, update the previous row with Saved start time, and mark "Keep": Update only if
  --    Prod_Id(original) or Applied_Prod_Id(applied) matches the filter.
TOP_OF_FETCH_LOOP:
  FETCH NEXT FROM TCursor INTO @@Pu_Id, @@Ps_Start_Time, @@Ps_End_Time, @@Start_Time, @@End_Time, @@Prod_Id, @@Applied_Prod_Id
  If (@@Fetch_Status = 0)
    BEGIN
      -- ********************************************************************************************
      -- FIRST FETCH: 
      If @Previous_Prod_Id = -1 	  	  	                 
        -- The very first fetch, collect row information and save start time
        BEGIN  
          --SELECT @Saved_Start_Time   = @@Start_Time
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
          SELECT @AP_Found           = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found     = 1 - @AP_Found
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
          --First Reel of a product uses start time from Production_Starts
          If @AP_Found = 1 --First reeel as applied product
            BEGIN
              If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @@Applied_Prod_Id)
                BEGIN
                  UPDATE #Applied_Products SET Start_Time = Ps_Start_Time WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                  SELECT @Saved_Start_Time = Ps_Start_Time FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                END
              --EndIf EXISTS
            END
          Else --1st Reel is original product
            BEGIN
             If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @@Prod_Id)
               BEGIN
                 UPDATE #Applied_Products SET Start_Time = Ps_Start_Time WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                 SELECT @Saved_Start_Time = Ps_Start_Time FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
               END
             --EndIf EXISTS
            END
          --EndIf @AP_Found.
        END
      -- ********************************************************************************************
      -- PRODUCT ID SWITCHED OR PRODUCTION CHANGE OCCURS (SAME ID BUT DIFF START & END TIMES) 
         -- It is the time to 
         -- (a) process last events of previous product. Use Ps_End_Time for last reel)
         -- (b) Update start time for first reel (event) with Ps_Start_Time.
         --
      Else If @Previous_Prod_Id <> @@Prod_Id 
          OR ( @Previous_Prod_Id = @@Prod_Id AND @Prev_Ps_Start_Time <> @@Ps_Start_Time AND (@Prev_Ps_End_Time <> @@Ps_End_Time OR @Prev_Ps_End_Time Is NULL OR @@Ps_End_Time Is NULL) )
        BEGIN                    
          SELECT @AP_Found       = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found = 1 - @AP_Found
          --Update Previous Running Events ...
          If @AP_Found = 1  --fetched event is applied
            BEGIN
              If @Sum_AP_Found = 0  --Running original turns applied
                BEGIN
                  --Update last row of running original
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1  
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS    
                END
              Else --(@Sum_AP_Found >0): Running applied turns applied at new ID
                BEGIN
                  --Update last row of running applied (if Applied_Prod_Id matches filter)
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time                     
                      SELECT @Sum_AP_Found = 0 --reset applied running count
                    END
                  --EndIf:EXISTS
                END
              --EndIf:@Sum_AP_Found =0
            END
          Else  --@AP_Found = 0: Original fetched
            BEGIN
              If @Sum_AP_Found > 0  --Running applied switches to original
                BEGIN                  
                  --Update last row in running AP events (if Applied_Prod_Id matches filter), and reset the running sum
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS
                  SELECT @Sum_AP_Found = 0  --(reset running sum)                                    
                END
              Else --(@Sum_AP_Found = 0): Running original turns original at ID switch
                BEGIN
                  --Update last row in running original events
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time        
                    END
                  --EndIf:EXISTS
                END
              --EndIf:@Sum_AP_Found >0
            END           
          --EndIf:@AP_Found =1 Block
              --Reset counters (for original product only tracking)
          SELECT @Fetch_Count        = 0
          SELECT @Sum_Original_Found = 0
              --Collect relevant info for this ID ....
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
          --First Reel of product uses start time from Production_Starts
          SELECT @Saved_Start_Time = Ps_Start_Time  FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
        END
      -- ********************************************************************************************
      -- RUNNING PRODUCT -- SAME PRODUCT FETCHED; Has this event been applied?
      Else If @Previous_Prod_Id = @@Prod_Id              
        BEGIN  
          --Get applied/original status
          SELECT @AP_Found       = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found = 1 - @AP_Found
          If @AP_Found = 1 --fetched event is applied
            BEGIN
              If @Sum_AP_Found = 0 --Running original switches to applied
                BEGIN
                  --Update last row of running original
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS
                  SELECT @Saved_Start_Time = @@Start_Time --Save start_time
                END
              --EndIf:@Sum_AP_Found =0
            END     
          Else  --(@AP_Found = 0): fetched event is original
            BEGIN
              If @Sum_AP_Found > 0  --Running applied turns original
                BEGIN                  
                  --Update last row in running AP events (if Applied_Prod_Id matches filter), and reset the running sum
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf                      
                  SELECT @Sum_AP_Found = 0  --(reset running sum)                                    
                  SELECT @Saved_Start_Time = @@Start_Time  --Save current original event's Start_Time
                END
              --Else --(@Sum_AP_Found = 0): Running original turns original turns original
                     --(do nothing, just continue accumulate running events)
              --EndIf:@Sum_AP_Found >0
            END           
          --EndIf:@AP_Found =1 Block
              --Collect information of current fetched
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
        END
      --EndIf:@Previous_Prod_Id = -1( Main block )
      GOTO TOP_OF_FETCH_LOOP
    END
  --EndIf (@@Fetch_Status = 0)
  -- ****************************************************************
  --HANDLE END OF LOOP UPDATE: ( single event also included here )
    If @AP_Found = 1  --Last fetch was applied
      BEGIN
        --Handle previously 100% running applied
        If @Fetch_Count = @Sum_AP_Found 
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = Ps_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
          END        
        Else --Not 100% running applied
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
              BEGIN
               UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
            --EndIf:EXISTS
        --EndIf @Fetch_Count
      END
    Else --Last fetch was original (@AP_Found =0)
      BEGIN
        --Handle previously 100% Running original events, use times from production_Starts table
        If @Fetch_Count = @Sum_Original_Found
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = Ps_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
          END     
        Else --not 100% running original event; use times from Events table
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
            --EndIf:EXISTS
          END
        --EndIf:@Fetch_Count = @Sum_Original_Found
      END
    --EndIf:@Sum_AP_Found =1
  CLOSE TCursor
  DEALLOCATE TCursor
  -- DELETE UNMARKED ROWS .....
  DELETE FROM #Applied_Products WHERE Keep_Event Is NULL
  If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_APPLIED_INSERT
  Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_APPLIED_INSERT
  Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_APPLIED_INSERT
  Else                                 GOTO HASCREW_HASSHIFT_APPLIED_INSERT
  --EndIf:Crew,Shift
  -- Insert Data Into Temp Table #TempAlarmData
NOCREW_NOSHIFT_APPLIED_INSERT:
  If @Acknowledged = 1  --Get only acknowledged Alarms
    INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
              , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When ap.Start_Time >= a.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case When a.End_Time Is NULL Then ap.End_Time
                                          When ap.End_Time Is NULL Then a.End_Time
                                          When ap.End_Time <= a.End_Time Then ap.End_Time Else a.End_Time                                   
                                     End
                    , a.Duration, a.Source_PU_Id, ap.Prod_Id, ap.Applied_Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result
                    , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
         AND a.Ack = 1
  Else                  --Any alarm data; @Acknowledement not required
    INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration, Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
              , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When ap.Start_Time >= a.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case When a.End_Time Is NULL Then ap.End_Time
                                          When ap.End_Time Is NULL Then a.End_Time
                                          When ap.End_Time <= a.End_Time Then ap.End_Time Else a.End_Time                                   
                                     End
                    , a.Duration, a.Source_PU_Id, ap.Prod_Id, ap.Applied_Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result
                    , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
  --EndIf @Acknowledged = 1
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End NOCREW_NOSHIFT_APPLIED_INSERT:
HASCREW_NOSHIFT_APPLIED_INSERT:
  If @Acknowledged = 1  --Get only acknowledged Alarms
    INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
              , Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When ap.Start_Time >= a.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case When a.End_Time Is NULL Then ap.End_Time
                                          When ap.End_Time Is NULL Then a.End_Time
                                          When ap.End_Time <= a.End_Time Then ap.End_Time Else a.End_Time                                   
                                     End
                    , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ap.Prod_Id, ap.Applied_Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result
                    , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
        JOIN Crew_Schedule C ON 
             (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
               OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
               OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
             )
         AND C.Crew_Desc = @Crew_Desc
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
         AND a.Ack = 1
  Else                  --Any alarm data; @Acknowledement not required
    INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
              , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When ap.Start_Time >= a.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case When a.End_Time Is NULL Then ap.End_Time
                                          When ap.End_Time Is NULL Then a.End_Time
                                          When ap.End_Time <= a.End_Time Then ap.End_Time Else a.End_Time                                   
                                     End
                    , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ap.Prod_Id, ap.Applied_Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result
                    , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
        JOIN Crew_Schedule C ON 
             (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
               OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
               OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
             )
         AND C.Crew_Desc = @Crew_Desc
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
  --EndIf @Acknowledged = 1
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End HASCREW_NOSHIFT_APPLIED_INSERT:
NOCREW_HASSHIFT_APPLIED_INSERT:
  If @Acknowledged = 1  --Get only acknowledged Alarms
    INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
              , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When ap.Start_Time >= a.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case When a.End_Time Is NULL Then ap.End_Time
                                          When ap.End_Time Is NULL Then a.End_Time
                                          When ap.End_Time <= a.End_Time Then ap.End_Time Else a.End_Time                                   
                                     End
                    , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ap.Prod_Id, ap.Applied_Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result
                    , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
        JOIN Crew_Schedule C ON 
             (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
               OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
               OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
             )
         AND C.Shift_Desc = @Shift_Desc
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
         AND a.Ack = 1
  Else                  --Any alarm data; @Acknowledement not required
    INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
              , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When ap.Start_Time >= a.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case When a.End_Time Is NULL Then ap.End_Time
                                          When ap.End_Time Is NULL Then a.End_Time
                                          When ap.End_Time <= a.End_Time Then ap.End_Time Else a.End_Time                                   
                                     End
                    , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ap.Prod_Id, ap.Applied_Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result
                    , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
        JOIN Crew_Schedule C ON 
             (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
               OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
               OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
             )
         AND C.Shift_Desc = @Shift_Desc
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
  --EndIf @Acknowledged = 1
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End NOCREW_HASSHIFT_APPLIED_INSERT:
HASCREW_HASSHIFT_APPLIED_INSERT:
  If @Acknowledged = 1  --Get only acknowledged Alarms
    INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
              , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When ap.Start_Time >= a.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case When a.End_Time Is NULL Then ap.End_Time
                                          When ap.End_Time Is NULL Then a.End_Time
                                          When ap.End_Time <= a.End_Time Then ap.End_Time Else a.End_Time                                   
                                     End
                    , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ap.Prod_Id, ap.Applied_Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result
                    , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
        JOIN Crew_Schedule C ON 
             (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
               OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
               OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
             )
         AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
         AND a.Ack = 1
  Else                  --Any alarm data; @Acknowledement not required
    INSERT INTO #TempAlarmData(  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Crew_Start, Crew_End, Duration, Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
              , Comment_Id, Action_Comment_Id, Research_Comment_Id, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, Ack_On, A1_Id, A2_Id, A3_Id, A4_Id, Cutoff, User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When ap.Start_Time >= a.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case When a.End_Time Is NULL Then ap.End_Time
                                          When ap.End_Time Is NULL Then a.End_Time
                                          When ap.End_Time <= a.End_Time Then ap.End_Time Else a.End_Time                                   
                                     End
                    , C.Start_Time, C.End_Time, a.Duration, a.Source_PU_Id, ap.Prod_Id, ap.Applied_Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4, a.Cause_Comment_Id, a.Action_Comment_Id, a.Research_Comment_Id, a.Max_Result, a.Min_Result
                    , a.Start_Result, a.End_Result, a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff, a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
        JOIN Crew_Schedule C ON 
             (    a.Start_Time BETWEEN C.Start_Time AND C.End_Time
               OR a.End_Time > C.Start_Time AND (a.End_Time < C.End_Time OR a.End_Time Is NULL)
               OR a.Start_Time <= C.Start_Time AND (a.End_Time > C.End_Time OR a.End_Time Is NULL)
             )
         AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
  --EndIf @Acknowledged = 1
  GOTO FINISH_UP_TEMP_ALARM_TABLE
--End HASCREW_HASSHIFT_APPLIED_INSERT:
-- FINISH UP TEMP ALARM TABLE AND PROCESSING RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESSING RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESSING RESULTSET-
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
  If @ShowProductCode     = 0  GOTO RETRIEVE_RESULT_SET_WITHOUT_PRODUCT_CODES
  If @IsAppliedProdFilter = 1  GOTO RETRIEVE_APPLIED_PRODUCT_RESULT_SET
RETRIEVE_ORIGINAL_PRODUCT_RESULT_SET:
  If @TimeSort = 1 --Ascending Order
    BEGIN
        SELECT t.Alarm_Id
             , t.Alarm_Desc
             , [Start_Time] = Case When t.Crew_Start Is NULL Then t.Start_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_Start >= t.Start_Time Then t.Crew_Start at time zone @DBTz at time zone @InTimeZone Else t.Start_Time at time zone @DBTz at time zone @InTimeZone End
             , [End_Time]   = Case When t.Crew_End Is NULL Then t.End_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_End <= t.End_Time Then t.Crew_End at time zone @DBTz at time zone @InTimeZone Else t.End_Time at time zone @DBTz at time zone @InTimeZone End
             , t.Duration
             , Location  = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
             , Prod_Code = p.Prod_Code
             , Reason1   = Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2   = Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
             , Reason3   = Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4   = Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , t.Comment_Id
             , t.Action_Comment_Id
             , t.Research_Comment_Id
             , [Max_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Max_Result,   '.', @DecimalChar) Else t.Max_Result   End
             , [Min_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Min_Result,   '.', @DecimalChar) Else t.Min_Result   End
             , [Start_Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Start_Result, '.', @DecimalChar) Else t.Start_Result End
             , [End_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.End_Result,   '.', @DecimalChar) Else t.End_Result   End
             , [Modified_On] = t.Modified_On at time zone @DBTz at time zone @InTimeZone
             , [Ack_On] = t.Ack_On at time zone @DBTz at time zone @InTimeZone
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
             , [Research_Open_Date] = t.Research_Open_Date at time zone @DBTz at time zone @InTimeZone
             , [Research_Close_Date] = t.Research_Close_Date at time zone @DBTz at time zone @InTimeZone
             , [Data_Type_Id] = @Data_Type_Id
          FROM #TempAlarmData t
          LEFT OUTER JOIN Products p ON p.Prod_Id = t.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = t.Source_Pu_Id AND pu.Pu_Id <> 0
          LEFT OUTER JOIN Event_Reasons R1 ON R1.Event_Reason_Id = t.Reason1_Id
          LEFT OUTER JOIN Event_Reasons R2 ON R2.Event_Reason_Id = t.Reason2_Id
          LEFT OUTER JOIN Event_Reasons R3 ON R3.Event_Reason_Id = t.Reason3_Id
          LEFT OUTER JOIN Event_Reasons R4 ON R4.Event_Reason_Id = t.Reason4_Id 
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
             , [Start_Time] = Case When t.Crew_Start Is NULL Then t.Start_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_Start >= t.Start_Time Then t.Crew_Start at time zone @DBTz at time zone @InTimeZone Else t.Start_Time at time zone @DBTz at time zone @InTimeZone End
             , [End_Time]   = Case When t.Crew_End Is NULL Then t.End_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_End <= t.End_Time Then t.Crew_End at time zone @DBTz at time zone @InTimeZone Else t.End_Time at time zone @DBTz at time zone @InTimeZone End
             , t.Duration
             , Location  = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
             , Prod_Code = p.Prod_Code
             , Reason1   = Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2   = Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
             , Reason3   = Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4   = Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , t.Comment_Id
             , t.Action_Comment_Id
             , t.Research_Comment_Id
             , [Max_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Max_Result,   '.', @DecimalChar) Else t.Max_Result   End
             , [Min_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Min_Result,   '.', @DecimalChar) Else t.Min_Result   End
             , [Start_Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Start_Result, '.', @DecimalChar) Else t.Start_Result End
             , [End_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.End_Result,   '.', @DecimalChar) Else t.End_Result   End
             , [Modified_On] = t.Modified_On at time zone @DBTz at time zone @InTimeZone
             , [Ack_On] = t.Ack_On at time zone @DBTz at time zone @InTimeZone
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
             , [Research_Open_Date] = t.Research_Open_Date at time zone @DBTz at time zone @InTimeZone
             , [Research_Close_Date] = t.Research_Close_Date at time zone @DBTz at time zone @InTimeZone
             , [Data_Type_Id] = @Data_Type_Id
          FROM #TempAlarmData t
          LEFT OUTER JOIN Products p ON p.Prod_Id = t.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = t.Source_Pu_Id AND pu.Pu_Id <> 0
          LEFT OUTER JOIN Event_Reasons R1 ON R1.Event_Reason_Id = t.Reason1_Id
          LEFT OUTER JOIN Event_Reasons R2 ON R2.Event_Reason_Id = t.Reason2_Id
          LEFT OUTER JOIN Event_Reasons R3 ON R3.Event_Reason_Id = t.Reason3_Id
          LEFT OUTER JOIN Event_Reasons R4 ON R4.Event_Reason_Id = t.Reason4_Id 
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
RETRIEVE_APPLIED_PRODUCT_RESULT_SET:
  If @TimeSort = 1 --Ascending Order
    BEGIN
        SELECT t.Alarm_Id
             , t.Alarm_Desc
             , [Start_Time] = Case When t.Crew_Start Is NULL Then t.Start_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_Start >= t.Start_Time Then t.Crew_Start at time zone @DBTz at time zone @InTimeZone Else t.Start_Time at time zone @DBTz at time zone @InTimeZone End
             , [End_Time]   = Case When t.Crew_End Is NULL Then t.End_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_End <= t.End_Time Then t.Crew_End at time zone @DBTz at time zone @InTimeZone Else t.End_Time at time zone @DBTz at time zone @InTimeZone End
             , t.Duration
             , Prod_Code = p.Prod_Code
             , Applied_Prod_Code = p2.Prod_Code
             , Location  = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
             , Reason1   = Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2   = Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
             , Reason3   = Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4   = Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , t.Comment_Id
             , t.Action_Comment_Id
             , t.Research_Comment_Id
             , [Max_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Max_Result,   '.', @DecimalChar) Else t.Max_Result End
             , [Min_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Min_Result,   '.', @DecimalChar) Else t.Min_Result End
             , [Start_Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Start_Result, '.', @DecimalChar) Else t.Start_Result End
             , [End_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.End_Result,   '.', @DecimalChar) Else t.End_Result End
             , [Modified_On] = t.Modified_On at time zone @DBTz at time zone @InTimeZone
             , [Ack_On] = t.Ack_On at time zone @DBTz at time zone @InTimeZone
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
             , [Research_Open_Date] = t.Research_Open_Date at time zone @DBTz at time zone @InTimeZone
             , [Research_Close_Date] = t.Research_Close_Date at time zone @DBTz at time zone @InTimeZone
             , [Data_Type_Id] = @Data_Type_Id
          FROM #TempAlarmData t
          LEFT OUTER JOIN Products p ON t.Prod_Id = p.Prod_Id
          LEFT OUTER JOIN Products p2 ON t.Applied_Prod_Id = p2.Prod_Id
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
             , [Start_Time] = Case When t.Crew_Start Is NULL Then t.Start_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_Start >= t.Start_Time Then t.Crew_Start at time zone @DBTz at time zone @InTimeZone Else t.Start_Time at time zone @DBTz at time zone @InTimeZone End
             , [End_Time]   = Case When t.Crew_End Is NULL Then t.End_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_End <= t.End_Time Then t.Crew_End at time zone @DBTz at time zone @InTimeZone Else t.End_Time at time zone @DBTz at time zone @InTimeZone End
             , t.Duration
             , Prod_Code = p.Prod_Code
             , Applied_Prod_Code = p2.Prod_Code
             , Location  = Case When t.Source_Pu_Id Is NULL Then @Unspecified Else pu.Pu_Desc End
             , Reason1   = Case When t.Reason1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2   = Case When t.Reason2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
             , Reason3   = Case When t.Reason3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4   = Case When t.Reason4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , t.Comment_Id
             , t.Action_Comment_Id
             , t.Research_Comment_Id
             , [Max_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Max_Result,   '.', @DecimalChar) Else t.Max_Result End
             , [Min_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Min_Result,   '.', @DecimalChar) Else t.Min_Result End
             , [Start_Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Start_Result, '.', @DecimalChar) Else t.Start_Result End
             , [End_Result]   = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.End_Result,   '.', @DecimalChar) Else t.End_Result End
             , [Modified_On] = t.Modified_On at time zone @DBTz at time zone @InTimeZone
             , [Ack_On] = t.Ack_On at time zone @DBTz at time zone @InTimeZone
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
             , [Research_Open_Date] = t.Research_Open_Date at time zone @DBTz at time zone @InTimeZone
             , [Research_Close_Date] = t.Research_Close_Date at time zone @DBTz at time zone @InTimeZone
             , [Data_Type_Id] = @Data_Type_Id
          FROM #TempAlarmData t
          LEFT OUTER JOIN Products p ON t.Prod_Id = p.Prod_Id
          LEFT OUTER JOIN Products p2 ON t.Applied_Prod_Id = p2.Prod_Id
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
RETRIEVE_RESULT_SET_WITHOUT_PRODUCT_CODES:
  If @TimeSort = 1 --Ascending Order
    BEGIN
        SELECT t.Alarm_Id
             , t.Alarm_Desc
             , [Start_Time] = Case When t.Crew_Start Is NULL Then t.Start_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_Start >= t.Start_Time Then t.Crew_Start at time zone @DBTz at time zone @InTimeZone Else t.Start_Time at time zone @DBTz at time zone @InTimeZone End
             , [End_Time]   = Case When t.Crew_End Is NULL Then t.End_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_End <= t.End_Time Then t.Crew_End at time zone @DBTz at time zone @InTimeZone Else t.End_Time at time zone @DBTz at time zone @InTimeZone End
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
             , [Modified_On] = t.Modified_On at time zone @DBTz at time zone @InTimeZone
             , [Ack_On] = t.Ack_On at time zone @DBTz at time zone @InTimeZone
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
             , [Research_Open_Date] = t.Research_Open_Date at time zone @DBTz at time zone @InTimeZone
             , [Research_Close_Date] = t.Research_Close_Date at time zone @DBTz at time zone @InTimeZone
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
             , [Start_Time] = Case When t.Crew_Start Is NULL Then t.Start_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_Start >= t.Start_Time Then t.Crew_Start at time zone @DBTz at time zone @InTimeZone Else t.Start_Time at time zone @DBTz at time zone @InTimeZone End
             , [End_Time]   = Case When t.Crew_End Is NULL Then t.End_Time at time zone @DBTz at time zone @InTimeZone
                                   When t.Crew_End <= t.End_Time Then t.Crew_End at time zone @DBTz at time zone @InTimeZone Else t.End_Time at time zone @DBTz at time zone @InTimeZone End
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
             , [Modified_On] = t.Modified_On at time zone @DBTz at time zone @InTimeZone
             , [Ack_On] = t.Ack_On at time zone @DBTz at time zone @InTimeZone
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
             , [Research_Open_Date] = t.Research_Open_Date at time zone @DBTz at time zone @InTimeZone
             , [Research_Close_Date] = t.Research_Close_Date at time zone @DBTz at time zone @InTimeZone
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
  DROP TABLE #Prod_Starts
  DROP TABLE #Products
  DROP TABLE #Applied_Products 
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
