CREATE FUNCTION dbo.fnServer_CmnGetTestData(
@VarId int,
@PUId int,
@Time1 datetime,
@Time2 datetime,
@IncludeStartTime int, -- (0 or 1) default 0 
@IncludeEndTime int, -- (0 or 1) default 1
@HonorRejects int,
@Direction nVarChar(10),
@NumValuesRequested int,
@IgnoreNulls int,
@HonorProduct int, -- Only return values where product is the one being made at the time requested
@UseAppliedProduct int, -- Support using applied product
@ProductIdOverride int -- Null = Use actual product, otherwise use this one as an override
) 
     RETURNS @ResultTestData Table (Event_Id int NULL, Result nVarChar(255) NULL, Result_On datetime, Test_Id bigint NULL, Entry_On datetime)
AS 
BEGIN -- Function
-- This fn WILL return a table
-- 	  	 If there is an error, there will be a single row in the table
-- 	  	  	 Event_Id will be -1
-- 	  	  	 Result will contain an error msg
--
-- 	 Usage Notes:
--
-- 	 @Time1 MUST be set
-- 	 If Time2 is set
-- 	  	 @Time2 must be greater than @Time1
-- 	  	 @Direction will be ignored
-- 	  	 @NumValuesRequested will be ignored
-- 	  	 Result, Result_On, Event_Id will be set to NULL
--
-- 	  @IncludeStartTime only recognized when @Time2 is set
-- 	  @IncludeEndTime only recognized when @Time2 is set
--
-- 	 Possible Directions '<','<=','=','>','>=' or Closest Value '><' or Current Value '*'
-- 	 If @Direction is '=' or '*',  this sp will assume @NumValuesRequested is 1
--
Declare
 	 @VarEventType int,
 	 @MasterPUId int,
 	 @DataFound int,
 	 @VarReject int,
 	 @VarPUId int,
 	 @StartTime datetime,
 	 @EndTime datetime,
 	 @L_Reject float,
 	 @U_Reject float,
 	 @PS_StartTime datetime, 
 	 @PS_EndTime datetime, 
 	 @ProdId int,
 	 @PAIsRecordingByEventId int,
 	 @Status1 int,
 	 @Status2 int,
 	 @ErrorMsg1 nVarChar(255),
 	 @ErrorMsg2 nVarChar(255),
 	 @ResultOn1 datetime,
 	 @ResultOn2 datetime,
 	 @TimeDiff1 int,
 	 @TimeDiff2 int,
 	 @Future datetime,
 	 @Now datetime,
 	 @LimitTime datetime,
 	 @ResultCount int,
 	 @RawResultCount int,
 	 @ProdLookupTime datetime,
 	 @TargetStartTime datetime,
 	 @TargetEndTime datetime,
 	 @TargetProdId int,
 	 @TimeMultiplier int
Declare @TestData Table (EventId int NULL, Result nVarChar(255) NULL, ResultOn datetime, L_Reject float null, U_Reject float null, ProdId int, TestId bigint, EntryOn datetime)
Declare @TestData1 Table (EventId int NULL, Result nVarChar(255) NULL, Timestamp datetime, TestId bigint, EntryOn datetime)
Declare @TestData2 Table (EventId int NULL, Result nVarChar(255) NULL, Timestamp datetime, TestId bigint, EntryOn datetime)
Declare @ProdStartData Table (PU_Id int, Prod_Id int, Start_Time datetime, End_Time datetime null)
If (@Time1 Is NULL)
 	 Begin
 	  	 insert into @ResultTestData(Event_Id, Result, Result_On, Test_Id , Entry_On)
 	  	  	 Select -1,'Invalid Time1 [NULL]',GetDate(), -1, GetDate()
 	  	 Return
 	 End
Select @Future 	  	  	  	 = Dateadd(year,5,GetDate())
Select @DataFound 	  	  	 = NULL
Select @VarEventType 	 = NULL
Select @VarEventType = Event_Type, @VarReject = Var_Reject, @VarPUId = PU_Id From Variables_Base Where Var_Id = @VarId
If (@PUId Is NULL) Or (@PUId = 0) or (@VarPUId <> -100)
 	 Select @PUId = @VarPUId
