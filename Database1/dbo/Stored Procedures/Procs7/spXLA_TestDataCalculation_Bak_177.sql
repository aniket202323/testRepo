Create Procedure dbo.[spXLA_TestDataCalculation_Bak_177]
 	 @VarId 	  	 Integer,
 	 @StartTime 	 Datetime,
 	 @EndTime 	 DateTime,
 	 @PuId 	  	 Integer, 
 	 @ProdId 	  	 Integer, 
 	 @GroupId 	 Integer, 
 	 @PropId 	  	 Integer, 
 	 @CharId 	  	 Integer, 
 	 @ExtraCalcs 	 SmallInt
 	 , @InTimeZone 	 varchar(200) = null
AS
SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
Declare @QueryType tinyint
Declare @Average 	 Real
Declare @Min 	  	 Real
Declare @Max 	  	 Real
Declare @Std 	  	 Real
Declare @Total 	  	 Real
Declare @Count 	  	 Int
Declare @TimeOfMin 	 DateTime
Declare @TimeOfMax 	 DateTime
/* mt/1-15-2002: This is inherited from old Add-In approach when it loop through resultSet from Tests and calulate
                 the desired statistics. This would have been a bug since Add-In no longer process Tests recordSet. 
                 Add-In now expects AVG, STD, etc.
If @EndTime Is Null
    BEGIN
        Select t.*, ps.prod_id
        From   tests t
        Join   production_starts ps On ps.pu_id = @PuId And (ps.start_time <= t.result_on And (ps.end_time > t.result_on or ps.end_time Is Null))
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
        Where  t.var_id = @VarId 
 	 And    t.result_on = @StartTime
        Return
    END
*/
--Single Specific Time, will get at most one row
If @EndTime Is NULL
  BEGIN
    SELECT @Average   = AVG(CONVERT(Real,Result))
         , @Min       = MIN(CONVERT(Real,Result))
         , @Max       = MAX(CONVERT(Real,Result))
         , @Total     = SUM(CONVERT(Real,Result))
         , @TimeOfMin = MIN(CONVERT(DateTime,Result_On))
         , @TimeOfMax = MAX(CONVERT(DateTime,Result_On))
         , @Count     = COUNT(Result)
      FROM Tests
     WHERE Var_id = @VarId AND Result_On = @StartTime AND Result Is NOT NULL AND canceled = 0
    SELECT Average       = @Average
         , Minimum       = @Min
         , Maximum       = @Max
         , Total         = @Total
         , TimeOfMinimum =  dbo.fnServer_CmnConvertFromDbTime(@TimeOfMin,@InTimeZone)
         , TimeOfMaximum =  dbo.fnServer_CmnConvertFromDbTime(@TimeOfMax,@InTimeZone)
         , CountOfRows   = @Count
         , StandardDeviation = Case @Count When 1 Then 0 Else NULL End
      FROM Tests
     WHERE Var_id = @VarId AND Result_On = @StartTime AND Result Is NOT NULL AND canceled = 0
    RETURN
  END
--EndIf
Create Table #Tests (Result_On DateTime, Result varchar(25))
Create Table #prod_starts (prod_id  	 Int, start_time DateTime, end_time DateTime NULL)
--Figure Out Query Type
If @ProdId Is Not Null
    Select @QueryType = 1 	 --Single Product
Else If @GroupId Is Not Null and @PropId Is Null 
    Select @QueryType = 2 	 --Single Group
Else If @PropId Is Not Null and @GroupId Is Null
    Select @QueryType = 3 	 --Single Characteristic
Else If @PropId Is Not Null and @GroupId Is Not Null
    Select @QueryType = 4 	 --Group and Property  
Else
    Select @QueryType = 5 	 --only PuId
/* Extract Test Data into #Test table 
   Data in Start-End time range  */
Insert Into #Tests (Result_On, Result) 
Select t.Result_On, Result
From   tests t
Where  var_id = @VarId 
And    result_on >= @StartTime 
And    result_On <= @EndTime 
And    result Is Not Null 
And    canceled = 0
/* Extract Production Start data into Temp table (#prod_starts)
   Based on QueryType(PuId only, single Product, by characteristics, by group & property) */
If @QueryType = 5 	  	  	 --By Pu ID only
    BEGIN
        Insert into #prod_starts
        Select ps.prod_id, ps.start_time, ps.end_time
        From   production_starts ps
        Where  pu_id = @PuId 
        And    (    (start_time between @StartTime and @EndTime) 
 	          or (end_time between @StartTime and @EndTime) 
 	          Or (start_time <= @StartTime And (end_time > @EndTime Or end_time Is Null))
 	  	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               ) 
    END
Else If @QueryType = 1 	  	  	 --By Single Product
    BEGIN
        Insert into #prod_starts
        Select  	 ps.prod_id, ps.start_time, ps.end_time
        From  	 production_starts ps
        Where  	 pu_id = @PuId 
        And     prod_id = @ProdId 
        And     (    start_time Between @StartTime And @EndTime
 	  	   Or end_time Between @StartTime And @EndTime
 	  	   Or (start_time <= @StartTime AND (end_time > @EndTime OR end_time Is Null))
 	  	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
             	 ) 
    END
