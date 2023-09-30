CREATE PROCEDURE dbo.spServer_SchMgrGetSetupPPId     
@PPSetupId int,
@PPId int OUTPUT 
AS
Select @PPId = NULL
Select @PPId = PP_Id From Production_Setup Where PP_Setup_Id = @PPSetupId
If (@PPId Is NULL)
  Select @PPId = 0
