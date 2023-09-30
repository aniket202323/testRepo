CREATE PROCEDURE dbo.spRS_AddReportTreeUser
@User_Id int,
@Report_Tree_Template_Id int
 AS
INSERT INTO Report_Tree_Users(
  User_Id,
  Report_Tree_Template_Id,
  User_Rights)
VALUES(
  @User_Id,
  @Report_Tree_Template_Id,
  0)
IF @@Error <> 0
  RETURN (1)
ELSE
  RETURN (0)
