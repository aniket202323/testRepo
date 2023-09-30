/*
This Stored Procedure was first used in Version 2 of the Report Server Engine.
It is called after the engine is finished generating a report and the report results are
known.  Results are written to the Report Schedule table and to the Report_Runs table.
*/
CREATE PROCEDURE dbo.spRS_UpdateReportRun
@Run_Id int,
@File_Name varchar(20) = Null,
@End_Time datetime = Null,
@Error_Id int = Null,
@User_Name varchar(20) = Null
 AS
Declare @MyError int
Select @MyError = 0
Begin Transaction
If Not(@File_Name Is Null)
  Update Report_Runs
    Set File_Name = @File_Name
    Where Run_Id = @Run_Id
If @@Error <> 0 
    Select @MyError = 1
If Not(@End_Time Is Null)
  Update Report_Runs
    Set End_Time = @End_Time
    Where Run_Id = @Run_Id
If @@Error <> 0 
    Select @MyError = 2
If Not(@Error_Id Is Null)
  Update Report_Runs
    Set Error_Id = @Error_Id
/* 	 (
      Select Code_Desc
      From Return_Error_Codes
      Where App_Id = 11
      And Group_Id = 5 
      And Code_Value = @Error_Id)
*/
If @@Error <> 0 
    Select @MyError = 3
If Not(@User_Name Is Null)
  Update Report_Runs
    Set User_Id = (
      Select User_Id
      From Users
      Where username = @User_Name)
If @@Error <> 0 
    Select @MyError = 4
If @MyError = 0
  Begin
    Commit Transaction
    Return (@MyError)
  End
Else
  Begin
    RollBack Transaction
    Return (@MyError)
  End
