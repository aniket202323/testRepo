CREATE PROCEDURE dbo.spSupport_FixTestsTable
AS
Declare
  @VarId int,
  @TestId BigInt,
  @UserId int,
  @TimeStamp datetime
Select @VarId = NULL
Select @VarId = Max(Var_Id) From Variables
If (@VarId Is NULL)
  Return
Select @UserId = NULL
Select @UserId = Max(User_Id) From Users
If (@UserId Is NULL)
  Return
Select @TestId = NULL
Select @TestId = Max(Test_Id) From Tests
If (@TestId Is NULL)
  Select @TestId = 1
Else
  Select @TestId = @TestId + 1
Select @TimeStamp = GetDate()
Set Identity_Insert Tests On
Insert Into Tests(Test_Id,Var_Id,Result_On,Entry_On,Entry_By,Result) Values(@TestId,@VarId,@TimeStamp,@TimeStamp,@UserId,NULL)
Set Identity_Insert Tests Off
Delete From Tests Where Test_Id = @TestId
