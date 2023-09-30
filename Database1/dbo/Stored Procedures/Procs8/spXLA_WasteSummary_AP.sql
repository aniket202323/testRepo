-- DESCRIPTION: spXLA_WasteSummary_AP handles original or applied product filter. Any product (product not specified) is not
-- a valid option for applied product. No product specified is handled by a separate stored procedure (spXLA_WasteSummary_NoProduct)
-- MT/3-26-2002
--
-- ECR #27198(mt/12-22-2003): Perfomance tuning; drop hinting from Waste_Event_Details in the join clause; add hinting to Events in the from clause
--
CREATE PROCEDURE dbo.spXLA_WasteSummary_AP
 	   @Start_Time  	  	 DateTime
 	 , @End_Time  	  	 DateTime
 	 , @Pu_Id  	  	 Int
 	 , @SelectSource 	  	 Int
 	 , @SelectR1  	  	 Int
 	 , @SelectR2  	  	 Int
 	 , @SelectR3  	  	 Int
 	 , @SelectR4  	  	 Int
 	 , @ReasonLevel  	  	 Int
 	 , @Prod_Id  	  	 Int
 	 , @Group_Id  	  	 Int
 	 , @Prop_Id  	  	 Int
 	 , @Char_Id  	  	 Int
 	 , @IsAppliedProdFilter 	 TinyInt 	 --1 = Yes, filter by applied product; 0 = No, filter by original product
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
--SET NOCOUNT ON 	 disabled 10-27-2004:mt ECR #28901 to comply with MSI Multilinugal design
 	 --Local query assistance
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
DECLARE @Unspecified varchar(50)
 	 --Waste-Related identifiers
DECLARE @TotalWaste  	  	 real
DECLARE @TotalOperating  	 real
DECLARE @MasterUnit  	  	 Int
SELECT @MasterUnit = @Pu_Id
CREATE TABLE #Prod_Starts (Pu_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Applied_Products_From_Events(Pu_Id Int, Event_Id Int, TimeStamp DateTime)
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--
--SELECT @Unspecified = dbo.fnDBTranslate(@LangId, 38333, 'Unspecified')
CREATE TABLE #MyReport (  
    ReasonName  	  	 varchar(100) 	 --Changed from 30 to 100 chars
  , NumberOfOccurances  	 Int NULL
  , TotalReasonUnits  	 real NULL
  , AvgReasonUnits  	 real NULL
  , TotalWasteUnits  	 real NULL
  , TotalOperatingUnits real NULL
)
CREATE TABLE #TopNDR (
    TimeStamp 	 DateTime
  , Amount real NULL
  , Reason_Name varchar(100) NULL
  , SourcePU  	 Int NULL
  , R1_Id  	 Int NULL
  , R2_Id  	 Int NULL
  , R3_Id  	 Int NULL
  , R4_Id  	 Int NULL
  , Type_Id  	 Int NULL
  , Meas_Id  	 Int NULL
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
    INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
     WHERE Pu_Id = @MasterUnit 
       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
             OR (End_Time BETWEEN @Start_Time AND @End_Time) 
             OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
           )   --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  END
Else If @QueryType = @SingleProduct 	 --1
  BEGIN
    INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
     WHERE Pu_Id = @MasterUnit 
       AND Prod_Id = @Prod_Id 
       AND (   (Start_Time BETWEEN @Start_Time AND @End_Time)
             OR (End_Time BETWEEN @Start_Time AND @End_Time) 
             OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
           )   --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  END
Else 	  	  	  	  	 --Not a single product
  BEGIN
    --CREATE TABLE #Products (Prod_Id Int)
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
    INSERT INTO #Prod_Starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM production_starts ps
        JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
       WHERE Pu_Id = @MasterUnit 
         AND (   (Start_Time BETWEEN @Start_Time AND @End_Time) 
              OR (End_Time BETWEEN @Start_Time AND @End_Time) 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
             )  --Start_time & End_time condition checked ; MSi/MT/3-21-2001
    --DROP TABLE #Products
  END
--End If @QueryType
-- Insert relevant Waste Information Into TopNDR Temp Table
 	 -- Get All The Event Based Waste (Get TimeStamp from Events Table)
INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
  SELECT ev.TimeStamp
       , D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
       , D.WET_Id, D.WEMT_Id
    FROM Events ev 
    --{ ECR #27198(mt/12-22-2003)
    JOIN Waste_Event_Details D ON D.Event_Id = ev.Event_Id
    --}
    JOIN #Prod_Starts ps ON ps.Start_Time <= ev.TimeStamp AND (ps.End_Time > ev.TimeStamp OR ps.End_Time Is NULL) 
   WHERE ev.Pu_Id = @Pu_Id AND ev.TimeStamp > @Start_Time AND ev.TimeStamp <= @End_Time   
         --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	 -- Get All The Time Based Waste (Get TimeStamp from Wast_Event_Details Table)
INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
  SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
       , D.WET_Id, D.WEMT_Id  
    FROM Waste_Event_Details D WITH (INDEX(WEvent_Details_IDX_PUIdTime)) 
    JOIN #Prod_Starts ps ON ps.Start_Time <= D.TimeStamp AND (ps.End_Time > D.TimeStamp OR ps.End_Time Is NULL)
   WHERE D.Pu_Id = @Pu_Id AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
        --Start_time & End_time condition checked ; MSi/MT/3-21-2001 [Bug in Prev Summary: "Event_Id Is NULL" missing ]
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
  --SET NOCOUNT ON disabled 10-27-2004:mt ECR #28901 to comply with MSI Multilinugal design
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
      SELECT e.Pu_Id, e.Event_Id, e.TimeStamp
        FROM Events e
        JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NOT NULL
    UNION
      SELECT e.Pu_Id, e.Event_Id, e.TimeStamp
        FROM Events e
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NULL
        JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
  -- Insert Waste Data Into Temp Table
     -- Get All The Event-Based Waste (Get TimeSTamp from Events Table VIA Temp Table)
  INSERT INTO #TopNDR (TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
    SELECT ap.TimeStamp
         , D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
         , D.WET_Id, D.WEMT_Id
      FROM #Applied_Products_From_Events ap 
      --{ ECR #27198(mt/12-22-2003)
      JOIN Waste_Event_Details D ON D.Event_Id = ap.Event_Id
      --}
     WHERE ap.Pu_Id = @Pu_Id AND ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time   
     -- Get All The Time-Based Waste (Get TimeStamp from Waste_Event_Details Table)
  INSERT INTO #TopNDR (TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id)
    SELECT D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4
         , D.WET_Id, D.WEMT_Id  
      FROM Waste_Event_Details D WITH (INDEX(WEvent_Details_IDX_PUIdTime)) 
      JOIN #Applied_Products_From_Events ap ON ap.TimeStamp = D.TimeStamp
     WHERE D.Pu_Id = @Pu_Id AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL
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
  -- Calculate Total Waste
  SELECT @TotalWaste = (SELECT Sum(Amount) FROM #TopNDR) 
  --Go And Get Total Production For Time Period
  SELECT @TotalOperating = 0
  --SELECT @TotalOperating = NULL
  SELECT @TotalOperating = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0) - @TotalOperating
  --Delete Rows that donot match Additional Selection Criteria
  If @SelectSource Is NOT NULL 	 DELETE FROM #TopNDR WHERE SourcePU Is NULL OR SourcePU <> @SelectSource
  If @SelectR1 Is NOT NULL 	 DELETE FROM #TopNDR WHERE R1_Id Is NULL OR R1_Id <> @SelectR1  
  If @SelectR2 Is NOT NULL 	 DELETE FROM #TopNDR WHERE R2_Id Is NULL OR R2_Id <> @SelectR2
  If @SelectR3 Is NOT NULL 	 DELETE FROM #TopNDR WHERE R3_Id Is NULL OR R3_Id <> @SelectR3
  If @SelectR4 Is NOT NULL 	 DELETE FROM #TopNDR WHERE R4_Id Is NULL OR R4_Id <> @SelectR4
  UPDATE #TopNDR 
    SET Reason_Name = 
      Case @ReasonLevel
        When 0 Then PU.PU_Desc
        When 1 Then R1.Event_Reason_Name
        When 2 Then R2.Event_Reason_Name
        When 3 Then R3.Event_Reason_Name
        When 4 Then R4.Event_Reason_Name
        When 5 Then T.WET_Name
        When 6 Then M.WEMT_Name
      End
    FROM #TopNDR 
    LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
    LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
    LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
    LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
  UPDATE #TopNDR 
    SET Reason_Name = @Unspecified  WHERE Reason_Name Is NULL
  -- Populate Temp Table With Reason
  INSERT INTO #MyReport (ReasonName, NumberOfOccurances, TotalReasonUnits, AvgReasonUnits, TotalWasteUnits, TotalOperatingUnits)
    SELECT Reason_Name, COUNT(Amount), Total_Amount = SUM(Amount),  (SUM(Amount) / COUNT(Amount)), @TotalWaste, @TotalOperating
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
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