Select @MasterPUId 	  	 = COALESCE(Master_Unit,@PUId) From Prod_Units_Base Where PU_Id = @PUId
If (@IgnoreNulls Is NULL)
 	 Select @IgnoreNulls = 1
If (@IgnoreNulls <> 0)
 	 Select @IgnoreNulls = 1
 	 
Select @PAIsRecordingByEventId = NULL
Select @PAIsRecordingByEventId = ValidateTestData From Event_Types Where (ET_Id = @VarEventType)
If (@PAIsRecordingByEventId Is NULL)
 	 Select @PAIsRecordingByEventId = 0
If (@VarReject Is NULL)
 	 Select @VarReject = 0
If (@IncludeStartTime Is NULL)
 	 Select @IncludeStartTime = 0
If (@IncludeEndTime Is NULL)
 	 Select @IncludeEndTime = 1
If (@HonorRejects Is NULL)
 	 Select @HonorRejects = 0
If (@Time1 Is Not NULL) And (@Time2 Is NULL) And (@NumValuesRequested Is Not NULL) And (@NumValuesRequested > 0) And 
 	  	 (@Direction Is Not NULL) And (@Direction <> '')
Begin
 	  	 
 	 If (@Direction <> '>') And (@Direction <> '>=') And (@Direction <> '=') And (@Direction <> '<') And (@Direction <> '<=') And (@Direction <> '><') And (@Direction <> '*')
 	 Begin
 	  	 insert into @ResultTestData(Event_Id, Result, Result_On, Test_Id , Entry_On)
 	  	  	 Select -1,'Invalid Direction [' + @Direction + ']',GetDate(), -1, GetDate()
 	  	 Return
 	 End
