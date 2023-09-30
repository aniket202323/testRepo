CREATE PROCEDURE dbo.spEM_GetNPTUnits 
  AS
 	 SELECT PU_Id,UnitName = PL_desc + '.' + Pu_Desc
 	 FROM Prod_Units pu
 	 Join Prod_Lines pl on pl.PL_Id = pu.PL_Id
 	 WHERE Non_Productive_Category Is Not NUll
 	 ORDER BY UnitName
