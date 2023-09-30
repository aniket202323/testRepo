Create Procedure dbo.SpServer_PurgeComments
AS
Declare
  @@CommentId int,
  @Num int,
  @Cmd nVarChar(1000)
Select @Num = 0
Declare Comment_Cursor INSENSITIVE CURSOR
  For (Select Comment_Id From Comments Where (ShouldDelete = 1))
  For Read Only
  Open Comment_Cursor  
Fetch_Loop:
  Fetch Next From Comment_Cursor Into @@CommentId
  If (@@Fetch_Status = 0)
    Begin
      Delete From Comments Where Comment_Id = @@CommentId
      Select @Num = @Num + 1
      If ((@Num % 1000) = 0)
        Begin
          Select @Cmd = 'Dump Transaction ' + db_name() + ' With No_Log'
          Execute(@Cmd)
        End
      Goto Fetch_Loop 
    End
Close Comment_Cursor
Deallocate Comment_Cursor
Return(@Num)
