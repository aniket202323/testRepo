-- DESCRIPTION: spXLA_DowntimeDetail_AP() handle down time detail with original or applied product filter only. The No-Product 
-- specified call Will be handled by a separate stored procedure (spXLA_DowntimeDetail_NoProduct). MT/3-26-2002
-- Note: Added Uptime: MT/4-9-2002 (Updated Applied Product Cursor:MT/4-24-2002)
-- Defect #24434:9-6-2002:mt: When "Unit" is specified; Remove join predicate ps.PU_Id = D.Source_PU_Id (D=Timed_Event_Detail) 
-- join only on start & end times. When "unit" is not specified join ps.PU_Id = D.Pu_Id
--
CREATE PROCEDURE dbo.spXLA_DowntimeDetail_AP
 	   @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @PU_Id 	  	 Int 	  	 --Add-In;sUnit (which is MasterUnit)
 	 , @SelectSource 	  	 Int 	  	 -- 	  	  	  slave units
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @Prod_Id 	  	 Int 
 	 , @Group_Id 	  	 Int
 	 , @Prop_Id 	  	 Int
 	 , @Char_Id 	  	 Int
 	 , @TimeSort 	  	 TinyInt
 	 , @ShowProductCode 	 TinyInt  	 -- 1 = yes, show product code; 0 = no, don't show them
 	 , @IsAppliedProdFilter 	 TinyInt
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
 	 --Local query assistance
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
 	 --Downtime-Related Identifiers
DECLARE @MasterUnit  	  	 Int
DECLARE @Unit 	  	  	 Varchar(50)
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
If @PU_Id Is NULL SELECT @MasterUnit = NULL Else SELECT @MasterUnit = @PU_Id
--
--DECLARE @UserId 	 Int
--SELECT @UserId = User_Id
--FROM users
--WHERE Username = @Username
--
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
CREATE TABLE #Applied_Products (Pu_Id Int, Ps_Start_Time DateTime, Ps_End_Time DateTime NULL, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL, Keep_Event TinyInt NULL)
CREATE TABLE #Prod_Starts (PU_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Comments (Detail_Id Int, FirstComment Int NULL, LastComment Int NULL)
CREATE TABLE #TopNDR (
 	   Detail_Id 	  	 Int
 	 , Start_Time 	  	 DateTime
 	 , End_Time 	  	 DateTime NULL
  	 , Duration 	  	 real NULL
        , Uptime                Real NULL 	 --MT/4-9-2002
 	 , SourcePU 	  	 Int NULL
 	 , MasterUnit 	  	 Int NULL
 	 , R1_Id 	  	  	 Int NULL
 	 , R2_Id 	  	  	 Int NULL
 	 , R3_Id  	  	 Int NULL
 	 , R4_Id  	  	 Int NULL
 	 , Fault_Id  	  	 Int NULL
 	 , Status_Id  	  	 Int NULL
 	 , Prod_Id  	  	 Int NULL
        , Applied_Prod_Id 	 Int NULL
 	 , First_Comment_Id 	 Int NULL
 	 , Last_Comment_Id  	 Int NULL
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
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Get Product And Related Info from Production_Starts Table (NOTE: any product is a legitimate original product filter )
If @QueryType = @NoProductSpecified 	 --5
  BEGIN
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #prod_starts
          SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE Start_Time BETWEEN @Start_Time AND @End_Time
              OR End_Time BETWEEN @Start_Time AND @End_Time 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null)) 	 --MSi/MT/3-14-2001 	  	     
      END
    Else    --@MasterUnit not null
      BEGIN
        INSERT INTO #prod_starts
          SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
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
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time    
            FROM production_starts ps
           WHERE Prod_Id = @Prod_Id 
             AND (   (Start_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time is NULL))) --change Start_Time & End_Time conditions ; MSi/MT/3-14-2001
                 )  
      END
    Else     --@MasterUnit NOT NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
             AND Prod_Id = @Prod_Id 
             AND (   (Start_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time is NULL))) --change Start_Time & End_Time conditions ; MSi/MT/3-14-2001
                 )  
      END
    --EndIf @MasterUnit
  END