End
if (@HonorProduct = 1)
Begin
 	 -- Figure out the Target times for grade lookups
 	 If (@Time1 Is Not NULL) And (@Time2 Is NULL) And (@NumValuesRequested Is Not NULL) And (@NumValuesRequested > 0) And (@Direction Is Not NULL) And (@Direction <> '')
 	  	 Set @ProdLookupTime = @Time1
 	 else If (@Time1 Is Not NULL) And (@Time2 Is Not NULL) And (@Time2 > @Time1)
 	  	 Set @ProdLookupTime = @Time2
 	 -- Figure out the Target Product
 	 if (@ProductIdOverride is null)
 	 Begin
 	  	 -- Get the product map near the lookup time, this is the grade we will honor for the rest of the data we gather
 	  	 if (@UseAppliedProduct = 1)
 	  	 Begin
 	  	  	 Insert Into @ProdStartData(PU_Id, Prod_Id, Start_Time, End_Time)
 	  	  	   select @MasterPUId, ProdId, StartTime, EndTime
 	  	  	  	 from fnCMN_GetPSFromEvents(@MasterPUId,DateAdd(second,-1,@ProdLookupTime),DateAdd(second,1,@ProdLookupTime))
 	  	 end
 	  	 Else
 	  	 Begin
 	  	  	 Insert Into @ProdStartData(PU_Id, Prod_Id, Start_Time, End_Time)
 	  	  	   Select PU_Id, Prod_Id, Start_Time, Case when End_Time is null then dbo.fnServer_CmnGetDate(GETUTCDATE()) else End_Time end
 	  	  	  	 from Production_Starts
 	  	  	  	 where PU_Id = @MasterPUId and Start_Time < @ProdLookupTime and (@ProdLookupTime <= End_Time or End_Time is null)
 	  	  	  	 order by Start_Time Asc
 	  	 end
 	  	 -- lookup the target grade
 	  	 Select @TargetProdId = Prod_Id
 	  	   From @ProdStartData
 	  	   where PU_Id = @MasterPUId and Start_Time < @ProdLookupTime and (@ProdLookupTime <= End_Time or End_Time is null)
 	 End
 	 Else
 	  	 Set @TargetProdId = @ProductIdOverride
 	 -- Set the override for recursive calls, we don't want to do the lookup again
 	 Set @ProductIdOverride = @TargetProdId
 	 If (@Time1 Is Not NULL) And (@Time2 Is NULL) And (@NumValuesRequested Is Not NULL) And (@NumValuesRequested > 0) And (@Direction Is Not NULL) And (@Direction <> '')
 	 Begin
 	  	 Select @Now 	  	 = dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	 
 	  	 If (@Direction = '*')
 	  	 Begin
 	  	  	 Set @Time1 = @Now
 	  	  	 Set @Direction = '<='
 	  	  	 Set @NumValuesRequested = 1
 	  	 End
 	  	 If ((@Direction = '>') or (@Direction = '>='))
 	  	 Begin
 	  	  	 Set @TargetStartTime = DateAdd(minute,-1,@Time1)
 	  	  	 Select @ResultCount = COUNT(*) from @TestData
 	  	  	 While (@TargetStartTime < @Now) and (@ResultCount < @NumValuesRequested)
 	  	  	 Begin
 	  	  	  	 Set @TargetEndTime = DateAdd(hour,12,@TargetStartTime)
 	  	  	  	 delete from @TestData1
 	  	  	  	 Insert Into @TestData1(EventId, Result, Timestamp, TestId, EntryOn)
 	  	  	  	  	 Select Event_Id, Result, Result_On, Test_Id, Entry_On
 	  	  	  	  	   from dbo.fnServer_CmnGetTestData(@VarId, @PUId, @TargetStartTime, @TargetEndTime, 0, 0, @HonorRejects, null, null, @IgnoreNulls, @HonorProduct, @UseAppliedProduct, @ProductIdOverride)
 	  	  	  	 delete from @TestData1 where TestId in (select TestId from @TestData)
 	  	  	  	 delete from @TestData1 where Timestamp < @Time1
 	  	  	  	 if (@Direction = '>')
 	  	  	  	  	 delete from @TestData1 where Timestamp = @Time1
 	  	  	  	 Insert Into @TestData(EventId, Result, ResultOn, TestId, EntryOn)
 	  	  	  	  	 Select top (@NumValuesRequested - @ResultCount) EventId, Result, Timestamp, TestId, EntryOn
 	  	  	  	  	   from @TestData1
 	  	  	  	  	   order by Timestamp asc
 	  	  	  	 Set @TargetStartTime = @TargetEndTime
 	  	  	  	 Select @ResultCount = COUNT(*) from @TestData
 	  	  	 End
 	  	  	 goto FinalCleanup
 	  	 End
 	  	 Else If ((@Direction = '<') 	 or (@Direction = '<='))
 	  	 Begin
 	  	  	 set @LimitTime = DateAdd(day,-180,@Time1)
 	  	  	 Set @TargetEndTime = DateAdd(minute,1,@Time1)
 	  	  	 Select @ResultCount = COUNT(*) from @TestData
 	  	  	 set @TimeMultiplier = 1
 	  	  	 While (@TargetEndTime > @LimitTime) and (@ResultCount < @NumValuesRequested)
 	  	  	 Begin
 	  	  	  	 Set @TargetStartTime = DateAdd(hour,-(24 * @TimeMultiplier),@TargetEndTime)
 	  	  	  	 delete from @TestData1
 	  	  	  	 Insert Into @TestData1(EventId, Result, Timestamp, TestId, EntryOn)
 	  	  	  	  	 Select Event_Id, Result, Result_On, Test_Id, Entry_On
 	  	  	  	  	   from dbo.fnServer_CmnGetTestData(@VarId, @PUId, @TargetStartTime, @TargetEndTime, 0, 0, @HonorRejects, null, null, @IgnoreNulls, @HonorProduct, @UseAppliedProduct, @ProductIdOverride)
 	  	  	  	 Select @RawResultCount = COUNT(*) from @TestData1
 	  	  	  	 delete from @TestData1 where TestId in (select TestId from @TestData)
 	  	  	  	 delete from @TestData1 where Timestamp > @Time1
 	  	  	  	 if (@Direction = '<')
 	  	  	  	  	 delete from @TestData1 where Timestamp = @Time1
 	  	  	  	 Insert Into @TestData(EventId, Result, ResultOn, TestId, EntryOn)
 	  	  	  	  	 Select top (@NumValuesRequested - @ResultCount) EventId, Result, Timestamp, TestId, EntryOn
 	  	  	  	  	   from @TestData1
 	  	  	  	  	   order by Timestamp desc
 	  	  	  	 Set @TargetEndTime = @TargetStartTime
 	  	  	  	 Select @ResultCount = COUNT(*) from @TestData
 	  	  	  	 if (@RawResultCount < 10000)
 	  	  	  	  	 set @TimeMultiplier = @TimeMultiplier + 1
 	  	  	  	 else if (@RawResultCount > 15000)
 	  	  	  	  	 set @TimeMultiplier = @TimeMultiplier - 1
 	  	  	 End
 	  	  	 goto FinalCleanup
 	  	 End
 	 End
 	 -- Figure out the Target times for grade lookups
 	 If (@Time1 Is Not NULL) And (@Time2 Is NULL) And (@NumValuesRequested Is Not NULL) And (@NumValuesRequested > 0) And (@Direction Is Not NULL) And (@Direction <> '') And (@Direction <> '*')
 	 begin
 	  	 If (@Direction = '=')
 	  	 Begin
 	  	  	 Set @TargetStartTime = DateAdd(minute,-1,@Time1)
 	  	  	 Set @TargetEndTime = DateAdd(minute,1,@Time1)
 	  	 End
 	 end
 	 else If (@Time1 Is Not NULL) And (@Time2 Is Not NULL) And (@Time2 > @Time1)
 	 begin
 	  	 Set @TargetStartTime = DateAdd(minute,-1,@Time1)
 	  	 Set @TargetEndTime = DateAdd(minute,1,@Time2)
 	 end
 	 -- Now, get the grade map loaded in for the target time range
 	 delete from @ProdStartData
 	 if (@UseAppliedProduct = 1)
 	 Begin
 	  	 Insert Into @ProdStartData(PU_Id, Prod_Id, Start_Time, End_Time)
 	  	   select @MasterPUId, ProdId, StartTime, EndTime
 	  	     from fnCMN_GetPSFromEvents(@MasterPUId,@TargetStartTime,@TargetEndTime)
 	  	 delete from @ProdStartData where Prod_Id <> @TargetProdId
 	 End
 	 Else
 	 Begin
 	  	 Insert Into @ProdStartData(PU_Id, Prod_Id, Start_Time, End_Time)
 	  	   Select PU_Id, Prod_Id, Start_Time, Case when End_Time is null then dbo.fnServer_CmnGetDate(GETUTCDATE()) else End_Time end
 	  	     from Production_Starts
 	  	     where PU_Id = @MasterPUId and Prod_Id = @TargetProdId and Start_Time < @TargetEndTime and (End_Time >= @TargetStartTime or End_Time is null)
 	  	     order by Start_Time Asc
 	 End
