CREATE PROCEDURE dbo.spRS_AddReportQue
/* This sp is used by Report Server V2*/
@Schedule_Id int
AS
Declare @Exists int
Declare @MyError int
Select @MyError = 0
Select @Exists = Schedule_Id
From Report_Que
Where Schedule_Id = @Schedule_Id
If @Exists Is Null
Begin
  Insert Into Report_Que(
    Schedule_Id)
  Values(
    @Schedule_Id)
 If @@Error <> 0 
    Select @MYError = 1
  Update Report_Schedule
    Set Status = 2,
 	 Computer_Name = Null,
 	 Process_Id = Null
    Where Schedule_Id = @Schedule_Id
  If @@Error <> 0 
     Select @MyError = 2
End
IF @MyError <> 0
  RETURN (0) -- No Errors
ELSE
  RETURN @MYError
