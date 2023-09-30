-- DESCRIPTION: spXLA_DowntimeSUMM_AP_NPT replaces spXLA_DowntimeSummary_AP. Changes include 7 additional input parameters :
-- Action level reasons (Defect #23386:MT/8-7-2002); Crew, Shift filter(Defect #24395:mt/8-30-2002)  
-- Defect #24434:mt/9-9-2002:correct join condition; never include Source_PU_Id in join. If Source_PU_Id is null, it indicates
-- the master unit is the source, and slave unit when not null. Thus the join condition is :
-- When "unit" is specified, remove join ps.PU_Id = D.Source_PU_Id; when "Unit" is not specified, join ps.Pu_Id = D.PU_Id
--
-- ECR #25517(mt/5-14-2003): Perfomrance Tune on Timed_Event_Details' Where Clause
-- ECR #25517(mt/5-19-2003): Added (C.Start_Time < @End_Time AND C.End_Time > @Start_Time) to the JOIN of Crew_Schedule
-- to Time_Event_Details. Without it, D.End_Time Is NULL will include crew periods that are completely outside report
-- end time
--
-- ECR #23418 (mt/3-14-2005): Added Total Product Operating Minutes, defined as:
--                            Total Product Operating Minutes = SUM(Product Start Time - Product End Time) - Total Downtime Minutes
--                            Where Product Start Time and Product End Time are adjusted for report's time range.
--
-- ECR #29652(mt/7-28-2005): QA failed, count of rows in summary doesn't match that in details be cause of slight differences in code between the two
-- modify spXLA_DownttimeSUMM_AP code to match that in spXLA_DownttimeDT_AP
--
CREATE PROCEDURE dbo.spXLA_DowntimeSUMM_AP_NPT
 	   @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Pu_Id 	  	 Int 	  	 --Add-In's "Line" Is masterUnit here
 	 , @SelectSource  	 Int 	  	 --Slave Units Pu_Id in Timed_Event_
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @SelectA1 	  	 Int
 	 , @SelectA2 	  	 Int
 	 , @SelectA3 	  	 Int
 	 , @SelectA4 	  	 Int
 	 , @ReasonLevel 	  	 Int
 	 , @Crew_Desc 	  	 Varchar(10)
 	 , @Shift_Desc 	  	 Varchar(10)
 	 , @Prod_Id 	  	 Int
 	 , @Group_Id 	  	 Int
 	 , @Prop_Id 	  	 Int
 	 , @Char_Id 	  	 Int
 	 , @IsAppliedProdFilter 	 TinyInt 	  	 --1=Yes filter by Applied Product; 0 = No, Filter By Original Product
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @NPT  Int = 1
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
DECLARE @MasterUnit     Int,@LevelLocation  Int,@LevelReason1   Int,@LevelReason2   Int,@LevelReason3   Int
DECLARE @LevelReason4   Int,@LevelFault     Int,@LevelStatus    Int,@LevelAction1   Int,@LevelAction2   Int
DECLARE @LevelAction3   Int,@LevelAction4   Int,@LevelUnit      Int,@NPCat 	  	  	 Int,@NumberOfOccurances INT
DECLARE @TotalDowntimeMinutes Float,@TotalUptimeMinutes  Float,@TotalOperatingMinutes Float
DECLARE @NPTMinutes Float,@NumberOfUTOccurances Int,@TotalNPTMinutes Float
DECLARE @TotalProductOperating  FLOAT 
DECLARE @DataSlices Table (Start_Time DateTime,End_Time DateTime)
DECLARE @ProdUnits Table (Id Int Identity(1,1),PUId Int)
DECLARE @Start Int, @End Int,@Start2 Int
DECLARE @CurrentStartTime DateTime,@PrevEnd DateTime,@CurrentEndTime DateTime
DECLARE @CurrentPU Int
DECLARE @NextEnd DateTime,@NextStart DateTime
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration Float)
IF @NPT Is Null
 	 SET @NPT = 1
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Local query assistance
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
 	 --Define Reason Levels
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
If @Pu_Id Is NULL SELECT @MasterUnit = NULL Else Select @MasterUnit = @Pu_Id
SELECT @NPCat = Non_Productive_Category 
 	 FROM prod_units 
 	 WHERE PU_id = @PU_Id