End
If (@Time1 Is Not NULL) And (@Time2 Is NULL) And (@NumValuesRequested Is Not NULL) And (@NumValuesRequested > 0) And 
 	  	 (@Direction Is Not NULL) And (@Direction <> '')
 	 Begin
 	  	 
 	  	 If (@Direction = '=') Or (@Direction = '*')
 	  	  	 Select @NumValuesRequested = 1
 	  	  	 
 	  	 -- Closest Value
 	  	 If (@Direction = '><')
 	  	  	 Begin
 	  	  	 
 	  	  	  	 Insert Into @TestData1(EventId, Result, Timestamp, TestId, EntryOn)
 	  	  	  	  	 Select Event_Id, Result, Result_On, Test_Id, Entry_On
 	  	  	  	  	   from dbo.fnServer_CmnGetTestData(@VarId, @PUId, @Time1, NULL, 0, 0, @HonorRejects, '<=', 1, @IgnoreNulls, @HonorProduct, @UseAppliedProduct, @ProductIdOverride)
 	  	  	  	 Insert Into @TestData2(EventId, Result, Timestamp, TestId, EntryOn)
 	  	  	  	  	 Select Event_Id, Result, Result_On, Test_Id, Entry_On
 	  	  	  	  	   from dbo.fnServer_CmnGetTestData(@VarId, @PUId, @Time1, NULL, 0, 0, @HonorRejects, '>',  1, @IgnoreNulls, @HonorProduct, @UseAppliedProduct, @ProductIdOverride)
 	  	  	  	 
 	  	  	  	 Select @Status1 = NULL
 	  	  	  	 Select @Status2 = NULL
 	  	  	  	 Select @ErrorMsg1 = NULL
 	  	  	  	 Select @ErrorMsg2 = NULL
 	  	  	  	 
 	  	  	  	 Select @Status1 = EventId, @ErrorMsg1 = Result From @TestData1 Where EventId = -1
 	  	  	  	 Select @Status2 = EventId, @ErrorMsg2 = Result From @TestData2 Where EventId = -1
 	  	  	  	 If (@Status1 Is NULL)
 	  	  	  	  	 Select @Status1 = 1
 	  	  	  	 Else
 	  	  	  	  	 Select @Status1 = 0
 	  	  	  	 If (@Status2 Is NULL)
 	  	  	  	  	 Select @Status2 = 1
 	  	  	  	 Else 	  	  	  	 
 	  	  	  	  	 Select @Status2 = 0 	  	  	  	 
 	  	  	  	 
 	  	  	  	 If (@Status1 = 0) And (@Status2 = 0)
 	  	  	  	  	 Begin
 	  	  	  	  	  	 insert into @ResultTestData(Event_Id, Result, Result_On, Test_Id , Entry_On)
 	  	  	  	  	  	  	 Select -1,'[' + @ErrorMsg1 + '] And [' + @ErrorMsg2 + ']',GetDate(), -1, GetDate()
 	  	  	  	  	  	 Return
 	  	  	  	  	 End
 	  	  	  	 
 	  	  	  	 If (@Status1 = 0) 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select EventId,Result,Timestamp,TestId,EntryOn From @TestData2
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@Status2 = 0) 
 	  	  	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select EventId,Result,Timestamp,TestId,EntryOn From @TestData1
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 Select @ResultOn1 = NULL
 	  	  	  	  	  	  	  	 Select @ResultOn2 = NULL
 	  	  	  	 
 	  	  	  	  	  	  	  	 Select @ResultOn1 = Timestamp From @TestData1
 	  	  	  	  	  	  	  	 Select @ResultOn2 = Timestamp From @TestData2
 	  	  	  	  	  	  	  	 If (@ResultOn1 = @Time1)
 	  	  	  	  	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select EventId,Result,Timestamp,TestId,EntryOn From @TestData1
 	  	  	  	  	  	  	  	 Else
 	  	  	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  	 Select @TimeDiff1 = Datediff(second,@ResultOn1,@Time1)
 	  	  	  	  	  	  	  	  	  	 Select @TimeDiff2 = Datediff(second,@ResultOn2,@Time1) * -1
 	  	  	  	  	  	  	  	  	  	 If (@TimeDiff1 < @TimeDiff2)
 	  	  	  	  	  	  	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select EventId,Result,Timestamp,TestId,EntryOn From @TestData1
 	  	  	  	  	  	  	  	  	  	 Else
 	  	  	  	  	  	  	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select EventId,Result,Timestamp,TestId,EntryOn From @TestData2
 	  	  	  	  	  	  	  	  	 End
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	  	 
 	  	 -- Time , ProductionEvent ByTime, ProductChange ByTime, ProcessOrder ByTime Or (We are not storing eventids for this eventtype)
 	  	 Else If (@PAIsRecordingByEventId = 0) Or (@VarEventType = 0) Or (@VarEventType = 5) Or (@VarEventType = 26) Or (@VarEventType = 28) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On 
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On 
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On >  @Time1)  And (Result Is Not NULL) /*And (Event_Id Is NULL)*/ Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On >= @Time1)  And (Result Is Not NULL) /*And (Event_Id Is NULL)*/ Order By Result_On 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On <  @Time1)  And (Result Is Not NULL) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On <= @Time1)  And (Result Is Not NULL) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On =  @Time1)  And (Result Is Not NULL) /*And (Event_Id Is NULL)*/ Order By Result_On 
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On <  @Future) And (Result Is Not NULL) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On >  @Time1)  /*And (Event_Id Is NULL)*/ Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On >= @Time1)  /*And (Event_Id Is NULL)*/ Order By Result_On 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On <  @Time1)  /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On <= @Time1)  /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On =  @Time1)  /*And (Event_Id Is NULL)*/ Order By Result_On 
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On <  @Future) /*And (Event_Id Is NULL)*/ Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	  	 
 	  	 -- Production Event 
 	  	 Else If (@VarEventType = 1) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	 -- Segment Response 
 	  	 Else If (@VarEventType = 31) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc 
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) Join SegmentResponse c on (c.SegmentResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc 
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc 
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc 
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	  	 
 	  	 -- Work Response 
 	  	 Else If (@VarEventType = 32) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc 
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join S95_Event b on (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) Join WorkResponse c on (c.WorkResponseId = b.S95_Guid) Join PAEquipment_Aspect_SOAEquipment d on (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc 
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc 
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc 
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*') 	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId) Order By Result_On Desc 
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	  	 
 	  	 -- Waste 
 	  	 Else If (@VarEventType = 3) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1) 	 And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1) 	 Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1) 	 Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b on (b.WED_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	 -- User-Defined 
 	  	 Else If (@VarEventType = 14) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1) 	 And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1) 	 Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1) 	 Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	  	 
 	  	 -- Product Change 
 	  	 Else If (@VarEventType = 4) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1) 	 And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1) 	 Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1) 	 Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	  	 
 	  	 -- Process Order 
 	  	 Else If (@VarEventType = 19) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1) 	 And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	 And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1) 	 Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1) 	 Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	 Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	 -- Input Genealogy 
 	  	 Else If (@VarEventType = 17) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1) 	  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	 -- Downtime
 	  	 Else If (@VarEventType = 2) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	  	 
 	  	 -- Uptime 
 	  	 Else If (@VarEventType = 22) 
 	  	  	 Begin
 	  	  	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (s.Prod_Id = @TargetProdId) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Join @ProdStartData s on s.PU_Id = @MasterPUId and a.Result_On > s.Start_Time and a.Result_On <= s.End_Time Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (s.Prod_Id = @TargetProdId) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 If (@IgnoreNulls = 1)
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  And (a.Result Is Not NULL) Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) And (a.Result Is Not NULL) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 Else
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	  	  If (@Direction = '>')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >  @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '>=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '<')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Time1)  Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '<=') Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <= @Time1)  Order By Result_On Desc
 	  	  	  	  	  	  	  	 Else If (@Direction = '=')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On =  @Time1)  Order By Result_On
 	  	  	  	  	  	  	  	 Else If (@Direction = '*')  Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Top (@NumValuesRequested) a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On <  @Future) Order By Result_On Desc
 	  	  	  	  	  	  	 End
 	  	  	  	  	 End
 	  	  	 End
 	  	 -- Not Supported
 	  	 Else
 	  	  	 Begin
 	  	  	  	 insert into @ResultTestData(Event_Id, Result, Result_On, Test_Id , Entry_On)
 	  	  	  	  	 Select -1,'Event Type [' + Convert(nVarChar(25),@VarEventType) + '] Not Supported',GetDate(), -1, GetDate()
 	  	  	  	 Return
 	  	  	 End
 	  	  	 
 	 End
 	 
