-- spXLA_FilteredTestsCalc_AP() is based on spXLATestsCalc_AP:Defect #24489:mt/1-10-2002. Change include (a) addition of 
-- crew,shift filter. (b) Disallow null end_time: no more of this nonsense.
--
-- ECR #25128: mt/3-13-2003: handle duplicate Var_Desc as GBDB doesn't enforce unique Var_Desc across entire database
-- ECR #34381: sb/9-15-2007: Tests returned should be start_time<result_on<=end_time
CREATE PROCEDURE dbo.spXLA_FilteredTestsCalc_AP
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50)
 	 , @Start_Time 	  	 Datetime
 	 , @End_Time 	  	 DateTime
 	 , @Crew_Desc            Varchar(10)
 	 , @Shift_Desc           Varchar(10)
 	 , @Prod_Id 	  	 Integer 
 	 , @Group_Id 	  	 Integer 
 	 , @Prop_Id 	  	 Integer 
 	 , @Char_Id 	  	 Integer 
 	 , @AppliedProductFilter 	 TinyInt 	  	 --1 = Filter By Applied Product; 0 = Filter By Original Product
 	 , @ExtraCalcs 	  	 SmallInt
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
 	 --Needed for internal lookup
DECLARE 	 @Pu_Id 	  	  	 Integer 
DECLARE 	 @Data_Type_Id  	  	 Integer 
DECLARE 	 @MasterUnitId 	  	 Integer
DECLARE 	 @VariableFetchCount  	 Integer
 	 --Needed to define query type
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
 	 --Needed for statistical calculations
DECLARE @Average 	    Real
DECLARE @Min 	  	    Real
DECLARE @Max 	  	    Real
DECLARE @Std 	  	    Real
DECLARE @Total 	  	    Real
DECLARE @Count 	  	    Int
DECLARE @Prod_Code         Varchar(50)
DECLARE @Applied_Prod_Code Varchar(50)
DECLARE @TimeOfMin 	    DateTime
DECLARE @TimeOfMax 	    DateTime
DECLARE @@Result 	    Varchar(25)
DECLARE @@Result_On  	    DateTime
DECLARE @FetchCount  	    Int
DECLARE @TempMin  	    Real
DECLARE @TempMax  	    Real
DECLARE @SumXSqr 	    Real
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
--First verify variable input and get required information
SELECT @Data_Type_Id  	  	 = -1
SELECT @MasterUnitId 	  	 = -1
SELECT @Pu_Id  	  	  	 = -1
SELECT @VariableFetchCount  	 = 0
-- ECR #25128: mt/3-13-2003: handle duplicate Var_Desc as GBDB doesn't enforce unique Var_Desc across entire database
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --input variable NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have @Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @MasterUnitId = pu.Master_Unit 
      FROM Variables v 
      JOIN Prod_Units pu  ON pu.Pu_Id = v.Pu_Id  
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
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @MasterUnitId = pu.Master_Unit 
      FROM Variables v
      JOIN Prod_Units pu  on pu.Pu_Id = v.Pu_Id
     WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount <> 1
      BEGIN
        If @VariableFetchCount = 0 	 
          SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        Else --too many Var_desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND for var_desc
        --EndIf:Count     
        RETURN
      END
    --EndIf:Count<>1
  END
--EndIf:Both @Var_Id and @Var_Desc null
If @MasterUnitId Is NOT NULL SELECT @Pu_Id = @MasterUnitId
If ISNUMERIC(@Data_Type_Id) = 0
  BEGIN 
    SELECT ReturnStatus = -20 	  	 --"Illegal data type"
    RETURN
  END
--EndIf:Numeric
--Defect 24123: mt/7-3-2002
If NOT (@Data_Type_Id = 2 OR @Data_Type_Id = 1)
  BEGIN
    SELECT ReturnStatus = -20 	  	 --"Illegal Data Type", Not a Float
    RETURN
  END
