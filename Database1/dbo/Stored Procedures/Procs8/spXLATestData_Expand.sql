-- ECR #26270 (mt/9-2-2003): added Canceled=0 to be consistent with the rest of TestsData functionality in AddIn 
--
CREATE PROCEDURE dbo.spXLATestData_Expand
 	   @Var_Id 	 Integer
 	 , @Start_Time 	 DateTime
 	 , @End_Time 	 DateTime
 	 , @Pu_Id 	 Integer
 	 , @Prod_Id 	 Integer
 	 , @Group_Id 	 Integer
 	 , @Prop_Id 	 Integer
 	 , @Char_Id 	 Integer
 	 , @TimeSort 	 SmallInt 
 	 , @DecimalSep 	 varchar(1)= '.'
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
--JG Added this for regional settings:
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period.
If @DecimalSep is Null Set @DecimalSep = '.' 
DECLARE @DataType 	  	 Int
SELECT @DataType = Data_Type_Id FROM Variables WHERE Var_Id = @Var_Id
--JG END
DECLARE @QueryType TinyInt
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
-- Proficy AddIn Query Tests At Specfic Time. No Filter on Canceled (i.e., we'll return a row regardless of Canceled = 0 or 1)
If @End_Time Is NULL
  BEGIN
    SELECT 
     t.Canceled
    , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
    , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
    , t.Comment_Id
    , e.Event_Id
    , [Result] = CASE 
                        WHEN @DecimalSep <> '.' and @DataType = 2 THEN REPLACE(t.Result, '.', @DecimalSep)
                        ELSE t.Result
                      END,
           p.Prod_Code, e.Event_Num, s.ProdStatus_Desc as 'Event_Status'
      FROM tests t
 	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
      JOIN production_starts ps ON ps.Pu_Id = @Pu_Id AND ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)
      JOIN Products p ON p.Prod_Id = ps.Prod_Id
      LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
      LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Id
     WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time 
    RETURN
  END
--EndIf no End_Time
CREATE TABLE #prod_starts (prod_id int, Start_Time DateTime, End_Time DateTime NULL)
--Figure Out Query Type
if @Prod_Id Is NOT NULL 	  	  	  	  	 SELECT @QueryType = 1   	  	 --Single Product
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL 	 SELECT @QueryType = 2   	  	 --Single Group
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL 	 SELECT @QueryType = 3   	  	 --Single Characteristic
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL 	 SELECT @QueryType = 4   	  	 --Group and Property  
Else 	  	  	  	  	  	  	 SELECT @QueryType = 5
DECLARE @MyTests Table(Canceled Bit,Result_On DateTime,Entry_On DateTime,Comment_Id Int,Result VarChar(25))
Insert Into @MyTests(Canceled,Result_On,Entry_On,Comment_Id,Result)
SELECT Canceled,Result_On,Entry_On,Comment_Id,Result 
  FROM tests t
  WHERE Var_Id = @Var_Id AND
        Result_On >= @Start_Time AND
        result_On <= @End_Time
--JG Added this for regional settings:
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period.
If @DataType = 2 AND @DecimalSep <> '.'
  BEGIN
    UPDATE @MyTests Set Result = REPLACE(Result, '.', @DecimalSep)
  END
--JG END
If @QueryType = 5 
  BEGIN
    INSERT INTO #prod_starts
    SELECT ps.prod_id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
     WHERE Pu_Id = @Pu_Id 
       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ) 
  END
Else If @QueryType = 1
  BEGIN
    INSERT INTO #prod_starts
    SELECT ps.prod_id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
     WHERE Pu_Id = @Pu_Id 
       AND prod_id = @Prod_Id 
       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ) 
  END
Else
  BEGIN
    CREATE TABLE #products (prod_id int)
    if @QueryType = 2 
      BEGIN
         INSERT INTO #products
         SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = 3
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
    SELECT ps.prod_id, ps.Start_Time, ps.End_Time
      FROM production_starts ps
      JOIN #products p on ps.prod_id = p.prod_id 
     WHERE Pu_Id = @Pu_Id 
       AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (End_Time BETWEEN @Start_Time AND @End_Time) 
 	      OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
            ) 
    DROP TABLE #products
  END
--EndIf @QueryType (Product Info)
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @TimeSort = 1 
      SELECT
      t.Canceled
      , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
      , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
      , t.Comment_Id
      , e.Event_Id
      , Result
      , p.Prod_Code, e.Event_Num, s.ProdStatus_Desc as 'Event_Status'
        FROM @MyTests t
 	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
        JOIN #prod_starts ps ON ps.Start_Time <= t.Result_On AND ((ps.End_Time > t.Result_On) OR (ps.End_Time Is NULL)) AND t.canceled = 0
        JOIN Products p ON p.Prod_Id = ps.Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Id
    ORDER BY Result_On
Else
      SELECT 
       t.Canceled
      , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
      , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
      , t.Comment_Id
      , e.Event_Id
      , Result
      , p.Prod_Code, e.Event_Num, s.ProdStatus_Desc as 'Event_Status' 
        FROM @MyTests t
 	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
        JOIN #prod_starts ps ON (ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)) AND t.canceled = 0
        JOIN Products p ON p.Prod_Id = ps.Prod_Id
        LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
        LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Id
    ORDER BY Result_On desc
--EndIf @TimeSort
DROP TABLE #prod_starts