Else If (@Time1 Is Not NULL) And (@Time2 Is Not NULL) And (@Time2 > @Time1)
 	 Begin
 	  	 If (@IgnoreNulls = 1)
 	  	  	 Begin 	 
 	  	  	  	 -- Time , ProductionEvent ByTime, ProductChange ByTime, ProcessOrder ByTime Or (We are not storing eventids for this eventtype)
 	  	  	  	 If (@PAIsRecordingByEventId = 0) Or (@VarEventType = 0) Or (@VarEventType = 5) Or (@VarEventType = 26) Or (@VarEventType = 28) 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On >= @Time1) And (Result_On <= @Time2) And (Result Is Not NULL) -- And (Event_Id Is NULL)
 	  	  	  	 Else If (@VarEventType = 1) -- Production Event 	  	  	 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And 	  	  	  	  	  	  	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2) And (a.Result Is Not NULL)
 	  	  	  	 Else If (@VarEventType = 31) -- Segment Response 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >=  @Time1) And (a.Result_On <=  @Time2) And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId)
 	  	  	  	 Else If (@VarEventType = 32) -- Work Response 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >=  @Time1) And (a.Result_On <=  @Time2) And (a.Result Is Not NULL) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId)
 	  	  	  	 Else If (@VarEventType = 3) -- Waste 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b 	 on (b.WED_Id = a.Event_Id) And 	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2) And (a.Result Is Not NULL)
 	  	  	  	 Else If (@VarEventType = 14) -- User-Defined 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And 	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2) And (a.Result Is Not NULL)
 	  	  	  	 Else If (@VarEventType = 4) -- Product Change 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And 	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2) And (a.Result Is Not NULL)
 	  	  	  	 Else If (@VarEventType = 19) -- Process Order 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And 	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2) And (a.Result Is Not NULL)
 	  	  	  	 Else If (@VarEventType = 17) -- Input Genealogy 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And 	  	  	  	  	  	  	  	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2) And (a.Result Is Not NULL)
 	  	  	  	 Else If (@VarEventType = 2) -- Downtime
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And 	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2) And (a.Result Is Not NULL)
 	  	  	  	 Else If (@VarEventType = 22) -- Uptime 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And 	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2) And (a.Result Is Not NULL)
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 insert into @ResultTestData(Event_Id, Result, Result_On, Test_Id , Entry_On)
 	  	  	  	  	  	  	 Select -1,'Event Type [' + Convert(nVarChar(25),@VarEventType) + '] Not Supported',GetDate(), -1, GetDate()
 	  	  	  	  	  	 Return
 	  	  	  	  	 End
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 -- Time , ProductionEvent ByTime, ProductChange ByTime, ProcessOrder ByTime Or (We are not storing eventids for this eventtype)
 	  	  	  	 If (@PAIsRecordingByEventId = 0) Or (@VarEventType = 0) Or (@VarEventType = 5) Or (@VarEventType = 26) Or (@VarEventType = 28) 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select Event_Id, Result, Result_On, Test_Id, Entry_On From Tests Where (Var_Id = @VarId) And (Result_On >= @Time1) And (Result_On <= @Time2) -- And (Event_Id Is NULL)
 	  	  	  	 Else If (@VarEventType = 1) -- Production Event 	  	  	 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And 	  	  	  	  	  	  	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2) 
 	  	  	  	 Else If (@VarEventType = 31) -- Segment Response 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, SegmentResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >=  @Time1) And (a.Result_On <=  @Time2) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 31) And (c.SegmentResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId)
 	  	  	  	 Else If (@VarEventType = 32) -- Work Response 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a , S95_Event b, WorkResponse c, PAEquipment_Aspect_SOAEquipment d Where (a.Var_Id = @VarId) And (a.Result_On >=  @Time1) And (a.Result_On <=  @Time2) And (b.Event_Id = a.Event_Id) And (b.Event_Type = 32) And (c.WorkResponseId = b.S95_Guid) And (d.Origin1EquipmentId = c.EquipmentId) And (d.PU_Id = @MasterPUId)
 	  	  	  	 Else If (@VarEventType = 3) -- Waste 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Waste_Event_Details b 	 on (b.WED_Id = a.Event_Id) And 	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2)
 	  	  	  	 Else If (@VarEventType = 14) -- User-Defined 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join User_Defined_Events b on (b.UDE_Id = a.Event_Id) And 	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2)
 	  	  	  	 Else If (@VarEventType = 4) -- Product Change 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Starts b on (b.Start_Id = a.Event_Id) And 	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2)
 	  	  	  	 Else If (@VarEventType = 19) -- Process Order 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Production_Plan_Starts b on (b.PP_Start_Id = a.Event_Id) And 	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2)
 	  	  	  	 Else If (@VarEventType = 17) -- Input Genealogy 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Events b on (b.Event_Id = a.Event_Id) And 	  	  	  	  	  	  	  	  	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2)
 	  	  	  	 Else If (@VarEventType = 2) -- Downtime
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And 	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2)
 	  	  	  	 Else If (@VarEventType = 22) -- Uptime 
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn,TestId,EntryOn) Select a.Event_Id, a.Result, a.Result_On, a.Test_Id, a.Entry_On From Tests a Join Timed_Event_Details b on (b.TEDET_Id = a.Event_Id) And 	  	  	  	 (b.PU_Id = @MasterPUId) Where (a.Var_Id = @VarId) And (a.Result_On >= @Time1) And (a.Result_On <= @Time2)
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 insert into @ResultTestData(Event_Id, Result, Result_On, Test_Id , Entry_On)
 	  	  	  	  	  	  	 Select -1,'Event Type [' + Convert(nVarChar(25),@VarEventType) + '] Not Supported',GetDate(), -1, GetDate()
 	  	  	  	  	  	 Return
 	  	  	  	  	 End
 	  	  	 End
 	  	  	 
 	  	 If (@IncludeStartTime = 0)
 	  	  	 Delete From @TestData Where (ResultOn = @Time1)
 	  	 If (@IncludeEndTime = 0)
 	  	  	 Delete From @TestData Where (ResultOn = @Time2)
 	  	 if ((@HonorProduct = 1) and (@TargetProdId is not null))
 	  	  	 Begin
 	  	  	  	 update @TestData
 	  	  	  	   set ProdId = Prod_Id
 	  	  	  	   from @ProdStartData where PU_Id = @MasterPUId and ResultOn > Start_Time and ResultOn <= End_Time
 	  	  	  	 Delete From @TestData Where (ProdId is null) or (ProdId <> @TargetProdId)
 	  	  	 End
 	 End 	 