Else 	  	  	  	  	  	 --It is not a single Product
  BEGIN
    If @QueryType = @Group   	  	  	 --2
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id  FROM Product_Group_Data  WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @Characteristic  	 --3
      BEGIN
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id  FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else 	  	  	  	  	 --Group and Property  
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id  FROM Product_Group_Data WHERE product_grp_id = @Group_Id
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id FROM pu_characteristics  WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
            JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
 	    WHERE (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	       OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	       OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time is NULL)))
      END
    Else     --@MasterUnit NOT NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
            JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
           WHERE (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
 	      AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	  	    OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	  	    OR (Start_Time <= @Start_Time AND ((End_Time > @End_Time) OR (End_Time is NULL)))
                 )
      END
    --EndIf @MasterUnit is NULL 
  END
--EndIf =5 Fill Out Product-Related Temp Tables
-- Get All The Detail Records We Care About
-- Insert Data Into #TopNDR Temp Table
If @MasterUnit Is NULL
  BEGIN
    INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id, Prod_Id)
      SELECT DISTINCT 
             D.TEDEt_Id
           , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
           , [End_Time]   = Case 
                              When D.End_Time Is NULL Then ps.End_Time
                              When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                              When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                              Else D.End_Time
                            End
           , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.TEFault_Id, D.TEStatus_Id, ps.Prod_Id
        FROM Timed_Event_Details D
        JOIN #Prod_Starts ps ON ps.Pu_Id = D.PU_Id
         AND (    (D.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
               OR (D.End_Time > ps.Start_Time AND D.End_Time <= ps.End_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time <= ps.Start_Time AND (D.End_Time > ps.End_Time OR D.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time >= ps.Start_Time AND D.End_Time Is NULL AND ps.End_Time Is NULL) 
               OR (D.End_Time > ps.Start_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NULL)
             )
        JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
       WHERE D.Start_Time BETWEEN @Start_Time AND @End_Time
          OR D.End_Time BETWEEN @Start_Time AND @End_Time
          OR (D.Start_Time <= @Start_Time AND (D.End_Time > @End_Time OR D.End_Time Is NULL))
    END
Else    --@MasterUnit NOT NULL
  BEGIN
    INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id, Prod_Id)
      SELECT DISTINCT
             D.TEDEt_Id
           , [Start_Time] = Case When D.Start_Time <= ps.Start_Time Then ps.Start_Time Else D.Start_Time End
           , [End_Time]   = Case 
                              When D.End_Time Is NULL Then ps.End_Time
                              When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                              When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                              Else D.End_Time
                            End
           , D.Duration, D.Uptime, D.Source_PU_Id, PU.PU_Id, D.Reason_Level1, D.Reason_Level2,D.Reason_Level3,D.Reason_Level4, D.TEFault_Id, D.TEStatus_Id, ps.Prod_Id
        FROM  Timed_Event_Details D
        /* Remove ps.Pu_Id = D.Source_PU_Id mt/9-6-2002: This join predicate doesn't exist in original spXLA_DowntimeDetail
        JOIN #Prod_Starts ps ON ps.Pu_Id = D.Source_PU_Id
         AND (    (D.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
               OR (D.End_Time > ps.Start_Time AND D.End_Time <= ps.End_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time <= ps.Start_Time AND (D.End_Time > ps.End_Time OR D.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time >= ps.Start_Time AND D.End_Time Is NULL AND ps.End_Time Is NULL) 
               OR (D.End_Time > ps.Start_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NULL)
             )
         */
        JOIN #Prod_Starts ps ON 
             (    (D.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
               OR (D.End_Time > ps.Start_Time AND D.End_Time <= ps.End_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time <= ps.Start_Time AND (D.End_Time > ps.End_Time OR D.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time >= ps.Start_Time AND D.End_Time Is NULL AND ps.End_Time Is NULL) 
               OR (D.End_Time > ps.Start_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NULL)
             )
        JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
       WHERE D.PU_Id = @MasterUnit 
         AND (    D.Start_Time BETWEEN @Start_Time AND @End_Time
               OR D.End_Time BETWEEN @Start_Time AND @End_Time
               OR (D.Start_Time <= @Start_Time AND (D.End_Time > @End_Time OR D.End_Time Is NULL))
             )
  END
--EndIf @MasterUnit
-- Clean up unwanted PU_Id = 0 (marked for unused/obsolete)
DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
--Delete Rows that don't match Additional Selection Criteria
If @SelectSource Is NOT NULL 	 --@SelectSource Is Location in Proficy AddIn
  BEGIN 	 
    If @SelectSource = -1 	 --MSi/MT/4/11/01:AddIn's "None" location=>to retain only NULL locations, delete others
      DELETE FROM #TopNDR WHERE SourcePU Is NOT NULL
    Else
      DELETE FROM #TopNDR WHERE (SourcePU Is NULL AND MasterUnit <> @PU_Id) OR SourcePU <> @SelectSource
    --EndIf
  END
--EndIf @SelectSource ...
If @SelectR1 Is NOT NULL  DELETE FROM #TopNDR WHERE R1_Id Is NULL Or R1_Id <> @SelectR1  
If @SelectR2 Is NOT NULL  DELETE FROM #TopNDR WHERE R2_Id Is NULL Or R2_Id <> @SelectR2
If @SelectR3 Is NOT NULL  DELETE FROM #TopNDR WHERE R3_Id Is NULL Or R3_Id <> @SelectR3
If @SelectR4 Is NOT NULL  DELETE FROM #TopNDR WHERE R4_Id Is NULL Or R4_Id <> @SelectR4
-- Update Temp Table #TopNDR
 	 -- Take Care Of Record Start And End Times 
UPDATE #TopNDR SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
UPDATE #TopNDR SET End_Time = @End_Time WHERE End_Time > @End_Time OR End_Time is NULL
UPDATE #TopNDR SET Duration = DATEDIFF(ss, Start_Time, End_Time) / 60.0
 	 --Get First And Last Comment
INSERT INTO #Comments
    SELECT D.Detail_Id,  min(C.WTC_ID), max(C.WTC_ID)
      FROM #TopNDR D, Waste_n_Timed_Comments C
     WHERE C.WTC_Source_Id = D.Detail_Id AND C.WTC_Type = 2
  GROUP BY D.Detail_Id   
UPDATE #TopNDR 
    SET First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
   FROM #TopNDR D, #Comments C 
  WHERE D.Detail_Id = C.Detail_Id 
-- RETURN DATA
If @MasterUnit Is NOT NULL SELECT @Unit = PU_Desc FROM Prod_Units WHERE PU_Id = @MasterUnit
 	 --(If "Unit" (master unit) is specified, we'll need its description)
If @ShowProductCode = 0 GOTO GET_DOWNTIME_DETAIL_WITHOUT_PRODUCT_CODE
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @TimeSort = 1
  If @MasterUnit Is NULL
    BEGIN
        SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
             , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
             , D.Duration
             , D.Uptime
             , P.Prod_Code
             , Unit 	 = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
 	  	  	     -- [When Master Unit is SourcePu we will report it as a location]
             , Location 	 = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
             , Reason1 	 = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2 	 = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
             , Reason3 	 = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4 	 = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , Fault 	 = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
             , Status 	 = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
             , D.First_Comment_Id
             , D.Last_Comment_Id
          FROM #TopNDR D
          JOIN Products P on P.Prod_Id = D.Prod_Id
          LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
          LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL) 	 --
          LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
          LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
          LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
      ORDER BY D.Start_Time ASC
    END
  Else    --@MasterUnit specified; don't need line
    BEGIN
        SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
             , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
             , D.Duration
             , D.Uptime
             , P.Prod_Code
             , Unit     = @Unit
 	  	  	     -- [When Master Unit is SourcePu we will report it as a location]
             , Location = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
             , Reason1  = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2  = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
             , Reason3  = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4  = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , Fault    = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
             , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
             , D.First_Comment_Id
             , D.Last_Comment_Id
          FROM #TopNDR D
          JOIN Products P on P.Prod_Id = D.Prod_Id
          LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
          LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
          LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
          LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
      ORDER BY D.Start_Time ASC
    END
  --EndIf @MasterUnit
Else   -- Descending
  If @MasterUnit Is NULL
    BEGIN
        SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
             , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
             , D.Duration
             , D.Uptime
             , P.Prod_Code
             , Unit 	 = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
 	  	  	 -- [When Master Unit is SourcePu we will report it as a location]
             , Location 	 = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
             , Reason1 	 = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2 	 = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
             , Reason3 	 = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4 	 = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , Fault 	 = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
             , Status 	 = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
             , D.First_Comment_Id
             , D.Last_Comment_Id
          FROM #TopNDR D
          JOIN Products P on P.Prod_Id = D.Prod_Id
          LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
          LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
          LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)          
          LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
          LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
          LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
      ORDER BY D.Start_Time DESC
    END
  Else    --@MasterUnit specified
    BEGIN
        SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
             , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
             , D.Duration
             , D.Uptime
             , P.Prod_Code
             , Unit     = @Unit
 	  	  	     -- [When Master Unit is SourcePu we will report it as a location]
             , Location = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
             , Reason1  = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
             , Reason2  = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
             , Reason3  = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
             , Reason4  = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
             , Fault    = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
             , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
             , D.First_Comment_Id
             , D.Last_Comment_Id
          FROM #TopNDR D
          JOIN  Products P on P.Prod_Id = D.Prod_Id
          LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
          LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
          LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
          LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
          LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
      ORDER BY D.Start_Time DESC
    END
  --EndIf @MasterUnit
--EndIf @TimeSort...
GOTO DROP_TEMP_TABLES
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
APPLIED_PRODUCT_FILTER:
  --SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
  --Get all relevant products and info from production_Start table
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #prod_starts
        SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
          FROM production_starts ps
         WHERE Start_Time BETWEEN @Start_Time AND @End_Time
            OR End_Time BETWEEN @Start_Time AND @End_Time 
            OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null))
    END
  Else    --@MasterUnit not null
    BEGIN
      INSERT INTO #prod_starts
        SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
          FROM production_starts ps
         WHERE (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
           AND (    Start_Time BETWEEN @Start_Time AND @End_Time 
                 OR End_Time BETWEEN @Start_Time AND @End_Time 
                 OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null))
               )     --change Start_Time & End_Time conditions ; MSi/MT/3-14-2001
    END
  --EndIf @MasterUnit
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
  --  NOTE1: JOIN condition for Production_Starts consistent with AutoLog's )
  --  NOTE2: As of 3-25-2002 MSI Start_Time inEvents table are mostly null. This storec procedure will insert
  --         a dummy value of TimeStamp minus one second for null Start_Time. For Customers who are concern about correct 
  --         Start_Time, which affect correct time-dependent results, MSI will give them a script for one-time update of 
  --         the Events table. This update is time/disk-space consuming, thus, available upon request only.
  --Make TEMP TABLE: Split ANY PRODUCT In #Prod_Starts into individual events.
  INSERT INTO #Applied_Products ( Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id )
      SELECT e.Pu_Id, ps.Start_Time, ps.End_Time, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product 
        FROM #Prod_Starts ps 
        JOIN Events e ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
