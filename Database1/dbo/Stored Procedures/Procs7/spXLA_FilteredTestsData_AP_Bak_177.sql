-- spXLA_FilteredTestsData_AP ( mt/1-8-2002 ) is modified from --spXLATestData_AP (spXLATestData_Expand & spXLATestData_NoProduct). 
-- Defect #24472:mt/9-12-2002: Changes include 
--    (a)crew,shift filters (b) ResultSet Always returns product code
-- ECR #25128: mt/3-13-2003: handle duplicate Var_desc since MSI doen't enforce unique Var_Desc across the entire GBDB.
-- ECR #34381 sb/9-15-2007:  Tests returned should be start_time<result_on<=end_time
-- ECR #34510 sb/9-16-2007: Crew schedule should be start_time<=result_on<=end_time
-- ECR #35939 sb/8-11-2008: Crew schedule altered to left outer join when no crew or shift specified to catch when no crew is available
CREATE PROCEDURE dbo.[spXLA_FilteredTestsData_AP_Bak_177]
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50) = NULL
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Prod_Id 	  	 Integer
 	 , @Group_Id 	  	 Integer
 	 , @Prop_Id 	  	 Integer
 	 , @Char_Id 	  	 Integer
    , @Crew_Desc            Varchar(10)
    , @Shift_Desc           Varchar(10)
 	 , @AppliedProductFilter 	 TinyInt 	  	   --0 = filter by original product; 1 = filter by applied product
 	 , @TimeSort 	  	 SmallInt 
 	 , @DecimalChar 	  	 Varchar(1) = NULL --Comma Or Period (Default) to accommodate different regional setttings on PC --mt/2-6-2002
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
 	 --Pertaining Data To Be included in ResultSet
DECLARE @Pu_Id 	  	  	 Integer
DECLARE @Data_Type_Id 	  	 Integer
DECLARE @Event_Type 	  	 SmallInt
DECLARE @MasterUnitId 	  	 Integer
DECLARE @VariableFetchCount 	 Integer
 	 --Needed for crew,shift
DECLARE @CrewShift              TinyInt
DECLARE @NoCrewNoShift          TinyInt
DECLARE @HasCrewNoShift         TinyInt
DECLARE @NoCrewHasShift         TinyInt
DECLARE @HasCrewHasShift        TinyInt
 	 --Local query assistance
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Define Crew,Shift Types
SELECT @NoCrewNoShift           = 1
SELECT @HasCrewNoShift          = 2
SELECT @NoCrewHasShift          = 3
SELECT @HasCrewHasShift         = 4
 	 --Initialize
SELECT @Data_Type_Id  	  	 = -1
SELECT @MasterUnitId 	  	 = -1
SELECT @Pu_Id  	  	  	 = -1
SELECT @Event_Type 	  	 = -1
SELECT @VariableFetchCount  	 = 0
-- TFS #23428 - Test Data By Test Name is calling spXLA_FilteredTestData_NoProduct or spXLA_FilteredTestData_AP with null start and end times.
-- since 01-Jan-1970 is the minumum date that any datetime can have in the GBDB database, check the start time and if it's less than 01-Jan-1970, just do a RETURN 
If @Start_Time < '01/01/1971'
BEGIN
 	 RETURN
END
If @DecimalChar Is NULL SELECT @DecimalChar = '.' 	 --Set Decimal Separator Default Value, if applicable
-- ECR #25128: mt/3-13-2003: the following code block modified to handle duplicate Var_desc
If @Var_Desc Is NULL AND @Var_Id Is NULL 
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --variable NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have @Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnitId = pu.Master_Unit 
      FROM Variables v 
      JOIN Prod_Units pu  ON pu.Pu_Id = v.Pu_Id  
     WHERE v.Var_Id = @Var_Id
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        RETURN
      END
    --EndIf:count =0
  END
Else --@Var_Desc NOT null
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnitId = pu.Master_Unit 
      FROM Variables v
      JOIN Prod_Units pu  on pu.Pu_Id = v.Pu_Id
     WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount <> 1
      BEGIN 
        If @VariableFetchCount = 0
          SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        Else --too many Var_Desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND for var_desc
        --EndIf:count=0
        RETURN     
      END
    --EndIf:Count<>1
  END
--EndIf:Both @Var_Id and @Var_Desc NULL
If @MasterUnitId Is NOT NULL SELECT @Pu_Id = @MasterUnitId
SELECT @Event_Type = Case @Event_Type When 0 Then 0 Else 1 End
If ISNUMERIC(@Data_Type_Id) = 0
  BEGIN 
    SELECT ReturnStatus = -20 	  	 --"Illegal data type"
    RETURN
  END
--EndIf:Numeric test
--Determine Crew,Shift Type
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     SELECT @CrewShift = @NoCrewNoShift
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL SELECT @CrewShift = @HasCrewNoShift
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL SELECT @CrewShift = @NoCrewHasShift
Else                                                   SELECT @CrewShift = @HasCrewHasShift
--EndIf:Crew,Shift
CREATE TABLE #Prod_Starts (Pu_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Applied_Products(Pu_Id Int, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL)
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
--TestData At Specific Time
If @End_Time Is NULL
  BEGIN
   if @CrewShift = @NoCrewNoShift
     begin
       SELECT 
        	  	  	 t.Canceled
 	  	  	 , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
 	  	  	 , C.Crew_Desc
 	  	  	 , C.Shift_Desc
 	  	  	 , p.Prod_Code
 	  	  	 , e.Event_Num
 	  	  	 , Event_Status = s.ProdStatus_Desc
         , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
         FROM tests t
         JOIN Production_Starts ps ON ps.Pu_Id = @Pu_Id 
          AND ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)
        LEFT OUTER JOIN Crew_Schedule C On C.Pu_Id = ps.PU_id AND C.Start_Time<t.Result_On AND C.End_Time>=t.Result_On
 	  	 JOIN Products p ON p.Prod_Id = ps.Prod_Id
         LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time AND t.Canceled = 0
      end
    else if @CrewShift = @HasCrewNoShift
     begin
       SELECT  	  	  	 t.Canceled
 	  	  	 , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
 	  	  	 , C.Crew_Desc, C.Shift_Desc, p.Prod_Code, e.Event_Num, Event_Status = s.ProdStatus_Desc
         , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
         FROM tests t
         JOIN Production_Starts ps ON ps.Pu_Id = @Pu_Id 
          AND ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)
         JOIN Crew_Schedule C On C.Pu_Id = ps.PU_id AND C.Start_Time<t.Result_On AND C.End_Time>=t.Result_On
           AND C.Crew_Desc = @Crew_Desc
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time AND t.Canceled = 0
      end
    else if @CrewShift = @NoCrewHasShift
      begin
       SELECT t.Canceled
 	  	  	 , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
 	  	  	 , C.Crew_Desc, C.Shift_Desc, p.Prod_Code, e.Event_Num, Event_Status = s.ProdStatus_Desc
         , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
         FROM tests t
         JOIN Production_Starts ps ON ps.Pu_Id = @Pu_Id 
          AND ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)
         JOIN Crew_Schedule C On C.Pu_Id = ps.PU_id AND C.Start_Time<t.Result_On AND C.End_Time>=t.Result_On
           AND C.Shift_Desc = @Shift_Desc
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time AND t.Canceled = 0
      end
    else if @CrewShift = @HasCrewHasShift
      begin
       SELECT  	  	  	 t.Canceled
 	  	  	 , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
 	  	  	 , C.Crew_Desc, C.Shift_Desc, p.Prod_Code, e.Event_Num, Event_Status = s.ProdStatus_Desc
         , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
         FROM tests t
         JOIN Production_Starts ps ON ps.Pu_Id = @Pu_Id 
          AND ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)
         JOIN Crew_Schedule C On C.Pu_Id = ps.PU_id AND C.Start_Time<t.Result_On AND C.End_Time>=t.Result_On
           AND C.Crew_Desc = @Crew_Desc and C.Shift_Desc = @Shift_Desc
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time AND t.Canceled = 0
      end
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
--Grab Relevant Data From Tests Table, Store Them In Temp Table
DECLARE @MyTests Table(Canceled Bit,Result_On DateTime,Entry_On DateTime,Comment_Id Int,Result VarChar(25))
Insert Into @MyTests(Canceled,Result_On,Entry_On,Comment_Id,Result)
SELECT Canceled,Result_On,Entry_On,Comment_Id,Result 
  FROM tests t
  WHERE Var_Id = @Var_Id AND Result_On > @Start_Time AND Result_On <= @End_Time AND t.Canceled = 0
If @AppliedProductFilter = 1 GOTO DO_FILTER_BY_APPLIED_PRODUCT
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
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
 	      OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
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
 	      OR (ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time Is NULL))
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
 	      OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
            ) 
  END
--EndIf @QueryType (Product Info)
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
--Retrieve From Out Temp Test Table including product code based on Crew,shift type
If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_ORIGINAL_RESULTSET
Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_ORIGINAL_RESULTSET
Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_ORIGINAL_RESULTSET
Else                                 GOTO HASCREW_HASSHIFT_ORIGINAL_RESULTSET
--EndIf:Crew,Shift
NOCREW_NOSHIFT_ORIGINAL_RESULTSET:
  If @TimeSort = 1 
        SELECT 
 	  	  	  [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
 	  	  	 , t.Canceled
 	  	  	 , C.Crew_Desc
 	  	  	 , C.Shift_Desc
 	  	  	 , t.Comment_Id
             , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
             , p.Prod_Code
             , e.Event_Id
             , e.Event_Num
             , Event_Status = s.ProdStatus_Desc
             , Data_Type_Id = @Data_Type_Id
             , Event_Type = @Event_Type
             , Pu_Id = @Pu_Id
          FROM @MyTests  t
          JOIN #Prod_Starts ps ON ps.Start_Time <= t.Result_On AND ((ps.End_Time > t.Result_On) OR (ps.End_Time Is NULL)) AND t.canceled = 0        
          LEFT OUTER JOIN Crew_Schedule C On C.Pu_Id = ps.PU_id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
 	  	   JOIN Products p ON p.Prod_Id = ps.Prod_Id
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On ASC
  Else
        --SELECT t.*, p.Prod_Code, e.Event_Num, s.ProdStatus_Desc as 'Event_Status' 
        SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	  , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
 	  	  	  , t.Canceled
 	  	  	  , C.Crew_Desc
 	  	  	  , C.Shift_Desc
 	  	  	  , t.Comment_Id
             , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
             , p.Prod_Code
             , e.Event_Id
             , e.Event_Num
             , Event_Status = s.ProdStatus_Desc
             , Data_Type_Id = @Data_Type_Id
             , Event_Type = @Event_Type
             , Pu_Id = @Pu_Id
          FROM @MyTests t
          JOIN #prod_starts ps ON (ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)) AND t.canceled = 0
          LEFT OUTER JOIN Crew_Schedule C On C.Pu_Id = ps.PU_id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
 	  	   JOIN Products p ON p.Prod_Id = ps.Prod_Id
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On desc
  --EndIf @TimeSort
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_ORIGINAL_RESULTSET:
HASCREW_NOSHIFT_ORIGINAL_RESULTSET:
  If @TimeSort = 1 
        SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, C.Crew_Desc, C.Shift_Desc, t.Comment_Id
             , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
              , p.Prod_Code, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
          FROM @MyTests t
          JOIN #Prod_Starts ps ON ps.Start_Time <= t.Result_On AND ((ps.End_Time > t.Result_On) OR (ps.End_Time Is NULL)) AND t.canceled = 0
          JOIN Crew_Schedule C ON C.Pu_Id = ps.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
           AND C.Crew_Desc = @Crew_Desc
          JOIN Products p ON p.Prod_Id = ps.Prod_Id
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On ASC
  Else
        SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, C.Crew_Desc, C.Shift_Desc, t.Comment_Id
             , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
             , p.Prod_Code, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
          FROM @MyTests t
          JOIN #prod_starts ps ON (ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)) AND t.canceled = 0
          JOIN Crew_Schedule C ON C.Pu_Id = ps.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
           AND C.Crew_Desc = @Crew_Desc
          JOIN Products p ON p.Prod_Id = ps.Prod_Id
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On desc
  --EndIf @TimeSort
  GOTO DROP_TEMP_TABLES
--End HASCREW_NOSHIFT_ORIGINAL_RESULTSET:
NOCREW_HASSHIFT_ORIGINAL_RESULTSET:
  If @TimeSort = 1 
        SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, C.Crew_Desc, C.Shift_Desc, t.Comment_Id
             , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
              , p.Prod_Code, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
          FROM @MyTests t
          JOIN #Prod_Starts ps ON ps.Start_Time <= t.Result_On AND ((ps.End_Time > t.Result_On) OR (ps.End_Time Is NULL)) AND t.canceled = 0
          JOIN Crew_Schedule C ON C.Pu_Id = ps.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
           AND C.Shift_Desc = @Shift_Desc
          JOIN Products p ON p.Prod_Id = ps.Prod_Id
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On ASC
  Else
        SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, C.Crew_Desc, C.Shift_Desc, t.Comment_Id
             , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
             , p.Prod_Code, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
          FROM @MyTests t
          JOIN #prod_starts ps ON (ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)) AND t.canceled = 0
          JOIN Crew_Schedule C ON C.Pu_Id = ps.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
           AND C.Shift_Desc = @Shift_Desc
          JOIN Products p ON p.Prod_Id = ps.Prod_Id
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On desc
  --EndIf @TimeSort
  GOTO DROP_TEMP_TABLES
--End NOCREW_HASSHIFT_ORIGINAL_RESULTSET:
HASCREW_HASSHIFT_ORIGINAL_RESULTSET:
  If @TimeSort = 1 
        SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, C.Crew_Desc, C.Shift_Desc, t.Comment_Id
             , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
              , p.Prod_Code, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
          FROM @MyTests t
          JOIN #Prod_Starts ps ON ps.Start_Time <= t.Result_On AND ((ps.End_Time > t.Result_On) OR (ps.End_Time Is NULL)) AND t.canceled = 0
          JOIN Crew_Schedule C ON C.Pu_Id = ps.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
          JOIN Products p ON p.Prod_Id = ps.Prod_Id
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On ASC
  Else
        SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, C.Crew_Desc, C.Shift_Desc, t.Comment_Id
             , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
             , p.Prod_Code, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
          FROM @MyTests t
          JOIN #prod_starts ps ON (ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)) AND t.canceled = 0
          JOIN Crew_Schedule C ON C.Pu_Id = ps.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
           AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
          JOIN Products p ON p.Prod_Id = ps.Prod_Id
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On desc
  --EndIf @TimeSort
  GOTO DROP_TEMP_TABLES
--END HASCREW_HASSHIFT_ORIGINAL_RESULTSET:
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
             OR (ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time Is NULL))
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
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NOT NULL
    UNION
      SELECT e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product
        FROM Events e
        JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
         AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @Pu_Id AND e.Applied_Product Is NULL
        JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
