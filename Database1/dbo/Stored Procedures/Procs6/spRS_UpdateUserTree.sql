/* This SP is used by Report Server V2 */
CREATE PROCEDURE dbo.spRS_UpdateUserTree
@User_Id 	 int,
@Child_Node_Id  int,
@Report_Def_Id 	 int
 AS
Declare @Report_Tree_Template_Id     	 int
Declare @Parent_Node_Id  	  	 int
Declare @Node_Name 	  	  	 varchar(50)
Declare @New_Row 	  	  	 int
Declare @RtnVal 	  	  	  	 int
-- Get the User Template Id
Select @Report_Tree_Template_Id = Report_Tree_Template_Id
  From Report_Tree_Users
  Where User_Id = @User_Id
-- Get the Parent Node Id from the child node
Select @Parent_Node_Id = Parent_Node_Id
  From Report_Tree_Nodes
  where Node_Id = @Child_Node_Id
-- Get the report definition
Select @Node_Name = Report_Name 
  from Report_Definitions
  where Report_Id = @Report_Def_id
Exec @RtnVal = spRS_AddReportTreeNode @Report_Tree_Template_Id, 7, @Node_Name, @Parent_Node_Id, @Report_Def_Id,null, null, @New_Row
If @RtnVal = 1
  Return (0)
Else
  Return (1)
/*
-- Add the report definition to the users tree
Insert into Report_Tree_Nodes(
  Report_Tree_Template_Id,
  Node_Id_Type,
  Node_Name,
  Parent_Node_Id,
  Report_Def_Id)  
Values(
  @Report_Tree_Template_Id,
  7,
  @Node_Name,
  @Parent_Node_Id,
  @Report_Def_Id)
If @@Error <> 0
  Return (1) 	 -- Problem with sp
Else
  Return (0)    -- sp ran ok
*/