Else
 	 Begin
 	  	 insert into @ResultTestData(Event_Id, Result, Result_On, Test_Id , Entry_On)
 	  	  	 Select -1,'Invalid Parameter Combination [' + Convert(nVarChar(30),@Time1) + '] [' + Convert(nVarChar(30),@Time2) + '] [' + Convert(nVarChar(30),@NumValuesRequested) + '] [' + @Direction + ']',GetDate(), -1, GetDate()
 	  	 Return
 	 End
FinalCleanup:
Select @DataFound = Count(*) From @TestData
If (@DataFound Is NULL) Or (@DataFound = 0)
 	 Return
If (@HonorRejects = 0) Or (@VarReject = 0)
 	 Begin
 	  	 insert into @ResultTestData(Event_Id, Result, Result_On, Test_Id , Entry_On)
 	  	  	 Select EventId, Result, ResultOn, TestId, EntryOn From @TestData Order By ResultOn
 	  	 Return
 	 End
Select @MasterPUId = Master_Unit from Prod_Units_Base where PU_Id = @VarPUId
If (@MasterPUId is null) 
 	 Select @MasterPUId = @VarPUId
 	 
Select @StartTime = Min(ResultOn), @EndTime = Max(ResultOn) from @TestData
Declare Starts Cursor Read_Only
  For Select Start_Time, End_Time, Prod_Id
    From Production_Starts
 	  	 Where PU_Id = @MasterPUId
 	  	  	 and ((@StartTime >  Start_Time and @StartTime <= End_Time)
      or (@EndTime   >  Start_Time and @EndTime   <= End_Time)
      or (@StartTime <= Start_Time and @EndTime   >= End_Time)
      or (@EndTime   >  Start_Time and End_Time is null))
 	  	 Open Starts
    Fetch Next From Starts Into @PS_StartTime, @PS_EndTime, @ProdId
    While @@FETCH_STATUS = 0
      Begin
        Select @L_Reject = L_Reject, @U_Reject = U_Reject From Var_Specs
         Where Var_Id = @VarId and Prod_Id = @ProdId
           and (Effective_Date  <=  @PS_EndTime or (@PS_EndTime is null and Effective_Date < @PS_StartTime))
           and (Expiration_Date > @PS_EndTime or Expiration_Date is null)
        Update @TestData Set L_Reject = @L_Reject, U_Reject = @U_Reject Where ResultOn > @PS_StartTime and (ResultOn <= @PS_EndTime or @PS_EndTime is null)
        Fetch Next From Starts Into @PS_StartTime, @PS_EndTime, @ProdId
      End
Close Starts
Deallocate Starts
insert into @ResultTestData(Event_Id, Result, Result_On, Test_Id , Entry_On)
 	 Select EventId, Result, ResultOn, TestId, EntryOn
 	  	 From @TestData
 	  	 Where ((L_Reject is null) Or (convert(float,Result) >= L_Reject))
 	  	  	 and ((U_Reject is null) Or (convert(float,Result) <= U_Reject))
 	  	 Order By ResultOn
return
END
