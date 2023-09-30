Create PROCEDURE dbo.spServer_CmnGetTestValuesByNum
@Var_Id int,
@RefTime datetime,
@NumValuesBefore int,
@NumValuesAfter int,
@IncludeRefTime int,
@IncludeNulls  int,
@MU_Id int,
@HonorProduct int = 0, -- Only return values where product is the one being made at the time requested
@UseAppliedProduct int = 0, -- Support using applied product
@ProductIdOverride int = NULL -- Null = Use actual product, otherwise use this one as an override
AS
Declare 
 	 @Count 	 Int,
 	 @TS 	 DateTime,
 	 @NextTime Datetime,
 	 @Now 	 DateTime,
 	 @IgnoreNulls int,
 	 @Status int,
 	 @ErrorMsg nVarChar(255)
If (@IncludeNulls = 0)
 	 Select @IgnoreNulls = 1
Else
 	 Select @IgnoreNulls = 0
Select @Now = dbo.fnServer_CmnGetDate(GetUTCDate())
Declare @GetTestValuesByNum Table(Result nVarChar(30) COLLATE DATABASE_DEFAULT NULL, Result_On datetime NULL, EventId int NULL, TestId bigint NULL, Entry_On datetime NULL)
Declare @TestData Table (EventId int NULL, Result nVarChar(255) NULL, ResultOn datetime, TestId bigint NULL, Entry_On datetime NULL)
If (@NumValuesBefore > 0)
 	 Begin
 	  	 Delete From @TestData
 	  	 If @IncludeRefTime = 1
 	  	  	 Begin
 	  	  	  	 Select @NumValuesBefore = @NumValuesBefore + 1
 	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,Entry_On) Select Event_Id,Result,Result_On,Test_Id,Entry_On from fnServer_CmnGetTestData(@Var_Id,@MU_Id,@RefTime,NULL,0,0,0,'<=',@NumValuesBefore,@IgnoreNulls,@HonorProduct,@UseAppliedProduct,@ProductIdOverride)
 	  	  	 End
 	  	 Else
 	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,Entry_On) Select Event_Id,Result,Result_On,Test_Id,Entry_On from fnServer_CmnGetTestData(@Var_Id,@MU_Id,@RefTime,NULL,0,0,0,'<',@NumValuesBefore,@IgnoreNulls,@HonorProduct,@UseAppliedProduct,@ProductIdOverride)
 	  	 Select @Status = NULL
 	  	 Select @Status = EventId, @ErrorMsg = Result From @TestData Where EventId = -1
 	  	 If (@Status Is NULL)
 	  	  	 Insert Into @GetTestValuesByNum(Result, Result_On, EventId, TestId, Entry_On) (Select Result,ResultOn,EventId,TestId,Entry_On From @TestData)
 	  	  	 
 	 End
If (@NumValuesAfter > 0)
 	 Begin
 	  	 Delete From @TestData
 	  	 If @IncludeRefTime = 1
 	  	  	 Begin
 	  	  	  	 Select @NumValuesAfter = @NumValuesAfter + 1
 	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,Entry_On) Select Event_Id,Result,Result_On,Test_Id,Entry_On from fnServer_CmnGetTestData(@Var_Id,@MU_Id,@RefTime,NULL,0,0,0,'>=',@NumValuesAfter,@IgnoreNulls,@HonorProduct,@UseAppliedProduct,@ProductIdOverride)
 	  	  	 End
 	  	 Else
 	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,Entry_On) Select Event_Id,Result,Result_On,Test_Id,Entry_On from fnServer_CmnGetTestData(@Var_Id,@MU_Id,@RefTime,NULL,0,0,0,'>',@NumValuesAfter,@IgnoreNulls,@HonorProduct,@UseAppliedProduct,@ProductIdOverride)
 	  	 Select @Status = NULL
 	  	 Select @Status = EventId, @ErrorMsg = Result From @TestData Where EventId = -1
 	  	 If (@Status Is NULL)
 	  	  	 Insert Into @GetTestValuesByNum(Result, Result_On, EventId, TestId, Entry_On) (Select Result,ResultOn,EventId,TestId,Entry_On From @TestData)
 	 End
If (@NumValuesAfter = 0) And (@NumValuesBefore = 0) And (@IncludeRefTime = 1)
 	 Begin
 	  	 Delete From @TestData
 	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,Entry_On) Select Event_Id,Result,Result_On,Test_Id,Entry_On from fnServer_CmnGetTestData(@Var_Id,@MU_Id,@RefTime,NULL,0,0,0,'=',1,@IgnoreNulls,@HonorProduct,@UseAppliedProduct,@ProductIdOverride)
 	  	 Select @Status = NULL
 	  	 Select @Status = EventId, @ErrorMsg = Result From @TestData Where EventId = -1
 	  	 If (@Status Is NULL)
 	  	  	 Insert Into @GetTestValuesByNum(Result, Result_On, EventId, TestId, Entry_On) (Select Result,ResultOn,EventId,TestId,Entry_On From @TestData)
 	 End
Select Distinct Result,Result_On,Entry_On,TestId,EventId From @GetTestValuesByNum Order By Result_On 
