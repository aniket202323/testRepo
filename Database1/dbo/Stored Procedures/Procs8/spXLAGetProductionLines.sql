Create Procedure dbo.spXLAGetProductionLines
AS 
  SELECT PL_Id, PL_Desc FROM Prod_Lines WHERE PL_Id <> 0 ORDER BY PL_Desc
