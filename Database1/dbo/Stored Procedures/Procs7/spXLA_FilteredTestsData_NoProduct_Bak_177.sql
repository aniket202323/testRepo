-- spXLA_FilteredTestsData_NoProduct ( mt/1-8-2002 ) is modified from --spXLA_FilteredTestData_AP
-- Defect #24472:mt/9-12-2002
--
-- ECR #25128: mt/3-13-2003: modify to handle duplicate Var_Desc since MSI doesn't enforce unique Var_desc in the entire GBDB.
-- ECR #34381 sb/9-15-2007:  Tests returned should be start_time<result_on<=end_time
-- ECR #34510 sb/9-16-2007: Crew schedule should be start_time<=result_on<=end_time
-- ECR #34070 sb/9-16-2007: Crew schedule should include PU_Id test
-- ECR #35939 sb/8-11-2008: Crew schedule altered to left outer join when no crew or shift specified to catch when no crew is available
CREATE PROCEDURE dbo.[spXLA_FilteredTestsData_NoProduct_Bak_177]
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50) = NULL
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
    , @Crew_Desc            Varchar(10)
    , @Shift_Desc           Varchar(10)
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
DECLARE @MasterUnit 	  	 Integer
DECLARE @VariableFetchCount 	 Integer
DECLARE @CrewShift              TinyInt
DECLARE @NoCrewNoShift          TinyInt
DECLARE @HasCrewNoShift         TinyInt
DECLARE @NoCrewHasShift         TinyInt
DECLARE @HasCrewHasShift        TinyInt
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Define Crew,Shift Types
SELECT @NoCrewNoShift           = 1
SELECT @HasCrewNoShift          = 2
SELECT @NoCrewHasShift          = 3
SELECT @HasCrewHasShift         = 4
 	 --Initialize
SELECT @Data_Type_Id  	  	 = -1
SELECT @MasterUnit 	  	 = -1
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
-- ECR #25128: mt/3-13-2003: modify to handle duplicate Var_Desc (since unique Var_desc in the entire GBDB not enforced).
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --variable NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have @Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnit = pu.Master_Unit 
      FROM Variables v 
      JOIN Prod_Units pu ON pu.Pu_Id = v.Pu_Id  
     WHERE v.Var_Id = @Var_Id
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        RETURN
      END
    --EndIf:Count=0
  END
Else --@Var_Desc NOT null
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnit = pu.Master_Unit 
      FROM Variables v
      JOIN Prod_Units pu on pu.Pu_Id = v.Pu_Id
     WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount <> 1
      BEGIN
        If @VariableFetchCount = 0
          SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND
        Else --too many Var_Desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND for var_desc
        --EndIf:Count
        RETURN
      END
    --EndIf:Count<>1
  END
--EndIf:Both @Var_Id and @Var_Desc Null
--If @MasterUnit Is NOT NULL SELECT @Pu_Id = @MasterUnit 	 --Defect #24672
If @MasterUnit Is NULL SELECT @MasterUnit = @Pu_Id 	  	 --Defect #24672
SELECT @Event_Type = Case @Event_Type When 0 Then 0 Else 1 End
If ISNUMERIC(@Data_Type_Id) = 0
  BEGIN 
    SELECT ReturnStatus = -20 	  	 --"Illegal data type"
    RETURN
  END
--EndIf:Numeric
--Determine Crew,Shift Type
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     SELECT @CrewShift = @NoCrewNoShift
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL SELECT @CrewShift = @HasCrewNoShift
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL SELECT @CrewShift = @NoCrewHasShift
Else                                                   SELECT @CrewShift = @HasCrewHasShift
--EndIf:Crew,Shift
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
 	  	  	 , e.Event_Num
 	  	  	 , Event_Status = s.ProdStatus_Desc
 	  	  	 , Data_Type_Id = @Data_Type_Id
 	  	  	 , Event_Type = @Event_Type
 	  	  	 , Pu_Id = @MasterUnit
          FROM tests t
          LEFT OUTER JOIN Crew_Schedule C ON C.Pu_Id = @MasterUnit AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time AND t.Canceled = 0
       end
    else if @CrewShift = @HasCrewNoShift
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
 	  	  	 , C.Crew_desc
 	  	  	 , C.Shift_Desc
 	  	  	 , e.Event_Num
 	  	  	 , Event_Status = s.ProdStatus_Desc
 	  	  	 , Data_Type_Id = @Data_Type_Id
 	  	  	 , Event_Type = @Event_Type
 	  	  	 , Pu_Id = @MasterUnit
          FROM tests t
          JOIN Crew_Schedule C ON C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On AND C.Crew_Desc = @Crew_Desc and C.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time AND t.Canceled = 0
      end
    else if @CrewShift = @NoCrewHasShift
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
 	  	  	 , C.Crew_desc
 	  	  	 , C.Shift_Desc
 	  	  	 , e.Event_Num
 	  	  	 , Event_Status = s.ProdStatus_Desc
 	  	  	 , Data_Type_Id = @Data_Type_Id
 	  	  	 , Event_Type = @Event_Type
 	  	  	 , Pu_Id = @MasterUnit
          FROM tests t
          JOIN Crew_Schedule C ON C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On AND C.Shift_Desc = @Shift_Desc and C.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time AND t.Canceled = 0
      end
    else if @CrewShift = @HasCrewHasShift
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
 	  	  	 , C.Crew_desc
 	  	  	 , C.Shift_Desc
 	  	  	 , e.Event_Num
 	  	  	 , Event_Status = s.ProdStatus_Desc
 	  	  	 , Data_Type_Id = @Data_Type_Id
 	  	  	 , Event_Type = @Event_Type
 	  	  	 , Pu_Id = @MasterUnit
          FROM tests t
          JOIN Crew_Schedule C ON C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc and C.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE t.Var_Id = @Var_Id AND t.Result_On = @Start_Time AND t.Canceled = 0
      end
    RETURN
  END