--EndIf:@Data_Type_Id
CREATE TABLE #Tests (Result_On DateTime, Result varchar(25))
CREATE TABLE #Prod_starts (Pu_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Applied_Products (Pu_Id Int, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL)
CREATE TABLE #Products (Prod_Id Int)
 	 --Define product filter types
SELECT @SingleProduct 	  	 = 1 	 --@SingleProduct
SELECT @Group 	  	  	 = 2 	 --@Group
SELECT @Characteristic 	  	 = 3 	 --@Characteristic
SELECT @GroupAndProperty 	 = 4 	 --@GroupAndProperty  
SELECT @NoProductSpecified 	 = 5 	 --@NoProductSpecified
--Figure Out Query Type Based on Product Info given
-- NOTE: We DO NOT handle all possible null combinations of product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
-- Proficy Add-In blocks out illegal combinations, and allows only these combination:
--     * Property AND Characteristic 
--     * Group Only
--     * Group, Propery, AND Characteristic
--     * Product Only
--     * No Product Information At All 
If      @Prod_Id Is NOT NULL                           SELECT @QueryType = @SingleProduct
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL     SELECT @QueryType = @Group 
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL     SELECT @QueryType = @Characteristic 
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL SELECT @QueryType = @GroupAndProperty 
Else                                                   SELECT @QueryType = @NoProductSpecified 
--EndIf
 	 --Determine Crew,Shift Types
If       @Crew_Desc Is NULL AND @Shift_Desc Is NULL     GOTO NOCREW_NOSHIFT_INSERT
Else If  @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL GOTO HASCREW_NOSHIFT_INSERT
Else If  @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL GOTO NOCREW_HASSHIFT_INSERT
Else                                                    GOTO HASCREW_HASSHIFT_INSERT
--EndIf:Crew,Shift
--Extract Test Data into #Test table  Data in Start-End time range And Crew,Shift Types
NOCREW_NOSHIFT_INSERT:
  INSERT Into #Tests (Result_On, Result) 
    SELECT t.Result_On, Result
      FROM Tests t
     WHERE Var_Id = @Var_Id AND Result_On > @Start_Time AND Result_On <= @End_Time AND Result Is NOT NULL AND canceled = 0
  GOTO START_OF_TESTS_CALC_BODY
--End NOCREW_NOSHIFT_INSERT:
HASCREW_NOSHIFT_INSERT:
  INSERT Into #Tests (Result_On, Result) 
    SELECT t.Result_On, Result
      FROM Tests t
      JOIN Crew_Schedule C ON C.Pu_Id = @Pu_Id AND C.Start_Time <= t.Result_On AND C.End_Time > t.Result_On AND C.Crew_Desc = @Crew_Desc
     WHERE Var_Id = @Var_Id AND Result_On > @Start_Time AND Result_On <= @End_Time AND Result Is NOT NULL AND canceled = 0
  GOTO START_OF_TESTS_CALC_BODY
--End HASCREW_NOSHIFT_INSERT:
NOCREW_HASSHIFT_INSERT:
  INSERT Into #Tests (Result_On, Result) 
    SELECT t.Result_On, Result
      FROM Tests t
      JOIN Crew_Schedule C ON C.Pu_Id = @Pu_Id AND C.Start_Time <= t.Result_On AND C.End_Time > t.Result_On AND C.Shift_Desc = @Shift_Desc
     WHERE Var_Id = @Var_Id AND Result_On > @Start_Time AND Result_On <= @End_Time AND Result Is NOT NULL AND canceled = 0
  GOTO START_OF_TESTS_CALC_BODY
--End NOCREW_HASSHIFT_INSERT:
HASCREW_HASSHIFT_INSERT:
  INSERT Into #Tests (Result_On, Result) 
    SELECT t.Result_On, Result
      FROM Tests t
      JOIN Crew_Schedule C ON C.Pu_Id = @Pu_Id AND C.Start_Time <= t.Result_On AND C.End_Time > t.Result_On AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
     WHERE Var_Id = @Var_Id AND Result_On > @Start_Time AND Result_On <= @End_Time AND Result Is NOT NULL AND canceled = 0
  GOTO START_OF_TESTS_CALC_BODY