-- { ECR #23418: added Minute_Difference field
--CREATE TABLE #Prod_Starts (Pu_Id Int, prod_id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Prod_Starts (Pu_Id Int, prod_id Int, Start_Time DateTime, End_Time DateTime NULL, Minute_Difference Float NULL)
-- }
CREATE TABLE #Products (prod_id Int)
CREATE TABLE #Applied_Products (Pu_Id Int, Ps_Start_Time DateTime, Ps_End_Time DateTime NULL, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL, Keep_Event TinyInt NULL)
CREATE TABLE #AllEvents  (Id int Identity(1,1),Pu_Id Int, Start_Time DateTime, End_Time DateTime,Prod_Id Int)
-- Get All TED Records In Field I Care About
CREATE TABLE #TopNDR (
 	 Detail_Id         Int  
 	 , Start_Time        DateTime
 	 , End_Time          DateTime     NULL
 	 , Duration          Float         NULL
 	 , Uptime            Float         NULL 	 --MT/4-9-2002
 	 , Reason_Name       varchar(100) NULL
 	 , SourcePU          Int          NULL
 	 , MasterUnit        Int          NULL
 	 , R1_Id 	             Int          NULL
 	 , R2_Id 	             Int          NULL
 	 , R3_Id 	             Int          NULL
 	 , R4_Id 	             Int          NULL
 	 , A1_Id             Int          NULL
 	 , A2_Id             Int          NULL
 	 , A3_Id             Int          NULL
 	 , A4_Id             Int          NULL
 	 , Prod_Id           Int          NULL
 	 , Applied_Prod_Id   Int          NULL
 	 , Fault_Id          Int          NULL
 	 , Status_Id         Int          NULL
 	 , UptimeOffOffset 	 Int 	  	  	  NULL 
)
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
If @IsAppliedProdFilter = 1 GOTO APPLIED_PRODUCT_FILTER
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Get Product And Related Info from Production_Starts Table
-- NOTE: "No Product Specified" Case remains here for debugging (validity check against the older spXLA_DowntimeDetail)
If @QueryType = @NoProductSpecified 	 --5
  BEGIN
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #prod_starts
          SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time, [Minute_Difference] = NULL
            FROM production_starts ps
           WHERE Start_Time BETWEEN @Start_Time AND @End_Time
              OR End_Time BETWEEN @Start_Time AND @End_Time 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null)) 	 --MSi/MT/3-14-2001 	  	     
      END
    Else    --@MasterUnit not null
      BEGIN
        INSERT INTO #prod_starts
          SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time, [Minute_Difference] = NULL
            FROM production_starts ps
           WHERE (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
             AND (    Start_Time BETWEEN @Start_Time AND @End_Time 
                   OR End_Time BETWEEN @Start_Time AND @End_Time 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null)) --change Start_Time & End_Time conditions ; MSi/MT/3-14-2001
                 )     
      END
    --EndIf @MasterUnit
  END
Else If @QueryType = @SingleProduct   	 --1
  BEGIN
    IF @MasterUnit IS NULL
      BEGIN
        INSERT INTO #Prod_Starts
 	     SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time, [Minute_Difference] = NULL
 	       FROM production_starts ps
 	      WHERE prod_id = @Prod_Id 
 	        AND ( 	  Start_Time BETWEEN @Start_Time AND @End_Time
 	  	      OR End_Time BETWEEN @Start_Time AND @End_Time
 	  	      OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL)) --Change Start_Time < @Start_Time to Start_Time <= @Start_Time ; Msi/Mt/3-14-2001
                   )   
      END
    ELSE     --@MasterUnit not NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time, [Minute_Difference] = NULL
            FROM Production_Starts ps
           WHERE Pu_Id = @MasterUnit 
             AND Pu_Id <> 0
             AND prod_id = @Prod_Id 
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL)) --Change Start_Time < @Start_Time to Start_Time <= @Start_Time ; Msi/Mt/3-14-2001
                 )    
      END
    --ENDIF @MasterUnit
  END
