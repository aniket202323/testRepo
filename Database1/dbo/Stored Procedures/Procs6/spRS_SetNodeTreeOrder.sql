CREATE PROCEDURE dbo.spRS_SetNodeTreeOrder
@NodeId int, 
@ParentNodeId int,
@NodeOrder int
AS
---Local Vars
Declare @myNode int
Declare @ok int
Declare @nodeCounter int
Declare @TemplateId int
Declare @myError int
Declare @NodeLevel int
Select @nodeCounter = 1
Select @MyError = 0
-- Get the Template Id
Select @TemplateId = Report_Tree_Template_Id
From Report_Tree_Nodes
Where Node_Id = @nodeId
CREATE TABLE #Temp_Table(
    Node_Id int,
    Parent_Node_Id int,
    Node_Order int,
    Node_Name varchar(50),
    Node_Level int)
If @nodeId = @parentNodeId
  Begin
  Insert Into #Temp_Table
    Select node_Id, Parent_Node_Id, node_order, node_name, Node_Level
    From report_tree_Nodes
    where 
   	 (report_tree_template_Id = @TemplateId and parent_Node_Id is Null)
      or
 	 (report_tree_template_Id = @TemplateId and parent_Node_Id = Node_Id)
      or
 	 (report_tree_template_Id = @TemplateId and parent_Node_Id = @ParentNodeId)
      or
 	 (report_tree_template_Id = @TemplateId and Node_Id = @NodeId)
      Order By Parent_Node_Id asc, Node_Order asc
      Select @ParentNodeId = Null
  End
Else
  Begin
  Insert Into #Temp_Table
    Select node_Id, Parent_Node_Id, node_order, node_name, Node_Level
    From report_tree_Nodes
    where 
 	 (report_tree_template_Id = @TemplateId and parent_Node_Id = @ParentNodeId)
      or
 	 (report_tree_template_Id = @TemplateId and Node_Id = @NodeId)
      Order By Parent_Node_Id asc, Node_Order asc
  End
-- Get the level
If @ParentNodeId Is Null
  Select @NodeLevel = 0
Else
  Begin
    Exec spRS_GetUserTreeNodeLevel @ParentNodeId, @NodeLevel output
    Select @NodeLevel = @NodeLevel + 1
  End
/*
Select @NodeLevel 'Node Level', @ParentNodeId 'ParentNodeId'
Select @NodeId 'NodeId', @ParentNodeId 'ParentNodeId', @NodeOrder 'NodeOrder'
Select 'Temp_Table'
select * from #Temp_Table
*/
--Declare CurSetNodeTreeOrder INSENSITIVE CURSOR
--  For (
-- 	 select node_Id --, Parent_Node_Id, node_order, node_name
-- 	 from #Temp_Table
--      )
--  For Read Only
--  Open CurSetNodeTreeOrder  
----BEGIN TRANSACTION
--MyLoop1:
--  Fetch Next From CurSetNodeTreeOrder Into @myNode 
--  If (@@Fetch_Status = 0)
--    Begin -- Begin Loop Here
-- 	 -- What is the node count?
---- 	 If (@nodeCounter = @nodeOrder)
---- 	   Begin
---- 	     Select 'This is where I want to be'
---- 	   End
-- 	 If @myNode = @nodeId
--          Begin
-- 	  	 -- This is the node being affected
-- 	  	 -- update #Temp_Table
-- 	  	 --Select 'Setting Myself ' + convert(varchar(5), @MyNode) + ' to ' + convert(varchar(5), @nodeOrder)
-- 	  	 Update Report_Tree_Nodes
-- 	         Set Node_Order = @nodeOrder,
-- 	  	 Parent_Node_Id = @parentNodeId,
-- 	  	 Node_Level = @NodeLevel
-- 	         Where Node_Id = @nodeId 	     
-- 	  	 If @@Error <> 0 
-- 	  	   Select @MyError = 1
--          End
--        Else
-- 	   Begin
-- 	  	 -- These are the rest of the sibling nodes
-- 	  	 -- update #Temp_Table
-- 	  	 If @NodeCounter = @NodeOrder
-- 	  	   Select @NodeCounter = @NodeCounter + 1
 	  	 
-- 	  	 --Select 'Setting ' + convert(varchar(5), @MyNode) + ' to ' + convert(varchar(5), @nodeCounter)
-- 	  	 Update Report_Tree_Nodes
-- 	  	 Set Node_Order = @nodeCounter,
-- 	  	 Node_Level = @NodeLevel
-- 	  	 Where Node_Id = @myNode
-- 	  	 Select @nodeCounter = @nodeCounter + 1
-- 	  	 If @@Error <> 0 
-- 	  	   Select @MyError = 2
-- 	   End
-- 	 Goto MyLoop1
--    End -- End Loop Here
--  Else -- Nothing Left To Loop Through
--    goto myEnd
--myEnd:
  UPDATE report_tree_Nodes SET Node_Order = @nodeOrder,
 	  	 Parent_Node_Id = @parentNodeId,
 	  	 Node_Level = @NodeLevel  Where  Node_Id = @nodeId
Declare @parentNodeorder int
 	  	  SELECT @parentNodeorder = Node_Order From report_tree_Nodes where Node_Id = @parentNodeId AND @parentNodeId IS NOT NULL
Declare @dif int
Select @dif = @NodeOrder-Node_Order from #Temp_Table where Node_Id = @NodeId
if @dif = 1 
begin
 	 UPDATE #Temp_Table SET Node_Order = @NodeOrder-@dif where Node_Order = @NodeOrder
 	 UPDATE #Temp_Table SET Node_Order = @NodeOrder Where Node_Id = @NodeId and Parent_Node_Id =@ParentNodeId
 	 
end
else
begin
 	 UPDATE #Temp_Table SET Node_Order = @NodeOrder Where Node_Id = @NodeId and Parent_Node_Id =@ParentNodeId
 	 UPDATE #Temp_Table SET Node_Order = Node_Order+1 Where Node_Order >= @NodeOrder and Node_Id <> @NodeId
end
;WITH S As (
  Select *,row_number() Over (Partition by PArent_Node_Id Order by Node_Order) rownum from #Temp_Table)
  UPDATE S SET Node_Order = rownum Where rownum <> Node_Order
  UPDATE #Temp_Table SET Node_Order = Case when Node_Order>=@parentNodeorder then Node_Order+1 else Node_Order End
  UPDATE RptNodes
  SET Rptnodes.Node_Order=Tmp.Node_Order
  from report_tree_Nodes RptNodes join #Temp_Table Tmp on Tmp.Node_Id = RptNodes.Node_Id and Tmp.Parent_Node_Id = RptNodes.Parent_Node_Id
exec spRS_SetUserTreeNodeLevel @NodeId
/*
Select 'Temp_Table'
select * from #Temp_Table
order by Node_Order asc
*/
--Close CurSetNodeTreeOrder
--Deallocate CurSetNodeTreeOrder
Drop Table #Temp_Table
If @MyError = 0
  Begin
--    Commit Transaction
    Return (0)
  End
Else
  Begin
--    Rollback Transaction
    Return @MyError
  End
