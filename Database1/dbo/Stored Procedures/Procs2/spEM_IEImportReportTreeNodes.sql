CREATE PROCEDURE dbo.spEM_IEImportReportTreeNodes
@Report_Tree_Template_Name 	 nvarchar(50),
@P1_Name 	  	  	  	  	 nvarchar(50) = null,
@P2_Name 	  	  	  	  	 nvarchar(50) = null,
@P3_Name 	  	  	  	  	 nvarchar(50) = null,
@P4_Name 	  	  	  	  	 nvarchar(50) = null,
@P5_Name 	  	  	  	  	 nvarchar(50) = null,
@P6_Name 	  	  	  	  	 nvarchar(50) = null,
@P7_Name 	  	  	  	  	 nvarchar(50) = null,
@P8_Name 	  	  	  	  	 nvarchar(50) = null,
@P9_Name 	  	  	  	  	 nvarchar(50) = null,
@Node_Name 	  	  	  	 nvarchar(50) = null,
@sNode_Id_Type 	  	  	  	 nVarChar(2) = null,
@Report_Name 	  	  	  	 nvarchar(50) = null,
@Report_Type_Name 	  	  	 nvarchar(50) = null,
@sForceRunMode 	  	  	  	 VarChar(4) = null,
@sSendParameters 	  	  	 VarChar(4) = null,
@URL 	  	  	  	  	  	 VarChar(7000) = null,
@sUserId 	  	  	  	  	 VarChar(5)
AS
-- ADD AUDIT TRAIL STUFF
--------------------------------------
-- Local Variables
--------------------------------------
Declare @Node_Level int, @Node_Order int, @Node_Id_Type int, @ForceRunMode int, @SendParameters int, @UserId int
Declare @ReportTreeTemplateId Int
Declare @Parent_Node_Id int, @Child_Id int, @P1_Id int, @P2_Id int, @P3_Id int, @P4_Id int, @P54_Id int, @P6_Id int, @P7_Id int, @P8_Id int, @P9_Id int
Declare @Report_Type_Id int, @Report_Id int
Declare @NodeTable TABLE (Node_Name nvarchar(50))
--------------------------------------
-- Clean Arguments 
--------------------------------------
Select @Report_Tree_Template_Name = LTrim(RTrim(@Report_Tree_Template_Name))
Select @P1_Name = IsNull(RTrim(LTrim(@P1_Name)), '')
Select @P2_Name = IsNull(RTrim(LTrim(@P2_Name)), '')
Select @P3_Name = IsNull(RTrim(LTrim(@P3_Name)), '')
Select @P4_Name = IsNull(RTrim(LTrim(@P4_Name)), '')
Select @P5_Name = IsNull(RTrim(LTrim(@P5_Name)), '')
Select @P6_Name = IsNull(RTrim(LTrim(@P6_Name)), '')
Select @P7_Name = IsNull(RTrim(LTrim(@P7_Name)), '')
Select @P8_Name = IsNull(RTrim(LTrim(@P8_Name)), '')
Select @P9_Name = IsNull(RTrim(LTrim(@P9_Name)), '')
Insert Into @NodeTable(Node_Name) Values(@P1_Name)
Insert Into @NodeTable(Node_Name) Values(@P2_Name)
Insert Into @NodeTable(Node_Name) Values(@P3_Name)
Insert Into @NodeTable(Node_Name) Values(@P4_Name)
Insert Into @NodeTable(Node_Name) Values(@P5_Name)
Insert Into @NodeTable(Node_Name) Values(@P6_Name)
Insert Into @NodeTable(Node_Name) Values(@P7_Name)
Insert Into @NodeTable(Node_Name) Values(@P8_Name)
Insert Into @NodeTable(Node_Name) Values(@P9_Name)
Select @Node_Name = RTrim(LTrim(@Node_Name))
Select @sNode_Id_Type = RTrim(LTrim(@sNode_Id_Type))
Select @Report_Name =  RTrim(LTrim(@Report_Name))
Select @Report_Type_Name =  RTrim(LTrim(@Report_Type_Name))
Select @URL = RTrim(LTrim(@URL))
Select @sForceRunMode = RTrim(LTrim(@sForceRunMode))
Select @sSendParameters = RTrim(LTrim(@sSendParameters))
--------------------------------------
-- Initialize Variables
--------------------------------------
Select @UserId = Convert(int, @sUserId)
Select @Node_Id_Type = Convert(int, @sNode_Id_Type)
If ((@sForceRunMode Is Not Null) AND (@sForceRunMode <> ''))
 	 Select @ForceRunMode = Convert(int, @sForceRunMode)
