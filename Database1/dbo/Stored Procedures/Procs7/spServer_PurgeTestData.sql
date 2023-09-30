CREATE PROCEDURE dbo.spServer_PurgeTestData
@VarId int,
@StartTime datetime,
@EndTime datetime,
@NumTestsDeleted int OUTPUT,
@NumTestHistoryDeleted int OUTPUT,
@NumCommentsDeleted int OUTPUT,
@NumArraysDeleted int OUTPUT
AS
Declare
  @CurrentStartTime datetime,
  @CurrentEndTime datetime,
  @@TestId bigint,
  @@CommentId int,
  @@ArrayId int,
  @NumTestHistoryValues int,
  @Cmd nVarChar(1000),
  @MinResultOn datetime,
  @MaxResultOn datetime,
  @NumTestHistoryArraysDeleted int
Declare @TestIds Table(TestId bigint, CommentId int NULL, ArrayId int NULL)
Select @NumTestsDeleted = 0
Select @NumTestHistoryDeleted = 0
Select @NumCommentsDeleted = 0
Select @NumArraysDeleted = 0
If (@VarId Is NULL) Or (@VarId < 1)
  Return
Select @MinResultOn = NULL
Select @MinResultOn = Min(Result_On) From Tests Where Var_Id = @VarId
If (@MinResultOn Is NULL)
  Return
If (@MinResultOn >= @EndTime)
  Return
If (@MinResultOn > @StartTime)
  Select @StartTime = @MinResultOn
Select @MaxResultOn = NULL
Select @MaxResultOn = Max(Result_On) From Tests Where Var_Id = @VarId
If (@MaxResultOn Is NULL)
  Return
If (@MaxResultOn < @EndTime)
  Select @EndTime = @MaxResultOn
Select @CurrentStartTime = @StartTime
DeleteData:
Select @CurrentEndTime = DateAdd(Day,1,@CurrentStartTime)
If (@CurrentEndTime > @EndTime)
  Select @CurrentEndTime = @EndTime
Insert Into @TestIds (TestId,CommentId,ArrayId) (Select Test_Id,Comment_Id,Array_Id From Tests Where (Var_Id = @VarId) And (Result_On >= @CurrentStartTime) And (Result_On <= @CurrentEndTime))
Declare Value_Cursor INSENSITIVE CURSOR 
  For (Select TestId,CommentId,ArrayId From @TestIds) Order By TestId
  For Read Only
  Open Value_Cursor  
Value_Loop:
  Fetch Next From Value_Cursor Into @@TestId,@@CommentId,@@ArrayId
  If (@@Fetch_Status = 0)
    Begin
      Select @NumTestsDeleted = @NumTestsDeleted + 1
      Delete From Tests Where Test_Id = @@TestId
      Select @NumTestHistoryValues = NULL
      Select @NumTestHistoryValues = Count(*) From Test_History Where Test_Id = @@TestId
      If (@NumTestHistoryValues Is Not NULL) And (@NumTestHistoryValues > 0)
        Begin
 	   Select @NumTestHistoryArraysDeleted = NULL
 	   Select @NumTestHistoryArraysDeleted = Count(*) From Test_History Where (Test_Id = @@TestId) And (Array_Id Is Not NULL)
 	   If (@NumTestHistoryArraysDeleted Is Not NULL) And (@NumTestHistoryArraysDeleted > 0)
            Begin
              Select @NumArraysDeleted = @NumArraysDeleted + @NumTestHistoryArraysDeleted
              Delete From Array_Data Where Array_Id = (Select Array_Id From Test_History Where (Test_Id = @@TestId) And (Array_Id Is Not NULL))
            End
          Select @NumTestHistoryDeleted = @NumTestHistoryDeleted + @NumTestHistoryValues
          Delete From Test_History Where Test_Id = @@TestId
        End
      If (@@CommentId Is Not NULL)
        Begin 
          Select @NumCommentsDeleted = @NumCommentsDeleted + 1
          Delete From Comments Where Comment_Id = @@CommentId
        End
      If (@@ArrayId Is Not NULL)
        Begin 
          Select @NumArraysDeleted = @NumArraysDeleted + 1
          Delete From Array_Data Where Array_Id = @@ArrayId
        End
      If ((@NumTestsDeleted % 5000) = 0)
        Begin
          Select @Cmd = 'Dump Transaction ' + db_name() + ' With No_Log'
          Execute(@Cmd)
        End
      Goto Value_Loop
    End
Close Value_Cursor
Deallocate Value_Cursor
If (@CurrentEndTime < @EndTime)
  Begin
    Select @CurrentStartTime = @CurrentEndTime
    Goto DeleteData
  End
