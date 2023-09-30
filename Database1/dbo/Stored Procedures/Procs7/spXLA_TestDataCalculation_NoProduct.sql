CREATE PROCEDURE dbo.spXLA_TestDataCalculation_NoProduct
 	   @Var_Id 	 Integer
 	 , @Start_Time 	 DateTime
 	 , @End_Time 	 DateTime
 	 , @ExtraCalcs 	 SmallInt
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
DECLARE @QueryType tinyint
DECLARE @Average 	 Real
DECLARE @Min 	  	 Real
DECLARE @Max 	  	 Real
DECLARE @Std 	  	 Real
DECLARE @Total 	  	 Real
DECLARE @Count 	  	 Int
DECLARE @TimeOfMin 	 DateTime
DECLARE @TimeOfMax 	 DateTime
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
CREATE TABLE #Tests (Result_On DateTime, Result varchar(25))
--Single Specific Time, will get at most one row
If @End_Time Is NULL
  BEGIN
    SELECT @Average   = AVG(CONVERT(Real,Result))
         , @Min       = MIN(CONVERT(Real,Result))
         , @Max       = MAX(CONVERT(Real,Result))
         , @Total     = SUM(CONVERT(Real,Result))
         , @TimeOfMin = MIN(CONVERT(DateTime,Result_On))
         , @TimeOfMax = MAX(CONVERT(DateTime,Result_On))
         , @Count     = COUNT(Result)
      FROM Tests
     WHERE Var_id = @Var_Id AND Result_On = @Start_Time AND Result Is NOT NULL AND canceled = 0
    SELECT Average       = @Average
         , Minimum       = @Min
         , Maximum       = @Max
         , Total         = @Total
         , TimeOfMinimum = @TimeOfMin at time zone @DBTz at time zone @InTimeZone
         , TimeOfMaximum = @TimeOfMax at time zone @DBTz at time zone @InTimeZone
         , CountOfRows   = @Count
         , StandardDeviation = Case @Count When 1 Then 0 Else NULL End
      FROM Tests
     WHERE Var_id = @Var_Id AND Result_On = @Start_Time AND Result Is NOT NULL AND canceled = 0
    RETURN
  END
--EndIf
--Extract Test Data into #Test table 
--Data in Start-End time range  
INSERT INTO #Tests (Result_On, Result) 
   SELECT t.Result_On, Result 
     FROM Tests t 
    WHERE t.Var_Id = @Var_Id AND t.Result_On >= @Start_Time AND t.Result_On <= @End_Time AND t.Result Is NOT NULL AND t.Canceled = 0
--Retrieve from the join, the basic data that require no calculation
SELECT  	   @Average = AVG(CONVERT(Real,Result))
 	 , @Min = MIN(CONVERT(Real,Result))
 	 , @Max = MAX(CONVERT(Real,Result))
 	 , @Total = SUM(CONVERT(Real,Result))
 	 , @Count = COUNT(Result)
  FROM  #tests t
--If calculation requested, calculate statistics
If @ExtraCalcs = 1 
    BEGIN
 	 DECLARE @@Result 	 Varchar(25)
 	 DECLARE @@Result_On  	 DateTime
 	 DECLARE @FetchCount  	 Int
 	 DECLARE @TempMin  	 Real
 	 DECLARE @TempMax  	 Real
 	 DECLARE @SumXSqr 	 Real
 	 SELECT @FetchCount = 0
 	 SELECT @SumXSqr = 0
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	 Execute ('DECLARE XLATestDataCalculationNP_TCursor CURSOR Global Static 
 	  	   For ( SELECT t.* FROM   #Tests t 
 	  	       )  
 	  	   For Read Only'
 	  	 )
   	 Open XLATestDataCalculationNP_TCursor  
FETCH_LOOP:
   	 Fetch Next FROM XLATestDataCalculationNP_TCursor Into @@Result_On, @@Result
 	 If (@@Fetch_Status = 0)
 	     BEGIN
 	  	 If @FetchCount = 0 
 	  	     BEGIN
 	  	  	 SELECT @TempMin = CONVERT(Real, @@Result)
 	  	  	 SELECT @TempMax = @TempMin
 	  	  	 SELECT @TimeOfMin = @@Result_On
 	  	  	 SELECT @TimeOfMax = @@Result_On 
 	  	     END
 	  	 --EndIf
 	  	 If CONVERT(Real,@@Result) < @TempMin
 	  	     BEGIN
 	  	  	 SELECT @TempMin = CONVERT(Real,@@Result)
 	  	  	 SELECT @TimeOfMin = @@Result_On
 	  	     END
 	  	 --EndIf
 	  	 If CONVERT(Real,@@Result) > @TempMax
 	  	     BEGIN
 	  	  	 SELECT @TempMax = CONVERT(Real,@@Result)
 	  	  	 SELECT @TimeOfMax = @@Result_On
 	  	     END
 	  	 --EndIf
 	  	 SELECT @SumXSqr = @SumXSqr + Power(@Average - CONVERT(Real,@@Result),2)      
 	  	 SELECT @FetchCount = @FetchCount + 1
 	  	 Goto FETCH_LOOP
 	     END
 	 --EndIf (@@Fetch_Status = 0)
 	 Close XLATestDataCalculationNP_TCursor
 	 Deallocate XLATestDataCalculationNP_TCursor
 	 --FIX: MSi/mt/8-2-2001
 	 --SELECT @Std = Power(@SumXSqr / (1.0 * (@Count - 1)),0.5) ( *** ERROR:OVERFLOW if @Count = 1; *** )
 	 --If there is only one row MAX = MIN and standard deviation = 0
 	 If @Count = 1 SELECT @Std = 0 Else SELECT @Std = POWER(@SumXSqr / (1.0 * (@Count - 1)),0.5)
    END
--EndIf @ExtraCalcs = 1 
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
--Return resultset
SELECT  	   Average = @Average 
 	 , Minimum = @Min
 	 , Maximum = @Max
 	 , Total = @Total
 	 , CountOfRows = @Count
 	 , StandardDeviation = @Std
 	 , TimeOfMinimum = @TimeOfMin at time zone @DBTz at time zone @InTimeZone 
 	 , TimeOfMaximum = @TimeOfMax at time zone @DBTz at time zone @InTimeZone
DROP TABLE #tests