--End HASCREW_HASSHIFT_INSERT:
START_OF_TESTS_CALC_BODY:
  If @AppliedProductFilter = 1 GOTO RETRIEVE_WITH_APPLIED_PRODUCT_FILTER
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Extract Product information from Production Start data into Temp table (#Prod_Starts)--
If @QueryType = @NoProductSpecified  --5
  BEGIN
    INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
      FROM Production_starts ps
     WHERE Pu_Id = @Pu_Id 
       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
             OR (End_Time BETWEEN @Start_Time AND @End_Time) 
             OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
           ) 
  END
Else If @QueryType = @SingleProduct  --1
  BEGIN
    INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
      FROM Production_Starts ps
     WHERE Pu_Id = @Pu_Id 
       AND Prod_Id = @Prod_Id 
       AND (    Start_Time BETWEEN @Start_Time AND @End_Time
             OR End_Time BETWEEN @Start_Time AND @End_Time
             OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
           ) 
  END
Else
  BEGIN     	 
    If @QueryType = @Group  --2
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @Characteristic  --3
      BEGIN
        INSERT INTO  #Products
        SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else --By Group & Property
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
        INSERT INTO #Products
        SELECT distinct Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END  
    --EndIf
    INSERT INTO #Prod_Starts
      SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM Production_Starts ps
        JOIN #Products p on ps.Prod_Id = p.Prod_Id 
       WHERE Pu_Id = @Pu_Id 
         AND (    Start_Time BETWEEN @Start_Time AND @End_Time
               OR End_Time BETWEEN @Start_Time AND @End_Time                 
               OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
             ) 
    END
--EndIf @QueryType ...
/* Retrieve FROM the join, the basic data that require no calculation  */
SELECT @Average = AVG(CONVERT(Real,Result))
     , @Min     = MIN(CONVERT(Real,Result))
     , @Max     = Max(CONVERT(Real,Result))
     , @Total   = sum(CONVERT(Real,Result))
     , @Count   = count(Result)
  FROM #Tests t
  JOIN #Prod_Starts ps On ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)
If @ExtraCalcs = 1 
  BEGIN
    SELECT @FetchCount = 0
    SELECT @SumXSqr = 0
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
    EXECUTE ('Declare spXLA_FilteredTestsCalc_AP_TCursor CURSOR Global Static
              For ( SELECT t.* 
                      FROM #Tests t 
                      JOIN #Prod_Starts ps ON ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)
                  )  
 	  	   For Read Only'
            )
    GOTO OPEN_CURSOR_AND_PROCESS_EXTRACALC_STUFF
  END
