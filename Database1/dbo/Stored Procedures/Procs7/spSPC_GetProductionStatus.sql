Create Procedure dbo.spSPC_GetProductionStatus
AS
Select ID = ProdStatus_Id, Description = ProdStatus_Desc, Good = Count_For_Production
  From Production_Status
