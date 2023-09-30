--spXLATestData_AP ( mt/1-8-2002 ) is modified from spXLATestData_Expand & spXLATestData_NoProduct. Changes are:
-- (1) spXLATestData_AP accepts variable either as ID or description
-- (2) spXLATestData_AP does internal lookup for product code, etc. as needed. 
-- (3) spXLATestData_AP includes Pu_Id, Data_Type_Id, Event_Type in ResultSet
-- (4) spXLATestData_AP handles no product, original product, and applied product cases.
--
-- Defect #24141: mt/7-9-2002:Fix error in Event Status
-- ECR #26270 (mt/8-29-2003): Fixed Where-Clause missing Canceled = 0
-- ECR #34956: (sb/1-1-2008: Fixed time convention (start...end]
--
CREATE PROCEDURE dbo.spXLATestData_AP
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50) = NULL
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Prod_Id 	  	 Integer
 	 , @Group_Id 	  	 Integer
 	 , @Prop_Id 	  	 Integer
 	 , @Char_Id 	  	 Integer
 	 , @IncludeProducts 	 TinyInt 	  	   --1 = Yes, include prod_code via JOIN, expensive; 0 = No, exclude it
 	 , @NeedProductCodes 	 TinyInt 	  	   --1 = include applied product code in RsultSet; 0 = exclude
 	 , @AppliedProductFilter 	 TinyInt 	  	   --0 = filter by original product; 1 = filter by applied product
 	 , @TimeSort 	  	 SmallInt 
 	 , @DecimalChar 	  	 Varchar(1) = NULL --Comma Or Period (Default) to accommodate different regional setttings on PC --mt/2-6-2002
 	 , @InTimeZone 	 varchar(200) = null
AS
 	 --Pertaining Data To Be included in ResultSet
DECLARE @Pu_Id 	  	  	 Integer
DECLARE @Data_Type_Id 	  	 Integer
DECLARE @Event_Type 	  	 SmallInt
DECLARE @MasterUnitId 	  	 Integer
DECLARE @VariableFetchCount 	 Integer
 	 --Local query assistance
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
SELECT @Data_Type_Id  	  	 = -1
SELECT @MasterUnitId 	  	 = -1
SELECT @Pu_Id  	  	  	 = -1
SELECT @Event_Type 	  	 = -1
SELECT @VariableFetchCount  	 = 0
If @DecimalChar Is NULL SELECT @DecimalChar = '.' 	 --Set Decimal Separator Default Value, if applicable
If @Var_Desc Is NULL
  BEGIN
 	 SELECT @VariableFetchCount = 0
 	 IF EXISTS(SELECT 1 from Variables_Base where Var_Id = @Var_Id)
 	 Begin
 	  	 SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnitId = pu.Master_Unit 
 	  	  	 FROM variables_base v
 	  	  	 JOIN prod_units_base pu ON pu.Pu_Id = v.Pu_Id  
 	  	  	 WHERE v.Var_Id = @Var_Id
 	  	  	 SELECT @VariableFetchCount = @@ROWCOUNT
 	 END
 	  
  END
Else --@Var_Desc NOT null, use it
  BEGIN
 	 SELECT @VariableFetchCount = 0
 	 IF EXISTS(SELECT 1 from Variables_Base where Var_Desc = @Var_Desc)
 	 Begin
 	  	 SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnitId = pu.Master_Unit 
 	  	   FROM variables_base v
 	  	   JOIN prod_units_base pu on pu.Pu_Id = v.Pu_Id
 	  	  WHERE v.Var_Desc = @Var_Desc
 	  	  SELECT @VariableFetchCount = @@ROWCOUNT
 	  End
  END
--EndIf
If @VariableFetchCount = 0 
  BEGIN
    SELECT ReturnStatus = -10 	  	 --Tells the Add-In "Variable specified not found"
    RETURN
  END
