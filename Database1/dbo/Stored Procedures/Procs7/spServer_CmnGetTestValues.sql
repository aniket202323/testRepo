CREATE PROCEDURE dbo.spServer_CmnGetTestValues
@Var_Id int,
@StartTime nVarChar(30),
@EndTime nVarChar(30),
@IncludeNulls  int,
@MU_Id int
AS
if @IncludeNulls = 0
 	 Select Result, Result_On, Entry_On, Test_Id 
 	   From Tests 
 	   Where var_id = @Var_Id and Result_On >= @StartTime and Result_On <= @EndTime and result is not NULL and Canceled <> 1 order by result_on
else
 	 Select Result, Result_On, Entry_On, Test_Id 
 	   From Tests 
 	   Where var_id = @Var_Id and Result_On >= @StartTime and Result_On <= @EndTime order by result_on