--EndIf no End_Time
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
--Grab Relevant Data From Tests Table, Store Them In Temp Table
DECLARE @MyTests Table(Canceled Bit,Result_On DateTime,Entry_On DateTime,Comment_Id Int,Result VarChar(25))
Insert Into @MyTests(Canceled,Result_On,Entry_On,Comment_Id,Result)
SELECT Canceled,Result_On,Entry_On,Comment_Id,Result 
  FROM tests t
  WHERE Var_Id = @Var_Id AND Result_On > @Start_Time AND Result_On <= @End_Time AND t.Canceled = 0
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
--Determine Crew,Shift Type
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     GOTO NOCREW_NOSHIFT_NOPRODUCT_RESULTSET
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL GOTO HASCREW_NOSHIFT_NOPRODUCT_RESULTSET
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL GOTO NOCREW_HASSHIFT_NOPRODUCT_RESULTSET
Else                                                   GOTO HASCREW_HASSHIFT_NOPRODUCT_RESULTSET
--EndIf:Crew,Shift
NOCREW_NOSHIFT_NOPRODUCT_RESULTSET:
  If @TimeSort = 1 
        SELECT 
 	  	  	   [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
            , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
            , C.Crew_Desc
            , C.Shift_Desc
            , e.Event_Id
            , e.Event_Num
            , Event_Status = s.ProdStatus_Desc
            , Data_Type_Id = @Data_Type_Id
            , Event_Type = @Event_Type
            , Pu_Id = @MasterUnit
          FROM @MyTests t
          LEFT OUTER JOIN Crew_Schedule C ON C.Pu_Id = @MasterUnit AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On ASC
  Else
        SELECT 	  	  	   
 	  	  	 [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
            , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
            , C.Crew_Desc
            , C.Shift_Desc
            , e.Event_Id
            , e.Event_Num
            , Event_Status = s.ProdStatus_Desc
            , Data_Type_Id = @Data_Type_Id
            , Event_Type = @Event_Type
            , Pu_Id = @MasterUnit
          FROM @MyTests t
          LEFT OUTER JOIN Crew_Schedule C ON C.Pu_Id = @MasterUnit AND C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On desc
  --EndIf @TimeSort
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_NOPRODUCT_RESULTSET:
HASCREW_NOSHIFT_NOPRODUCT_RESULTSET:
  If @TimeSort = 1 
        SELECT 
 	  	  	 [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
            , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
             , C.Crew_Desc, C.Shift_Desc, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @MasterUnit
          FROM @MyTests t
          JOIN Crew_Schedule C ON C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On AND C.Crew_Desc = @Crew_Desc and C.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On ASC
  Else
        SELECT 
 	  	  	 [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
            , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
             , C.Crew_Desc, C.Shift_Desc, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @MasterUnit
          FROM @MyTests  t
          JOIN Crew_Schedule C ON C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On AND C.Crew_Desc = @Crew_Desc and C.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On desc
  --EndIf @TimeSort
  GOTO DROP_TEMP_TABLES
--End HASCREW_NOSHIFT_NOPRODUCT_RESULTSET:
NOCREW_HASSHIFT_NOPRODUCT_RESULTSET:
  If @TimeSort = 1 
        SELECT  	  	  	 [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
            , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
             , C.Crew_Desc, C.Shift_Desc, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @MasterUnit
          FROM @MyTests t
          JOIN Crew_Schedule C ON C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On AND C.Shift_Desc = @Shift_Desc and C.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On ASC
  Else
        SELECT
 	  	  	 [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
            , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
             , C.Crew_Desc, C.Shift_Desc, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @MasterUnit
          FROM @MyTests t
          JOIN Crew_Schedule C ON C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On AND C.Shift_Desc = @Shift_Desc and C.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On desc
  --EndIf @TimeSort
  GOTO DROP_TEMP_TABLES
--End NOCREW_HASSHIFT_NOPRODUCT_RESULTSET:
HASCREW_HASSHIFT_NOPRODUCT_RESULTSET:
  If @TimeSort = 1 
        SELECT 
 	  	  	 [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
            , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
              , C.Crew_Desc, C.Shift_Desc, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @MasterUnit
          FROM @MyTests t
          JOIN Crew_Schedule C ON C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc and C.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On ASC
  Else
        SELECT  	  	  	 
 	  	  	 [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
 	  	  	 , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
            , t.Canceled
 	  	  	 , t.Comment_Id
 	  	  	 , [Result] = CASE 
                        WHEN @DecimalChar  <> '.' and @Data_Type_Id = 2 THEN REPLACE(t.Result, '.', @DecimalChar)
                        ELSE t.Result
                      END
 	  	  	 , e.Event_Id
             , C.Crew_Desc, C.Shift_Desc, e.Event_Id, e.Event_Num, Event_Status = s.ProdStatus_Desc, Data_Type_Id = @Data_Type_Id, Event_Type = @Event_Type, Pu_Id = @MasterUnit
          FROM @MyTests  t
          JOIN Crew_Schedule C ON C.Start_Time < t.Result_On AND C.End_Time >= t.Result_On AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc and C.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @MasterUnit
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY Result_On desc
  --EndIf @TimeSort
  GOTO DROP_TEMP_TABLES
--END HASCREW_HASSHIFT_NOPRODUCT_RESULTSET:
DROP_TEMP_TABLES:
  GOTO EXIT_PROCEDURE
EXIT_PROCEDURE:
