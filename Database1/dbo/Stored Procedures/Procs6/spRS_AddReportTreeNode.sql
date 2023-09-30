CREATE PROCEDURE dbo.spRS_AddReportTreeNode
@Report_Tree_Template_Id int,
@Node_Id_Type int,
@Node_Name varchar(50),
@Parent_Node_Id int,
@Report_Def_Id int = Null,
@Report_Type_Id int = Null,
@URL varchar(255) = Null,
@New_Row int output
 AS
Declare @MyCount int
Declare @Ok int
Declare @Local_Node_Id_Type int
Declare @Class int
If @Node_Id_Type = 7
  Begin
    Select @Class = Class From Report_Definitions Where Report_Id = @Report_Def_Id
    If @Class = 2
      Begin
        --This definition is scheduled and should have the clock icon
        Select @Local_Node_Id_Type = 4
      End
    Else
      Begin
        --This is just a report def and should have the standard definition icon
        Select @Local_Node_Id_Type = @Node_Id_Type 
      End
  End
Else
  Select @Local_Node_Id_Type = @Node_Id_Type
  INSERT INTO Report_Tree_Nodes(
    Report_Tree_Template_Id,
    Node_Id_Type,
    Node_Name,
    Parent_Node_Id,
    Report_Def_Id,
    Report_Type_Id,
    URL)
  Values(
    @Report_Tree_Template_Id,
    @Local_Node_Id_Type,
    @Node_Name,
    @Parent_Node_Id,
    @Report_Def_Id,
    @Report_Type_Id,
    @URL)
  Select @New_Row = Scope_Identity()
  If @New_Row is Null
    return (0)
  Else
    Begin
/*
      if @Node_Id_Type = 1
        Begin
 	   Update Report_Tree_Nodes
            Set Parent_Node_Id = @New_Row
            Where Node_Id = @New_Row
        End
*/
      -- Get the count at this level
     If @Parent_Node_Id is null
       Begin
         Select @MyCount = Count(Node_Id)
         From Report_Tree_Nodes
         Where Report_Tree_Template_Id = @Report_Tree_Template_Id
         And Parent_Node_Id Is Null
       End
     Else
       Begin
         Select @MyCount = Count(Node_Id)
         From Report_Tree_Nodes
         Where Report_Tree_Template_Id = @Report_Tree_Template_Id
         And Parent_Node_Id = @Parent_Node_Id 	 
       End
     Select @MyCount = @MyCount + 1
     If @Parent_Node_Id Is Null
       Select @Parent_Node_Id = @New_Row
     Exec @Ok = spRS_SetNodeTreeOrder @New_Row, @Parent_Node_Id, @MyCount
 	 
     return (1)
   End
