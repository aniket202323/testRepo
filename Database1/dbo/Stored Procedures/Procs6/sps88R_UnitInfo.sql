CREATE PROCEDURE [dbo].[sps88R_UnitInfo]
  @UnitId INT
AS
SELECT PU_Id, PU_Desc
FROM Prod_Units
WHERE PU_Id = @UnitId
