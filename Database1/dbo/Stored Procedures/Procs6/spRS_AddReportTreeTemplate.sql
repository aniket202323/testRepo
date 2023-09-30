CREATE PROCEDURE dbo.spRS_AddReportTreeTemplate
@Template_Name varchar(50),
@Template_Id int output
 AS
Insert into Report_Tree_Templates(
  Report_Tree_Template_Name)
Values(
  @Template_Name)
Select @Template_Id = Scope_Identity()
If @Template_Id Is NULL
  Return (0)
Else
  Return (1)
