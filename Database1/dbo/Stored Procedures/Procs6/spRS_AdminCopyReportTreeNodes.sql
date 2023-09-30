CREATE PROCEDURE dbo.spRS_AdminCopyReportTreeNodes
@SourceTree Int,
@SourceNode Int,
@TargetTree Int,
@TargetNode Int
AS
------------------------------------
-- Local Parameters
------------------------------------
Declare @SourceNodeType int
Declare @TargetNodeType int
Declare @ThisNode int
Declare @ThisNodeType int
Declare @LocalID int
Declare @ParentNodeId int
Declare @NewRowId int
Declare @InsertId Int
------------------------------------
-- Temp Table
------------------------------------
CREATE TABLE #NODES_TO_BE_COPIED(
LOCAL_ID INT IDENTITY (1, 1) NOT NULL,
INSERT_ID INT, 
Report_Tree_Template_Id Int,
Node_Id Int,
Node_Id_Type Int,
Parent_Node_Id Int,
Report_Def_Id Int,
Report_Type_Id Int,
Node_Order Int,
Node_Level Int,
Node_Name VarChar(50),
URL VarChar(255),
ForceRunMode TinyInt,
SendParameters TinyInt
)
------------------------------------
-- Insert Seed Nodes
------------------------------------
If (@SourceNode Is Null) AND (@TargetNode Is Null)
 	 --This Works
 	 Insert Into #NODES_TO_BE_COPIED(Report_Tree_Template_Id, Node_Id, Node_Id_Type, Parent_Node_Id, Report_Def_Id,Report_Type_Id,Node_Order,Node_Level,Node_Name,URL,ForceRunMode,SendParameters)
 	  	 Select @TargetTree, Node_Id, Node_Id_Type, Null ,Report_Def_Id,Report_Type_Id,Node_Order,Node_Level,Node_Name,URL,ForceRunMode,SendParameters
 	  	 From Report_Tree_Nodes where Report_Tree_Template_Id = @SourceTree AND Parent_Node_Id Is Null
Else If (@SourceNode Is Null) AND (@TargetNode Is Not Null)
 	 Insert Into #NODES_TO_BE_COPIED(Report_Tree_Template_Id, Node_Id, Node_Id_Type, Parent_Node_Id, Report_Def_Id,Report_Type_Id,Node_Order,Node_Level,Node_Name,URL,ForceRunMode,SendParameters)
 	  	 Select @TargetTree, Node_Id, Node_Id_Type, Null ,Report_Def_Id,Report_Type_Id,Node_Order,Node_Level,Node_Name,URL,ForceRunMode,SendParameters
 	  	 From Report_Tree_Nodes where Report_Tree_Template_Id = @SourceTree AND Parent_Node_Id Is Null
Else If (@SourceNode Is Not Null) AND (@TargetNode Is Null)
 	 --This Works
 	 Insert Into #NODES_TO_BE_COPIED(Report_Tree_Template_Id, Node_Id, Node_Id_Type, Parent_Node_Id, Report_Def_Id,Report_Type_Id,Node_Order,Node_Level,Node_Name,URL,ForceRunMode,SendParameters)
 	  	 Select @TargetTree, Node_Id, Node_Id_Type, 1, Report_Def_Id, Report_Type_Id,Node_Order, Node_Level, Node_Name, URL, ForceRunMode, SendParameters
 	  	 From Report_Tree_Nodes where Node_Id = @SourceNode
Else If (@SourceNode Is Not Null) AND (@TargetNode Is Not Null)
 	 --This Works
 	 Insert Into #NODES_TO_BE_COPIED(Report_Tree_Template_Id, Node_Id, Node_Id_Type, Parent_Node_Id, Report_Def_Id,Report_Type_Id,Node_Order,Node_Level,Node_Name,URL,ForceRunMode,SendParameters)
 	  	 Select @TargetTree, Node_Id, Node_Id_Type, 1, Report_Def_Id,Report_Type_Id, Node_Order, Node_Level, Node_Name, URL, ForceRunMode, SendParameters
 	  	 From Report_Tree_Nodes where Node_Id = @SourceNode
------------------------------------
-- Populate Seed Sub-Nodes
------------------------------------
Declare @MyCursor Cursor
Set  @MyCursor = Cursor For
 	 Select LOCAL_ID, Node_Id, Node_Id_Type From #NODES_TO_BE_COPIED
Open @MyCursor
MyLoop1:
 	 Fetch Next From @MyCursor Into @LocalID, @ThisNode, @ThisNodeType
 	 If (@@Fetch_Status = 0)
 	  	 Begin 
 	  	  	 If @ThisNodeType in (1,2,3)-- Folder That May Contain Other Nodes
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into #NODES_TO_BE_COPIED(Report_Tree_Template_Id, Node_Id,Node_Id_Type,Parent_Node_Id,Report_Def_Id,Report_Type_Id,Node_Order,Node_Level,Node_Name,URL,ForceRunMode,SendParameters)
 	  	  	  	  	  	 Select @TargetTree,Node_Id,Node_Id_Type,@LocalID,Report_Def_Id,Report_Type_Id,Node_Order,Node_Level,Node_Name,URL,ForceRunMode,SendParameters
 	  	  	  	  	  	 From Report_Tree_Nodes where Parent_Node_Id = @ThisNode
 	  	  	  	 End 
 	  	  	 Goto MyLoop1
 	  	 End 
myEnd:
Close @MyCursor
Deallocate @MyCursor
------------------------------------
-- Loop through temp table 
-- and insert into real table
------------------------------------
Declare @InsertCursor Cursor
Set  @InsertCursor = Cursor For
 	 Select LOCAL_ID, Node_Id, Parent_Node_Id, Node_Id_Type From #NODES_TO_BE_COPIED
Open @InsertCursor
MyLoop2:
 	 Fetch Next From @InsertCursor into @LocalId, @ThisNode, @ParentNodeId, @ThisNodeType
 	 If (@@Fetch_Status = 0)
 	  	 Begin 	  	  	 
 	  	  	 Insert Into Report_Tree_Nodes(Report_Tree_Template_Id, Node_Id_Type, Parent_Node_Id, Report_Def_Id, Report_Type_Id,Node_Order, Node_Level, Node_Name, URL, ForceRunMode, SendParameters)
 	  	  	 Select Report_Tree_Template_Id, Node_Id_Type, Null, Report_Def_Id,Report_Type_Id, Node_Order, Node_Level, Node_Name, URL, ForceRunMode, SendParameters
 	  	  	 From #NODES_TO_BE_COPIED Where Node_Id = @ThisNode
 	  	  	 
 	  	  	 --Record the identity of the row just added
 	  	  	 Select @NewRowId = Scope_Identity()
 	  	  	 Update #NODES_TO_BE_COPIED Set Insert_Id = Scope_Identity() Where Local_Id = @LocalId
 	  	  	 Select @InsertId = Insert_Id From #NODES_TO_BE_COPIED Where Local_Id = @ParentNodeId
 	  	  	 -- Update The Parent_Node_Id
 	  	  	 if (@LocalId = 1)
 	  	  	  	 Update Report_Tree_Nodes Set Parent_Node_Id = @TargetNode Where Node_Id = @NewRowId
 	  	  	 Else If (@ParentNodeId Is Null) AND (@TargetNode Is Not Null)
 	  	  	  	 Update Report_Tree_Nodes Set Parent_Node_Id = @TargetNode Where Node_Id = @NewRowId
 	  	  	 Else
 	  	  	  	 Update Report_Tree_Nodes Set Parent_Node_Id = @InsertId Where Node_Id = @NewRowId
 	  	  	 GoTo MyLoop2
 	  	 End
Close @InsertCursor
Deallocate @InsertCursor
Drop Table #NODES_TO_BE_COPIED
---------------------------------------
-- Reset the Node_Order and Node_Level
---------------------------------------
If (@TargetNode Is Not Null)
Begin
 	 Declare @TargetNodeParentId int
 	 Declare @TargetNodeOrder int
 	 Select @TargetNodeParentId = Parent_Node_Id, @TargetNodeOrder = Node_Order From Report_Tree_Nodes Where Node_Id = @TargetNode
 	 Exec spRS_SetNodeTreeOrder @TargetNode, @TargetNodeParentId, @TargetNodeOrder
End