If ((@sSendParameters Is Not Null) AND (@sSendParameters <> ''))
 	 Select @SendParameters = Convert(int, @sSendParameters)
--------------------------------------
-- If Report Type Name Is Given Then Find It
--------------------------------------
If ((@Report_Type_Name Is Not NULL) AND (@Report_Type_Name <> ''))
  Begin
 	 Select @Report_Type_Id = Report_Type_Id From Report_Types Where Description = @Report_Type_Name
     If @Report_Type_Id Is Null
 	  	 Begin
 	  	  	 Select 'Failed - Report Type Not Found'
 	  	  	 Return(-100)
 	  	 End
  End
--------------------------------------
-- If Report Definition Name Is Given Then Find It
--------------------------------------
If ((@Report_Name Is Not NULL) AND (@Report_Name <> ''))
  Begin
 	 Select @Report_Id = Report_Id From Report_Definitions Where Report_Type_Id = @Report_Type_Id AND Report_Name = @Report_Name
 	 if @Report_Id Is Null
 	  	 Begin
 	  	  	 Select 'Failed - Report Definition Not Found'
 	  	  	 Return(-100)
 	  	 End
  End
--------------------------------------
-- Find or Create Template Tree
--------------------------------------
Print 'Searching For Tree Named: ' + @Report_Tree_Template_Name
select @ReportTreeTemplateId = Report_Tree_Template_Id 
from report_tree_templates 
where Report_Tree_Template_Name = @Report_Tree_Template_Name
If @ReportTreeTemplateId Is Null
  Begin
 	 Insert Into Report_Tree_Templates(Report_Tree_Template_Name)
 	 Values(@Report_Tree_Template_Name)
 	 Select @ReportTreeTemplateId = SCOPE_IDENTITY() 
 	 Print 'Created Tree With Id = ' + convert(varchar(5), @ReportTreeTemplateId)
  End
Else
  Begin
 	 Print 'Tree Found With Id = ' + convert(varchar(5), @ReportTreeTemplateId)
  End
