Create Procedure dbo.spEMPSC_GetAssociatedUnits  
@ProdStatusId int,
@User_Id int
AS
Select PU.PU_Id as Id, PL.PL_Desc  + ' - ' + PU.PU_Desc as 'Associated Units'
  From Prod_Units PU
  Join PrdExec_Status PS on PS.PU_Id = PU.PU_Id
  Join Prod_Lines PL on PL.PL_Id = PU.PL_Id
  Where PS.Valid_Status = @ProdStatusId
  order by PL.PL_Desc, PU.PU_Desc
