-- DESCRIPTION: spXLA_WasteDetail_AP_NPT handles original and applied product filter. Any product (no product 
-- information specified) is not a valid option for applied product. No product specified is handled by a separate stored
-- procedure (spXLA_WasteDetail_AP_NPT_NoProduct). MT/3-26-2002
-- ECR #29673: mt/5-3-2005 -- Amount as additional sort criteria in return result set 
CREATE PROCEDURE dbo.spXLA_WasteDetail_AP_NPT
 	   @Start_Time  	  	 DateTime
 	 , @End_Time  	  	 DateTime
 	 , @Pu_Id  	  	 Int
 	 , @SelectSource  	 Int
 	 , @SelectR1  	  	 Int
 	 , @SelectR2  	  	 Int
 	 , @SelectR3  	  	 Int
 	 , @SelectR4  	  	 Int
 	 , @Prod_Id 	  	 Int
 	 , @Group_Id  	  	 Int
 	 , @Prop_Id  	  	 Int
 	 , @Char_Id 	  	 Int
 	 , @TimeSort  	  	 TinyInt = NULL
 	 , @ShowProductCode 	 TinyInt  	 -- 1 = yes, show product code; 0 = no, don't show them
 	 , @IsAppliedProdFilter 	 TinyInt 	  	 -- 1 = Yes, use applied product filter ; 0 = No, use original product filter
 	 , @Username Varchar(50) = Null
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003) 
 	 --Local query assistance
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
DECLARE @Unspecified varchar(50)
DECLARE @NotApplicable varchar(50)
 	 --Waste-Related identifiers
DECLARE @MasterUnit Int
If @TimeSort IS NULL SELECT @TimeSort = 1  --Ascending, DEFAULT
SELECT @MasterUnit = @Pu_Id
--DECLARE @UserId 	 Int
--
--SELECT @UserId = User_Id
--FROM users
--WHERE Username = @Username
--
--EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
--
--SELECT @Unspecified = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified')
--
--SELECT @NotApplicable = dbo.fnDBTranslate(@Langid, 31333, 'Not Applicable')
CREATE TABLE #Applied_Products(Pu_Id Int, Event_Id Int, Event_Num Varchar(50), Prod_Id Int, Applied_Prod_Id Int NULL, Start_Time Datetime, TimeStamp DateTime)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Comments (Detail_Id Int, FirstComment Int NULL, LastComment Int NULL)
CREATE TABLE #prod_starts (Pu_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #TopNDR (
    Detail_Id  	  	 Int
  , Start_Time DateTime
  , TimeStamp  	  	 DateTime
  , Amount  	  	 real NULL
  , Reason_Name  	 varchar(100) NULL
  , SourcePU  	  	 Int NULL
  , R1_Id  	  	 Int NULL
  , R2_Id  	  	 Int NULL
  , R3_Id  	  	 Int NULL
  , R4_Id  	  	 Int NULL
  , Type_Id  	  	 Int NULL
  , Meas_Id  	  	 Int NULL 
  , Prod_Id  	  	 Int NULL
  , Applied_Prod_Id 	 Int NULL
  , First_Comment_Id 	 Int NULL
  , Last_Comment_Id  	 Int NULL
  , EventBased  	  	 tinyInt NULL
  , EventNumber  	 varchar(50) NULL
  , NPT tinyint 	 NULL  	      
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
If      @Prod_Id Is NOT NULL 	  	  	  	 SELECT @QueryType = @SingleProduct   	 --1
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
    INSERT INTO #prod_starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM production_starts ps
       WHERE Pu_Id = @MasterUnit 
         AND (   (Start_Time BETWEEN @Start_Time AND @End_Time) 
              OR (End_Time BETWEEN @Start_Time AND @End_Time) 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
             )    --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  END
Else If @QueryType = @SingleProduct 	  	 --1
  BEGIN
    INSERT INTO #prod_starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM production_starts ps
       WHERE Pu_Id = @MasterUnit 
         AND Prod_Id = @Prod_Id 
         AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
               OR (End_Time BETWEEN @Start_Time AND @End_Time) 
               OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
             )    --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  END
Else 	  	  	  	  	 --More than single product
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
    --EndIf @QueryType ..
    INSERT INTO #prod_starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM production_starts ps
        JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
       WHERE Pu_Id = @MasterUnit 
         AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
               OR (End_Time BETWEEN @Start_Time AND @End_Time) 
               OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL))
             )   --Start_time & End_time condition checked ; MSi/MT/3-21-2001
  END
