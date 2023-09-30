CREATE PROCEDURE dbo.spServer_CmnGetProdPlanInfo
@Id int,
@PLId int OUTPUT,
@Found int OUTPUT
AS
Declare
  @PathId int
Select @Found = 0
Select @PathId = NULL
Select @PathId = Path_Id From Production_Plan Where PP_Id = @Id
If (@PathId Is NULL)
  Return
Select @PLId = NULL
Select @PLId = PL_Id From PrdExec_Paths Where Path_Id = @PathId
If (@PLId Is NULL)
  Return
Select @Found = 1
select pu_id from prdexec_path_units where path_id = @pathid
