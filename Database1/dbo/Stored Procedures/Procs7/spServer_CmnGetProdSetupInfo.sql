CREATE PROCEDURE dbo.spServer_CmnGetProdSetupInfo
@Id int,
@PLId int OUTPUT,
@Found int OUTPUT
AS
Declare
  @PPId int
Select @Found = 0
Select @PPId = NULL
Select @PPId = PP_Id From Production_Setup Where PP_Setup_Id = @Id
If (@PPId Is NULL)
  Return
Execute spServer_CmnGetProdPlanInfo @PPId,@PLId OUTPUT,@Found OUTPUT 
