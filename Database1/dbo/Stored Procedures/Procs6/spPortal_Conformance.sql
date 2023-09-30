/* 
  DESCRIPTION:
  This stored procedure is to provide to Portal Connector the funtionality currently available in a custom report known as "Conformance Report". The report retrieves
  data (products, variables, and conformance data) from the database and performs a secondary processing of the data to produce the final output for display on Excel
  spreadsheet. 
  DESIGN:
  Out goal is to eliminate secondary processing of data on the Portal Connector Client. The design goal is to return to Portal Connector a single
  result set containing all of the data that RTIP Connnector needs. Thus spPortal_Conformance will combine code logics from all of Conformance report's 
  components (stored procedures VBA code logics in the template named "Conformance.xlt") taking into consideration of the Portal Connector limited 
  display capability, such as its inability to displaying tabs like Excel.
  Conformance Report provides option for short form (18 fields) or long form (24 fields) depending on the  number of fields to display. We will provide
  all 24 fields and let RTIP side decides what to display.
-- DEVELOPMENT NOTE:
--   Count of Events and Count of Rejects within a given variable for a given product and production unit
--   Count of events  = count of events from Events table between start and end times
--   Count of Rejects = count of rejects between start and end time
--     where Rejects defined as: products that have been applied (Events.Applied_product is not null) or products with event_status in (10, 12)
--
--   Start and End Date use in counting events and rejects
--     Start = Effective Date OR report's start time if Effective Date is NULL OR Effective Date is earlier than report's start time
--     End   = Expiration Date OR reporot's end date if Expiration Date is NULL OR Expiration Date is later than report's end time 
   Display Heading   Field Name
   In Conformance    In this SP
   Report
   _______________   _________________
1  Lower Reject      L_Reject
2  Lower Warning     L_Warning
3  Target            Target        
4  Upper Warning     U_Warning          
5  Upper Reject      U_Reject           
6  Reject % Below    Percent_L_Reject         <--------------- iPercent_LR / #Tested
7  Control % Below   Percent_L_Control        <--------------- iPercent_LW / #Tested
8  % Control         Percent_Control          <--------------- iPercent_TR / #Tested
9  Control % Above   Percent_U_Control        <--------------- iPercent_UW / #Tested
10 Reject % Above    Percent_U_Reject         <--------------- iPercent_UR / #Tested
11 Minimum Value     Min_Value                <--------------- Min(Result)
12 Maximum Value     Max_Value                <--------------- Max(Result)
13 Average           Average                  <--------------- Avg(Result)
14 Coeff Var Mean    percent_Coeff_Var_Mean   <--------------  100 * ABS(Std_Dev_Mean / Average)                  (not in short form)
15 Coeff Var Target  percent_Coeff_Var_Target <--------------- 100 *ABS(Std_Dev_Target/Target)                    (not in short form)
16 # of Samples      Num_Samples              <--------------- count of events
17 Std Dev Target    Std_Dev_Target           <--------------- Std Dev in Target                                  (not in short form)
18 % Tested          Num_Tested               <--------------- Sum (Tests.Result)
19 % Reject          Percent_Reject           <--------------- 100 *Reject Count/ Event Count
20 CPK               Cpk                      <--------------- see details elsewhere
21 % Dev Target      Percent_Dev_Target       <--------------- 100 * ABS((Average - Target)/ Target)              (not in short form)
22 Std Dev Mean      Std_Dev_Mean             <--------------- standard deviation of Mean                         (not in short form)
23 # Tested          Num_Tested               <--------------- Count(Tests.Result)
24 CPM               Cpm                      <--------------- see details elsewhere                              (not in short form)
*/
CREATE PROCEDURE dbo.spPortal_Conformance             -- ********************* PARAMETER DESCRIPTIONS ********************* 
 	   @Master_Unit  	         Integer               -- Master_Unit or PU_Id
 	 , @VariableStr1         Varchar(8000)         -- @VariableStr1 and @VariableStr2 are comma-separated lists of variable IDs
 	 , @VariableStr2         Varchar(8000)         -- Use '$' to denote the end of comma-separated list; use '_' (underscore) as continuation sign
 	 , @Start_Time  	         Datetime              -- Report's start time
 	 , @End_Time  	         Datetime              -- Report's end time
 	 , @ProductStr1  	  	 Varchar(8000) = NULL  -- @ProductStr1 and @ProductStr2 are comma-separated lists of product IDs
 	 , @ProductStr2  	  	 Varchar(8000) = NULL  -- Use '$' to denote the end of comma-separated list; use '_' (underscore) as continuation sign
        , @AppliedProductFilter TinyInt       = 0     -- 0 = Don't use applied product filter; 1 = do use applied product filter
        , @BrokeEventFilter     TinyInt       = 0     -- 0 = Don't use broke event filter;     1 = do use broke event filter  (Event Status 10, 12)
AS
 	 -- For Processing Comma-Separated ID List
DECLARE @CurrentIDString   Varchar(8000) 	 
DECLARE @i                 Integer
DECLARE @TempChar          char
DECLARE @TempString        Varchar(10)
Declare @ItemCount         Integer
DECLARE @TempID            Integer
 	 -- For Filter Time Table
DECLARE @TimeFilter                       TinyInt
DECLARE @APPLIED_PRODUCT_AND_BROKE_EVENT  TinyInt
DECLARE @BROKE_EVENT                      TinyInt
DECLARE @APPLIED_PRODUCT                  TinyInt
SELECT @APPLIED_PRODUCT                   = 1
SELECT @APPLIED_PRODUCT_AND_BROKE_EVENT   = 2
SELECT @BROKE_EVENT                       = 3
 	 -- For Cursor Use (To process/calculate Conformance Data)
DECLARE @Cpk               FLOAT
DECLARE @Cpm               FLOAT
DECLARE @Result            FLOAT
DECLARE @L_Warning         FLOAT
DECLARE @U_Warning         FLOAT
DECLARE @L_Reject          FLOAT
DECLARE @U_Reject          FLOAT
DECLARE @Target            FLOAT
DECLARE @Min               FLOAT
DECLARE @Max               FLOAT
DECLARE @Mean              FLOAT
DECLARE @StdDevTarget      FLOAT
DECLARE @StdDevMean        FLOAT
DECLARE @Temp              FLOAT
DECLARE @RejectCount       INT 	  	 -- count of Rejects for one product
DECLARE @TotalRejects      INT 	  	 -- count of rejects in all products
DECLARE @EventCount        INT          -- count of events in one product
DECLARE @TotalEvents       INT 	  	 -- count of events in all products
DECLARE @Old_L_Reject      FLOAT
DECLARE @Old_U_Reject      FLOAT
DECLARE @Old_Target        FLOAT
DECLARE @Old_Var_Id        INT
DECLARE @Old_Prod_Id       INT
DECLARE @Old_Start_Date    DATETIME
DECLARE @Old_End_Date      DATETIME
DECLARE @Old_Result_On     DATETIME
DECLARE @TotalNum          INT
DECLARE @Count             INT
DECLARE @Sum               FLOAT
DECLARE @SumSquares        FLOAT
DECLARE @SumDeltaTargetSqrs     FLOAT
DECLARE @percent_L_Reject  INT 	  	 -- intermediate for calc % Reject Below  = @percent_L_Reject  / #Tested
DECLARE @percent_U_Reject  INT 	  	 -- intermediate for calc % Reject Above  = @percent_U_Reject  / #Tested
DECLARE @percent_L_Warning INT 	  	 -- intermediate for calc % Control Below = @percent_L_Warning / #Tested
DECLARE @percent_Target    INT 	  	 -- intermediate for calc % Control       = @percent_Target    / #Tested  
DECLARE @percent_U_Warning INT 	  	 -- intermediate for calc % Control Above = @percent_U_Warning / #Tested
DECLARE @Curr_Start_Time   DATETIME
DECLARE @Result_On         DATETIME
 	 -- Cursor Variables