--EndIf
If @MasterUnitId Is NOT NULL SELECT @Pu_Id = @MasterUnitId
SELECT @Event_Type = Case @Event_Type When 0 Then 0 Else 1 End
--select pu_Id = @Pu_Id, Event_Type = @Event_type, Master_Id = @MasterUnitId, Var_id = @Var_Id
If ISNUMERIC(@Data_Type_Id) = 0
  BEGIN 
    SELECT ReturnStatus = -20 	  	 --"Illegal data type"
    RETURN
  END
--EndIf
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
If @IncludeProducts = 0 GOTO RETRIEVE_RECORDSET_WITHOUT_PRODUCTS
CREATE TABLE #Prod_Starts (Pu_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Applied_Products(Pu_Id Int, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL)
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
--TestData At Specific Time; Don't filter by Canceled (we'll return data for Canceled = 0 or 1)
If @End_Time Is NULL
  BEGIN
    SELECT  t.Test_Id
    , t.Canceled
    , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
    , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
    , t.Comment_Id
    , t.Array_Id
    , t.Event_Id
    , T.Var_Id
    , t.Locked
    , [Result] = CASE 
                        WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	 , p.Prod_Code, e.Event_Num, Event_Status = s.ProdStatus_Desc
         , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
      FROM tests t
      JOIN Production_Starts ps ON ps.Pu_Id = @Pu_Id 
       AND ps.Start_Time < t.Result_On AND (ps.End_Time >= t.Result_On OR ps.End_Time Is NULL)
      JOIN Products_base p ON p.Prod_Id = ps.Prod_Id
      LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
      LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
     WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time
    RETURN
  END
--EndIf no End_Time
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
SELECT @SingleProduct 	  	 = 1
SELECT @Group 	  	  	 = 2
SELECT @Characteristic 	  	 = 3
SELECT @GroupAndProperty 	 = 4
SELECT @NoProductSpecified 	 = 5
--Figure Out Query Type Based on Product Info given
-- NOTE: We DO NOT handle all possible null combinations of product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
-- Proficy Add-In blocks out illegal combinations, and allows only these combination:
--     * Property AND Characteristic 
--     * Group Only
--     * Group, Propery, AND Characteristic
--     * Product Only
--     * No Product Information At All 
If      @Prod_Id Is NOT NULL 	  	  	  	 SELECT @QueryType = @SingleProduct   	 --1
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL 	 SELECT @QueryType = @Group   	  	 --2
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL 	 SELECT @QueryType = @Characteristic  	 --3
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL 	 SELECT @QueryType = @GroupAndProperty 	 --4
Else 	  	  	  	  	  	  	 SELECT @QueryType = @NoProductSpecified 	 --5
--EndIf
DECLARE @MyTests Table(Canceled Bit,Result_On DateTime,Entry_On DateTime,Comment_Id Int,Result VarChar(25))
Insert Into @MyTests(Canceled,Result_On,Entry_On,Comment_Id,Result)
SELECT Canceled,Result_On,Entry_On,Comment_Id,Result 
  FROM tests t
  WHERE Var_Id = @Var_Id AND Result_On > @Start_Time AND Result_On <= @End_Time
If @AppliedProductFilter = 1 GOTO DO_FILTER_BY_APPLIED_PRODUCT
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
--Get relevant products and their information from Production_Starts table
If @QueryType = @NoProductSpecified  --5 
  BEGIN
    INSERT INTO #prod_starts
    SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
     WHERE Pu_Id = @Pu_Id 
       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (Start_Time < @Start_Time AND (End_Time >= @End_Time OR End_Time Is NULL))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ) 
  END
