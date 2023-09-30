-- spXLA_TestsDataByTestName_AP 
-- MODIFICATION NOTE:
--     DO NOT use SET NOCOUNT in stored procedure as client connection software depends on this property determine _LOCAL / _GLOBAL for 
--     "Description" fields (Var_Desc, Prod_Desc, PU_Desc, etc) DO NOT use SET NOCOUNT in stored procedure.
-- ECR #25583: mt/12-20-2004: Provide retrieval for a given @Test_Name, @Start_Time, @End_Time, test values (Tests.Result) for variables that belong to 
--             the specified "Test Name". Test_Name is a relatively new column in dbo.Variables. 
-- ECR #ECR #29677: mt/5-4-2005 -- added Var_Desc as additional sort criteria to return result set
-- ECR #34381 sb/9-15-2007:  Tests returned should be start_time<timestamp<=end_time
CREATE PROCEDURE dbo.[spXLA_TestsDataByTestName_AP_Bak_177]
 	   @Test_Name 	  	 Varchar(50)
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Prod_Id 	  	 Integer
 	 , @Group_Id 	  	 Integer
 	 , @Prop_Id 	  	 Integer
 	 , @Char_Id 	  	 Integer
    , @Crew_Desc            Varchar(10)
    , @Shift_Desc           Varchar(10)
 	 , @AppliedProductFilter 	 TinyInt 	  	   -- 0 = filter by original product; 1 = filter by applied product
    , @TimeSort             TinyInt           -- 1 = Ascending; otherwise Descending
 	 , @DecimalChar 	  	 Varchar(1) = NULL -- Comma Or Period (Default) to accommodate different regional setttings on PC
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
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
 	 --Define Crew,Shift Types
SELECT @NoCrewNoShift           = 1
SELECT @HasCrewNoShift          = 2
SELECT @NoCrewHasShift          = 3
SELECT @HasCrewHasShift         = 4
 	 --Define Product Filter Types
SELECT @SingleProduct 	  	 = 1
SELECT @Group 	  	  	 = 2
SELECT @Characteristic 	  	 = 3
SELECT @GroupAndProperty 	 = 4
SELECT @NoProductSpecified 	 = 5
--Determine Crew,Shift Type
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     SELECT @CrewShift = @NoCrewNoShift
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL SELECT @CrewShift = @HasCrewNoShift
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL SELECT @CrewShift = @NoCrewHasShift
Else                                                   SELECT @CrewShift = @HasCrewHasShift
--EndIf:Crew,Shift
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
If @DecimalChar Is NULL SELECT @DecimalChar = '.' 	 --Set Decimal Separator Default Value, if applicable
CREATE TABLE #VariablesAndEvents ( Master_Unit Int, PU_Id Int, Var_Id Int, Var_Desc Varchar(50), Data_Type_Id Int
                                 , Event_Num Varchar(25), Event_Id Int, Event_Type Int NULL, Event_Status Int NULL, Start_Time DateTime NULL, TimeStamp DateTime, Applied_Product Int NULL )
CREATE TABLE #Prod_Starts (Pu_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Applied_Products( PU_Id Int, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL)
CREATE TABLE #Units ( PU_Id Int )
-- Get the variables that belong to Test_Name and related events into temp table
--------------------------------------------------------------------------------
  INSERT 
    INTO #VariablesAndEvents ( Master_Unit, PU_Id, Var_Id, Var_Desc, Data_Type_Id, Event_Num, Event_Id, Event_Type, Event_Status, Start_Time, TimeStamp, Applied_Product )
  SELECT COALESCE( pu.Master_Unit, v.PU_Id ), v.PU_Id, v.Var_Id, v.Var_Desc, v.Data_Type_Id, e.Event_Num, e.Event_Id, e.Event_Subtype_Id, e.Event_Status
       , e.Start_Time, e.TimeStamp, e.Applied_Product
    FROM Variables v 
    JOIN Events e ON e.PU_Id = v.PU_Id AND e.TimeStamp > @Start_Time AND e.TimeStamp <= @End_Time
    JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
   WHERE v.Test_Name = @Test_Name AND v.Event_Type = 1 -- Event based; Do not filter by Data_type_Id, let Excel Add-In handle it
