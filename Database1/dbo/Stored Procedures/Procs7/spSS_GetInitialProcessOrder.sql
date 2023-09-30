Create Procedure dbo.spSS_GetInitialProcessOrder
AS
 Declare @AnyProduct nVarChar(50),
 	  @NoProductionUnit nVarChar(50)
 Select @AnyProduct = '<Any>'
 Select @NoProductionUnit =  '<Any>'
---------------------------------------------------------
-- Defaults
--------------------------------------------------------
 Select @AnyProduct as AnyProduct, @NoProductionUnit as NoProductionUnit
-----------------------------------------------------------
-- Product Unit combo box
-----------------------------------------------------------
 Create Table #PU (PU_Id int, PU_Desc nVarChar(50))
 Insert Into #PU 
  Select PU_Id, PU_Desc
   From Prod_Units PU  
    Where PU_Id<>0
 Insert Into #PU
  Select 0, @NoProductionUnit  
 Select PU_Id, PU_Desc
  From #PU  
   Order by PU_Desc
 Drop Table #PU
