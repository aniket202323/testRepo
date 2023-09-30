CREATE PROCEDURE [dbo].[spWO_GetLineFromUnitId]
  @UnitId INT
AS
SELECT PL_Id
FROM Prod_Units
WHERE PU_Id = @UnitId