--Note: PU_Id = 0 and PL_Id = 0 are invalid unit and line. We keep them in the database for cleanup purposes. 
  --    Whenever users decdided to obsolete variables, they will not be deleted from Tests table (performance issue) 
  --    but they will be assigned to the deleted PU_Id instead.
DELETE FROM  #VariablesAndEvents WHERE PU_Id = 0
-- Store the PU_Id's relvant to the Variables we care for future use
INSERT INTO #Units SELECT DISTINCT ve.PU_Id FROM #VariablesAndEvents ve
If @AppliedProductFilter = 1 GOTO DO_FILTER_BY_APPLIED_PRODUCT
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
--Get relevant products and their information from Production_Starts table
If @QueryType = @NoProductSpecified  --5 
  BEGIN
    INSERT INTO #Prod_Starts ( Pu_Id, Prod_Id, Start_Time, End_Time )
    SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
      FROM Production_Starts ps
      JOIN #Units u ON u.PU_Id = ps.PU_Id
     WHERE (    (ps.Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (ps.End_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (ps.Start_Time < @Start_Time AND (ps.End_Time >= @End_Time OR ps.End_Time Is NULL))
            ) 
  END
Else If @QueryType = @SingleProduct  --1
  BEGIN
    INSERT INTO #prod_starts
    SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
      JOIN #Units u ON u.PU_Id = ps.PU_Id
     WHERE ps.prod_id = @Prod_Id 
       AND (    (ps.Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (ps.End_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (ps.Start_Time < @Start_Time AND (ps.End_Time >= @End_Time OR ps.End_Time Is NULL))
            ) 
  END
Else -- Group of products OR products with specific characteristic 
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
    Else -- products from certain Group AND certain characteristic
      BEGIN
         INSERT INTO #products
         SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id
         INSERT INTO #products
         SELECT DISTINCT prod_id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END  
    --EndIf @QueryType..
    INSERT INTO #prod_starts
    SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
      JOIN #Units u ON u.PU_Id = ps.PU_Id
      JOIN #products p on ps.prod_id = p.prod_id 
     WHERE (    (ps.Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (ps.End_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (ps.Start_Time < @Start_Time AND (ps.End_Time >= @End_Time OR ps.End_Time Is NULL))
            ) 
  END
--EndIf @QueryType (Product Info)
--Retrieve From Out Temp Test Table including product code based on Crew,shift type
If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_ORIGINAL_RESULTSET
Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_ORIGINAL_RESULTSET
Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_ORIGINAL_RESULTSET
Else                                 GOTO HASCREW_HASSHIFT_ORIGINAL_RESULTSET
--EndIf:Crew,Shift
NOCREW_NOSHIFT_ORIGINAL_RESULTSET:
  If @TimeSort = 1
       SELECT 
 	  	    pl.PL_Desc
 	  	    , [Master_Unit] = pu.PU_Desc
 	  	    , pu2.PU_Desc
 	  	    , ve.Event_Num
 	  	    , ve.Event_Id
 	  	    , ve.Var_Desc
 	  	    , ve.Var_Id
 	  	    , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
 	  	    , Event_Status = s.ProdStatus_Desc
 	  	    , ve.Data_Type_Id
 	  	    , et.ET_Desc
 	  	    , p.Prod_Code
 	  	    , ve.Applied_Product 
 	  	    , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	    , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
 	  	    , t.Canceled
 	  	    , t.Comment_Id
 	  	    , C.Crew_Desc
 	  	    , C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ((ps.End_Time >= ve.TimeStamp) OR (ps.End_Time Is NULL)) AND ps.PU_Id = ve.PU_Id
 	  	  JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677 
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , p.Prod_Code, ve.Applied_Product -- (we include Applied Product for troubleshooting info, Client module will choose not to display applied product)
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ((ps.End_Time >= ve.TimeStamp) OR (ps.End_Time Is NULL)) AND ps.PU_Id = ve.PU_Id
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id
 	  	  JOIN Products p ON p.Prod_Id = ps.Prod_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	 -- ECR #29677 
  --EndIf
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_ORIGINAL_RESULTSET:
HASCREW_NOSHIFT_ORIGINAL_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , p.Prod_Code, ve.Applied_Product -- (we include Applied Product for troubleshooting info, Client module will choose not to display applied product)
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ((ps.End_Time >= ve.TimeStamp) OR (ps.End_Time Is NULL)) AND ps.PU_Id = ve.PU_Id
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677 
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , p.Prod_Code, ve.Applied_Product -- (we include Applied Product for troubleshooting info, Client module will choose not to display applied product)
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ((ps.End_Time >= ve.TimeStamp) OR (ps.End_Time Is NULL)) AND ps.PU_Id = ve.PU_Id
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	 -- ECR #29677 
  --EndIf
  GOTO DROP_TEMP_TABLES
--End HASCREW_NOSHIFT_ORIGINAL_RESULTSET:
NOCREW_HASSHIFT_ORIGINAL_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , p.Prod_Code, ve.Applied_Product -- (we include Applied Product for troubleshooting info, Client module will choose not to display applied product)
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ((ps.End_Time >= ve.TimeStamp) OR (ps.End_Time Is NULL)) AND ps.PU_Id = ve.PU_Id
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Shift_Desc = @Shift_Desc
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677 
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , p.Prod_Code, ve.Applied_Product -- (we include Applied Product for troubleshooting info, Client module will choose not to display applied product)
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ((ps.End_Time >= ve.TimeStamp) OR (ps.End_Time Is NULL)) AND ps.PU_Id = ve.PU_Id
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Shift_Desc = @Shift_Desc
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	  	 -- ECR #29677 
  --Endif
  GOTO DROP_TEMP_TABLES
--End NOCREW_HASSHIFT_ORIGINAL_RESULTSET:
HASCREW_HASSHIFT_ORIGINAL_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , p.Prod_Code, ve.Applied_Product -- (we include Applied Product for troubleshooting info, Client module will choose not to display applied product)
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ((ps.End_Time >= ve.TimeStamp) OR (ps.End_Time Is NULL)) AND ps.PU_Id = ve.PU_Id
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677 
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , p.Prod_Code, ve.Applied_Product -- (we include Applied Product for troubleshooting info, Client module will choose not to display applied product)
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ((ps.End_Time >= ve.TimeStamp) OR (ps.End_Time Is NULL)) AND ps.PU_Id = ve.PU_Id
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         JOIN Products p ON p.Prod_Id = ps.Prod_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	  	 -- ECR #29677 
  --EndIf
  GOTO DROP_TEMP_TABLES
--END HASCREW_HASSHIFT_ORIGINAL_RESULTSET:
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
DO_FILTER_BY_APPLIED_PRODUCT:
  --Get all relevant products and info from production_Start table
  INSERT INTO #Prod_Starts
    SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
      FROM Production_Starts ps
      JOIN #Units u ON u.PU_Id = ps.PU_Id
     WHERE (    ps.Start_Time BETWEEN @Start_Time AND @End_Time
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
  INSERT INTO #Applied_Products( PU_Id, Start_Time, End_Time, Prod_Id, Applied_Prod_Id  )
      SELECT ve.Pu_Id, COALESCE(ve.Start_Time, DATEADD(ss, -1, ve.TimeStamp)), ve.TimeStamp, ps.Prod_Id, ve.Applied_Product
        FROM #VariablesAndEvents ve
        JOIN #Products p ON p.Prod_Id = ve.Applied_Product
        JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ( ps.End_Time >= ve.TimeStamp OR ps.End_Time Is NULL ) AND ps.PU_Id = ve.PU_Id
         AND ps.Pu_Id = ve.Pu_Id AND ve.Applied_Product Is NOT NULL
    UNION
      SELECT ve.Pu_Id, COALESCE(ve.Start_Time, DATEADD(ss, -1, ve.TimeStamp)), ve.TimeStamp, ps.Prod_Id, ve.Applied_Product
        FROM #VariablesAndEvents ve
        JOIN #Prod_Starts ps ON ps.Start_Time < ve.TimeStamp AND ( ps.End_Time >= ve.TimeStamp OR ps.End_Time Is NULL ) AND ps.PU_Id = ve.PU_Id
         AND ps.Pu_Id = ve.Pu_Id AND ve.Applied_Product Is NULL
        JOIN #Products p ON p.Prod_Id = ps.Prod_Id
--Retrieve From Out Temp Test Table including product code based on Crew,shift type
If      @CrewShift = @NoCrewNoShift  GOTO NOCREW_NOSHIFT_APPLIED_RESULTSET
Else If @CrewShift = @HasCrewNoShift GOTO HASCREW_NOSHIFT_APPLIED_RESULTSET
Else If @CrewShift = @NoCrewHasShift GOTO NOCREW_HASSHIFT_APPLIED_RESULTSET
Else                                 GOTO HASCREW_HASSHIFT_APPLIED_RESULTSET
--EndIf:Crew,Shift
NOCREW_NOSHIFT_APPLIED_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
            , p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id 
 	  	  JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         JOIN #Applied_Products ap ON ap.Start_Time < ve.TimeStamp AND ap.End_Time >= ve.TimeStamp AND ap.PU_Id = ve.PU_Id
         JOIN Products p ON p.Prod_Id = ap.Prod_Id
         LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677 
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
            , p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id 
 	  	  JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         JOIN #Applied_Products ap ON ap.Start_Time < ve.TimeStamp AND ap.End_Time >= ve.TimeStamp AND ap.PU_Id = ve.PU_Id
         JOIN Products p ON p.Prod_Id = ap.Prod_Id
         LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	  	 -- ECR #29677 
  --EndIf
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_APPLIED_RESULTSET:
HASCREW_NOSHIFT_APPLIED_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
            , p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         JOIN #Applied_Products ap ON ap.Start_Time < ve.TimeStamp AND ap.End_Time >= ve.TimeStamp AND ap.PU_Id = ve.PU_Id
         JOIN Products p ON p.Prod_Id = ap.Prod_Id
         LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677 
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
            , p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         JOIN #Applied_Products ap ON ap.Start_Time < ve.TimeStamp AND ap.End_Time >= ve.TimeStamp AND ap.PU_Id = ve.PU_Id
         JOIN Products p ON p.Prod_Id = ap.Prod_Id
         LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	  	 -- ECR #29677 
  --EndIf
  GOTO DROP_TEMP_TABLES
-- End HASCREW_NOSHIFT_APPLIED_RESULTSET:
NOCREW_HASSHIFT_APPLIED_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
            , p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Shift_Desc = @Shift_Desc
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         JOIN #Applied_Products ap ON ap.Start_Time < ve.TimeStamp AND ap.End_Time >= ve.TimeStamp AND ap.PU_Id = ve.PU_Id
         JOIN Products p ON p.Prod_Id = ap.Prod_Id
         LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677 
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
            , p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Shift_Desc = @Shift_Desc
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         JOIN #Applied_Products ap ON ap.Start_Time < ve.TimeStamp AND ap.End_Time >= ve.TimeStamp AND ap.PU_Id = ve.PU_Id
         JOIN Products p ON p.Prod_Id = ap.Prod_Id
         LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	  	 -- ECR #29677 
  --EndIf
  GOTO DROP_TEMP_TABLES
--END NOCREW_HASSHIFT_APPLIED_RESULTSET:
HASCREW_HASSHIFT_APPLIED_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
            , p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         JOIN #Applied_Products ap ON ap.Start_Time < ve.TimeStamp AND ap.End_Time >= ve.TimeStamp AND ap.PU_Id = ve.PU_Id
         JOIN Products p ON p.Prod_Id = ap.Prod_Id
         LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677 
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone), [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone), t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
            , p.Prod_Code, Applied_Prod_Code = p2.Prod_Code
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         JOIN #Applied_Products ap ON ap.Start_Time < ve.TimeStamp AND ap.End_Time >= ve.TimeStamp AND ap.PU_Id = ve.PU_Id
         JOIN Products p ON p.Prod_Id = ap.Prod_Id
         LEFT OUTER JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
    ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	  	 -- ECR #29677 
  --EndIf
  GOTO DROP_TEMP_TABLES
--End HASCREW_HASSHIFT_APPLIED_RESULTSET:
-- DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-
-- DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-DROP ALL TEMP TABLES-
DROP_TEMP_TABLES:
  DROP TABLE #VariablesAndEvents
  DROP TABLE #Prod_Starts
  DROP TABLE #Products
  DROP TABLE #Applied_Products 
  GOTO EXIT_PROCEDURE
EXIT_PROCEDURE:
