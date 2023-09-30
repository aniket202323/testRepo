CREATE PROCEDURE dbo.spRS_SetUserTreeNodeLevel 
@NodeId int
AS
Declare @NodeLevel int
Declare @MyCount int
Declare @MyId int
CREATE TABLE #Temp_Master(
    Node_Id int,
    Node_Level int)
CREATE TABLE #Temp_Parent(
    Node_Id int,
    Node_Level int)
CREATE TABLE #Temp_Child(
    Node_Id int,
    Node_Level int)
exec spRS_GetUserTreeNodeLevel @NodeId, @NodeLevel output
Insert Into #Temp_Parent(Node_Id, Node_Level)
Values(@NodeId, @NodeLevel)
GatherChildren:
Insert Into #Temp_Child
Select Node_Id, Node_Level
From Report_Tree_Nodes
Where Parent_Node_Id in(
  Select Node_Id
  From #Temp_Parent)
Select @MyCount = Count(Node_Id)
 from #Temp_child
If @MyCount > 0
  Begin
    -- Insert The parents into the master table
    Insert Into #Temp_Master
    Select * From #Temp_Parent
    Delete From #Temp_Parent
    -- Insert the children into the parents table
    Insert Into #Temp_Parent
    Select * From #Temp_Child
    Delete from #Temp_Child
    goto GatherChildren
  End
Else
  Begin
    -- Insert The parents into the master table
    Insert Into #Temp_Master
    Select * From #Temp_Parent
    goto StartUpdate
  End
StartUpdate:
Declare CurSetUserTreeNodeLevel INSENSITIVE CURSOR
  For (
       Select Node_Id
       From #Temp_Master
      )
  For Read Only
  Open CurSetUserTreeNodeLevel  
-- Go through cursor
MyLoop1:
  Fetch Next From CurSetUserTreeNodeLevel Into @MyId 
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop Here
      -- Get/Set the node level for each node in the master list
      exec spRS_GetUserTreeNodeLevel @MyId, @NodeLevel output
      Update Report_Tree_Nodes
      Set Node_Level = @NodeLevel
      Where Node_Id = @MyId
--      Select @MyId 'NodeId', @NodeLevel 'Level'
      Goto MyLoop1
    End -- End Loop Here
  Else -- Nothing Left To Loop Through
    goto myEnd
myEnd:
Close CurSetUserTreeNodeLevel
Deallocate CurSetUserTreeNodeLevel
Drop Table #Temp_Master
Drop Table #Temp_Parent
Drop Table #Temp_Child
