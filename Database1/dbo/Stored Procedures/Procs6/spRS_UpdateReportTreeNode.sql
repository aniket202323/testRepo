CREATE PROCEDURE dbo.spRS_UpdateReportTreeNode
@Node_Id int,
@Node_Name varchar(50),
@URL varchar(255), 
@Node_Id_Type int = NULL,
@ForceRunMode int = NULL,
@SendParameters int = Null
 AS
Declare @MyError int
Select @MyError = 0
If @Node_Id_Type Is Null
  Begin
    Update Report_Tree_Nodes Set
      Node_Name = @Node_Name,
      URL = @URL,
 	   ForceRunMode = @ForceRunMode,
 	   SendParameters = @SendParameters
      Where Node_Id = @Node_Id
  End
Else
  Begin
    Update Report_Tree_Nodes Set
      Node_Name = @Node_Name,
      URL = @URL,
      Node_Id_Type = @Node_Id_Type,
 	   ForceRunMode = @ForceRunMode,
 	   SendParameters = @SendParameters
      Where Node_Id = @Node_Id
  End
If @@Error <> 0
  return (1)
Else
  return (0)