--EndIf @QueryType ...
-- Insert relevant Waste Information Into TopNDR Temp Table
 	 -- Get All The Event Based Waste
INSERT INTO #TopNDR (Detail_Id, Start_Time,TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id, Prod_Id, EventBased, EventNumber)
  SELECT D.WED_Id, EV.Start_Time, EV.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.WET_Id, D.WEMT_Id
       , PS.Prod_Id, 1, EV.Event_Num 
    FROM Events EV 
    JOIN Waste_Event_Details D ON D.Event_Id = EV.Event_Id
    JOIN #Prod_Starts PS ON PS.Start_Time <= EV.TimeStamp AND (PS.End_Time > EV.TimeStamp OR PS.End_Time Is NULL) 
   WHERE EV.Pu_Id = @Pu_Id AND EV.TimeStamp > @Start_Time AND EV.TimeStamp <= @End_Time   
  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	 -- Get All The Time Based Waste
INSERT INTO #TopNDR (Detail_Id, TimeStamp, Amount,SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id, Prod_Id, EventBased)
  SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.WET_Id, D.WEMT_Id
       , PS.Prod_Id, 0  
    FROM Waste_Event_Details D 
    JOIN #Prod_Starts PS ON PS.Start_Time <= D.TimeStamp AND (PS.End_Time > D.TimeStamp OR PS.End_Time Is NULL) 
   WHERE D.Pu_Id = @Pu_Id AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
--DELETE For Additional Selection Criteria
If @SelectSource Is NOT NULL  DELETE FROM #TopNDR WHERE SourcePU Is NULL OR SourcePU <> @SelectSource
If @SelectR1 Is NOT NULL      DELETE FROM #TopNDR WHERE R1_Id Is NULL OR R1_Id <> @SelectR1  
If @SelectR2 Is NOT NULL      DELETE FROM #TopNDR WHERE R2_Id Is NULL OR R2_Id <> @SelectR2
If @SelectR3 Is NOT NULL      DELETE FROM #TopNDR WHERE R3_Id Is NULL OR R3_Id <> @SelectR3
If @SelectR4 Is NOT NULL      DELETE FROM #TopNDR WHERE R4_Id Is NULL OR R4_Id <> @SelectR4
--Get First And Last Comment
INSERT INTO #Comments
    SELECT D.Detail_Id,  MIN(C.WTC_ID), MAX(C.WTC_ID)
      FROM #TopNDR D, Waste_n_Timed_Comments C
     WHERE C.WTC_Source_Id = D.Detail_Id AND C.WTC_Type = 3
  GROUP BY D.Detail_Id   
UPDATE #TopNDR 
    SET First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
   FROM #TopNDR D, #Comments C 
  WHERE D.Detail_Id = C.Detail_Id 