--Retrieve From Out Temp Test Table including product code based on Crew,shift type
If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_APPLIED_RESULTSET
Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_APPLIED_RESULTSET
Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_APPLIED_RESULTSET
Else                                 GOTO HASCREW_HASSHIFT_APPLIED_RESULTSET
--EndIf:Crew,Shift
NOCREW_NOSHIFT_APPLIED_RESULTSET:
  If @TimeSort = 1 
      SELECT 
 	  	  	 p.Prod_Code
 	  	  	 , Applied_Prod_Code = p2.Prod_Code
 	  	  	 , C.Crew_Desc
 	  	  	 , C.Shift_Desc
 	  	  	 , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
 	  	  	 , t.Canceled
 	  	  	 , e.Event_Id
 	  	  	 , e.Event_Num
 	  	  	 , Event_Status = s.ProdStatus_Desc
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
 	  	  	 , Data_Type_Id = @Data_Type_Id
 	  	  	 , Event_Type = @Event_Type
 	  	  	 , Pu_Id = @Pu_Id
        FROM @MyTests t
        --Note join condition; Start_Time < Result_ON; End_Time >= Result_On; or we misalign the event
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        JOIN Products p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Crew_Schedule C ON C.Pu_Id = ap.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_On > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On ASC
  Else
      SELECT p.Prod_Code, Applied_Prod_Code = p2.Prod_Code, C.Crew_Desc, C.Shift_Desc
           , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, t.Comment_Id
           , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
           , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests t
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        LEFT OUTER JOIN Crew_Schedule C ON C.Pu_Id = ap.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
        JOIN Products p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On DESC
  --EndIf
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_APPLIED_RESULTSET:
HASCREW_NOSHIFT_APPLIED_RESULTSET:
  If @TimeSort = 1 
      SELECT p.Prod_Code, Applied_Prod_Code = p2.Prod_Code, C.Crew_Desc, C.Shift_Desc
           , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, t.Comment_Id
           , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
           , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests t
        --Note join condition; Start_Time < Result_ON; End_Time >= Result_On; or we misalign the event
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        JOIN Crew_Schedule C ON C.Pu_Id = ap.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
         AND C.Crew_Desc = @Crew_Desc
        JOIN Products p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On ASC
  Else
      SELECT p.Prod_Code, Applied_Prod_Code = p2.Prod_Code, C.Crew_Desc, C.Shift_Desc
           , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, t.Comment_Id
           , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
           , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests t
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        JOIN Crew_Schedule C ON C.Pu_Id = ap.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
         AND C.Crew_Desc = @Crew_Desc
        JOIN Products p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On DESC
  --EndIf
  GOTO DROP_TEMP_TABLES