--EndIf
GOTO DO_FINAL_RETRIEVAL
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
RETRIEVE_WITH_APPLIED_PRODUCT_FILTER:
  --SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
  --Get Relevant information from production_Starts for any product in the specified time range.
  INSERT INTO #Prod_Starts
  SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
    FROM Production_starts ps
   WHERE Pu_id = @Pu_Id 
     AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
           OR (End_Time BETWEEN @Start_Time AND @End_Time) 
           OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
               --Start_time & End_time condition checked ; MSi/MT/3-21-2001
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
  -- NOTE3: As of 3-25-2002 MSI Start_Time inEvents table are mostly null. This storec procedure will insert
  --        a dummy value of TimeStamp minus one second for null Start_Time. For Customers who are concern about correct 
  --        Start_Time, which affect correct time-dependent Results, MSI will give them a script for one-time update of 
  --        the Events table. This update is time/disk-space consuming, thus, available upon request only.
  INSERT INTO #Applied_Products
      SELECT e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product
        FROM Events e
        JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NOT NULL
    UNION
      SELECT e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product
        FROM Events e
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NULL
        JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
  --Collect Database retrievable statistics
  SELECT @Average = AVG(CONVERT(Real,Result))
       , @Min     = MIN(CONVERT(Real,Result))
       , @Max     = Max(CONVERT(Real,Result))
       , @Total   = sum(CONVERT(Real,Result))
       , @Count   = count(Result)
    FROM #Tests t
    JOIN #Applied_Products ap On ap.Start_Time < t.Result_On AND (ap.End_Time >= t.Result_On OR ap.End_Time Is NULL)
    -- JOIN #Prod_Starts ps On ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)
  If @ExtraCalcs = 1 
    BEGIN
      EXECUTE ('Declare spXLA_FilteredTestsCalc_AP_TCursor CURSOR Global Static 
                For ( SELECT t.* 
                        FROM #Tests t 
                        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On
                    )  
                For Read Only'
              )
      GOTO OPEN_CURSOR_AND_PROCESS_EXTRACALC_STUFF
    END
  --EndIf
  GOTO DO_FINAL_RETRIEVAL
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
-- OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-OPEN AND PROCESS CURSOR TO DO EXTRACALC-
OPEN_CURSOR_AND_PROCESS_EXTRACALC_STUFF:
  SELECT @FetchCount = 0
  SELECT @SumXSqr = 0
  OPEN spXLA_FilteredTestsCalc_AP_TCursor
EXTRACALC_FETCH_LOOP:
  FETCH NEXT FROM spXLA_FilteredTestsCalc_AP_TCursor INTO @@Result_On, @@Result
  If (@@Fetch_Status = 0)
    BEGIN
      If @FetchCount = 0 
        BEGIN
          SELECT @TempMin   = CONVERT(Real, @@Result)
          SELECT @TempMax   = @TempMin
          SELECT @TimeOfMin = @@Result_On
          SELECT @TimeOfMax = @@Result_On 
        END
      --EndIf @FetchCount = 0
      If CONVERT(Real,@@Result) < @TempMin
        BEGIN
          SELECT @TempMin   = CONVERT(Real,@@Result)
          SELECT @TimeOfMin = @@Result_On
        END
      --EndIf CONVERT...
      If CONVERT(Real,@@Result) > @TempMax
        BEGIN
          SELECT @TempMax   = CONVERT(Real,@@Result)
          SELECT @TimeOfMax = @@Result_On
        END
      --EndIf CONVERT...
      SELECT @SumXSqr = @SumXSqr + Power(@Average - CONVERT(Real,@@Result),2)      
      SELECT @FetchCount = @FetchCount + 1
      GOTO EXTRACALC_FETCH_LOOP
    END
  --EndIf (@@Fetch_Status = 0)
  CLOSE spXLA_FilteredTestsCalc_AP_TCursor
  DEALLOCATE spXLA_FilteredTestsCalc_AP_TCursor
  --FIX: MSi/mt/8-2-2001
  --SELECT @Std = Power(@SumXSqr / (1.0 * (@Count - 1)),0.5) ( *** ERROR:OVERFLOW if @Count = 1; *** )
  --If there is only one row MAX = MIN and standard deviation = 0
  If @Count = 1 SELECT @Std = 0 Else SELECT @Std = POWER(@SumXSqr / (1.0 * (@Count - 1)),0.5)
DO_FINAL_RETRIEVAL:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  --Return Resultset
  SELECT Average = @Average 
       , Minimum = @Min
       , Maximum = @Max
       , Total = @Total
       , CountOfRows = @Count
       , StandardDeviation = @Std
       , TimeOfMinimum     = @TimeOfMin at time zone @DBTz at time zone @InTimeZone
       , TimeOfMaximum     = @TimeOfMax at time zone @DBTz at time zone @InTimeZone  
       , Data_Type_Id = @Data_Type_Id
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #Tests
  DROP TABLE #Prod_Starts 
  DROP TABLE #Products
  DROP TABLE #Applied_Products