Else 	  	  	  	  	 --We have product grouping info
  BEGIN
    If @QueryType = @Group 	  	  	 --2
      BEGIN
        INSERT INTO #products
        SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @Characteristic  	 --3
      BEGIN
        INSERT INTO #products
        SELECT DISTINCT prod_id  FROM pu_characteristics  WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else 	  	  	  	  	 --Group & Property (4)
      BEGIN
        INSERT INTO #products
        SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id
        INSERT INTO #products
        SELECT DISTINCT prod_id  FROM pu_characteristics  WHERE prop_id = @Prop_Id  AND char_id = @Char_Id
      END
    --EndIf @QueryType =2 ...
    If @MasterUnit IS NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time, [Minute_Difference] = NULL
            FROM production_starts ps
            JOIN #Products p ON ps.prod_id = p.prod_id 
           WHERE (Start_Time BETWEEN @Start_Time AND @End_Time)
              OR (End_Time BETWEEN @Start_Time AND @End_Time) 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL)) --Change Start_Time < @Start_Time to Start_Time <= @Start_Time ; Msi/Mt/3-14-2001
      END
    ELSE     --@MasterUnit not NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time, [Minute_Difference] = NULL
            FROM Production_Starts ps
            JOIN #Products p ON ps.prod_id = p.prod_id 
           WHERE Pu_Id = @MasterUnit AND Pu_Id <> 0
             AND (    Start_Time BETWEEN @Start_Time AND @End_Time
                   OR End_Time BETWEEN @Start_Time AND @End_Time
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL)) --Change Start_Time < @Start_Time to Start_Time <= @Start_Time ; Msi/Mt/3-14-2001
                 )   
      END
  END
  UPDATE #Prod_Starts SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time              --Adjust start time to report start time as appropriate
  UPDATE #Prod_Starts SET End_Time = @End_Time WHERE End_Time > @End_Time OR End_Time IS NULL  --Adjust end time to report end time as appropriate
  UPDATE #Prod_Starts SET Minute_Difference = DATEDIFF(ss, Start_Time, End_Time) / 60.0        --Fill out the Minute_Difference field
  SELECT @TotalProductOperating = SUM( Minute_Difference ) FROM #Prod_Starts                   --Get total product operating minutes (including downtime at this point)
-- -----------------------------------------------------------------
--
-- Insert Data Into Temp Table #TopNDR For ORIGINAL PRODUCT FILTER
--
-- -----------------------------------------------------------------
IF  @Crew_Desc Is NULL AND @Shift_Desc Is NULL 
BEGIN
  If @MasterUnit IS NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT 
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                                Else D.End_Time
                              End
             , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id , D.Reason_Level1, D.Reason_Level2, D.Reason_Level3 , D.Reason_Level4 
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4 , ps.Prod_Id , D.TEFault_Id, D.TEStatus_Id  
          FROM Timed_Event_Details D
          JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time )
           AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
    END
  Else  --@MasterUnit not NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT 
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                                Else D.End_Time
                              End
             , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id , D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4 , ps.Prod_Id , D.TEFault_Id, D.TEStatus_Id  
          FROM  Timed_Event_Details D
          JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND 
 	  	  	 (D.Start_Time < ps.End_Time ) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