-- End HASCREW_NOSHIFT_APPLIED_RESULTSET:
NOCREW_HASSHIFT_APPLIED_RESULTSET:
  If @TimeSort = 1 
      SELECT p.Prod_Code, Applied_Prod_Code = p2.Prod_Code, C.Crew_Desc, C.Shift_Desc
           , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, t.Comment_Id
           , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
           , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests t
        --Note join condition; Start_Time < Result_ON; End_Time >= Result_On; or we misalign the event
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        JOIN Crew_Schedule C ON C.Pu_Id = ap.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
         AND C.Shift_Desc = @Shift_Desc
        JOIN Products p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On ASC
  Else
      SELECT p.Prod_Code, Applied_Prod_Code = p2.Prod_Code, C.Crew_Desc, C.Shift_Desc
           , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, t.Comment_Id
           , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
           , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests t
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        JOIN Crew_Schedule C ON C.Pu_Id = ap.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
         AND C.Shift_Desc = @Shift_Desc
        JOIN Products p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On DESC
  --EndIf
  GOTO DROP_TEMP_TABLES
--END NOCREW_HASSHIFT_APPLIED_RESULTSET:
HASCREW_HASSHIFT_APPLIED_RESULTSET:
  If @TimeSort = 1 
      SELECT p.Prod_Code, Applied_Prod_Code = p2.Prod_Code, C.Crew_Desc, C.Shift_Desc
           , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, t.Comment_Id
           , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
           , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests t
        --Note join condition; Start_Time < Result_ON; End_Time >= Result_On; or we misalign the event
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        JOIN Crew_Schedule C ON C.Pu_Id = ap.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
         AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
        JOIN Products p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On ASC
  Else
      SELECT p.Prod_Code, Applied_Prod_Code = p2.Prod_Code, C.Crew_Desc, C.Shift_Desc
           , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, t.Comment_Id
           , [Result] = Case When @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar) Else t.Result End
           , Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @Pu_Id
        FROM @MyTests t
        JOIN #Applied_Products ap ON ap.Start_Time < t.Result_On AND ap.End_Time >= t.Result_On AND t.Canceled = 0
        JOIN Crew_Schedule C ON C.Pu_Id = ap.Pu_Id AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
         AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
        JOIN Products p ON p.Prod_Id = ap.Prod_Id
        LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
       WHERE t.Result_on > @Start_Time AND t.Result_On <= @End_Time
    ORDER BY t.Result_On DESC
  --EndIf
  GOTO DROP_TEMP_TABLES
--End HASCREW_HASSHIFT_APPLIED_RESULTSET:
-- DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-
DROP_TEMP_TABLES:
  DROP TABLE #Prod_Starts
  DROP TABLE #Products
  DROP TABLE #Applied_Products 
  GOTO EXIT_PROCEDURE
EXIT_PROCEDURE:
