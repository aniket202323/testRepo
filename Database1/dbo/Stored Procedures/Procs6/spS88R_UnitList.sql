CREATE procedure [dbo].[spS88R_UnitList]
@UserId int
AS
/******************************************************
-- For Testing
--*******************************************************
Select @UserId = 1
--*******************************************************/
Select pu.PU_ID, PL.PL_Desc + ' - ' + pu.PU_Desc PU_DESC
  From Prod_Units pu
  Join Prod_Lines PL ON PL.PL_ID = PU.PL_ID
Where PU.PU_Id <> 0 and PU.PU_Desc like '<%>'
