CREATE PROCEDURE dbo.spRS_DeleteReportTreeTemplate
@Template_Id int
 AS
DECLARE @MyError int
Select @MyError = 0
BEGIN TRANSACTION
-- ********************************
-- Delete Related Report_Tree_Nodes
-- ********************************
DELETE FROM Report_Tree_Nodes
  WHERE Report_Tree_Template_Id = @Template_Id
IF @@Error <> 0
  Select @MyError = 1
-- ********************************
-- Delete Related Report_Tree_Users
-- ********************************
DELETE FROM Report_Tree_Users
  WHERE Report_Tree_Template_Id = @Template_Id
IF @@Error <> 0
  Select @MyError = 2
-- ********************************
-- Delete The Template
-- ********************************
DELETE FROM Report_Tree_Templates
  WHERE Report_Tree_Template_Id = @Template_Id
IF @@Error <> 0
  Select @MyError = 3
IF @MyError = 0
  BEGIN
    COMMIT TRANSACTION
    RETURN (@MyError)
  END
ELSE
  BEGIN
    ROLLBACK TRANSACTION
    RETURN (@MyError)
  END