END
IF  @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL 
BEGIN
  If @MasterUnit IS NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT 
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                                Else D.End_Time
                              End
             , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id , D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4 , ps.Prod_Id , D.TEFault_Id, D.TEStatus_Id  
          FROM Timed_Event_Details D
          JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
          JOIN Crew_Schedule C ON C.Pu_Id = D.Pu_Id AND C.Crew_Desc = @Crew_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
    END
  Else  --@MasterUnit not NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT 
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                                Else D.End_Time
                              End
             , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id , D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4 , ps.Prod_Id , D.TEFault_Id, D.TEStatus_Id  
          FROM  Timed_Event_Details D
          JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
          JOIN Crew_Schedule C ON C.Pu_Id = D.Pu_Id AND C.Crew_Desc = @Crew_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
           AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
END
IF  @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL 
BEGIN
  If @MasterUnit IS NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT 
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                                Else D.End_Time
                              End
             , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id , D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4 , ps.Prod_Id , D.TEFault_Id, D.TEStatus_Id  
          FROM Timed_Event_Details D
          JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
          JOIN Crew_Schedule C ON C.Pu_Id = D.Pu_Id AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
    END
  Else  --@MasterUnit not NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT 
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                                Else D.End_Time
                              End
             , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id , D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4 , ps.Prod_Id , D.TEFault_Id, D.TEStatus_Id  
          FROM  Timed_Event_Details D
          JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
          JOIN Crew_Schedule C ON C.Pu_Id = D.Pu_Id AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
           AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
END
IF  @Crew_Desc Is NOT NULL AND @Shift_Desc Is NOT NULL 
BEGIN
  If @MasterUnit IS NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT 
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                                Else D.End_Time
                              End
             , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ps.Prod_Id, D.TEFault_Id, D.TEStatus_Id  
          FROM Timed_Event_Details D
          JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
          JOIN Crew_Schedule C ON C.Pu_Id = D.Pu_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
    END
  Else  --@MasterUnit not NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT 
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                                When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                                Else D.End_Time
                              End
             , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ps.Prod_Id, D.TEFault_Id, D.TEStatus_Id  
          FROM  Timed_Event_Details D
          JOIN #Prod_Starts ps ON ps.PU_Id = D.PU_Id AND (D.Start_Time < ps.End_Time OR ps.End_Time Is NULL) AND (D.End_Time > ps.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
          JOIN Crew_Schedule C ON C.Pu_Id = D.Pu_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
           AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
