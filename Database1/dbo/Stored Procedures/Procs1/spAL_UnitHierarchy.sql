Create Procedure dbo.spAL_UnitHierarchy AS
  SELECT PL_Id, PL_Desc FROM Prod_Lines
  SELECT PU_Id, PU_Desc, PL_Id FROM Prod_Units