Else If @QueryType = @SingleProduct  --1
  BEGIN
    INSERT INTO #prod_starts
    SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
     WHERE ps.Pu_Id = @Pu_Id 
       AND ps.prod_id = @Prod_Id 
       AND (    (ps.Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (ps.End_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (ps.Start_Time < @Start_Time AND (ps.End_Time >= @End_Time OR ps.End_Time Is NULL))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ) 
  END
Else
  BEGIN
    --CREATE TABLE #products (prod_id int)
    if @QueryType = @Group  --2 
      BEGIN
         INSERT INTO #products
         SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @Characteristic --3
      BEGIN
         INSERT INTO #products
         SELECT DISTINCT prod_id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else
      BEGIN
         INSERT INTO #products
         SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id
         INSERT INTO #products
         SELECT DISTINCT prod_id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END  
    INSERT INTO #prod_starts
    SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
      JOIN #products p on ps.prod_id = p.prod_id 
     WHERE ps.Pu_Id = @Pu_Id 
       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (Start_Time < @Start_Time AND (End_Time >= @End_Time OR End_Time Is NULL))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ) 
    --DROP TABLE #products
  END
--EndIf @QueryType (Product Info)
If @NeedProductCodes = 0 GOTO DO_ORIGINAL_PRODUCT_FILTER_WITHOUT_PRODCODE
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
--Retrieve From Out Temp Test Table including product code
If @TimeSort = 1 
      --SELECT t.*, p.Prod_Code, e.Event_Num, s.ProdStatus_Desc as 'Event_Status'
    SELECT 
    [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
    , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
    , t.Canceled
    , t.Comment_Id
    , [Result] = CASE 
                        WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
            , p.Prod_Code, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc
            , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests  t
        JOIN #Prod_Starts ps ON ps.Start_Time < t.Result_On AND ((ps.End_Time >= t.Result_On) OR (ps.End_Time Is NULL)) AND t.canceled = 0
        JOIN Products_base p ON p.Prod_Id = ps.Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
    ORDER BY Result_On ASC
Else
      --SELECT t.*, p.Prod_Code, e.Event_Num, s.ProdStatus_Desc as 'Event_Status' 
      SELECT     
 	  	  	   [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	  	  	  	 ELSE t.Result
 	  	  	  	  	  	  	   END
            , p.Prod_Code, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc
            , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests t
        JOIN #prod_starts ps ON (ps.Start_Time < t.Result_On AND (ps.End_Time >= t.Result_On OR ps.End_Time Is NULL)) AND t.canceled = 0
        JOIN Products_base p ON p.Prod_Id = ps.Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
    ORDER BY Result_On desc
--EndIf @TimeSort
GOTO DROP_TEMP_TABLES
DO_ORIGINAL_PRODUCT_FILTER_WITHOUT_PRODCODE:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @TimeSort = 1 
        SELECT 
 	  	  	 [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	  	  	  	 ELSE t.Result
 	  	  	  	  	  	  	   END
             , e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc
             , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
          FROM @MyTests t
          JOIN #Prod_Starts ps ON ps.Start_Time < t.Result_On AND ((ps.End_Time >= t.Result_On) OR (ps.End_Time Is NULL)) AND t.canceled = 0
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY t.Result_On ASC
  Else
        SELECT 
 	  	  	 [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	  	  	  	 ELSE t.Result
 	  	  	  	  	  	  	   END
             , e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc
             , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
          FROM @MyTests t
          JOIN #prod_starts ps ON (ps.Start_Time < t.Result_On AND (ps.End_Time >= t.Result_On OR ps.End_Time Is NULL)) AND t.canceled = 0
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY t.Result_On DESC
  --EndIf @TimeSort
  GOTO DROP_TEMP_TABLES
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
DO_FILTER_BY_APPLIED_PRODUCT:
  --SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
  --Get all relevant products and info from production_Start table
  INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
      FROM Production_Starts ps
     WHERE ps.Pu_Id = @Pu_Id 
       AND (    ps.Start_Time BETWEEN @Start_Time AND @End_Time
             OR ps.End_Time BETWEEN @Start_Time AND @End_Time 
             OR (ps.Start_Time < @Start_Time AND (ps.End_Time >= @End_Time OR ps.End_Time Is NULL))
           ) 
  --Grab all of the "Specified" to filter product(s) filter, put them into Temp Table #Products
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
  -- RETRIEVE RESULTSET BASED ON WHETHER OR NOT "Applied Products" information is asked for.
  -- NOTE:  Definition of matched "Applied Products" from Events Table.  
  --        When matched product has Applied_Product = NULL, we take that the original product is applied product.
  --        When matched product has Applied_Product <> NULL, include that product as applied product
  -- NOTE2: JOIN condition for Production_Starts consistent with AutoLog's
  -- NOTE2: As of 3-25-2002 MSI Start_Time inEvents table are mostly null. This storec procedure will insert
  --        a dummy value of TimeStamp minus one second for null Start_Time. For Customers who are concern about correct 
  --        Start_Time, which affect correct time-dependent results, MSI will give them a script for one-time update of 
  --        the Events table. This update is time/disk-space consuming, thus, available upon request only.
  INSERT INTO #Applied_Products
      SELECT e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product
        FROM Events e
        JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
        JOIN #Prod_Starts ps ON ps.Start_Time < e.TimeStamp AND ( ps.End_Time >= e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NOT NULL
    UNION
      SELECT e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product
        FROM Events e
        JOIN #Prod_Starts ps ON ps.Start_Time < e.TimeStamp AND ( ps.End_Time >= e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NULL
        JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
  If @NeedProductCodes = 0 GOTO RETRIEVE_APPLIED_PRODUCT_FILTER_WITHOUT_PRODUCT_CODE
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @TimeSort = 1 
      SELECT p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
       	  	 , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	  	  	  	 ELSE t.Result
 	  	  	  	  	  	  	   END
           , e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc 
          , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests  t
        --Note join condition; Start_Time < Result_ON; End_Time >= Result_On; or we misalign the event
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        JOIN Products_base p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products_base p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On ASC
  Else
      SELECT p.Prod_Code
 	  	  	 , Applied_Prod_Code = p2.Prod_Code
            , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	 ELSE t.Result
 	  	  	  	   END
           , e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc
           , Data_Type_Id = @Data_Type_Id
           , Event_Type = @Event_Type
           , Pu_Id = @Pu_Id
        FROM @MyTests t
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        JOIN Products_base p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products_base p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On DESC
  --EndIf
  GOTO DROP_TEMP_TABLES
RETRIEVE_APPLIED_PRODUCT_FILTER_WITHOUT_PRODUCT_CODE:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @TimeSort = 1 
        SELECT 
 	  	  	 [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	 ELSE t.Result
 	  	  	  	   END
 	  	  	 , e.Event_Id
 	  	  	 , e.Event_Num
 	  	  	 , Event_Status = s.ProdStatus_Desc
            , Data_Type_Id = @Data_Type_Id
            , Event_Type = @Event_Type
            , Pu_Id = @Pu_Id
        FROM @MyTests t
        --Note join condition; Start_Time < Result_ON; End_Time >= Result_On; or we misalign the event
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On ASC
  Else
        SELECT 
         	 [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	 ELSE t.Result
 	  	  	  	   END
 	  	  	  , e.Event_Id
 	  	  	  , e.Event_Num
 	  	  	  , Event_Status = s.ProdStatus_Desc
             , Data_Type_Id = @Data_Type_Id
             , Event_Type = @Event_Type
             , Pu_Id = @Pu_Id
        FROM @MyTests  t
        --Note join condition; Start_Time < Result_ON; End_Time >= Result_On; or we misalign the event
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On DESC
  --EndIf
  GOTO DROP_TEMP_TABLES
-- RETRIEVE RECORDSET WITHOUT PRODUCT CODES-RETRIEVE RECORDSET WITHOUT PRODUCT CODES-RETRIEVE RECORDSET WITHOUT PRODUCT CODES-
RETRIEVE_RECORDSET_WITHOUT_PRODUCTS:
  DECLARE @QType 	  	  	 TinyInt
  DECLARE @NoEndTimeAscending 	  	 TinyInt
  DECLARE @NoEndTimeDescending 	  	 TinyInt
  DECLARE @StartAndEndAscending 	  	 TinyInt
  DECLARE @StartAndEndDescending 	 TinyInt
  SELECT @NoEndTimeAscending  	 = 1
  SELECT @NoEndTimeDescending  	 = 2
  SELECT @StartAndEndAscending  	 = 3
  SELECT @StartAndEndDescending = 4
  If @End_Time Is NULL
    BEGIN
      SELECT @QType = Case @TimeSort When 1 Then @NoEndTimeAscending Else @NoEndTimeDescending End
    END
  Else --@End_Time NOT NULL
    BEGIN
      SELECT @QType = Case @TimeSort When 1 Then @StartAndEndAscending Else @StartAndEndDescending End      
    END
  --EndIf @End_Time
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @QType = @NoEndTimeAscending
    BEGIN
        SELECT
              [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	 ELSE t.Result
 	  	  	  	   END
 	  	  	  , e.Event_Id
 	  	  	  , e.Event_Num
 	  	  	  , Event_Status = ps.ProdStatus_Desc
             , Data_Type_Id = @Data_Type_Id
             , Event_Type = @Event_Type
             , Pu_Id = @Pu_Id
          FROM Tests t 
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          --LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Id
          LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Status --ECR #25304: mt/3-25-2003
         WHERE t.Var_Id = @Var_Id AND t.Result_on = @Start_Time AND t.Canceled = 0   --ECR #26270(mt/8-29-2003)added Canceled = 0
      ORDER BY t.Result_On ASC
    END
  Else If @QType = @NoEndTimeDescending
    BEGIN
        SELECT
              [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	 ELSE t.Result
 	  	  	  	   END
 	  	  	  , e.Event_Id
 	  	  	  , e.Event_Num
 	  	  	  , Event_Status = ps.ProdStatus_Desc
             , Data_Type_Id = @Data_Type_Id
             , Event_Type = @Event_Type
             , Pu_Id = @Pu_Id
          FROM Tests t 
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          --LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Id
          LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Status --ECR #25304: mt/3-25-2003
         WHERE t.Var_Id = @Var_Id AND t.Result_on = @Start_Time AND t.Canceled = 0   --ECR #26270(mt/8-29-2003)added Canceled = 0
      ORDER BY t.Result_On DESC
    END
  Else If @QType = @StartAndEndAscending
    BEGIN
        SELECT
              [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	 ELSE t.Result
 	  	  	  	   END
 	  	  	  , e.Event_Id
 	  	  	  , e.Event_Num
 	  	  	  , Event_Status = ps.ProdStatus_Desc
             , Data_Type_Id = @Data_Type_Id
             , Event_Type = @Event_Type
             , Pu_Id = @Pu_Id
          FROM Tests t 
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          --LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Id
          LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Status --ECR #25304: mt/3-25-2003
         WHERE t.Var_Id = @Var_Id AND t.Result_on > @Start_Time AND t.Result_On <= @End_Time AND t.Canceled = 0 --ECR #26270(mt/8-29-2003)added Canceled = 0
      ORDER BY t.Result_On ASC
    END
  Else if @QType = @StartAndEndDescending
    BEGIN
        SELECT
              [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
 	  	  	  	  	 WHEN @DecimalChar <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
 	  	  	  	  	 ELSE t.Result
 	  	  	  	   END
 	  	  	  , e.Event_Id
 	  	  	  , e.Event_Num
 	  	  	  , Event_Status = ps.ProdStatus_Desc
             , Data_Type_Id = @Data_Type_Id
             , Event_Type = @Event_Type
             , Pu_Id = @Pu_Id
          FROM Tests t 
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          --LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Id
          LEFT OUTER JOIN  Production_Status ps ON ps.ProdStatus_Id = e.Event_Status --ECR #25304: mt/3-25-2003
         WHERE t.Var_Id = @Var_Id AND t.Result_on > @Start_Time AND t.Result_On <= @End_Time AND t.Canceled = 0 --ECR #26270(mt/8-29-2003)added Canceled = 0
      ORDER BY t.Result_On DESC
    END
  --EndIf
  GOTO EXIT_PROCEDURE
-- DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-
DROP_TEMP_TABLES:
  DROP TABLE #Prod_Starts
  DROP TABLE #Products
  DROP TABLE #Applied_Products 
  GOTO EXIT_PROCEDURE
EXIT_PROCEDURE:
