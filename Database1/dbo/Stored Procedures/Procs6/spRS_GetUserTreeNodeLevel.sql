CREATE PROCEDURE dbo.spRS_GetUserTreeNodeLevel
@NodeId int,
@Level int output
 AS
-- Local Vars
Declare @MyParent int
Declare @tempId int
Select @Level = 0
--Select 'Start NodeId ' + convert(varchar(5), @NodeId)
Select @tempId = @NodeId
MyLoop:
  If @Level > 100
    goto myEnd
  Select @MyParent = Parent_Node_Id
  From Report_Tree_Nodes
  Where Node_Id = @tempId
  If @MyParent Is Null
    Goto myEnd
  Else
    Begin
      Select @Level = @Level + 1
      Select @tempId = @MyParent
      Goto MyLoop
    End
myEnd:
/* Update function is performed by spRS_SetUserTreeNodeLevel */
/*
Update Report_Tree_Nodes
Set Node_Level = @Level
Where Node_Id = @NodeId
*/
/*
Select 'NodeId: ' + convert(varchar(5), @NodeId) + ' = Level: ' + convert(varchar(5), @Level)
--Select 'Final Level = ' + convert(varchar(5), @Level)
*/