--        JOIN Events e ON ps.Start_Time <= e.Start_Time AND (ps.End_Time >= e.TimeStamp OR ps.End_Time Is NULL)
         AND ps.Pu_Id = e.Pu_Id 
    ORDER BY e.Pu_Id, ps.Start_Time, e.Start_Time, ps.Prod_Id
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
          OR ( @Previous_Prod_Id = @@Prod_Id AND @Prev_Ps_Start_Time <> @@Ps_Start_Time AND (@Prev_Ps_End_Time <> @@Ps_End_Time OR @Prev_Ps_End_Time Is NULL Or @@Ps_End_Time Is NULL) )
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
  -- Insert The Detail Records We Care About Into #TopNDR Temp Table
  --
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id, Prod_Id, Applied_Prod_Id)
        SELECT D.TEDEt_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ap.End_Time
                                When ap.End_Time Is NOT NULL AND ap.End_Time <= D.End_Time Then ap.End_Time
                                When ap.End_Time Is NOT NULL AND D.End_Time <= ap.End_Time Then D.End_Time
                                Else D.End_Time 
                              End
             , D.Duration , D.Uptime , D.Source_PU_Id , PU.PU_Id , D.Reason_Level1 , D.Reason_Level2 , D.Reason_Level3
             , D.Reason_Level4 , TEFault_Id , TEStatus_Id , ap.Prod_Id , ap.Applied_Prod_Id
          FROM Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.Pu_Id = D.PU_Id
           AND (    (D.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
                 OR (D.End_Time > ap.Start_Time AND D.End_Time <= ap.End_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time <= ap.Start_Time AND (D.End_Time > ap.End_Time OR D.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time >= ap.Start_Time AND D.End_Time Is NULL AND ap.End_Time Is NULL) 
                 OR (D.End_Time > ap.Start_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NULL)
               )
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)
         WHERE D.Start_Time BETWEEN @Start_Time AND @End_Time
            OR D.End_Time BETWEEN @Start_Time AND @End_Time
            OR (D.Start_Time <= @Start_Time AND (D.End_Time > @End_Time OR D.End_Time Is NULL))
      END
  Else    --@MasterUnit NOT NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Fault_Id, Status_Id, Prod_Id, Applied_Prod_Id)
        SELECT D.TEDEt_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ap.End_Time
                                When ap.End_Time Is NOT NULL AND ap.End_Time <= D.End_Time Then ap.End_Time
                                When ap.End_Time Is NOT NULL AND D.End_Time <= ap.End_Time Then D.End_Time
                                Else D.End_Time 
                              End
             , D.Duration , D.Uptime , D.Source_PU_Id , PU.PU_Id , D.Reason_Level1 , D.Reason_Level2 , D.Reason_Level3
             , D.Reason_Level4 , TEFault_Id , TEStatus_Id , ap.Prod_Id , ap.Applied_Prod_Id
          FROM Timed_Event_Details D
          /* MT/9-6-2002:Remove the predicate ap.Pu_Id = D.Source_PU_Id: not in original spXLA_DowntimeDetail
          JOIN #Applied_Products ap ON ap.Pu_Id = D.Source_PU_Id
           AND (    (D.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
                 OR (D.End_Time > ap.Start_Time AND D.End_Time <= ap.End_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time <= ap.Start_Time AND (D.End_Time > ap.End_Time OR D.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time >= ap.Start_Time AND D.End_Time Is NULL AND ap.End_Time Is NULL) 
                 OR (D.End_Time > ap.Start_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NULL)
               )
           */
          JOIN #Applied_Products ap ON 
               (    (D.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
                 OR (D.End_Time > ap.Start_Time AND D.End_Time <= ap.End_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time <= ap.Start_Time AND (D.End_Time > ap.End_Time OR D.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time >= ap.Start_Time AND D.End_Time Is NULL AND ap.End_Time Is NULL) 
                 OR (D.End_Time > ap.Start_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NULL)
               )
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
         WHERE D.PU_Id = @MasterUnit 
           AND (    D.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR D.End_Time BETWEEN @Start_Time AND @End_Time
                 OR (D.Start_Time <= @Start_Time AND (D.End_Time > @End_Time OR D.End_Time Is NULL))
               )
    END
  --EndIf @MasterUnit
  -- Clean up unwanted PU_Id = 0 (marked for unused/obsolete)
  DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
  --Delete Rows that don't match Additional Selection Criteria
  If @SelectSource Is NOT NULL  --@SelectSource = AddIn's locations
    BEGIN
      If @SelectSource = -1 --MSi/MT/4/11/01:AddIn's "None" location=>to retain only NULL locations, delete others
        DELETE FROM #TopNDR WHERE SourcePU Is NOT NULL
      Else
        DELETE FROM #TopNDR WHERE (SourcePU Is NULL AND MasterUnit <> @PU_Id) OR SourcePU <> @SelectSource
      --EndIf
    END
  --EndIf @SelectSource ...
  If @SelectR1 Is NOT NULL  DELETE FROM #TopNDR WHERE R1_Id Is NULL Or R1_Id <> @SelectR1
  If @SelectR2 Is NOT NULL  DELETE FROM #TopNDR WHERE R2_Id Is NULL Or R2_Id <> @SelectR2
  If @SelectR3 Is NOT NULL  DELETE FROM #TopNDR WHERE R3_Id Is NULL Or R3_Id <> @SelectR3
  If @SelectR4 Is NOT NULL  DELETE FROM #TopNDR WHERE R4_Id Is NULL Or R4_Id <> @SelectR4
  -- Update Temp Table #TopNDR
    -- Take Care Of Record Start And End Times
  UPDATE #TopNDR SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
  UPDATE #TopNDR SET End_Time = @End_Time WHERE End_Time > @End_Time OR End_Time is NULL
  UPDATE #TopNDR SET Duration = DATEDIFF(ss, Start_Time, End_Time) / 60.0
    --Get First And Last Comment
  INSERT INTO #Comments
      SELECT D.Detail_Id,  min(C.WTC_ID), max(C.WTC_ID)
        FROM #TopNDR D, Waste_n_Timed_Comments C
       WHERE C.WTC_Source_Id = D.Detail_Id And C.WTC_Type = 2
    GROUP BY D.Detail_Id
  UPDATE #TopNDR
      SET First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End)
     FROM #TopNDR D, #Comments C
    WHERE D.Detail_Id = C.Detail_Id
  -- Retrieve RecordSet based on passed in paramters
  --
  If @MasterUnit Is NOT NULL SELECT @Unit = PU_Desc FROM Prod_Units WHERE PU_Id = @MasterUnit
 	 --(If "Unit" (master unit) is specified, we'll need its description)
  If @ShowProductCode = 0 GOTO GET_DOWNTIME_DETAIL_WITHOUT_PRODUCT_CODE
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @TimeSort = 1
    If @MasterUnit Is NULL
      BEGIN
            SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
               , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
               , D.Duration
               , D.Uptime
               , Prod_Code = p.Prod_Code
               , Applied_Prod_Code = p2.Prod_Code
               , Unit     = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
 	    	  	     -- [When Master Unit is SourcePu we will report it as a location]
               , Location = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
               , Reason1  = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2  = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3  = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4  = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
               , Fault    = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
               , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
               , D.First_Comment_Id
               , D.Last_Comment_Id
            FROM #TopNDR D
            LEFT OUTER JOIN Products p ON p.Prod_Id = D.Prod_Id
            LEFT OUTER JOIN Products p2 ON p2.Prod_Id = D.Applied_Prod_Id
            LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
            LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL) 	 --
            LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
            LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
            LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
        ORDER BY D.Start_Time ASC
      END
    Else    --@MasterUnit specified; don't need line
      BEGIN
          SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
               , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
               , D.Duration
               , D.Uptime
               , Prod_Code = p.Prod_Code
               , Applied_Prod_Code = p2.Prod_Code
               , Unit     = @Unit
 	    	  	     -- [When Master Unit is SourcePu we will report it as a location]
               , Location = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
               , Reason1  = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2  = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3  = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4  = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
               , Fault    = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
               , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
               , D.First_Comment_Id
               , D.Last_Comment_Id
            FROM #TopNDR D
            LEFT OUTER JOIN Products p ON p.Prod_Id = D.Prod_Id
            LEFT OUTER JOIN Products p2 ON p2.Prod_Id = D.Applied_Prod_Id
            LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
            LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
            LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
            LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
        ORDER BY D.Start_Time ASC
      END
    --EndIf @MasterUnit
  Else   -- Descending
    If @MasterUnit Is NULL
      BEGIN
          SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
               , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
               , D.Duration
               , D.Uptime
               , Prod_Code = p.Prod_Code
               , Applied_Prod_Code = p2.Prod_Code
               , Unit     = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
 	  	    	 -- [When Master Unit is SourcePu we will report it as a location]
               , Location = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
               , Reason1  = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2  = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3  = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4  = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
               , Fault    = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
               , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
               , D.First_Comment_Id
               , D.Last_Comment_Id
            FROM #TopNDR D
            LEFT OUTER JOIN Products p ON p.Prod_Id = D.Prod_Id
            LEFT OUTER JOIN Products p2 ON p2.Prod_Id = D.Applied_Prod_Id
            LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
            LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
            LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)          
            LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
            LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
            LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
        ORDER BY D.Start_Time DESC
      END
    Else    --@MasterUnit specified
      BEGIN
          SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
               , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
               , D.Duration
               , D.Uptime
               , Prod_Code = p.Prod_Code
               , Applied_Prod_Code = p2.Prod_Code
               , Unit     = @Unit
 	  	    	     -- [When Master Unit is SourcePu we will report it as a location]
               , Location = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
               , Reason1  = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2  = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3  = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4  = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
               , Fault    = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
               , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
               , D.First_Comment_Id
               , D.Last_Comment_Id
            FROM #TopNDR D
            LEFT OUTER JOIN Products p ON p.Prod_Id = D.Prod_Id
            LEFT OUTER JOIN Products p2 ON p2.Prod_Id = D.Applied_Prod_Id
            LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
            LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
            LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
            LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
        ORDER BY D.Start_Time DESC
      END
    --EndIf @MasterUnit
  --EndIf @TimeSort...
  GOTO DROP_TEMP_TABLES
