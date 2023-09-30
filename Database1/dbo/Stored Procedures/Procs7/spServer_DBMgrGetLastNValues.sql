CREATE PROCEDURE dbo.spServer_DBMgrGetLastNValues
@Var_Id int,
@NumValues int
AS
Declare @Count 	 Int, @LastCount int,
 	 @StartTime 	 DateTime,
 	 @EndTime  	 Datetime,
        @Try int
set nocount on
Declare @GetTestValuesByNum Table(
  Result nVarChar(30) COLLATE DATABASE_DEFAULT NULL, 
  Result_On datetime NULL, 
  Entry_On datetime NULL, 
  Test_Id bigint
)
  Select @Count = 0
  Select @Try = 0
  Select @StartTime = dateadd(day,-1,dbo.fnServer_CmnGetDate(GetUTCDate()))
  Select @EndTime = dateadd(day,100,dbo.fnServer_CmnGetDate(GetUTCDate()))
  While @Count < @NumValues
      Begin
        Select @Try = @Try + 1
        Select @LastCount = @Count
        Insert Into @GetTestValuesByNum(Result, Result_On, Entry_On, Test_Id)
 	   Select  Result, Result_On, Entry_On, Test_Id 
 	     From Tests 
 	     Where var_id = @Var_Id and Result_On >= @StartTime and Result_On < @EndTime
        Select @Count = Count(Result_On) From  @GetTestValuesByNum
        If @Try > 20   and @LastCount = @Count
          Begin
            Select @Count = @NumValues
          End 
        Select @EndTime = @StartTime
        Select @StartTime = dateadd(day,-1,@EndTime)
      End  
  Select  distinct Result, Result_On, Entry_On, Test_Id   
    from @GetTestValuesByNum 
    order by result_on 