END
GOTO MAKE_DOWNTIME_SUMMARY_REPORT
/***********************************************************************************/
/***********************************************************************************/
APPLIED_PRODUCT_FILTER:
  BEGIN
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
        SELECT ps.pu_id, ps.Prod_Id, ps.Start_Time, ps.End_Time, [Minute_Difference] = NULL
          FROM Production_Starts ps
         WHERE (    ps.Start_Time BETWEEN @Start_Time AND @End_Time 
 	  	  OR ps.End_Time BETWEEN @Start_Time AND @End_Time 
 	  	  OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR End_Time Is NULL) ) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               )
       END
    Else --@MasterUnit NOT NULL
      BEGIN
        INSERT INTO #Prod_Starts
        SELECT ps.pu_id, ps.Prod_Id, ps.Start_Time, ps.End_Time, [Minute_Difference] = NULL
          FROM Production_Starts ps
         WHERE ps.pu_id = @MasterUnit 
 	    AND (    ps.Start_Time BETWEEN @Start_Time AND @End_Time
 	  	  OR ps.End_Time BETWEEN @Start_Time AND @End_Time
 	  	  OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR End_Time Is NULL) ) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               )
      END 
    --EndIf
  END
  UPDATE #Prod_Starts SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time              --Adjust start time to report start time as appropriate
  UPDATE #Prod_Starts SET End_Time = @End_Time WHERE End_Time > @End_Time OR End_Time IS NULL  --Adjust end time to report end time as appropriate
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
  	 INSERT INTO #AllEvents (Pu_Id, Start_Time, End_Time,Prod_Id)
      SELECT e.Pu_Id, e.Start_Time, e.TimeStamp, coalesce(e.Applied_Product,ps.prod_Id)
        FROM #Prod_Starts ps 
        JOIN Events e ON ps.Start_Time < e.TimeStamp AND ( ps.End_Time >= e.TimeStamp ) AND ps.Pu_Id = e.Pu_Id 
        LEFT JOIN #Products p on p.prod_id = e.Applied_Product
 	  	 Order By e.Pu_Id,e.TimeStamp 
 	 INSERT INTO @ProdUnits(PUId)
 	  	 SELECT Distinct Pu_Id FROM #Prod_Starts
    SET @Start = 1
    SELECT @End = COUNT(*) FROM @ProdUnits
    WHILE @Start <= @End
    BEGIN
 	  	 SELECT @CurrentPU = puid FROM @ProdUnits WHERE Id = @Start
 	  	 Select @CurrentEndTime = Null
 	  	 Select @CurrentEndTime = MAX(End_Time) FROM #AllEvents  WHERE PU_Id = @CurrentPU
 	  	 IF @CurrentEndTime IS Not Null
 	  	 BEGIN
 	  	  	 IF @CurrentEndTime < @End_Time 
 	  	  	 BEGIN
 	  	  	  	 SET @NextEnd = Null
 	  	  	  	 SELECT @NextEnd = Min(Timestamp)
 	  	  	  	  	 FROM Events  
 	  	  	  	  	 WHERE TimeStamp > @CurrentEndTime and PU_Id = @CurrentPU
 	  	  	  	 IF @NextEnd Is Not Null
 	  	  	  	 BEGIN
 	  	  	  	  	 INSERT INTO #AllEvents(Pu_Id, Start_Time, End_Time,Prod_Id)
 	  	  	  	  	  	 SELECT @CurrentPU,e.Start_Time,@NextEnd,prod_id
 	  	  	  	  	  	  	 FROM Events e 
 	  	  	  	  	  	  	 Join Production_Starts ps on ps.PU_Id = e.PU_Id and  
 	  	  	  	  	  	  	  	  	 ps.Start_Time < e.TimeStamp AND ( ps.End_Time >= e.TimeStamp  or  ps.End_Time Is Null)
 	  	  	  	  	  	  	 WHERE e.TimeStamp = @NextEnd and e.PU_Id = @CurrentPU
 	  	  	  	 END
 	  	  	 END
 	  	 END
 	  	 SET @Start = @Start + 1
    END
    SET @Start = 1
    SET @PrevEnd = Null
    SELECT @End = COUNT(*) FROM #AllEvents
    WHILE @Start <= @End
    BEGIN
 	  	 SELECT @CurrentStartTime = Start_Time,@CurrentEndTime = End_Time ,@CurrentPU = pu_id FROM #AllEvents WHERE Id = @Start
 	  	 IF @CurrentStartTime IS Null
 	  	 BEGIN
 	  	  	 Select @CurrentStartTime = Null
 	  	  	 Select @CurrentStartTime = MAX(Timestamp) 
 	  	  	  	 FROM Events  
 	  	  	  	 WHERE TimeStamp < @CurrentEndTime and PU_Id = @CurrentPU
 	  	  	 IF @CurrentStartTime Is Null SET @CurrentStartTime = DATEADD(MINUTE,-1,@CurrentEndTime)
 	  	  	 Update #AllEvents Set Start_Time = @CurrentStartTime Where Id = @Start
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 IF @PrevEnd Is Not Null 
 	  	  	 BEGIN
 	  	  	  	 IF @CurrentStartTime < @PrevEnd
 	  	  	  	  	 Update #AllEvents Set Start_Time = @PrevEnd Where Id = @Start
 	  	  	 END
 	  	  	 SET @PrevEnd = @CurrentEndTime
 	  	 END
 	  	 IF @CurrentStartTime is Not Null and @CurrentEndTime Is Not Null
 	  	 BEGIN
 	  	  	 DELETE FROM #AllEvents WHERE Start_Time > @CurrentStartTime and End_Time < @CurrentEndTime
 	  	 END
 	  	 SET @Start2 = Null
 	  	 SELECT @Start2 = MIN(ID) FROM #AllEvents WHERE id > @Start
 	  	 IF @Start2 Is Null
 	  	  	 SET @Start = @End + 1
 	  	 ELSE
 	  	  	 SET @Start = @Start2
    END
 	 UPDATE #AllEvents SET Start_Time = @Start_Time Where Start_Time < @Start_Time
 	 UPDATE #AllEvents SET end_Time = @End_Time Where end_Time > @End_Time
 	 INSERT INTO #Applied_Products ( Pu_Id, Start_Time, End_Time,Prod_Id)
 	   SELECT e.Pu_Id, e.Start_Time,  e.End_Time ,p.prod_id 
 	  	 FROM #AllEvents e 
 	  	 JOIN #Products p on p.prod_id = e.prod_id 
  SELECT @TotalProductOperating = SUM( DATEDIFF(second, Start_Time, End_Time) / 60.0  ) 
 	  	 FROM #Applied_Products  a 
  -- Insert Data Into Temp Table #TopNDR
