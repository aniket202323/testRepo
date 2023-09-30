Create Procedure dbo.spDS_GetAddEventGeneralDetail
AS
 Declare  @NoProduct nVarChar(25),
               @ResearchedProducts nVarChar(25),
               @NoStatus nVarChar(25)
 Select @NoProduct = '<No Product>'
 Select @ResearchedProducts = '<Researched Products>'
 Select @NoStatus = '<None>'
--------------------------------------------------------
-- Constants
-------------------------------------------------------
 Select @NoProduct as No_Product, @ResearchedProducts as Researched_Products,  @NoStatus as No_Status
--------------------------------------------------------
-- Event Status
--------------------------------------------------------
DECLARE @Status Table (ProdStatus_Id int , ProdStatus_Desc nVarChar(50),LockData Int)
 Insert Into @Status(ProdStatus_Id,ProdStatus_Desc,LockData)
  Select ProdStatus_Id, ProdStatus_Desc,coalesce(LockData,0)
   From Production_status
    Order by ProdStatus_Id
 Insert Into @Status (ProdStatus_Id,ProdStatus_Desc,LockData) Values (0,@NoStatus,0)
 Select ProdStatus_Id,ProdStatus_Desc,LockData From @Status Order by ProdStatus_Id
