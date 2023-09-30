CREATE PROCEDURE dbo.spServer_CmnGetProdSetupDetailInfo
@Id int,
@PLId int OUTPUT,
@Found int OUTPUT
AS
Declare
  @PPId int,
  @PPSetupId int
Select @Found = 0
Select @PPSetupId = NULL
Select @PPSetupId = PP_Setup_Id From Production_Setup_Detail Where PP_Setup_Detail_Id = @Id
If (@PPSetupId Is NULL)
  Return
Select @PPId = NULL
Select @PPId = PP_Id From Production_Setup Where PP_Setup_Id = @PPSetupId
If (@PPId Is NULL)
  Return
Execute spServer_CmnGetProdPlanInfo @PPId,@PLId OUTPUT,@Found OUTPUT 