IF  @Crew_Desc Is NULL AND @Shift_Desc Is NULL
BEGIN
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                   When ap.End_Time Is NULL Then D.End_Time
                                   When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ap.Prod_Id, ap.Applied_Prod_Id, D.TEFault_Id, D.TEStatus_Id
          FROM Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
           AND (D.Start_Time < ap.End_Time) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
      END
  Else    --@MasterUnit NOT NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                   When ap.End_Time Is NULL Then D.End_Time
                                   When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ap.Prod_Id, ap.Applied_Prod_Id, D.TEFault_Id, D.TEStatus_Id
          FROM  Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
           AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit
    END
END
IF  @Crew_Desc Is Not NULL AND @Shift_Desc Is NULL
BEGIN
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                   When ap.End_Time Is NULL Then D.End_Time
                                   When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ap.Prod_Id, ap.Applied_Prod_Id, D.TEFault_Id, D.TEStatus_Id
          FROM Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
           AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
      END
  Else    --@MasterUnit NOT NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                   When ap.End_Time Is NULL Then D.End_Time
                                   When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ap.Prod_Id, ap.Applied_Prod_Id, D.TEFault_Id, D.TEStatus_Id
          FROM  Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
           AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
           AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
END
IF  @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL
BEGIN
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                   When ap.End_Time Is NULL Then D.End_Time
                                   When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ap.Prod_Id, ap.Applied_Prod_Id, D.TEFault_Id, D.TEStatus_Id
          FROM Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
           AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
      END
  Else    --@MasterUnit NOT NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                   When ap.End_Time Is NULL Then D.End_Time
                                   When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ap.Prod_Id, ap.Applied_Prod_Id, D.TEFault_Id, D.TEStatus_Id
          FROM  Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
           AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
           AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
END
IF  @Crew_Desc Is Not NULL AND @Shift_Desc Is NOT NULL
BEGIN
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                   When ap.End_Time Is NULL Then D.End_Time
                                   When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ap.Prod_Id, ap.Applied_Prod_Id, D.TEFault_Id, D.TEStatus_Id
          FROM Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
           AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
      END
  Else    --@MasterUnit NOT NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, A1_Id, A2_Id, A3_Id, A4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case When D.End_Time Is NULL Then ap.End_Time
                                   When ap.End_Time Is NULL Then D.End_Time
                                   When ap.End_Time <= D.End_Time Then ap.End_Time Else D.End_Time End
             , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
             , D.Action_Level1, D.Action_Level2, D.Action_Level3, D.Action_Level4, ap.Prod_Id, ap.Applied_Prod_Id, D.TEFault_Id, D.TEStatus_Id
          FROM  Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
           AND (D.Start_Time < ap.End_Time OR ap.End_Time Is NULL) AND (D.End_Time > ap.Start_Time OR D.End_Time Is NULL)
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
          JOIN Crew_Schedule C ON C.PU_Id = D.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
           AND D.Start_Time < C.End_Time AND (D.End_Time > C.Start_Time OR D.End_Time Is NULL)
           AND (C.Start_Time < @End_Time AND C.End_Time > @Start_Time)                       --ECR #25517(mt/5-19-2003)
           AND C.PU_Id = @MasterUnit                                                         --ECR #25517(mt/5-19-2003)
         WHERE D.Start_Time < @End_Time AND ( D.End_Time > @Start_Time OR D.End_Time Is NULL )
           AND D.PU_Id = @MasterUnit 
    END
