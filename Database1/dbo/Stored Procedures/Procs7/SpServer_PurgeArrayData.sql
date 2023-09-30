Create Procedure dbo.SpServer_PurgeArrayData
AS
Declare
  @@ArrayId int,
  @Num int,
  @Cmd nVarChar(1000)
Select @Num = 0
Declare Array_Cursor INSENSITIVE CURSOR
  For (Select Array_Id From Array_Data Where (ShouldDelete = 1))
  For Read Only
  Open Array_Cursor  
Fetch_Loop:
  Fetch Next From Array_Cursor Into @@ArrayId
  If (@@Fetch_Status = 0)
    Begin
      Delete From Array_Data Where Array_Id = @@ArrayId
      Select @Num = @Num + 1
      If ((@Num % 1000) = 0)
        Begin
          Select @Cmd = 'Dump Transaction ' + db_name() + ' With No_Log'
          Execute(@Cmd)
        End
      Goto Fetch_Loop 
    End
Close Array_Cursor
Deallocate Array_Cursor
Return(@Num)
