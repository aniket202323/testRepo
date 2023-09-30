-- spXLA_FilteredTestsCalc_NoProduct() is based on spXLA_FilteredTestsCalc_AP:Defect #24489:mt/1-10-2002. 
--
-- ECR #25128: mt/3-13-2003: handle duplicate Var_Desc as GBDB doesn't enforce unique Var_desc across the entire database; must handle via code
-- ECR #34381: sb/9-15-2007: Tests returned should be start_time<result_on<=end_time
--
CREATE PROCEDURE dbo.[spXLA_FilteredTestsCalc_NoProduct_Bak_177]
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50)
 	 , @Start_Time 	  	 Datetime
 	 , @End_Time 	  	 DateTime
 	 , @Crew_Desc            Varchar(10)
 	 , @Shift_Desc           Varchar(10)
 	 , @ExtraCalcs 	  	 SmallInt
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
 	 --Needed for internal lookup
DECLARE 	 @Pu_Id 	  	  	 Integer 
DECLARE 	 @Data_Type_Id  	  	 Integer 
DECLARE 	 @MasterUnitId 	  	 Integer
DECLARE 	 @VariableFetchCount  	 Integer
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
-- ECR #25128: mt/3-13-2003: handle duplicate Var_Desc as GBDB doesn't enforce unique Var_desc across the entire database; must handle via code
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --input variable NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have @Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @MasterUnitId = pu.Master_Unit 
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
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @MasterUnitId = pu.Master_Unit 
      FROM Variables v
      JOIN Prod_Units pu  on pu.Pu_Id = v.Pu_Id
     WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount <> 1
      BEGIN
        If @VariableFetchCount = 0
          SELECT [ReturnStatus] = -30 	 --specified variable NOT FOUND        
        Else --too many Var_Desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND in var_desc
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
  /* Retrieve FROM the join, the basic data that require no calculation  */
  SELECT @Average = AVG(CONVERT(Real,Result))
       , @Min     = MIN(CONVERT(Real,Result))
       , @Max     = Max(CONVERT(Real,Result))
       , @Total   = sum(CONVERT(Real,Result))
       , @Count   = count(Result)
    FROM #Tests t
  If @ExtraCalcs = 1 
    BEGIN
      SELECT @FetchCount = 0
      SELECT @SumXSqr = 0
   	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
      EXECUTE ('Declare XLAFilteredTestsCalc_NP_TCursor CURSOR Global Static 
                For ( SELECT t.* FROM #Tests t )  For Read Only'
              )
      GOTO OPEN_CURSOR_AND_PROCESS_EXTRACALC_STUFF
    END
  --EndIf
  GOTO DO_FINAL_RETRIEVAL
OPEN_CURSOR_AND_PROCESS_EXTRACALC_STUFF:
  SELECT @FetchCount = 0
  SELECT @SumXSqr = 0
  OPEN XLAFilteredTestsCalc_NP_TCursor
EXTRACALC_FETCH_LOOP:
  FETCH NEXT FROM XLAFilteredTestsCalc_NP_TCursor INTO @@Result_On, @@Result
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
  CLOSE XLAFilteredTestsCalc_NP_TCursor
  DEALLOCATE XLAFilteredTestsCalc_NP_TCursor
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
       , TimeOfMinimum     = dbo.fnServer_CmnConvertFromDBTime(@TimeOfMin,@InTimeZone)
       , TimeOfMaximum     = dbo.fnServer_CmnConvertFromDBTime(@TimeOfMax,@InTimeZone)  
       , Data_Type_Id = @Data_Type_Id
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #Tests