DECLARE @@Var_Id           INT
DECLARE @@Prod_Id          INT
DECLARE @@Result_On        DATETIME
DECLARE @@Result           Varchar(25)
DECLARE @@L_Reject         Varchar(25)
DECLARE @@L_Warning        Varchar(25)
DECLARE @@L_User           Varchar(25)
DECLARE @@Target           Varchar(25)
DECLARE @@U_User           Varchar(25)
DECLARE @@U_Warning        Varchar(25)
DECLARE @@U_Reject         Varchar(25)
DECLARE @@Adjusted_Start   DATETIME
DECLARE @@Adjusted_End     DATETIME
SET NOCOUNT ON
/*
CREATE TABLE #Conf_Data  (   Result_On DATETIME, Result Varchar(25)
                           , Var_Id INT, PU_Id INT, Prod_ID INT, Start_Time DATETIME, End_Time DATETIME NULL
                           , Adjusted_Start_Time DATETIME NULL, Adjusted_End_Time DATETIME NULL, Event_Count INT NULL, Reject_Count INT NULL
                           , L_Reject Varchar(25) NULL, L_Warning Varchar(25) NULL, L_User Varchar(25) NULL, Target Varchar(25) NULL
                           , U_User Varchar(25) NULL, U_Warning Varchar(25) NULL, U_Reject Varchar(25) NULL, Effective_Date DATETIME NULL
                           , Expiration_Date DATETIME NULL 
                         )
*/
CREATE TABLE #Conf_Data (   Result_On DATETIME, Result Varchar(25)
                           , Var_Id INT, PU_Id INT, Prod_ID INT, Start_Time DATETIME, End_Time DATETIME NULL
                           , Adjusted_Start_Time DATETIME NULL, Adjusted_End_Time DATETIME NULL, Event_Count INT NULL, Reject_Count INT NULL
                           , L_Reject Varchar(25) NULL, L_Warning Varchar(25) NULL, L_User Varchar(25) NULL, Target Varchar(25) NULL
                           , U_User Varchar(25) NULL, U_Warning Varchar(25) NULL, U_Reject Varchar(25) NULL, Effective_Date DATETIME NULL
                           , Expiration_Date DATETIME NULL
                         )
CREATE TABLE #MyReport   (   Prod_Id INT NULL, Var_Id INT, L_Reject Real NULL, L_Warning Real NULL, Target Real NULL, U_Warning Real NULL, U_Reject Real NULL
                           , Percent_L_Reject Real NULL, Percent_L_Control Real NULL, Percent_Control Real NULL, Percent_U_Control Real NULL
                           , Percent_U_Reject Real NULL, Min_Value Real NULL, Max_Value Real NULL, Average Real NULL, percent_Coeff_Var_Mean Real NULL
                           , percent_Coeff_Var_Target Real NULL, Num_Samples INT NULL, Std_Dev_Target Real NULL, Percent_Tested Real NULL, Percent_Reject Real NULL
                           , Cpk Real NULL, Percent_Dev_Target Real NULL, Std_Dev_Mean Real NULL, Num_Tested INT NULL, Cpm Real NULL
                         )
CREATE TABLE #Prod_Starts     ( Var_Id INT, PU_Id INT, Prod_Id INT, Start_Time DATETIME, End_Time DATETIME )
CREATE TABLE #Products        ( Prod_Id INT )  
CREATE TABLE #Tests           ( Var_Id INT, Result_On DATETIME, Result Varchar(25) NULL ) 
CREATE TABLE #Variables       ( Var_Id INT NULL )
CREATE TABLE #EventTimeStamps ( TimeStamp DATETIME NULL )
---------------------------------------------------------------------------------------------------------
-- Get Site Parameters: Specification Setting: needed in statistical calculations
--                      [Company Name];
--                      [Site Name]
--                      
---------------------------------------------------------------------------------------------------------
DECLARE @SPECSETTING_NORMAL    TINYINT
DECLARE @SPECSETTING_EXCLUSIVE TINYINT
DECLARE @SpecSetting           TINYINT
SELECT  @SPECSETTING_NORMAL    = 1
SELECT  @SPECSETTING_EXCLUSIVE = 2
SELECT @SpecSetting = s.Value FROM  Site_Parameters s JOIN Parameters p ON p.Parm_Id = s.Parm_Id AND p.Parm_Name = 'SpecificationSetting'
---------------------------------------------------------------------------------------------------------
-- Create Event TimeStamp Table: Use this table to filter out (eliminate) some Result_On in Tests Table
---------------------------------------------------------------------------------------------------------
IF      @AppliedProductFilter = 1 AND @BrokeEventFilter = 1 SELECT @TimeFilter = @APPLIED_PRODUCT_AND_BROKE_EVENT
ELSE IF @AppliedProductFilter = 1                           SELECT @TimeFilter = @APPLIED_PRODUCT
ELSE IF @BrokeEventFilter     = 1                           SELECT @TimeFilter = @BROKE_EVENT
If @TimeFilter = @APPLIED_PRODUCT
  BEGIN
    INSERT INTO #EventTimeStamps
    SELECT TimeStamp 
      FROM Events  
     WHERE PU_Id = @Master_Unit AND TimeStamp >= @Start_Time AND TimeStamp < @End_Time 
       AND Applied_Product IS NOT NULL
  END
ELSE IF @TimeFilter = @APPLIED_PRODUCT_AND_BROKE_EVENT
  BEGIN
    INSERT INTO #EventTimeStamps
    SELECT TimeStamp 
      FROM Events 
     WHERE PU_Id = @Master_Unit AND TimeStamp >= @Start_Time AND TimeStamp < @End_Time 
       AND ( Applied_Product Is NOT NULL OR Event_Status IN (10,12) )
  END
ELSE IF @TimeFilter = @BROKE_EVENT
  BEGIN
    INSERT INTO #EventTimeStamps
    SELECT TimeStamp
      FROM Events 
     WHERE PU_Id = @Master_Unit AND TimeStamp >= @Start_Time 
       AND TimeStamp < @End_Time AND Event_Status IN (10,12)
  END
--EndIf
-----------------------------------------------------------------------------------------
-- CAPTURE VARIABLES FROM COMMA-SEPARATED INPUT STRINGS: PUT THEM INTO A #Variables TABLE
-----------------------------------------------------------------------------------------
-- Initialize string-type variable to avoid string + NULL ==> Error
SELECT @CurrentIDString = ''
SELECT @TempString      = ''
SELECT @i = 1
SELECT @ItemCount = 0
SELECT @CurrentIDString = @VariableStr1
SELECT @TempChar = SUBSTRING (@CurrentIDString, @i, 1)
WHILE (@TempChar <> '$') AND (@i < 7999)
  BEGIN
    IF @TempChar <> ',' AND @TempChar <> '_'
      SELECT @TempString = @TempString + @TempChar
    ELSE
      BEGIN
        SELECT @TempString = LTRIM(RTRIM(@TempString))
        IF @TempString <> '' 
          BEGIN
            SELECT @TempID = CONVERT(Integer, @TempString)
            SELECT @ItemCount = @ItemCount + 1
            INSERT #Variables VALUES( @TempID )
          END
          IF @TempChar = ','
            BEGIN SELECT @TempString = ''  -- initailize string
            END
        ELSE -- @TempChar must be '_': time to Process the second input ID string 
          BEGIN
            SELECT @TempString = ''
            SELECT @CurrentIDString = @VariableStr2
            SELECT @i = 0
          END
      END
    --ENDIF @TempChar <> ',' AND @TempChar <> '_'              
    SELECT @i = @i + 1
    SELECT @TempChar = SUBSTRING(@CurrentIDString, @i, 1)
  END
--END WHILE (@TempChar <> '$') AND (@i < 7999)
 	  	 
SELECT @TempString = LTRIM(RTRIM(@TempString))
IF @TempString <> '' 
  BEGIN
    SELECT @TempID = CONVERT(Integer, @TempString)
    SELECT @ItemCount = @ItemCount + 1
    INSERT #Variables VALUES( @TempID )
  END
--ENDIF @TempString <> '' 
-----------------------------------------------------------------------
-- CAPTURE RELEVANT PRODUCT INFORMATION FROM Production_Starts TABLE
-----------------------------------------------------------------------
-- Initialize string-type variable to avoid string + null = NULL problem
SELECT @CurrentIDString = ''
SELECT @TempString      = ''
/* ID1 = "0$" signifies 'get any products' 5-25/2000 MSI/MT */
If @ProductStr1 = '0$' SELECT @ProductStr1 = NULL
If @ProductStr1 IS NOT NULL
  BEGIN
    SELECT @i = 1
    SELECT @ItemCount = 0
    SELECT @CurrentIDString = @ProductStr1 	  	     
    SELECT @TempChar = SUBSTRING (@CurrentIDString, @i, 1)
    WHILE (@TempChar <> '$') AND (@i < 7999)
      BEGIN
        IF @TempChar <> ',' AND @TempChar <> '_'
          SELECT @TempString = @TempString + @TempChar
        ELSE
          BEGIN
            SELECT @TempString = LTRIM(RTRIM(@TempString))
            IF @TempString <> '' 
              BEGIN
                SELECT @TempID = CONVERT(Integer, @TempString)
                SELECT @ItemCount = @ItemCount + 1
                INSERT #Products values( @TempID )
              END
              IF @TempChar = ','
                BEGIN
                  SELECT @TempString = ''
                END
            ELSE -- Go To Next Set Of Ids (@TempChar = '_')
              BEGIN
                SELECT @TempString = ''
                SELECT @CurrentIDString = @ProductStr2
                SELECT @i = 0
              END
          END
        --ENDIF @TempChar <> ',' AND @TempChar <> '_'              
        SELECT @i = @i + 1
        SELECT @TempChar = SUBSTRING(@CurrentIDString, @i, 1)
      END
    --END WHILE (@TempChar <> '$') AND (@i < 7999)
 	  	 
    SELECT @TempString = LTRIM(RTRIM(@TempString))
    IF @TempString <> '' 
      BEGIN
        SELECT @TempID = CONVERT(Integer, @TempString)
        SELECT @ItemCount = @ItemCount + 1
        INSERT #Products values( @TempID )
      END
    --ENDIF @TempString <> '' 
      INSERT INTO #Prod_Starts
      SELECT v.Var_Id, ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM Production_Starts ps
        JOIN #Products p ON p.Prod_Id = ps.Prod_Id 
        JOIN Variables v ON v.PU_Id = ps.PU_Id AND ps.PU_Id = @Master_Unit
        JOIN #Variables tv ON tv.Var_Id = v.Var_Id
       WHERE (    ( ps.Start_Time BETWEEN @Start_Time AND @End_Time ) 
               OR ( ps.End_Time BETWEEN @Start_Time AND @End_Time ) 
               OR ( ps.Start_Time <= @Start_Time AND ( ps.End_Time > @End_Time OR End_Time IS NULL) )
             )
  END
ELSE -- Get all products    
  BEGIN
      INSERT INTO #Prod_Starts
      SELECT v.Var_Id, ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
        FROM Production_Starts ps
        JOIN Variables v ON v.PU_Id = ps.PU_Id AND ps.PU_Id = @Master_Unit
        JOIN #Variables tv ON tv.Var_Id = v.Var_Id
       WHERE (     ( ps.Start_Time BETWEEN @Start_Time AND @End_Time ) 
               OR ( ps.End_Time BETWEEN @Start_Time AND @End_Time ) 
               OR ( ps.Start_Time <= @Start_Time AND ( PS.End_Time > @End_Time OR End_Time IS NULL ) )
             )
  END
--EndIf
 	 -- { ECR #29687: mt/4-19-2005
UPDATE #Prod_Starts SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
UPDATE #Prod_Starts SET End_Time   = @End_Time   WHERE End_Time   > @End_Time
UPDATE #Prod_Starts SET End_Time   = @End_Time   WHERE End_Time IS NULL
 	 -- } ECR #29687
-----------------------------------------------------------------------------------------
-- CAPTURE RELEVANT TESTS DATA INTO A #Tests TABLE
-----------------------------------------------------------------------------------------
INSERT INTO #Tests
  SELECT t.Var_Id, t.Result_On, t.Result 
    FROM Tests t
    JOIN #Variables v ON v.Var_Id = t.Var_Id 
   WHERE t.Result_On >= @Start_Time AND t.Result_on < @End_Time AND t.result is NOT NULL
DELETE FROM #Tests WHERE Result_On IN ( SELECT e.TimeStamp FROM #EventTimeStamps e )
-----------------------------------------------------------------------------------------
-- CAPTURE RELVANT DATA FROM VAR_SPECS INTO #Conf_Data TABLE
-- Update Adjusted_Start_Time & Adjusted_End_Time; they will be used to calculate
-- counts of events & rejectes later
-----------------------------------------------------------------------------------------
-- Get data from Tests table
INSERT INTO #Conf_Data
    SELECT t.Result_On, t.Result, t.Var_Id, ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time, [Adjusted_Start_Time] = ps.Start_Time, [Adjusted_End_Time] = ps.End_Time
          , [Event_Counts] = NULL, [Reject_Count] = NULL, L_Reject = NULL, L_Warning = NULL, L_User = NULL, Target = NULL
          , U_User = NULL, U_Warning = NULL, U_Reject = NULL, Effective_Date = NULL, Expiration_Date = NULL
      FROM #Tests t
      JOIN #Prod_Starts ps ON ps.Var_Id = t.Var_Id AND ps.Start_Time <= t.Result_On AND ( ps.End_Time > t.Result_On OR ps.End_Time IS NULL )
-- Get specifications for our variales. 
-- ( NOTE: DO NOT JOIN with Var_Specs, we'll lose our variables if they don't have specs )
UPDATE #Conf_Data
  SET L_Reject = vs.L_Reject, L_Warning = vs.L_Warning, L_User = vs.L_User, Target = vs.Target, U_User = vs.U_User, U_Warning = vs.U_Warning, U_Reject = vs.U_Reject, Effective_Date = vs.Effective_Date, Expiration_Date = vs.Expiration_Date
    FROM Var_Specs vs
   WHERE vs.Var_Id = #Conf_Data.Var_Id AND vs.Prod_Id = #Conf_Data.prod_Id AND vs.Effective_Date <= #Conf_Data.Start_Time 
     AND ( vs.Expiration_Date > #Conf_Data.Start_Time OR vs.Expiration_Date IS NULL )
 	 -- { ECR #29687: mt/4-19-2005
UPDATE #Conf_Data SET Adjusted_Start_Time = @Start_Time    WHERE Effective_Date IS NULL OR Effective_Date < @Start_Time
UPDATE #Conf_Data SET Adjusted_Start_Time = Effective_Date WHERE Effective_Date > @Start_Time AND Effective_Date Is NOT NULL
--UPDATE #Conf_Data SET Adjusted_Start_Time = @Start_Time WHERE Effective_Date < @Start_Time      	 -- ECR #29687
--UPDATE #Conf_Data SET Adjusted_Start_Time = @Start_Time WHERE Adjusted_Start_Time < @Start_Time    	 -- ECR #29687
UPDATE #Conf_Data SET Adjusted_End_Time = @End_Time       WHERE Expiration_Date IS NULL OR Expiration_Date > @End_Time
UPDATE #Conf_Data SET Adjusted_End_Time = Expiration_Date WHERE Expiration_Date < @End_Time AND Expiration_Date IS NOT NULL
--UPDATE #Conf_Data SET Adjusted_End_Time = @End_Time WHERE Expiration_Date > @Start_Time    	  	 -- ECR #29687
--UPDATE #Conf_Data SET Adjusted_End_Time = @End_Time WHERE Adjusted_End_Time > @Start_Time      	 -- ECR #29687
 	 -- } ECR #29687
TRUNCATE TABLE #Prod_Starts
TRUNCATE TABLE #Tests
TRUNCATE TABLE #Variables
TRUNCATE TABLE #Products
/*
GOAL: For each product returns specs and conformance info for the individual variables that associate with this product.
Algorithm Summary: 
  Loop through the cursor: 
   (a) whenever a different product is found get counts (events & rejects) for the previous product
   (b) whenever a different variable is found, calculate stats using cummulated counts, conformance statistics, etc.
initialize_old_tracking_identifiers_ProdId_VarId_Dates_etc
initialize_stat_intermediates
FETCH NEXT FROM CURSOR product etc.
n = 1
while ( @@FETCH_STATUS == 0 )
{  
    If ( old_Prod_Id == curr_Prod_Id || n = 1 ) //same product or row1
    {
        if ( old_Var_Id == curr_Var_Id || n = 1) // same var or row1
        {
            collect_and_accumulate_statistics_intermediates_for_current_set_of_rows
        }
        else //var_change
        {
            get_counts_event_reject_for_product_in_previous_row
            calculate_statistics_from_intermediates_for_previous_variable
            write_current_fetched_info_and_stats_for_previous_variable
            initialize_statistics_accumulators
                ---
            collect_and_accumulate_statistics_intermediates_for_the_next_set_of_rows
        }
    }
    Else //different product, completed previous variable 
    {
        get_counts_event_reject_for_product_in_previous_row
        calculate_statistics_from_intermediates_for_previous_variable
        write_current_fetched_info_and_stats_for_previous_variable
        initialize_statistics_accumulators
            ---
        collect_and_accumulate_statistics_intermediates_for_the_next_set_of_rows
    }//outer_block
    // always fetch at end of loop
    initialize_old_tracking_identifiers_product_variable_dates_etc
    n++
    FETCH NEXT FROM CURSOR product etc.
    cached_the_fetched_data_locally
}
get_counts_event_reject_for_product_in_the_current_row
calculate_statistics_from_intermediates_for_variable_the_current_row
write_current_fetched_info_and_stats_for_variable_in_the_current_row
Close Cursor
Dealocate Cursor
*/
/*
-- Use another temp table to pre-order the data (to get around inability to use ORDER BY in select statement in INSENSITIVE 
-- cursor) 
--
  INSERT INTO #Sorted_Data SELECT #Conf_Data.* FROM #Conf_Data ORDER BY #Conf_Data.Prod_Id, #Conf_Data.Var_Id, #Conf_Data.Result_On
  --TRUNCATE TABLE #Conf_Data
  DECLARE Conf_Cursor INSENSITIVE CURSOR 
  FOR 
    (  SELECT Var_Id, Prod_Id, Result_On, Result, L_Reject, L_Warning, Target, U_Warning, U_Reject, Adjusted_Start_Time, Adjusted_End_Time
       FROM #Conf_Data
    )
  FOR READ ONLY
*/    
  -- *** Cursor Definition fails if there are parentheses around select statement *** --
  DECLARE Conf_Cursor INSENSITIVE CURSOR 
  FOR 
      SELECT Var_Id, Prod_Id, Result_On, Result, L_Reject, L_Warning, Target, U_Warning, U_Reject, Adjusted_Start_Time, Adjusted_End_Time
        FROM #Conf_Data
    ORDER BY Prod_Id, Var_Id, Result_On
  FOR READ ONLY
  OPEN Conf_Cursor
  -- Initialize....
  SELECT @Old_Prod_Id = 0,      @Old_Var_Id = 0,        @EventCount = 0,        @RejectCount = 0
  SELECT @Old_Start_Date = '',  @Old_End_Date = '',     @Old_Result_On = '',    @Old_Target = 0,        @Old_U_Reject = 0,     @Old_L_Reject = 0
  SELECT @TotalNum = 0,         @Count = 0,             @Sum = 0,               @SumSquares = 0,        @SumDeltaTargetSqrs = 0 
  SELECT @StdDevTarget = 0,     @StdDevMean = 0,        @Temp = 0,              @Min = 0,               @Max = 0,              @Mean = 0
  SELECT @percent_L_Reject = 0, @percent_L_Warning = 0, @percent_U_Reject = 0,  @percent_U_Warning = 0
  SELECT @percent_U_Reject = 0, @percent_L_Reject  = 0, @percent_U_Warning = 0, @percent_L_Warning = 0, @percent_Target = 0
  SELECT @L_Reject = 0,         @U_Reject = 0,          @Target = 0
  FETCH NEXT FROM Conf_Cursor INTO @@Var_Id, @@Prod_Id, @@Result_On, @@Result, @@L_Reject, @@L_Warning, @@Target, @@U_Warning, @@U_Reject, @@Adjusted_Start, @@Adjusted_End
  SELECT @Count = @Count + 1 --, @TotalNum = @TotalNum + 1 ( don't increment @TotalNum here count 1 correspond to @Old_Prod_Id = 0; @Old_Var_Id = 0 )
  -- capture
  SELECT @Result = CONVERT( FLOAT, @@Result ), @L_Reject = CONVERT( FLOAT, @@L_Reject ), @L_Warning = CONVERT( FLOAT, @@L_Warning ), @U_Warning = CONVERT( FLOAT, @@U_Warning )
  SELECT @Target = CONVERT( FLOAT, @@Target ), @U_Reject = CONVERT( FLOAT, @@U_Reject )
  --
  WHILE ( @@FETCH_STATUS = 0 )
    BEGIN
      IF ( @Old_Prod_Id = @@Prod_Id OR @Count = 1 ) -- same product or row 1
        BEGIN
          IF ( @Old_Var_Id = @@Var_Id OR @Count = 1 ) --same var or row 1
            BEGIN
              -- accumulate_stats_intermediates_for_current_variable
              -- Note: @TotalNum = 0, the very first row; @TotalNum = 1 when first fetch after statistics written to temp table
              IF @Min > @Result OR @TotalNum = 0 SET @Min = @Result
              IF @Max < @Result OR @TotalNum = 0 SET @Max = @Result
              SELECT @Sum = @Sum + @Result, @SumSquares = @SumSquares + @Result * @Result
              IF @Target IS NOT NULL  SELECT @SumDeltaTargetSqrs = @SumDeltaTargetSqrs + (@Result - @Target) * (@Result - @Target)
              -- accumulate_spec_const_to_use_in_percent_specs_calc
             IF     ( @U_Reject  IS NOT NULL AND @Result >  @U_Reject  AND @SpecSetting = @SPECSETTING_NORMAL    ) 
                 OR ( @U_Reject  IS NOT NULL AND @Result >= @U_Reject  AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_U_Reject  = @percent_U_Reject  + 1
             ELSE IF( @U_Warning IS NOT NULL AND @Result >  @U_Warning AND @SpecSetting = @SPECSETTING_NORMAL    ) 
                 OR ( @U_Warning IS NOT NULL AND @Result >= @U_Warning AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_U_Warning = @percent_U_Warning + 1
             ELSE IF( @L_Reject  IS NOT NULL AND @Result <  @L_Reject  AND @SpecSetting = @SPECSETTING_NORMAL    ) 
                 OR ( @L_Reject  IS NOT NULL AND @Result <= @L_Reject  AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_L_Reject  = @percent_L_Reject  + 1
             ELSE IF( @L_Warning IS NOT NULL AND @Result <  @L_Warning AND @SpecSetting = @SPECSETTING_NORMAL    ) 
                 OR ( @L_Warning IS NOT NULL AND @Result <= @L_Warning AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_L_Warning = @percent_L_Warning + 1
             ELSE                                                                                                  SELECT @percent_Target    = @percent_Target    + 1
             --ENDIF spec_const_accumulate
            END
          ELSE -- DIFFERENT VARIABLE FOUND, DONE WITH ACCUMULATION
            BEGIN
              -- get_counts_events_and_rejects_for_product_in_previous_variable
              EXECUTE spRE_ConformanceCountEvents @Master_Unit, @Old_Prod_Id, @Old_Start_Date, @Old_End_Date, @EventCount OUT, @RejectCount OUT
              UPDATE #Conf_Data SET Event_Count = @EventCount, Reject_Count = @RejectCount WHERE Prod_Id = @Old_Prod_Id AND Var_Id = @Old_Var_Id AND Result_On = @Old_Result_On
              -- calculate_statistics_from_intermediates: write_current_fetched_info_and_stats : write_countevents_%tested_%reject
              SELECT @Mean = CASE @TotalNum WHEN 0 THEN 0 ELSE @Sum / CONVERT( FLOAT, @TotalNum ) END
              SELECT @Temp = CASE @TotalNum WHEN 0 THEN 0 ELSE ABS( @SumSquares - (@Sum * @Sum)/ CONVERT( FLOAT, @TotalNum ) ) END
              IF @Temp > 0 AND @TotalNum >= 2 SELECT @StdDevMean = SQRT( @Temp/ (@TotalNum - 1) ) ELSE SELECT @StdDevMean = 0
              IF @SumDeltaTargetSqrs > 0 AND @TotalNum >= 2 SELECT @StdDevTarget = SQRT( @SumDeltaTargetSqrs/(@TotalNum - 1) ) ELSE SELECT @StdDevTarget = 0
              -- Calculation of Cpk
              IF @StdDevMean > 0
                BEGIN
                  IF      @Mean = @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpk = CASE @Old_U_Reject WHEN NULL THEN NULL ELSE ABS( @Old_U_Reject - @Old_L_Reject ) / ( 6 * @StdDevMean ) END
                  ELSE IF @Mean > @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpk = CASE @Old_U_Reject WHEN NULL THEN NULL ELSE ABS( @Old_U_Reject - @Mean ) / ( 3 * @StdDevMean ) END
                  ELSE IF @Mean < @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpk = CASE @Old_L_Reject WHEN NULL THEN NULL ELSE ABS( @Old_L_Reject - @Mean ) / ( 3 * @StdDevMean ) END
                END
              --ENDIF @StdDevMean > 0
              -- Calculation of Cpm
              IF @StdDevTarget > 0
                BEGIN
                  IF      @Mean = @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpm = CASE @Old_U_Reject WHEN NULL THEN NULL ELSE ABS( @Old_U_Reject - @Old_L_Reject ) / ( 6 * @StdDevTarget ) END
                  ELSE IF @Mean > @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpm = CASE @Old_U_Reject WHEN NULL THEN NULL ELSE ABS( @Old_U_Reject - @Old_Target   ) / ( 3 * @StdDevTarget ) END
                  ELSE IF @Mean < @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpm = CASE @Old_L_Reject WHEN NULL THEN NULL ELSE ABS( @Old_L_Reject - @Old_Target   ) / ( 3 * @StdDevTarget ) END
                END
              --ENDIF @StdDevTarget > 0
              -- write_current_Info
              INSERT INTO #MyReport
                 SELECT TOP 1 
                        d.Prod_Id, d.Var_Id
                      , CONVERT( FLOAT, d.L_Reject ), CONVERT( FLOAT, d.L_Warning ), CONVERT( FLOAT, d.Target ), CONVERT( FLOAT, d.U_Warning ), CONVERT( FLOAT, d.U_Reject )
                      , Percent_L_Reject         = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_L_Reject  ) / CONVERT( FLOAT, @TotalNum ) END
                      , Percent_L_Control        = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_L_Warning ) / CONVERT( FLOAT, @TotalNum ) END
                      , Percent_Control          = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_Target    ) / CONVERT( FLOAT, @TotalNum ) END
                      , Percent_U_Control        = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_U_Warning ) / CONVERT( FLOAT, @TotalNum ) END
                      , Percent_U_Reject         = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_U_Reject  ) / CONVERT( FLOAT, @TotalNum ) END
                      , Min_Value                = @Min  
                      , Max_Value                = @Max  
                      , Average                  = @Mean
                      , percent_Coeff_Var_Mean   = CASE @StdDevMean WHEN 0 THEN 0 ELSE 100 * ABS( @StdDevMean/ @Mean ) END
                      , percent_Coeff_Var_Target = CASE CONVERT( FLOAT, d.Target ) WHEN NULL THEN NULL WHEN 0 THEN NULL ELSE 100 * ABS( @StdDevTarget / CONVERT(FLOAT, d.Target) ) END
                      , Num_Samples              = @EventCount
                      , Std_Dev_Target           = @StdDevTarget
                      , Percent_Tested           = CASE @EventCount WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @TotalNum    ) / CONVERT( FLOAT, @EventCount ) END
                      , Percent_Reject           = CASE @EventCount WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @RejectCount ) / CONVERT( FLOAT, @EventCount ) END
                      , Cpk                      = @Cpk
                      , Percent_Dev_Target       = CASE CONVERT( FLOAT, d.Target ) WHEN NULL THEN NULL WHEN 0 THEN NULL ELSE 100 * ABS( (@Mean - CONVERT(FLOAT, d.Target))/ CONVERT( FLOAT, d.Target) ) END
                      , Std_Dev_Mean             = @StdDevMean
                      , Num_Tested               = @TotalNum
                      , Cpm                      = @Cpm
                   FROM #Conf_Data d
                  WHERE d.Prod_Id = @Old_Prod_Id AND d.Var_Id = @Old_Var_Id AND d.Result_On = @Old_Result_On
              --INSERT END
              -- initialize_accumulators_from_previous_accumulations
              SELECT @TotalNum = 0,         @EventCount = 0,        @RejectCount = 0,      @SumSquares = 0,        @SumDeltaTargetSqrs = 0
                   ,  @Sum = 0,             @Max = 0,               @Min = 0,              @Cpk = NULL,            @Cpm = NULL
                   , @percent_U_Reject = 0, @percent_U_Warning = 0, @percent_L_Reject = 0, @percent_L_Warning = 0, @percent_Target = 0
              --accumulate_stats_intermediates_for_current_row
              SELECT @Min = @Result, @Max = @Result  -- this is the begin of next accumulation
              SELECT @Sum = @Sum + @Result, @SumSquares = @SumSquares + @Result * @Result
              IF @Target IS NOT NULL SELECT @SumDeltaTargetSqrs = @SumDeltaTargetSqrs + ( (@Result - @Target) * (@Result - @Target) )
              -- accumulate_spec_const_to_use_in_percent_specs_calc
             IF     ( @U_Reject  IS NOT NULL AND @Result >  @U_Reject  AND @SpecSetting = @SPECSETTING_NORMAL    ) 
                 OR ( @U_Reject  IS NOT NULL AND @Result >= @U_Reject  AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_U_Reject  = @percent_U_Reject  + 1
             ELSE IF( @U_Warning IS NOT NULL AND @Result >  @U_Warning AND @SpecSetting = @SPECSETTING_NORMAL    ) 
                 OR ( @U_Warning IS NOT NULL AND @Result >= @U_Warning AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_U_Warning = @percent_U_Warning + 1
             ELSE IF( @L_Reject  IS NOT NULL AND @Result <  @L_Reject  AND @SpecSetting = @SPECSETTING_NORMAL    ) 
                 OR ( @L_Reject  IS NOT NULL AND @Result <= @L_Reject  AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_L_Reject  = @percent_L_Reject  + 1
             ELSE IF( @L_Warning IS NOT NULL AND @Result <  @L_Warning AND @SpecSetting = @SPECSETTING_NORMAL    ) 
                 OR ( @L_Warning IS NOT NULL AND @Result <= @L_Warning AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_L_Warning = @percent_L_Warning + 1
             ELSE                                                                                                  SELECT @percent_Target    = @percent_Target    + 1
             --ENDIF accumulate_spec_const_to_use_in_percent_specs_calc
            END 
          --END IF old_variable_current_variable_check
        END
      Else -- DIFFERENT PRODUCT FOUND, DONE WITH ACCUMULATION
        BEGIN
          -- get_counts_events_and_rejects_for_product_in_previous_variable
          EXECUTE spRE_ConformanceCountEvents @Master_Unit, @Old_Prod_Id, @Old_Start_Date, @Old_End_Date, @EventCount OUT, @RejectCount OUT
          UPDATE #Conf_Data SET Event_Count = @EventCount, Reject_Count = @RejectCount WHERE Prod_Id = @Old_Prod_Id AND Var_Id = @Old_Var_Id AND Result_On = @Old_Result_On
          -- calculate_statistics_from_intermediates: write_current_fetched_info_and_stats : write_countevents_%tested_%reject
          SELECT @Mean = CASE @TotalNum WHEN 0 THEN 0 ELSE @Sum / CONVERT( FLOAT, @TotalNum ) END
          SELECT @Temp = CASE @TotalNum WHEN 0 THEN 0 ELSE ABS( @SumSquares - (@Sum * @Sum) / CONVERT(FLOAT, @TotalNum) ) END
          IF @Temp > 0 AND @TotalNum >= 2 SELECT @StdDevMean = SQRT( @Temp/ (@TotalNum - 1) ) ELSE SELECT @StdDevMean = 0
          IF @SumDeltaTargetSqrs > 0 AND  @TotalNum >= 2 SELECT @StdDevTarget = SQRT( @SumDeltaTargetSqrs/(@TotalNum - 1) ) ELSE SELECT @StdDevTarget = 0
          -- Calculation of Cpk
          IF @StdDevMean > 0
            BEGIN
              --CPK
              IF      @Mean = @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpk = CASE @Old_U_Reject WHEN NULL THEN NULL ELSE ABS( @Old_U_Reject - @Old_L_Reject ) / ( 6 * @StdDevMean ) END
              ELSE IF @Mean > @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpk = CASE @Old_U_Reject WHEN NULL THEN NULL ELSE ABS( @Old_U_Reject - @Mean ) / ( 3 * @StdDevMean ) END
              ELSE IF @Mean < @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpk = CASE @Old_L_Reject WHEN NULL THEN NULL ELSE ABS( @Old_L_Reject - @Mean ) / ( 3 * @StdDevMean ) END
            END
          --ENDIF @StdDevMean > 0
          -- Calculation of Cpm
          IF @StdDevTarget > 0
            BEGIN
              IF      @Mean = @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpm = CASE @Old_U_Reject WHEN NULL THEN NULL ELSE ABS( @Old_U_Reject - @Old_L_Reject ) / ( 6 * @StdDevTarget ) END
              ELSE IF @Mean > @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpm = CASE @Old_U_Reject WHEN NULL THEN NULL ELSE ABS( @Old_U_Reject - @Old_Target   ) / ( 3 * @StdDevTarget ) END
              ELSE IF @Mean < @Old_Target AND @Old_Target IS NOT NULL SELECT @Cpm = CASE @Old_L_Reject WHEN NULL THEN NULL ELSE ABS( @Old_L_Reject - @Old_Target   ) / ( 3 * @StdDevTarget ) END
            END
          --ENDIF @StdDevTarget > 0
          -- write_current_Info
          INSERT INTO #MyReport
             SELECT TOP 1 
                    d.Prod_Id, d.Var_Id
                  , CONVERT( FLOAT, d.L_Reject ), CONVERT( FLOAT, d.L_Warning ), CONVERT( FLOAT, d.Target ), CONVERT( FLOAT, d.U_Warning ), CONVERT( FLOAT, d.U_Reject )
                  , Percent_L_Reject         = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_L_Reject  ) / CONVERT( FLOAT, @TotalNum ) END
                  , Percent_L_Control        = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_L_Warning ) / CONVERT( FLOAT, @TotalNum ) END
                  , Percent_Control          = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_Target    ) / CONVERT( FLOAT, @TotalNum ) END
                  , Percent_U_Control        = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_U_Warning ) / CONVERT( FLOAT, @TotalNum ) END
                  , Percent_U_Reject         = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_U_Reject  ) / CONVERT( FLOAT, @TotalNum ) END
                  , Min_Value                = @Min  
                  , Max_Value                = @Max  
                  , Average                  = @Mean
                  , percent_Coeff_Var_Mean   = CASE @StdDevMean WHEN 0 THEN 0 ELSE 100 * ABS( @StdDevMean/ @Mean ) END
                  , percent_Coeff_Var_Target = CASE CONVERT(FLOAT, d.Target) WHEN NULL THEN NULL WHEN 0 THEN NULL ELSE 100 * ABS( @StdDevTarget / CONVERT(FLOAT, d.Target) ) END
                  , Num_Samples              = @EventCount
                  , Std_Dev_Target           = @StdDevTarget
                  , Percent_Tested           = CASE @EventCount WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @TotalNum    ) / CONVERT( FLOAT, @EventCount ) END
                  , Percent_Reject           = CASE @EventCount WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @RejectCount ) / CONVERT( FLOAT, @EventCount ) END
                  , Cpk                      = @Cpk
                  , Percent_Dev_Target       = CASE CONVERT( FLOAT, d.Target ) WHEN NULL THEN NULL WHEN 0 THEN NULL ELSE 100 * ABS( (@Mean - CONVERT(FLOAT, d.Target) )/ CONVERT( FLOAT, d.Target) ) END
                  , Std_Dev_Mean             = @StdDevMean
                  , Num_Tested               = @TotalNum
                  , Cpm                      = @Cpm
               FROM #Conf_Data d
              WHERE d.Prod_Id = @Old_Prod_Id AND d.Var_Id = @Old_Var_Id AND d.Result_On = @Old_Result_On
          --INSERT END
          -- initialize_accumulators_from_previous_accumulations
          SELECT @TotalNum = 0,         @EventCount = 0,        @RejectCount = 0,      @SumSquares = 0,        @SumDeltaTargetSqrs = 0
              ,  @Sum = 0,              @Max = 0,               @Min = 0,              @Cpk = NULL,            @Cpm = NULL --, @Target = 0
               , @percent_U_Reject = 0, @percent_U_Warning = 0, @percent_L_Reject = 0, @percent_L_Warning = 0, @percent_Target = 0
          --accumulate_stats_intermediates_for_current_row
          SELECT @Min = @Result, @Max = @Result   -- this is the start of next accumulation
          SELECT @Sum = @Sum + @Result, @SumSquares = @SumSquares + @Result * @Result
          IF @Target IS NOT NULL SELECT @SumDeltaTargetSqrs = @SumDeltaTargetSqrs + ( (@Result - @Target)*(@Result - @Target) )
          -- accumulate_spec_const_to_use_in_percent_specs_calc
          IF     ( @U_Reject  IS NOT NULL AND @Result >  @U_Reject  AND @SpecSetting = @SPECSETTING_NORMAL    ) 
              OR ( @U_Reject  IS NOT NULL AND @Result >= @U_Reject  AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_U_Reject  = @percent_U_Reject  + 1
          ELSE IF( @U_Warning IS NOT NULL AND @Result >  @U_Warning AND @SpecSetting = @SPECSETTING_NORMAL    ) 
              OR ( @U_Warning IS NOT NULL AND @Result >= @U_Warning AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_U_Warning = @percent_U_Warning + 1
          ELSE IF( @L_Reject  IS NOT NULL AND @Result <  @L_Reject  AND @SpecSetting = @SPECSETTING_NORMAL    ) 
              OR ( @L_Reject  IS NOT NULL AND @Result <= @L_Reject  AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_L_Reject  = @percent_L_Reject  + 1
          ELSE IF( @L_Warning IS NOT NULL AND @Result <  @L_Warning AND @SpecSetting = @SPECSETTING_NORMAL    ) 
              OR ( @L_Warning IS NOT NULL AND @Result <= @L_Warning AND @SpecSetting = @SPECSETTING_EXCLUSIVE ) SELECT @percent_L_Warning = @percent_L_Warning + 1
          ELSE                                                                                                  SELECT @percent_Target    = @percent_Target    + 1
          --ENDIF accumulate_spec_const_to_use_in_percent_specs_calc
        END
      --END IF old_product_new_product_check
      -- update_previous_row_tracking_identifiers
      SELECT @Old_Var_Id = @@Var_Id, @Old_Prod_Id = @@Prod_Id, @Old_Start_Date = @@Adjusted_Start, @Old_End_Date = @@Adjusted_End, @Old_Result_On = @@Result_On  
           , @Old_Target = CONVERT( FLOAT, @@Target ), @Old_U_Reject = CONVERT( FLOAT, @@U_Reject ), @Old_L_Reject = CONVERT(FLOAT, @@L_Reject )
      --FETCH NEXT FROM Conf_Cursor INTO @@Var_Id, @@Prod_Id, @@Start_Time, @@Result_On, @@Result, @@L_Reject, @@L_Warning, @@Target, @@U_Warning, @@U_Reject, @@Adjusted_Start, @@Adjusted_End
      FETCH NEXT FROM Conf_Cursor INTO @@Var_Id, @@Prod_Id, @@Result_On, @@Result, @@L_Reject, @@L_Warning, @@Target, @@U_Warning, @@U_Reject, @@Adjusted_Start, @@Adjusted_End
      SELECT @Count = @Count + 1, @TotalNum = @TotalNum + 1
      SELECT @Result   = CONVERT( FLOAT, @@Result   ), @Target    = CONVERT( FLOAT, @@Target    ), @U_Reject  = CONVERT( FLOAT, @@U_Reject  )
           , @L_Reject = CONVERT( FLOAT, @@L_Reject ), @U_Warning = CONVERT( FLOAT, @@U_Warning ), @L_Warning = CONVERT( FLOAT, @@L_Warning )
    END 
  --WHILE ( @@FETCH_STATUS = 0 )  
  -- CATCH THE VERY LAST ROW (CURRENT PRODUCT, CURRENT VARIABLE)
  -- get_counts_events_and_rejects_for_product_in_previous_variable
  EXECUTE spRE_ConformanceCountEvents @Master_Unit, @@Prod_Id, @@Adjusted_Start, @@Adjusted_End, @EventCount OUT, @RejectCount OUT
  -- update_Conf_Data2_for_debugging_purposes
  UPDATE #Conf_Data SET Event_Count = @EventCount, Reject_Count = @RejectCount WHERE Prod_Id = @@Prod_Id AND Var_Id = @@Var_Id AND Result_On = @@Result_On
  -- calculate_statistics_from_intermediates: write_current_fetched_info_and_stats : write_countevents_%tested_%reject
  SELECT @Mean = CASE @TotalNum WHEN 0 THEN 0 ELSE @Sum / CONVERT(FLOAT, @TotalNum) END
  SELECT @Temp = CASE @TotalNum WHEN 0 THEN 0 ELSE ABS(@SumSquares - (@Sum * @Sum)/ CONVERT(FLOAT, @TotalNum) ) END
  IF @Temp > 0 AND @TotalNum >= 2 SELECT @StdDevMean = SQRT(@Temp/ (@TotalNum - 1)) ELSE SELECT @StdDevMean = 0
  IF @SumDeltaTargetSqrs > 0 AND  @TotalNum >= 2 SELECT @StdDevTarget = SQRT( @SumDeltaTargetSqrs/(@TotalNum - 1) ) ELSE SELECT @StdDevTarget = 0
  -- Calculation of Cpk
  IF @StdDevMean > 0
    BEGIN
      IF      @Mean = @Target AND @Target IS NOT NULL SELECT @Cpk = CASE @U_Reject WHEN NULL THEN NULL ELSE ABS( @U_Reject - @L_Reject ) / ( 6 * @StdDevMean ) END
      ELSE IF @Mean > @Target AND @Target IS NOT NULL SELECT @Cpk = CASE @U_Reject WHEN NULL THEN NULL ELSE ABS( @U_Reject - @Mean     ) / ( 3 * @StdDevMean ) END
      ELSE IF @Mean < @Target AND @Target IS NOT NULL SELECT @Cpk = CASE @L_Reject WHEN NULL THEN NULL ELSE ABS( @L_Reject - @Mean     ) / ( 3 * @StdDevMean ) END
    END
  --ENDIF @StdDevMean > 0
  -- Calculation of Cpm
  IF @StdDevTarget > 0
    BEGIN
      IF      @Mean = @Target AND @Target IS NOT NULL SELECT @Cpm = CASE @U_Reject WHEN NULL THEN NULL ELSE ABS( @U_Reject - @L_Reject ) / ( 6 * @StdDevTarget ) END
      ELSE IF @Mean > @Target AND @Target IS NOT NULL SELECT @Cpm = CASE @U_Reject WHEN NULL THEN NULL ELSE ABS( @U_Reject - @Target   ) / ( 3 * @StdDevTarget ) END
      ELSE IF @Mean < @Target AND @Target IS NOT NULL SELECT @Cpm = CASE @L_Reject WHEN NULL THEN NULL ELSE ABS( @L_Reject - @Target   ) / ( 3 * @StdDevTarget ) END
    END
  --ENDIF @StdDevTarget > 0
  INSERT INTO #MyReport
    SELECT TOP 1 
        d.Prod_Id, d.Var_Id
      , CONVERT(FLOAT, d.L_Reject), CONVERT(FLOAT, d.L_Warning), CONVERT(FLOAT, d.Target), CONVERT(FLOAT, d.U_Warning), CONVERT(FLOAT, d.U_Reject)
      , Percent_L_Reject         = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_L_Reject  ) / CONVERT( FLOAT, @TotalNum ) END
      , Percent_L_Control        = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_L_Warning ) / CONVERT( FLOAT,@TotalNum  ) END
      , Percent_Control          = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_Target    ) / CONVERT( FLOAT,@TotalNum  ) END
      , Percent_U_Control        = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_U_Warning ) / CONVERT( FLOAT,@TotalNum  ) END
      , Percent_U_Reject         = CASE @TotalNum WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @percent_U_Reject  ) / CONVERT( FLOAT,@TotalNum  ) END
      , Min_Value                = @Min  
      , Max_Value                = @Max  
      , Average                  = @Mean
      , percent_Coeff_Var_Mean   = CASE @StdDevMean WHEN 0 THEN 0 ELSE 100 * ABS( @StdDevMean/ @Mean ) END
      , percent_Coeff_Var_Target = CASE CONVERT(FLOAT, d.Target) WHEN NULL THEN NULL WHEN 0 THEN 0 ELSE 100 * ABS( @StdDevTarget / CONVERT(FLOAT, d.Target) ) END
      , Num_Samples              = @EventCount
      , Std_Dev_Target           = @StdDevTarget
      , Percent_Tested           = CASE @EventCount WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @TotalNum    ) / CONVERT( FLOAT, @EventCount ) END
      , Percent_Reject           = CASE @EventCount WHEN 0 THEN 0 ELSE 100 * CONVERT( FLOAT, @RejectCount ) / CONVERT( FLOAT, @EventCount ) END
      , Cpk                      = @Cpk
      , Percent_Dev_Target       = CASE CONVERT(FLOAT,d.Target) WHEN NULL THEN NULL WHEN 0 THEN NULL ELSE 100 * ABS( (@Mean - CONVERT(FLOAT,d.Target))/ CONVERT(FLOAT, d.Target) ) END
      , Std_Dev_Mean             = @StdDevMean
      , Num_Tested               = @TotalNum
      , Cpm                      = @Cpm
   FROM #Conf_Data d
  WHERE d.Prod_Id = @@Prod_Id AND d.Var_Id = @@Var_Id AND d.Result_On = @@Result_On
  --INSERT END
  CLOSE Conf_Cursor
  DEALLOCATE Conf_Cursor
  GOTO RETURN_RESULTSET
--END OF PROCESS OF INDIVIDUAL PRODUCTS
RETURN_RESULTSET:  
  -- RETURN THE RESULT SET TO CALLER
  -- Portal Connector Client is responsible to hide 5 fields if user specified "Short Form"
  --select * From #MyReport -- debug to to prove that we have rows ordered correctly
/*
    SELECT Prod_Id, Var_Id, Event_Count, Reject_Count, [Adjusted_Start_Time] = CONVERT(Varchar(20), Adjusted_Start_Time), [Adjusted_End_Time]=CONVERT(Varchar(20), Adjusted_End_Time), [Start_Time]=CONVERT(Varchar(20), Start_Time), [End_Time]=CONVERT(Varchar(20), End_Time), [Effective_Date]=CONVERT(Varchar(20), Effective_Date), [Expiration_Date]=CONVERT(Varchar(20), Expiration_Date)
         , Result_On, Result, PU_Id, L_Reject, L_Warning, L_User, Target, U_User, U_Warning, U_Reject
      FROM #Conf_Data 
*/
    SELECT p.Prod_Code, v.Var_Desc, r.L_Reject, r.L_Warning, r.Target, r.U_Warning, r.U_Reject, r.Percent_L_Reject, r.Percent_L_Control, r.Percent_Control
         , r.Percent_U_Control, r.Percent_U_Reject, r.Min_Value, r.Max_Value, r.Average, r.percent_Coeff_Var_Mean, r.percent_Coeff_Var_Target, r.Num_Samples 	 
         , r.Std_Dev_Target, r.Percent_Tested, r.Percent_Reject, r.Cpk, r.Percent_Dev_Target, r.Std_Dev_Mean, r.Num_Tested, r.Cpm
      FROM #MyReport r
      JOIN Products p  ON p.Prod_Id = r.Prod_Id
      JOIN Variables v ON v.Var_Id = r.Var_Id
  ORDER BY p.Prod_Code, v.Var_Desc
DELETE_TEMP_TABLES:
  DROP TABLE #Conf_Data
  --DROP TABLE #Conf_Data
  DROP TABLE #Tests
  DROP TABLE #Products
  DROP TABLE #Variables
  DROP TABLE #Prod_Starts
  DROP TABLE #EventTimeStamps 
  DROP TABLE #MyReport 