END
MAKE_DOWNTIME_SUMMARY_REPORT:
  --Clean up zero Pu_Id (comes from
  DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
 	 If @SelectSource Is NOT NULL      --@SelectSource = AddIn's Location
 	 BEGIN
 	   If @SelectSource = -1     --MSi/MT/4-11-2001: AddIn's "None" keyword; Want to retain NULL location, delete others
 	  	 DELETE FROM #TopNDR WHERE SourcePU Is NOT NULL
 	   Else
 	  	 DELETE FROM #TopNDR WHERE ( SourcePU Is NULL AND MasterUnit <> @PU_Id ) Or SourcePU <> @SelectSource  -- ECR #29652: mt/7-28-2005
 	 END  
  UPDATE #TopNDR  SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
  UPDATE #TopNDR  SET End_Time = @End_Time  WHERE End_Time > @End_Time OR End_Time Is NULL
  UPDATE #TopNDR  SET Duration = DATEDIFF(ss, Start_Time, End_Time) 	  / 60.0
 IF @NPT = 1
 BEGIN
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
 	  	 WHERE PU_Id = @PU_id  AND np.Start_Time < @End_time  AND np.End_Time > @Start_Time
END
 	 IF @IsAppliedProdFilter = 1
 	 BEGIN
 	  	 INSERT INTO @DataSlices(Start_Time,End_Time)
 	  	  	 SELECT Start_Time,End_Time FROM #Applied_Products
 	 END
 	 ELSE
 	 BEGIN
 	  	 INSERT INTO @DataSlices(Start_Time,End_Time)
 	  	  	 SELECT Start_Time,End_Time FROM #Prod_Starts
 	 END
 	 SET @NPTMinutes = 0
 	 SELECT @NPTMinutes = @NPTMinutes + DATEDIFF(second, a.Start_Time, a.End_Time)/ 60.0
 	  	 FROM @DataSlices a
 	  	 Join @Periods_NPT b ON b.StartTime <= a.Start_Time and b.EndTime >= a.End_Time
 	 SELECT @NPTMinutes = @NPTMinutes + DATEDIFF(second, a.Start_Time, b.EndTime)/ 60.0
 	  	 FROM @DataSlices a
 	  	 Join @Periods_NPT b ON b.StartTime < a.Start_Time and b.EndTime > a.Start_Time and (b.EndTime > a.Start_Time  and b.EndTime < a.End_Time)
 	 SELECT @NPTMinutes = @NPTMinutes + DATEDIFF(second, b.StartTime, a.End_Time)/ 60.0
 	  	 FROM @DataSlices a
 	  	 Join @Periods_NPT b ON  (b.StartTime < a.End_Time and b.StartTime > a.Start_Time) and b.EndTime > a.End_Time 
 	 SELECT @NPTMinutes = @NPTMinutes + DATEDIFF(second, b.StartTime, b.EndTime)/ 60.0 
 	  	 FROM @DataSlices a
 	  	 Join @Periods_NPT b ON  a.Start_Time <= b.StartTime and a.End_Time >= b.EndTime 
-- Case 1 :  Downtime     St-----------------------End
--                NPT   St-------------------------------End
DELETE  #TopNDR 
 	 FROM #TopNDR a
 	 Join @Periods_NPT b ON b.StartTime <= a.Start_Time and b.EndTime >= a.End_Time
 	   
-- Case 2 :  Downtime      St---------------------End
--                NPT   St--------------End
UPDATE #TopNDR SET Start_Time = b.EndTime,Duration = DATEDIFF(ss, b.EndTime, a.End_Time)/ 60.0
 	 FROM #TopNDR a
 	 Join @Periods_NPT b ON b.StartTime < a.Start_Time and (b.EndTime > a.Start_Time  and b.EndTime < a.End_Time)
-- Case 3 :  Downtime 	  	 St---------------------End
--                NPT                          St--------------End
UPDATE #TopNDR SET End_Time = b.StartTime,Duration = DATEDIFF(ss, a.Start_Time , b.StartTime ) 	  / 60.0
 	 FROM #TopNDR a
 	 Join @Periods_NPT b ON (b.StartTime < a.End_Time and b.StartTime > a.Start_Time) and b.EndTime > a.End_Time 
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
SELECT @TotalNPTMinutes = SUM(DateDiff(second,a.StartTime ,a.EndTime) / 60.0)
 	 FROM @Periods_NPT a
IF @TotalNPTMinutes IS NULL SET @TotalNPTMinutes = 0
IF @NPTMinutes IS NULL SET @NPTMinutes = 0
IF Not Exists(SELECT 1 FROM #TopNDR)
BEGIN
 	 SELECT ReasonName = PU_Desc
 	  	 , NumberOfOccurances = 0
 	  	 , TotalReasonMinutes = 0
 	  	 , AvgReasonMinutes = 0
 	  	 , TotalDowntimeMinutes = 0
 	  	 , AvgUptimeMinutes = 100.0
 	  	 , TotalUptimeMinutes = @TotalProductOperating  - @NPTMinutes  
 	  	 , TotalOperatingMinutes = DateDiff(second,@Start_Time,@End_Time) / 60.0  - @TotalNPTMinutes
 	  	 ,TotalProductOperatingMinutes =  @TotalProductOperating  - @NPTMinutes
 	 FROM Prod_Units 
 	 WHERE PU_Id = @PU_Id
END
ELSE
BEGIN
 	 UPDATE #TopNDR set UptimeOffOffset = 0
 	 SELECT @NumberOfOccurances = COUNT(Distinct Detail_Id),@TotalDowntimeMinutes = SUM(Duration)
 	  	 FROM #TopNDR
 	 UPDATE #TopNDR set UptimeOffOffset = -1 WHERE Start_Time = @Start_Time
 	 UPDATE #TopNDR set UptimeOffOffset = -1 WHERE End_Time = @End_Time
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
 	 SELECT @TotalOperatingMinutes = DateDiff(second,@Start_Time,@End_Time) / 60.0  - @TotalNPTMinutes
 	 SELECT @TotalProductOperating = @TotalProductOperating - @NPTMinutes
 	 SELECT @TotalUptimeMinutes = @TotalProductOperating - @TotalDowntimeMinutes
 	 SELECT ReasonName = D.Reason_Name
 	  	 , NumberOfOccurances = COUNT(Distinct Detail_Id)
 	  	 , TotalReasonMinutes = SUM(Duration) 
 	  	 , AvgReasonMinutes = SUM(Duration)/COUNT(Distinct Detail_Id)
 	  	 , TotalDowntimeMinutes = @TotalDowntimeMinutes
 	  	 , AvgUptimeMinutes = @TotalUptimeMinutes / ((@NumberOfOccurances + 1)+ SUM(UptimeOffOffset))
 	  	 , TotalUptimeMinutes = @TotalUptimeMinutes  
 	  	 , TotalOperatingMinutes = @TotalOperatingMinutes
 	  	 , TotalProductOperatingMinutes = @TotalProductOperating
 	 FROM #TopNDR D
 	 GROUP BY D.Reason_Name
 	 Order by TotalReasonMinutes desc
 END
DROP TABLE #TopNDR
DROP TABLE #Prod_Starts
DROP TABLE #Products
DROP TABLE #Applied_Products
--
