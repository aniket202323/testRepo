CREATE PROCEDURE dbo.spRS_DeleteReportTreeUser
@User_Id int
 AS
Delete From Report_Tree_Users
  Where User_Id = @User_Id
IF @@Error <> 0
  RETURN (1)
ELSE
  RETURN (0)
