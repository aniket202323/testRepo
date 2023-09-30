Create Procedure dbo.spSS_ProductionUnitGetInitial
AS
 Declare @NoProductionLine nVarChar(25)
 Select @NoProductionLine = '<Any>'
---------------------------------------------------------
-- Defaults
--------------------------------------------------------
 Select @NoProductionLine as NoProductionLine
-------------------------------------------------------
-- Production Lines
-------------------------------------------------------
 Create Table #PL (PL_Id Int Null, PL_Desc nVarChar(50) Null)
 Insert Into #PL
  Select PL_Id, PL_Desc
   From Prod_Lines
    Where PL_Id<>0
 Insert Into #PL (PL_Id, PL_Desc) 
  Values (0, @NoProductionLine)
 Select PL_Id, PL_Desc 
  From #PL
   Order by PL_Desc
 Drop Table #PL