-------------------------------------------------------------------
-----------------------------------------------------------------------------------
/*
 	  	 Non Productive Time
 	  	 
*/
------------------------------------------------------------------------------------
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration int)
      INSERT INTO @Periods_NPT ( Starttime,Endtime)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @Start_Time  THEN @Start_Time 
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @End_Time THEN @End_Time
                                                ELSE np.End_Time
                                                END
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
            JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
                                                                                                      AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
      WHERE PU_Id = @PU_id
                  AND np.Start_Time < @End_Time
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
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003) 
If @ShowProductCode = 0 GOTO RETURN_FILTER_BY_ORIGINAL_PRODUCT_WITHOUT_PRODUCT_CODE
--Return Data And Join Results
If @TimeSort = 1 
  SELECT [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone, Amount
       , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
       , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
       , Event_Number = Case 
                          When #TopNDR.EventBased = 0 Then @NotApplicable
                          When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                          Else #TopNDR.EventNumber 
                        End
       , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
       , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
       , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
       , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
       , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
       , Products.Prod_Code
       , First_Comment_Id
       , Last_Comment_Id  
    FROM #TopNDR
    JOIN Products ON Products.Prod_Id = #TopNDR.Prod_Id
    LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
    LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
    LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
    LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
 	 WHERE NPT IS NULL   	 
    --ORDER BY TimeStamp ASC                                                  -- ECR #29673
    ORDER BY TimeStamp ASC, Amount ASC                                        -- ECR #29673
Else
  SELECT [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone, Amount
       , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
       , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
       , Event_Number = Case 
                          When #TopNDR.EventBased = 0 Then @NotApplicable
                          When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                          Else #TopNDR.EventNumber 
                        End
       , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
       , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
       , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
       , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
       , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
       , Products.Prod_Code
       , First_Comment_Id
       , Last_Comment_Id  
    FROM #TopNDR
    JOIN Products ON Products.Prod_Id = #TopNDR.Prod_Id
    LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
    LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
    LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
    LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
    LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
    --ORDER BY TimeStamp DESC 
 	 WHERE NPT IS NULL                                                    -- ECR #29673
    ORDER BY TimeStamp DESC, Amount DESC                                          -- ECR #29673
--EndIf @TimeSort ...
GOTO DROP_TEMP_TABLES
RETURN_FILTER_BY_ORIGINAL_PRODUCT_WITHOUT_PRODUCT_CODE:
  If @TimeSort = 1 
    SELECT [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone, Amount
         , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
         , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
         , Event_Number = Case 
                            When #TopNDR.EventBased = 0 Then @NotApplicable
                            When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                            Else #TopNDR.EventNumber 
                          End
         , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
         , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
         , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
         , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
         , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
         , First_Comment_Id
         , Last_Comment_Id  
      FROM #TopNDR
      LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
      LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
      LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
      --ORDER BY TimeStamp ASC
 	   WHERE NPT IS NULL 	                                                      -- ECR #29673
      ORDER BY TimeStamp ASC, Amount ASC                                           -- ECR #29673
  Else
    SELECT [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone, Amount
         , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
         , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
         , Event_Number = Case 
                            When #TopNDR.EventBased = 0 Then @NotApplicable
                            When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                            Else #TopNDR.EventNumber 
                          End
         , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
         , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
         , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
         , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
         , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
         , First_Comment_Id
         , Last_Comment_Id  
      FROM #TopNDR
      JOIN Products ON Products.Prod_Id = #TopNDR.Prod_Id
      LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
      LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
      LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
      --ORDER BY TimeStamp DESC 
 	   WHERE NPT IS NULL 	                                                       -- ECR #29673
      ORDER BY TimeStamp DESC, Amount DESC                                            -- ECR #29673
  --EndIf @TimeSort ...
  GOTO DROP_TEMP_TABLES
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
  -- NOTE1: JOIN condition for Production_Starts consistent with AutoLog's )
  INSERT INTO #Applied_Products
      SELECT e.Pu_Id, e.Event_Id, e.Event_Num, ps.Prod_Id, e.Applied_Product, e.Start_Time, e.TimeStamp
        FROM Events e
        JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NOT NULL
    UNION
      SELECT e.Pu_Id, e.Event_Id, e.Event_Num, ps.Prod_Id, e.Applied_Product, e.Start_Time, e.TimeStamp
        FROM Events e
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NULL
        JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
  -- Insert relevant Waste Information Into TopNDR Temp Table
     -- Get All The Event-Based Waste (Get TimeStamp from Events Table VIA Applied_Products_From_Events)
  INSERT INTO #TopNDR (Detail_Id, Start_Time, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id, Prod_Id, Applied_Prod_Id, EventBased, EventNumber)
    SELECT D.WED_Id, ap.Start_time, ap.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.WET_Id, D.WEMT_Id
         , ap.Prod_Id, ap.Applied_Prod_Id, 1, ap.Event_Num 
      FROM #Applied_Products ap 
      JOIN Waste_Event_Details D ON D.Event_Id = ap.Event_Id
     WHERE ap.Pu_Id = @Pu_Id AND ap.TimeStamp > @Start_Time AND ap.TimeStamp <= @End_Time   
     -- Get All The Time-Based Waste (Get TimeStamp From Waste_Event_Details Table)
  INSERT INTO #TopNDR (Detail_Id, TimeStamp, Amount, SourcePU, R1_Id, R2_Id, R3_Id, R4_Id, Type_Id, Meas_Id, Prod_Id, Applied_Prod_Id, EventBased)
    SELECT D.WED_Id, D.TimeStamp, D.Amount, D.Source_Pu_Id, D.Reason_Level1, D.Reason_Level2, D.Reason_Level3, D.Reason_Level4, D.WET_Id, D.WEMT_Id
         , ap.Prod_Id, ap.Applied_Prod_Id, 0  
      FROM Waste_Event_Details D 
      JOIN #Applied_Products ap ON ap.TimeStamp = D.TimeStamp 
     WHERE D.Pu_Id = @Pu_Id AND D.TimeStamp > @Start_Time AND D.TimeStamp <= @End_Time AND D.Event_Id Is NULL  
  --DELETE Rows that do not match Additional Selection Criteria
  If @SelectSource Is NOT NULL 	 DELETE FROM #TopNDR WHERE SourcePU Is NULL OR SourcePU <> @SelectSource
  If @SelectR1 Is NOT NULL 	 DELETE FROM #TopNDR WHERE R1_Id Is NULL OR R1_Id <> @SelectR1  
  If @SelectR2 Is NOT NULL 	 DELETE FROM #TopNDR WHERE R2_Id Is NULL OR R2_Id <> @SelectR2
  If @SelectR3 Is NOT NULL 	 DELETE FROM #TopNDR WHERE R3_Id Is NULL OR R3_Id <> @SelectR3
  If @SelectR4 Is NOT NULL 	 DELETE FROM #TopNDR WHERE R4_Id Is NULL OR R4_Id <> @SelectR4
  --Get First And Last Comment
  INSERT INTO #Comments
      SELECT D.Detail_Id,  MIN(C.WTC_ID), MAX(C.WTC_ID)
        FROM #TopNDR D, Waste_n_Timed_Comments C
       WHERE C.WTC_Source_Id = D.Detail_Id AND C.WTC_Type = 3
    GROUP BY D.Detail_Id   
  -- Update Fist & Last Comment For #TopNDR 
  UPDATE #TopNDR 
      SET First_Comment_Id = FirstComment, Last_Comment_Id = (Case When FirstComment <> LastComment Then LastComment Else NULL End) 
     FROM #TopNDR D, #Comments C 
    WHERE D.Detail_Id = C.Detail_Id 
-------------------------------------------------------------------
-----------------------------------------------------------------------------------
/*
 	  	 Non Productive Time
 	  	 
*/
------------------------------------------------------------------------------------
DECLARE @Periods_NPT1 TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration int)
      INSERT INTO @Periods_NPT1 ( Starttime,Endtime)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @Start_Time  THEN @Start_Time 
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @End_Time THEN @End_Time
                                                ELSE np.End_Time
                                                END
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
            JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
                                                                                                      AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@PU_Id)
      WHERE PU_Id = @PU_id
                  AND np.Start_Time < @End_Time
                  AND np.End_Time > @Start_Time 
-------NPT OF Downtime-------
-- Case 1 :  Downtime    St---------------------End
-- 	  	  	  NPT   St--------------End
UPDATE #TopNDR SET Start_Time = n.Endtime,
 	  	  	  	  	 NPT = 1
FROM #TopNDR  JOIN @Periods_NPT1 n ON (Start_Time > n.StartTime AND TimeStamp > n.EndTime AND Start_Time < n.EndTime)
-- Case 2 :  Downtime    St---------------------End
-- 	  	  	  NPT 	  	  	  	  	 St--------------End
UPDATE #TopNDR SET TimeStamp = n.Starttime,
 	  	  	  	    NPT = 1
FROM 	 #TopNDR 	  	    
JOIN @Periods_NPT1 n ON (Start_Time < n.StartTime AND TimeStamp < n.Endtime AND TimeStamp > n.StartTime)
 	  	 
-- Case 3 :  Downtime   St-----------------------End
-- 	  	  	  NPT   St-------------------------------End
UPDATE #TopNDR SET Start_Time = TimeStamp,
 	  	  	  	  	 NPT = 1
FROM 	 #TopNDR  	  	    
JOIN @Periods_NPT1 n ON( (Start_Time BETWEEN n.StartTime AND n.EndTime) AND (TimeStamp BETWEEN n.StartTime AND n.EndTime))
--Update #TopNDR Set Duration =DateDiff(ss,Start_Time,TimeStamp)/60.0
-- Case 4 :  Downtime   St-----------------------End
-- 	  	  	  NPT 	  	    St-----------------End
UPDATE #TopNDR  SET NPT = 1
FROM #TopNDR  JOIN @Periods_NPT1 n ON( (n.StartTime BETWEEN Start_Time AND TimeStamp) AND (n.Endtime BETWEEN Start_Time AND TimeStamp))
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003) 
  If @ShowProductCode = 0 GOTO RETURN_FILTER_BY_APPLIED_PRODUCT_WITHOUT_PRODUCT_CODES
  --Return Data And Join Results
  If @TimeSort = 1 
    SELECT [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone
         , Amount
         , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
         , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
         , Event_Number = Case 
                            When #TopNDR.EventBased = 0 Then @NotApplicable
                            When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                            Else #TopNDR.EventNumber 
                          End
         , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
         , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
         , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
         , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
         , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
         , p.Prod_Code
         , Applied_Prod_Code = p2.Prod_Code
         , First_Comment_Id
         , Last_Comment_Id  
      FROM #TopNDR
      JOIN Products p ON p.Prod_Id = #TopNDR.Prod_Id
      LEFT OUTER JOIN Products p2 ON p2.Prod_Id = #TopNDR.Applied_Prod_Id
      LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
      LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
      LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
 	   WHERE NPT IS NULL 	 
      --ORDER BY TimeStamp ASC                                                      -- ECR #29673
      ORDER BY TimeStamp ASC, Amount ASC                                            -- ECR #29673
  Else
    SELECT [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone
         , Amount
         , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
         , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
         , Event_Number = Case 
                            When #TopNDR.EventBased = 0 Then @NotApplicable
                            When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                            Else #TopNDR.EventNumber 
                          End
         , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
         , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
         , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
         , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
         , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
         , p.Prod_Code
         , Applied_Prod_Code = p2.Prod_Code
         , First_Comment_Id
         , Last_Comment_Id  
      FROM #TopNDR
      JOIN Products p ON p.Prod_Id = #TopNDR.Prod_Id
      LEFT OUTER JOIN Products p2 ON p2.Prod_Id = #TopNDR.Applied_Prod_Id
      LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
      LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
      LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
 	   WHERE NPT IS NULL 	 
      --ORDER BY TimeStamp DESC                                                       -- ECR #29673
      ORDER BY TimeStamp DESC, Amount DESC                                            -- ECR #29673
  --EndIf @TimeSort ...
  GOTO DROP_TEMP_TABLES
RETURN_FILTER_BY_APPLIED_PRODUCT_WITHOUT_PRODUCT_CODES:
  --Return Data And Join Results
  If @TimeSort = 1 
    SELECT [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone
         , Amount
         , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
         , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
         , Event_Number = Case 
                            When #TopNDR.EventBased = 0 Then @NotApplicable
                            When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                            Else #TopNDR.EventNumber 
                          End
         , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
         , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
         , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
         , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
         , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
         , First_Comment_Id
         , Last_Comment_Id  
      FROM #TopNDR
      LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
      LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
      LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
      --ORDER BY TimeStamp ASC
 	   WHERE NPT IS NULL 	                                                             -- ECR #29673
      ORDER BY TimeStamp ASC, Amount ASC                                                  -- ECR #29673
  Else
    SELECT [TimeStamp] = [TimeStamp] at time zone @DBTz at time zone @InTimeZone
         , Amount
         , Measurement = Case When #TopNDR.Meas_Id Is NULL Then @Unspecified  Else M.WEMT_Name End
         , Type = Case When #TopNDR.Type_Id Is NULL Then @Unspecified  Else T.WET_Name End
         , Event_Number = Case 
                            When #TopNDR.EventBased = 0 Then @NotApplicable
                            When #TopNDR.EventBased = 1 AND #TopNDR.EventNumber Is NULL Then @Unspecified   
                            Else #TopNDR.EventNumber 
                          End
         , Location = Case When #TopNDR.SourcePU Is NULL Then @Unspecified  Else PU.PU_Desc End
         , Reason1 =  Case When #TopNDR.R1_Id Is NULL Then @Unspecified  Else R1.Event_Reason_Name End
         , Reason2 =  Case When #TopNDR.R2_Id Is NULL Then @Unspecified  Else R2.Event_Reason_Name End
         , Reason3 =  Case When #TopNDR.R3_Id Is NULL Then @Unspecified  Else R3.Event_Reason_Name End
         , Reason4 =  Case When #TopNDR.R4_Id Is NULL Then @Unspecified  Else R4.Event_Reason_Name End
         , First_Comment_Id
         , Last_Comment_Id  
      FROM #TopNDR
      LEFT OUTER JOIN Prod_Units PU ON (#TopNDR.SourcePU = PU.Pu_Id)
      LEFT OUTER JOIN Event_Reasons R1 ON (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 ON (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 ON (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 ON (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Waste_Event_Type T ON (#TopNDR.Type_Id = T.WET_Id)
      LEFT OUTER JOIN Waste_Event_Meas M ON (#TopNDR.Meas_Id = M.WEMT_Id)
      --ORDER BY TimeStamp DESC
 	   WHERE NPT IS NULL 	                                                              -- ECR #29673
      ORDER BY TimeStamp DESC, Amount DESC                                                  -- ECR #29673
  --EndIf @TimeSort ...
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #TopNDR
  DROP TABLE #Prod_Starts
  DROP TABLE #Comments
  DROP TABLE #Products
--DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