-- FINAL RETRIEVE WITHOUT PRODUCT CODES -- FINAL RETRIEVE WITHOUT PRODUCT CODES -- FINAL RETRIEVE WITHOUT PRODUCT CODES -- 
GET_DOWNTIME_DETAIL_WITHOUT_PRODUCT_CODE:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @TimeSort = 1
    If @MasterUnit Is NULL
      BEGIN
            SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
               , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
               , D.Duration
               , D.Uptime 	 --MT/4-9-2002
               , Unit 	 = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
 	    	  	     -- [When Master Unit is SourcePu we will report it as a location]
               , Location 	 = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
               , Reason1 	 = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2 	 = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3 	 = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4 	 = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
               , Fault 	 = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
               , Status 	 = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
               , D.First_Comment_Id
               , D.Last_Comment_Id
            FROM #TopNDR D
            LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
            LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL) 	 --
            LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
            LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
            LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
        ORDER BY D.Start_Time ASC
      END
    Else    --@MasterUnit specified; don't need line
      BEGIN
          SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
               , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
               , D.Duration
               , D.Uptime 	 --MT/4-9-2002
               , Unit     = @Unit
 	    	  	     -- [When Master Unit is SourcePu we will report it as a location]
               , Location = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
               , Reason1  = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2  = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3  = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4  = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
               , Fault    = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
               , Status   = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
               , D.First_Comment_Id
               , D.Last_Comment_Id
            FROM #TopNDR D
            LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's can be master and slave
            LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
            LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
            LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
        ORDER BY D.Start_Time ASC
      END
    --EndIf @MasterUnit
  Else   -- Descending
    If @MasterUnit Is NULL
      BEGIN
          SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
               , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
               , D.Duration
               , Unit 	 = Case When D.MasterUnit Is NULL Then @Unspecified Else PU2.PU_Desc End
 	  	    	 -- [When Master Unit is SourcePu we will report it as a location]
               , Location 	 = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
               , Reason1 	 = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2 	 = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3 	 = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4 	 = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
               , Fault 	 = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
               , Status 	 = Case When D.Status_Id Is NULL Then @Unspecified Else S.TEStatus_Name End
               , D.First_Comment_Id
               , D.Last_Comment_Id
            FROM #TopNDR D
            LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
            LEFT OUTER JOIN Prod_Units PU2 ON (D.MasterUnit = PU2.PU_Id AND PU2.Master_Unit Is NULL)
            LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)          
            LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
            LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
            LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
        ORDER BY D.Start_Time DESC
      END
    Else    --@MasterUnit specified
      BEGIN
          SELECT [Start_Time] = D.Start_Time at time zone @DBTz at time zone @InTimeZone
               , [End_Time] = D.End_Time at time zone @DBTz at time zone @InTimeZone
               , D.Duration
               , Unit     = @Unit
 	  	    	     -- [When Master Unit is SourcePu we will report it as a location]
               , Location = Case When D.SourcePU Is NULL Then @Unspecified Else PU.PU_Desc End
               , Reason1  = Case When D.R1_Id Is NULL Then @Unspecified Else R1.Event_Reason_Name End
               , Reason2  = Case When D.R2_Id Is NULL Then @Unspecified Else R2.Event_Reason_Name End
               , Reason3  = Case When D.R3_Id Is NULL Then @Unspecified Else R3.Event_Reason_Name End
               , Reason4  = Case When D.R4_Id Is NULL Then @Unspecified Else R4.Event_Reason_Name End
               , Fault    = Case When D.Fault_Id Is NULL Then @Unspecified Else F.TEFault_Name End
               , Status   = Case When D.Status_Id Is Null Then @Unspecified Else S.TEStatus_Name End
               , D.First_Comment_Id
               , D.Last_Comment_Id
            FROM #TopNDR D
            LEFT OUTER JOIN Prod_Units PU on (D.SourcePu = PU.PU_Id) 	  	 --SourcePU's contain both masters and slaves
            LEFT OUTER JOIN Event_Reasons R1 on (D.R1_Id = R1.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R2 on (D.R2_Id = R2.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R3 on (D.R3_Id = R3.Event_Reason_Id)
            LEFT OUTER JOIN Event_Reasons R4 on (D.R4_Id = R4.Event_Reason_Id)
            LEFT OUTER JOIN Timed_Event_Fault F on (D.Fault_Id = F.TEFault_Id)
            LEFT OUTER JOIN Timed_Event_Status S on (D.Status_Id = S.TEStatus_Id)
        ORDER BY D.Start_Time DESC
      END
    --EndIf @MasterUnit
  --EndIf @TimeSort...
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  --SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
  DROP TABLE #TopNDR
  DROP TABLE #Products
  DROP TABLE #Prod_Starts
  DROP TABLE #Comments
  DROP TABLE #Applied_Products
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