--------------------------------------
-- Begin Loop of @NodeTable
--------------------------------------
Declare @curNode_Name nvarchar(50), @Previous_Parent_Id int, @Previous_Parent_Name nvarchar(50), @Node_Exists int
-- Seed the parent value
/*
Print 'Seeding...'
print 'looking for parent is null and node_name = ' + @P1_Name
Select @Previous_Parent_Id = Node_Id, @Previous_Parent_Name = @P1_Name
From Report_Tree_Nodes
Where Report_Tree_Template_Id = @ReportTreeTemplateId
 	 And Parent_Node_Id Is Null
 	 And Node_Name = @P1_Name
If @Previous_Parent_Id Is Not Null
  Print 'Seed found at ' + convert(varchar(5), @Previous_Parent_Id)
else
  Print 'no seed found'
*/
Declare MyCursor INSENSITIVE CURSOR
  For ( Select Node_Name From @NodeTable )
  For Read Only
  Open MyCursor  
  Fetch Next From MyCursor Into @curNode_Name 
  While (@@Fetch_Status = 0)
    Begin
 	  	 print ' '
 	  	 If @curNode_Name = ''
 	  	  	 Begin
 	  	  	  	 Select @Parent_Node_Id = @Previous_Parent_Id
 	  	  	  	 Break
 	  	  	 End
 	  	 Else
 	  	  	 Begin 
 	  	  	 
 	  	  	  	 Select @Parent_Node_Id = Null
 	  	  	  	 -- Does this node already exist?
 	  	  	  	 -- Find the parent node 	  	  	  	 
 	  	  	  	 
 	  	  	  	 If @Previous_Parent_Id Is Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 print 'searching for folder called ' + @curNode_Name + ' with parent id = NULL'
 	  	  	  	  	  	 Select @Parent_Node_Id = Node_Id 
 	  	  	  	  	  	 From   report_tree_nodes 
 	  	  	  	  	  	 Where  Report_Tree_Template_Id = @ReportTreeTemplateId 
 	  	  	  	  	  	  	  	 and Parent_Node_Id Is Null
 	  	  	  	  	  	  	  	 and Node_Name = @curNode_Name 	  	  	  	  	  	 
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 print 'searching for folder called ' + @curNode_Name + ' with parent id = ' + convert(varchar(5), @Previous_Parent_Id)
 	  	  	  	  	  	 Select @Parent_Node_Id = Node_Id 
 	  	  	  	  	  	 From   report_tree_nodes 
 	  	  	  	  	  	 Where  Report_Tree_Template_Id = @ReportTreeTemplateId 
 	  	  	  	  	  	  	  	 and Parent_Node_Id = @Previous_Parent_Id
 	  	  	  	  	  	  	  	 and Node_Name = @curNode_Name
 	  	  	  	  	 End 	  	  	  	 
 	 
 	  	  	  	 if @Parent_Node_Id is not null
 	  	  	  	  	 print 'Folder was found with id ' + convert(varchar(5), @Parent_node_Id) 	  	  	 
 	  	  	  	 -- Add Parent Node
 	  	  	  	 If @Parent_Node_Id Is Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 exec sprs_AddReportTreeNode @ReportTreeTemplateId, 2, @curNode_Name, @Previous_Parent_Id, @Report_Id, @Report_Type_Id, @URL, @Parent_Node_Id OUTPUT
 	  	  	  	  	  	 If @Parent_Node_Id Is Null
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 Select 'Failed - Unable To Add Folder ' + @curNode_Name
 	  	  	  	  	  	  	  	 Return(-100)
 	  	  	  	  	  	  	 End
 	  	  	  	  	  	 print 'adding parent folder ' + @curNode_Name + ' with node id ' + convert(varchar(5), @Parent_Node_Id)
 	  	  	  	  	 End
 	  	  	  	 Else
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Print 'Node found with Id = ' + convert(varchar(5), @Parent_Node_Id)
 	  	  	  	  	 End
 	  	  	  	 Select @Previous_Parent_Name = @curNode_Name, @Previous_Parent_Id = @Parent_Node_Id
 	  	  	 End
 	  	 Fetch Next From MyCursor Into @curNode_Name
    End 
Close MyCursor
Deallocate MyCursor
ADD_CHILD_NODE:
if @parent_node_id is null
  print 'parent is null'
else
  print 'parent node = ' + convert(varchar(5), @Parent_node_Id)
If @Parent_Node_Id Is Null
 	 Select @Child_Id = Node_Id 
 	 from Report_tree_nodes 
 	 where Report_Tree_Template_Id = @ReportTreeTemplateId
 	  	 AND Parent_Node_Id Is Null
 	  	 AND Node_Id_Type = @Node_Id_Type
 	  	 AND Node_Name = @Node_Name
Else
 	 Select @Child_Id = Node_Id 
 	 from Report_tree_nodes 
 	 where Report_Tree_Template_Id = @ReportTreeTemplateId
 	  	 AND Parent_Node_Id = @Parent_Node_Id
 	  	 AND Node_Id_Type = @Node_Id_Type
 	  	 AND Node_Name = @Node_Name
If @Child_Id Is Null
  Begin
 	 print 'adding node ' + @Node_Name
 	 exec sprs_AddReportTreeNode @ReportTreeTemplateId, @Node_Id_Type, @Node_Name, @Parent_Node_Id, @Report_Id, @Report_Type_Id, @URL, @Child_Id output
 	 print 'new id = ' + convert(varchar(5), @Child_Id)
 	 If @URL Is Not Null
 	   select Char(4) +  Convert(nVarChar(10),@Child_Id)
 	   --Return (-100)
  End