Else
    BEGIN
 	 Create Table #products (prod_id Int)
     	 
 	 If @QueryType = 2 	  	  	 --By Group of Product
            BEGIN
                Insert into #products
                Select prod_id
                From   product_group_data
                Where  product_grp_id = @GroupId
 	     END
 	 Else If @QueryType = 3 	  	  	 --By Characteristics
            BEGIN
                insert into  #products
                Select distinct prod_id 
 	         from   pu_characteristics 
                where  prop_id = @PropId 
 	         And    char_id = @CharId
 	     END
 	 Else 	  	  	  	  	 --By Group & Property
            BEGIN
 	         Insert into #products
                Select  prod_id
                From    product_group_data
                Where   product_grp_id = @GroupId
 	         Insert into #products
                Select distinct prod_id 
 	         From   pu_characteristics 
                Where  prop_id = @PropId   
 	         And    char_id = @CharId
 	     END  
 	 Insert into #prod_starts
        Select ps.prod_id, ps.start_time, ps.end_time
        From   production_starts ps
        Join   #products p on ps.prod_id = p.prod_id 
        Where  pu_id = @PuId 
 	 And    (    start_time Between @StartTime And @EndTime
 	  	  or end_time Between @StartTime And @EndTime
 	  	  or (start_time <= @StartTime AND (end_time > @EndTime OR end_time Is Null))
 	  	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
 	        ) 
        drop table #products
    END
--EndIf @QueryType ...
/* Retrieve from the join, the basic data that require no calculation  */
Select  	 @Average = avg(convert(Real,result)),
 	 @Min = Min(convert(Real,result)),
 	 @Max = Max(convert(Real,result)),
 	 @Total = sum(convert(Real,result)),
 	 @Count = count(result)
From    #tests t
Join    #prod_starts ps On ps.start_time <= t.result_on And (ps.end_time > t.result_on Or ps.end_time Is Null)
 	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
CHECK_FOR_EXTRACALC:
If @ExtraCalcs = 1 
    BEGIN
 	 Declare @@Result 	 Varchar(25)
 	 Declare @@Result_On  	 DateTime
 	 Declare @FetchCount  	 Int
 	 Declare @TempMin  	 Real
 	 Declare @TempMax  	 Real
 	 Declare @SumXSqr 	 Real
 	 Select @FetchCount = 0
 	 Select @SumXSqr = 0
 	  	 --Start_time & End_time condition checked ; MSi/MT/3-21-2001
        EXECUTE ('Declare spXLA_TestDataCalculation_TCursor CURSOR Global Static
                  For ( Select t.* 
                          From #Tests t 
                          JOIN #prod_starts ps ON ps.start_time <= t.result_on AND (ps.end_time > t.result_on OR ps.end_time Is Null)
                       )  
                  For Read Only'
                )
   	 OPEN spXLA_TestDataCalculation_TCursor  
FETCH_LOOP:
   	 Fetch Next From spXLA_TestDataCalculation_TCursor Into @@Result_On, @@Result
        If (@@Fetch_Status = 0)
            BEGIN
 	  	 If @FetchCount = 0 
 	  	     BEGIN
 	  	  	 Select @TempMin = convert(Real, @@Result)
 	  	  	 Select @TempMax = @TempMin
 	  	  	 Select @TimeOfMin = @@Result_On
 	  	  	 Select @TimeOfMax = @@Result_On 
 	  	     END
 	  	 If convert(Real,@@Result) < @TempMin
 	  	     BEGIN
 	  	  	 Select @TempMin = convert(Real,@@Result)
 	  	  	 Select @TimeOfMin = @@Result_On
 	  	     END
 	  	 If convert(Real,@@Result) > @TempMax
 	  	     BEGIN
 	  	  	 Select @TempMax = convert(Real,@@Result)
 	  	  	 Select @TimeOfMax = @@Result_On
 	  	     END
 	  	 Select @SumXSqr = @SumXSqr + Power(@Average - convert(Real,@@Result),2)      
 	  	 Select @FetchCount = @FetchCount + 1
 	  	 Goto FETCH_LOOP
            END
        --EndIf Fetch is OK
 	 Close spXLA_TestDataCalculation_TCursor
 	 Deallocate spXLA_TestDataCalculation_TCursor
 	 --FIX: MSi/mt/8-2-2001
 	 --Select @Std = Power(@SumXSqr / (1.0 * (@Count - 1)),0.5) ( *** ERROR:OVERFLOW if @Count = 1; *** )
 	 --If there is only one row MAX = MIN and standard deviation = 0
 	 If @Count = 1 SELECT @Std = 0 Else SELECT @Std = Power(@SumXSqr / (1.0 * (@Count - 1)),0.5)
    END
--EndIf @ExtraCalc = 1
Select  	 Average = @Average, 
 	 Minimum = @Min, 
 	 Maximum = @Max, 
 	 Total = @Total, 
 	 CountOfRows = @Count, 
 	 StandardDeviation = @Std,
 	 TimeOfMinimum = dbo.fnServer_CmnConvertFromDbTime( @TimeOfMin,@InTimeZone),  
 	 TimeOfMaximum = dbo.fnServer_CmnConvertFromDbTime( @TimeOfMax,@InTimeZone)  
Drop table #tests
Drop table #prod_starts
