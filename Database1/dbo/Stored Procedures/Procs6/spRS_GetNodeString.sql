CREATE PROCEDURE dbo.spRS_GetNodeString
@Node_Id int,
@Node_String varchar(20) output
 AS 
Declare @ParentNodeId int,
@TempNodeId int,
@Position int,
@TemplateId int
select @Node_String = ""
select @TempNodeId = @Node_Id
-- Who is my parent?
Select @ParentNodeId = Parent_Node_Id, @TemplateId = Report_Tree_Template_Id
From Report_Tree_Nodes
Where Node_Id = @TempNodeId
Select @TemplateId = Report_Tree_Template_Id
From Report_Tree_Nodes
Where Node_Id = @Node_Id
-- Am I the first node?
IF @ParentNodeId = @TempNodeId
  Begin
 	 Select @Position = count(*) 
 	 From  Report_Tree_Nodes
 	 Where Parent_Node_Id = Node_Id and
 	      Report_Tree_Template_Id = @TemplateID and
 	      Node_Id < @TempNodeId
 	 Select @Node_String =   LTrim(RTrim(convert(varchar(10),@Position)))
    return
  End
NextLevel:
select @Position = count(*) 
From  Report_Tree_Nodes
Where Parent_Node_Id = @ParentNodeId and Node_Id < @TempnodeId
 	 and @ParentNodeId <> Node_Id
--Format the string
select @Node_String =  '-' + convert(varchar(10),@Position) + @Node_String
Select @TempNodeId = @ParentNodeId
Select @ParentNodeId = Parent_Node_Id
From Report_Tree_Nodes
Where Node_Id = @TempNodeId
IF @TempNodeId = @ParentNodeId 
 	 BEGIN
 	     Select @Position = Count(*)
 	        from Report_Tree_Nodes 
 	        WHERE  Report_Tree_Template_Id = @TemplateId and node_Id  = Parent_Node_Id and Node_Id < @TempNodeId
 	        select @Node_String =  LTrim(RTrim( convert(varchar(10),@Position) + @Node_String))
 	  	 
 	    return
 	 END
goto nextLevel
